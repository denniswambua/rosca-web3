-include .env

install:;  forge install openzeppelin/openzeppelin-contracts --no-commit

build:; forge build

format:; forge fmt 

tests:; forge test -vvv

coverage:; forge coverage
