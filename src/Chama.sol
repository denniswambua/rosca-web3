// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

contract Chama {
    address[] s_members;
    uint256 immutable s_duration; // in seconds
    uint256 immutable s_minimum_contribution;
    bool s_open;
    uint256 index_payout;

    mapping(address => uint256) s_contributions;

    constructor(uint256 _duration, uint256 _minimum_contribution) {
        s_duration = _duration;
        s_minimum_contribution = _minimum_contribution;
        index_payout = 0;
    }

    function lock() public {
        s_open = false;
    }

    function deposit() public payable{
        require(msg.sender != address(0));
        s_contributions[msg.sender] += msg.value;
    }

    function join() public payable {
        require(msg.sender != address(0));
        require(msg.value >= s_minimum_contribution);
        require(s_open);
        s_members.push(msg.sender);
        s_contributions[msg.sender] += msg.value;
    }

    function withdraw() public payable{
        require(msg.sender != address(0));
        require(s_contributions[msg.sender] > 0);
        s_contributions[msg.sender] -= msg.value;

        // Send eth to msg.sender
        // emit event and log
    }

    function payout() public {
        require(s_open);
        for(uint256 i = 0; i < s_members.length; i++){
            address receiver = s_members[i];
            uint256 amount = s_contributions[receiver];
        }
            // Send eth to receiver
            // emit event and log   
    }
}

