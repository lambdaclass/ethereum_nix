let
  node = import ./vars.nix;

  validator_logs_dashboard = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/lambdaclass/nixos-infect/refs/heads/grafana-dashboards/nix/validator_logs.json";
    sha256 = "sha256-gilthB/J2eUH0vUs5lO2cw3GULIHH0WZmk/wMI/d+m8=";
  };

  validator_metrics_dashboard = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/lambdaclass/nixos-infect/refs/heads/grafana-dashboards/nix/validator_metrics.json";
    sha256 = "sha256-P5DDQQSnyqHUTvpLACUg9tiqJ6F0Djlv11PAHCFJIao=";
  };

  server_metrics_dashboard = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/lambdaclass/nixos-infect/refs/heads/grafana-dashboards/nix/server_metrics.json";
    sha256 = "sha256-N3qAKgXaph787VB+Ii+CT7xO8MKV8nYRICOMpRN+NE0=";
  };

in { config, pkgs, ... }: {
  environment.etc = {
    "grafana/dashboards/validator_logs.json".source = validator_logs_dashboard;
    "grafana/dashboards/validator_metrics.json".source = validator_metrics_dashboard;
    "grafana/dashboards/server_metrics.json".source = server_metrics_dashboard;
  };

  services.grafana = {
    enable = true;
    settings = {
      analytics.reporting_enabled = false;
      server = {
        http_addr = "${node.grafana.address}";
        http_port = 3000;
        enable_gzip = true;
      };
    };

    provision.dashboards = {
      settings.providers = [
        {
          name = "default";
          options.path = "/etc/grafana/dashboards/";
        }
      ];
    };

    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "prometheus";
          type = "prometheus";
          access = "proxy";
          url = "http://localhost:${toString config.services.prometheus.port}";
        }
        {
          name = "loki";
          type = "loki";
          access = "proxy";
          url = "http://localhost:${toString config.services.loki.configuration.server.http_listen_port}";
        }
      ];
    };
  };

  services.prometheus = {
    enable = true;
    port = 9090;
    globalConfig.scrape_interval = "15s";
    retentionTime = "7d";
    scrapeConfigs = [
      {
        job_name = "lighthouse_beacon";
        static_configs = [{
          targets = [ "localhost:${toString node.lighthouse.beacon.ports.metrics}" ];
        }];
        metrics_path = "/metrics";
      }
      {
        job_name = "lighthouse_validator";
        static_configs = [{
          targets = [ "localhost:${toString node.lighthouse.validator.ports.metrics}" ];
        }];
        metrics_path = "/metrics";
      }
      {
        job_name = "geth";
        static_configs = [{
          targets = [ "localhost:${toString node.geth.ports.metrics}" ];
        }];
        metrics_path = "/debug/metrics/prometheus";
      }
      {
        job_name = "node_exporter";
        static_configs = [{
          targets = [ "localhost:${toString config.services.prometheus.exporters.node.port}" ];
        }];
        metrics_path = "/metrics";
      }
    ];
  };

  services.loki = {
    enable = true;
    configuration = {
      auth_enabled = false;

      server = {
        http_listen_port = 3100;
      };

      ingester = {
        lifecycler = {
          address = "0.0.0.0";
          ring = {
            kvstore = {
              store = "inmemory";
            };
            replication_factor = 1;
          };
        };
        chunk_idle_period   = "12h";
        max_chunk_age       = "12h";
        chunk_target_size   = 1048576;
        chunk_retain_period = "30s";
      };

      schema_config = {
        configs = [
          {
            from         = "2020-10-24";
            store        = "boltdb-shipper";
            schema       = "v11";
            object_store = "filesystem";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }
        ];
      };

      storage_config = {
        boltdb_shipper = {
          active_index_directory = "/var/lib/loki/boltdb-shipper-active";
          cache_location         = "/var/lib/loki/boltdb-shipper-cache";
          cache_ttl              = "24h";
        };
        filesystem = {
          directory = "/var/lib/loki/chunks";
        };
      };

      limits_config = {
        reject_old_samples         = false;
        reject_old_samples_max_age = "168h";
        allow_structured_metadata  = false;
      };

      table_manager = {
        retention_deletes_enabled = false;
        retention_period          = "0s";
      };

      compactor = {
        working_directory = "/var/lib/loki";
        compactor_ring = {
          kvstore = {
            store = "inmemory";
          };
          instance_addr = "127.0.0.1";
        };
      };
    };
  };

  services.prometheus.exporters.node = {
    enable = true;
    port = 10000;
    enabledCollectors = [ "systemd" ];
  };

  services.promtail = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 3031;
        grpc_listen_port = 0;
      };
      positions = {
        filename = "/tmp/positions.yaml";
      };
      clients = [{
        url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}/loki/api/v1/push";
      }];
      scrape_configs = [{
        job_name = "journal";
        journal = {
          max_age = "1h";
          labels = {
            job = "systemd-journal";
          };
        };
        relabel_configs = [
          {
            source_labels = [ "__journal__systemd_user_unit" ];
            target_label = "service_name";
          }
        ];
      }];
    };
  };
}

