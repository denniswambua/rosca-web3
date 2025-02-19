// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

  /**
    * @author  Dennis Wambua
    * @title   Chama Merry Go Round Smart Contract.
    * @dev     Uses Ownable openzeppelin contract for access control.
    * @notice  This contract enable a use to create Rotating savings and credit association (ROSCA).
    *   Once created the owner can lock and no new member can join and contribution can start.
    *   Members come together to save and borrow for a specific time period.
    *   Members contribute a fixed amount (s_minimum_contribution) each period then the  contribution is given to one member.
    *   Once a member is given the contribution, they can withdraw it and wont be eligible until everyone else has been given.
        TODO:
    *   The risk of this arrangement is that members who are early in the payout rotation have an incentive to drop out of the chama after they have been paid
    */

contract Chama is Ownable {
    error Chama__Chama_Not_Open();
    error Chama__Invalid_Address();
    error Chama__Amount_Is_Not_Enough();
    error Chama__Contribution_Not_Enough();
    error Chama__Payout_Not_Open();
    error Chama__Cycle_Complete();

    address[] s_members;
    uint256 immutable s_duration; // in seconds
    uint256 immutable s_minimum_contribution;
    bool s_open;
    uint256 s_index_payout;
    uint256 s_last_payout_timestamp;

    mapping(address => uint256) s_members_index;
    mapping(uint256 => uint256) s_contributions;
    mapping(uint256 => uint256) s_arrears;
    mapping(uint256 => uint256) s_payout_balances;

    constructor(uint256 _duration, uint256 _minimum_contribution) Ownable(msg.sender) {
        s_duration = _duration;
        s_minimum_contribution = _minimum_contribution;
        s_index_payout = 0;
        s_last_payout_timestamp = block.timestamp
    }

    function lock() public onlyOwner {
        s_open = false;
    }

    function deposit() public payable {
        if (msg.sender == address(0)) {
            revert Chama__Invalid_Address();
        }

        if (msg.sender)

        if (s_arrears[msg.sender] > 0) {
            if(msg.value > s_arrears[msg.sender]){
                // Clear arrears first
                uint256 balance = msg.value - s_arrears[msg.sender];
                s_arrears[msg.sender] = 0;
                s_contributions[msg.sender] += balance;
            }else{
                s_arrears[msg.sender] -= msg.value;
            }
        }else{
            s_contributions[msg.sender] += msg.value;
        }
        

        // emit event and log
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
        uint256 member_index = s_members.push(msg.sender) - 1;
        s_members_index[msg.sender] = member_index;
        s_contributions[member_index] += msg.value;

        // emit event and log
    }

    /**
     * @notice Member can withdraw their contribution and amount from payout.
     */
    function withdraw(uint256 amount) public {
        if (msg.sender == address(0)) {
            revert Chama__Invalid_Address();
        }

        if (s_contributions[msg.sender] <= 0) {
            revert Chama__Contribution_Not_Enough();
        }
        if (amount < s_contributions[msg.sender]) {
            revert Chama__Contribution_Not_Enough();
        }

        s_contributions[msg.sender] -= amount;

        // Send eth to msg.sender
        payable(msg.sender).transfer(amount);
        // emit event and log
    }

    /**
     *  @notice After the payout period has passed, the owner can distribute the contribution to the eligible member.
     * Members with contribution less than minimum contribution are added to the arrears.
     * Todo:
        Automate this using chain link automate.
     */
    function payout() public onlyOwner {
        if (!s_open) {
            revert Chama__Chama_Not_Open();
        }

        if (block.timestamp - s_last_payout_timestamp < s_duration) {
            revert Chama__Payout_Not_Open();
        }

        if (s_index_payout >= s_members.length) {
            revert Chama__Cycle_Complete();
        }

        s_last_payout_timestamp = block.timestamp;

         address receiver = s_members[i];
        for (uint256 i = s_index_payout + 1; i < s_members.length; i++) {
            if (s_contributions[s_members[i]] >= s_minimum_contribution) {
                s_contributions[s_members[i]] -= s_minimum_contribution;
                s_contributions[receiver] += s_minimum_contribution;
                
            }else{
                uint256 balance = s_minimum_contribution - s_contributions[s_members[i]]
                s_arrears[s_members[i]] += balance;
                s_payout_balances[receiver] += balance;
                s_contributions[receiver] +=  s_contributions[s_members[i]]
                s_contributions[s_members[i]] = 0;

            }
            
        }

        s_last_payout_timestamp = block.timestamp;
        s_index_payout += 1
        
        // emit event and log
    }
}
