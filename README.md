# Web3 ROSCA on Forge

A decentralized Rotating Savings and Credit Association (ROSCA) implemented in Solidity using the Foundry/Forge framework. This project allows groups of members to collaboratively save and access funds in a cyclical manner on the blockchain.

## Description

This smart contract facilitates a Web3 version of a ROSCA. Members contribute a fixed amount periodically, and the collected sum (the "pot") is allocated to one member each period. The cycle continues until every member has received the pot once.

The process is initiated by an **Admin** (the contract deployer) who sets up the ROSCA. The Admin must activate the contract by making the first contribution, which also makes them eligible for the first payout. Once ready, the **Owner** (initially the Admin) can lock the contract to prevent new members from joining, allowing the contribution and payout cycles to begin. **New members must make the minimum contribution to successfully join the group.**

## How it Works (Workflow)

1.  **Creation:** The Admin deploys the ROSCA smart contract.
2.  **Activation:** The Admin activates the ROSCA by contributing the required minimum amount (`s_minimum_contribution`). This makes the Admin eligible for the first payout.
3.  **Joining:** Other members join the active ROSCA (before it's locked) **by contributing the `s_minimum_contribution`**. Their contribution is added to the pool.
4.  **Locking:** The Owner locks the contract. No new members can join after this point, and the contribution/payout cycles can start (or continue, depending on the exact timing/logic).
5.  **Contribution:** In each subsequent defined period, participating members contribute the fixed amount (`s_minimum_contribution`).
6.  **Payout:** The total contributed amount for the period `s_duration` is allocated to one eligible member according to the rotation schedule. Payout fails if some members haven't contributed.
7.  **Withdrawal:** The member who received the payout can withdraw the funds.
8.  **Rotation:** Once a member receives and withdraws their payout, they are no longer eligible to receive another payout until all other participating members have received theirs in the current cycle.
9.  **Repeat:** Steps 5-8 repeat for subsequent periods until the cycle completes.


## Key Parameter

*   `s_minimum_contribution`: The fixed amount each member must contribute per period, **and the amount required to initially join the ROSCA.**
*   `s_duration`: The rosca cycle period before the payout.

## Identified Risk ⚠️

*   **Early Dropout Risk:** A significant risk inherent in the ROSCA model is that members who receive their payout early in the rotation might lack the incentive to continue contributing for the remainder of the cycle, potentially jeopardizing the pool for later recipients. (Mechanisms to mitigate this may need to be considered depending on the implementation specifics).

## Getting Started

This project uses [Foundry](https://github.com/foundry-rs/foundry).

### Prerequisites

*   [Foundry (Forge & Cast)](https://book.getfoundry.sh/getting-started/installation)

### Installation

1.  Install dependencies & Build
    ```sh
    make install
    make build
    make tests
    make format
    ```

#### Deploy

```shell
$ forge script script/Rosca.s.sol:RoscaScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```
