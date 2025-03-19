SHELL := $(shell env bash -c 'echo $$0')

# make install_deposit_cli
install_deposit_cli:
	@echo "Fetching latest staking deposit CLI version..."
	@LATEST_URL=$$(curl -sL https://api.github.com/repos/ethereum/staking-deposit-cli/releases/latest | grep "browser_download_url.*linux-amd64.tar.gz" | cut -d '"' -f 4) && \
	[ -n "$$LATEST_URL" ] || { echo "Error: Failed to fetch latest release URL."; exit 1; } && \
	echo "Downloading staking deposit CLI from $$LATEST_URL..." && \
	wget -q "$$LATEST_URL" -O staking_deposit-cli.tar.gz && \
	echo "Extracting staking deposit CLI..." && \
	tar -xzf staking_deposit-cli.tar.gz && \
	mv staking_deposit-cli-*/deposit . && \
	rm -rf staking_deposit-cli-* staking_deposit-cli.tar.gz && \
	echo "Deposit CLI installed successfully!"

# CHAIN=<eth_chain>
# SEED=<seed_phrase> (optional, if already have one)
# KEYSTORE_PASSWORD=<custom_password>
# EXECUTION_ADDRESS=<withdrawals_eth_address>
# make generate_deposit_keys
generate_deposit_keys:
	@[ -n "$(CHAIN)" ] || { echo "Error: variable CHAIN is empty."; exit 1; }
	@[ -n "$(KEYSTORE_PASSWORD)" ] || { echo "Error: variable KEYSTORE_PASSWORD is empty."; exit 1; }
	@[ -n "$(EXECUTION_ADDRESS)" ] || { echo "Error: variable EXECUTION_ADDRESS is empty."; exit 1; } 
	@echo "Generating deposit keys..."
	@if [ -d ~/validator_keys ] && [ -n "$$(ls -A ~/validator_keys 2>/dev/null)" ]; then \
		echo "Error: ~/validator_keys is not empty. Stop."; \
		exit 1; \
	fi
	@if [ -z "$(SEED)" ]; then \
		echo -e "Creating new seed phrase... \n"; \
		SEED=$$(cast wallet new-mnemonic -w 12 | awk 'NR==4'); \
		echo -e "SEED: $$SEED \n"; \
		[ -n "$$SEED" ] || { echo "Error: Failed to generate mnemonic."; exit 1; }; \
		[[ $$(echo "$$SEED" | wc -w) -eq 12 ]] || { echo "Error: Output is not 12 words long."; exit 1; }; \
	fi
	./deposit --language english --non_interactive existing-mnemonic \
		--mnemonic "$$SEED" \
		--validator_start_index 0 \
		--num_validators 1 \
		--chain $(CHAIN) \
		--keystore_password $(KEYSTORE_PASSWORD) \
		--execution_address $(EXECUTION_ADDRESS) \
		> /dev/null 2>&1 && \
	echo "Your keys can be found at: ~/validator_keys"

# make generate_deposit_abi
generate_deposit_abi:
	@DATA=$$(cat ~/validator_keys/deposit_data-*.json) && \
	IFS=$$'\n' VALUES=($$(echo "$$DATA" | jq -r '.[0] | .pubkey, .withdrawal_credentials, .signature, .deposit_data_root')) && \
	echo "PUBKEY: $${VALUES[0]}" && \
	echo "WITHDRAWAL_CREDENTIALS: $${VALUES[1]}" && \
	echo "SIGNATURE: $${VALUES[2]}" && \
	echo "DEPOSIT_DATA_ROOT: $${VALUES[3]}" && \
	echo -e "\n" && \
	cast abi-encode "deposit(bytes,bytes,bytes,bytes32)" \
		0x$${VALUES[0]} \
		0x$${VALUES[1]} \
		0x$${VALUES[2]} \
		0x$${VALUES[3]}

# SEED=<seed_phrase_previously_generated>
# ABI_ENCODE=<output_from_generate_deposit_abi>
# FROM_ADDRESS=<generated_mnemonic_eth_address>
# WALLET_NAME=<custom_wallet_name>
# KEYSTORE_PASSWORD=<custom_password>
# make send_deposit
send_deposit:
	@[ -n "$(SEED)" ] || { echo "Error: variable SEED is empty."; exit 1; }
	@[ -n "$(ABI_ENCODE)" ] || { echo "Error: variable ABI_ENCODE is empty."; exit 1; }
	@[ -n "$(FROM_ADDRESS)" ] || { echo "Error: variable FROM_ADDRESS is empty."; exit 1; }
	@[ -n "$(WALLET_NAME)" ] || { echo "Error: variable WALLET_NAME is empty."; exit 1; }
	@[ -n "$(KEYSTORE_PASSWORD)" ] || { echo "Error: variable KEYSTORE_PASSWORD is empty."; exit 1; }
	@[ -n "$(CHAIN)" ] || { echo "Error: variable CHAIN is empty."; exit 1; }
	@if [ "$(CHAIN)" = "mainnet" ]; then \
        	DEPOSIT_CONTRACT="0x00000000219ab540356cBB839Cbe05303d7705Fa"; \
    	elif [ "$(CHAIN)" = "sepolia" ]; then \
        	DEPOSIT_CONTRACT="0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43"; \
    	elif [ "$(CHAIN)" = "holesky" ]; then \
        	DEPOSIT_CONTRACT="0x4242424242424242424242424242424242424242"; \
    	else \
        	echo "Error: Invalid CHAIN value. Must be mainnet, sepolia, or holesky."; \
        	exit 1; \
    	fi; \
    	cast wallet import $(WALLET_NAME) --unsafe-password "$(KEYSTORE_PASSWORD)" --mnemonic-path "$$SEED" && \
    	cast send $${DEPOSIT_CONTRACT} \
        	--password $(KEYSTORE_PASSWORD) \
        	--value 32ether \
        	--from $(FROM_ADDRESS) \
        	--keystore ~/.foundry/keystores/$(WALLET_NAME) \
        	--rpc-url https://ethereum-$(CHAIN).publicnode.com \
        	$(ABI_ENCODE)
