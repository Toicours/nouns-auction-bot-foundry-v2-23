-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil

# Default network is mainnet, but you can override it with `make deploy NETWORK=goerli`
NETWORK ?= mainnet

help:
	@echo "Usage:"
	@echo "  make deploy [ARGS=...]\n    example: make deploy ARGS=\"--network mainnet\""
	@echo ""
	@echo "  make fund [ARGS=...]\n    example: make fund ARGS=\"--network mainnet\""

all: clean update build

# Clean the repo
clean:
	forge clean

# Update Dependencies
update:
	forge update

build:
	forge build

test:
	forge test

snapshot:
	forge snapshot

format:
	forge fmt

anvil:
	anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1


NETWORK_ARGS := --rpc-url $(MAINNET_RPC_URL)  --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
# Set up network arguments based on the selected network
# ifeq ($(NETWORK),mainnet)
# 	NETWORK_ARGS := --rpc-url $(MAINNET_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
# else
# 	# If not mainnet, use default values or other network configurations
# 	NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast
# endif

# Deploy the contract using the network arguments
deploy:
	@echo "MAINNET_RPC_URL: $(MAINNET_RPC_URL)"
	@echo "PRIVATE_KEY: (PRIVATE_KEY)"
	@echo "ETHERSCAN_API_KEY: $(ETHERSCAN_API_KEY)"
	@echo "Using network arguments: $(NETWORK_ARGS)"
	forge script script/DeployBidder.s.sol:DeployBidder $(NETWORK_ARGS)
