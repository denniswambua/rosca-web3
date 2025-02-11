// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Chama is Ownable {
    error Chama__Chama_Not_Open();
    error Chama__Invalid_Address();
    error Chama__Amount_Is_Not_Enough();
    error Chama__Contribution_Not_Enough();

    address[] s_members;
    uint256 immutable s_duration; // in seconds
    uint256 immutable s_minimum_contribution;
    bool s_open;
    uint256 index_payout;

    mapping(address => uint256) s_contributions;

    constructor(uint256 _duration, uint256 _minimum_contribution) Ownable(msg.sender) {
        s_duration = _duration;
        s_minimum_contribution = _minimum_contribution;
        index_payout = 0;
    }

    function lock() public onlyOwner {
        s_open = false;
    }

    function deposit() public payable {
        if (msg.sender == address(0)) {
            revert Chama__Invalid_Address();
        }
        s_contributions[msg.sender] += msg.value;
    }

    function join() public payable {
        if (msg.sender == address(0)) {
            revert Chama__Invalid_Address();
        }
        if (msg.value < s_minimum_contribution) {
            revert Chama__Amount_Is_Not_Enough();
        }
        if (!s_open) {
            revert Chama__Chama_Not_Open();
        }
        s_members.push(msg.sender);
        s_contributions[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) public {
        if (msg.sender == address(0)) {
            revert Chama__Invalid_Address();
        }

        if (s_contributions[msg.sender] > 0) {
            revert Chama__Contribution_Not_Enough();
        }
        if (amount < s_contributions[msg.sender]) {
            revert Chama__Contribution_Not_Enough();
        }

        s_contributions[msg.sender] -= amount;

        // Send eth to msg.sender
        // emit event and log
    }

    function payout() public {
        if (!s_open) {
            revert Chama__Chama_Not_Open();
        }
        for (uint256 i = 0; i < s_members.length; i++) {
            address receiver = s_members[i];
            uint256 amount = s_contributions[receiver];
        }
        // Send eth to receiver
        // emit event and log
    }
}
