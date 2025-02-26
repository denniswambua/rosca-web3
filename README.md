## Chama(investment) Smart Contracts

**This project implements common chama(investments) functions in smart contracts**

## Functionalilty

### 1. Merry-go-round
Members agree to contribute a fixed amount at each interval for a fixed period.

### 2. Pooled investment with shares
TODO
### 3. Agriculture cooperatives
TODO
### 4. Peer-to-Peer Lending Chama
TODO

## Documentation

https://book.getfoundry.sh/

## Usage

### Install lib
```shell
$ make install
```

### Build

```shell
$ make build
```

### Test

```shell
$ make tests
```

### Format

```shell
$ make format
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/MerryGoRound.s.sol:MerryGoRoundScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
