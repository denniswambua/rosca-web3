// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @author  Dennis Wambua
 * @title   MerryGoRound Smart Contract.
 * @dev     Uses Ownable openzeppelin contract for access control.
 * @notice  This contract enable a use to create Rotating savings and credit association (ROSCA).
 *   Once created the owner can lock and no new member can join and contribution can start.
 *   Members come together to save and borrow for a specific time period.
 *   Members contribute a fixed amount (s_minimum_contribution) each period then the  contribution is given to one member.
 *   Once a member is given the contribution, they can withdraw it and wont be eligible until everyone else has been given.
 *         TODO:
 *   The risk of this arrangement is that members who are early in the payout rotation have an incentive to drop out of the MerryGoRound after they have been paid
 */
contract MerryGoRound is Ownable {
    error MerryGoRound__Not_Open();
    error MerryGoRound__Invalid_Address();
    error MerryGoRound__Amount_Is_Not_Enough();
    error MerryGoRound__Contribution_Not_Enough();
    error MerryGoRound__Payout_Not_Open();
    error MerryGoRound__Cycle_Complete();
    error MerryGoRound__Member_Not_Joined();
    error MerryGoRound__Transfer_Failed();

    address[] s_members; // List of all the MerryGoRound members.
    uint256 immutable s_duration; // The duration cycle of the MerryGoRound in seconds.
    uint256 immutable s_minimum_contribution; // MerryGoRound minimum periodic contribution.
    bool s_open; // MerryGoRound open to add new members.
    uint256 s_index_payout; // Tracks member payouts.
    uint256 s_last_payout_timestamp;

    mapping(address => uint256) s_members_index; // Stores member address index in member array.
    mapping(uint256 => uint256) s_contributions; // Stores member contribution.
    mapping(uint256 => uint256) s_arrears; // Stores member arrears.
    mapping(uint256 => uint256) s_payout_balances; // Stores the members pending payouts.

    event MerryGoRound_Deposit(address indexed member, uint256 value);
    event MerryGoRound_Join(address indexed member, uint256 index);
    event MerryGoRound_Withdraw(address indexed member, uint256 value);
    event MerryGoRound_Payout(address indexed member, uint256 value);

    constructor(uint256 _duration, uint256 _minimum_contribution) Ownable(msg.sender) {
        s_duration = _duration;
        s_minimum_contribution = _minimum_contribution;
        s_index_payout = 1;
        s_last_payout_timestamp = block.timestamp;
        s_open = true;
    }

    function lock() public onlyOwner {
        s_open = false;
    }

    /**
     * @notice Member can deposit their contribution.
     *  Arrears are cleared first before adding contribution.
     */
    function deposit() public payable {
        if (msg.sender == address(0)) {
            revert MerryGoRound__Invalid_Address();
        }

        if (s_members_index[msg.sender] == 0) {
            revert MerryGoRound__Member_Not_Joined();
        }
        uint256 member_index = s_members_index[msg.sender];

        if (s_arrears[member_index] > 0) {
            uint256 arrears = s_arrears[member_index];
            if (msg.value > s_arrears[member_index]) {
                // Clear arrears first
                uint256 balance = msg.value - arrears;
                s_arrears[member_index] = 0;
                s_contributions[member_index] += balance;
            } else {
                s_arrears[member_index] -= msg.value;
            }

            _distribute_arrears(arrears);
        } else {
            s_contributions[member_index] += msg.value;
        }

        // emit event
        emit MerryGoRound_Deposit(msg.sender, msg.value);
    }

    /**
     * @notice Once open members can join the MerryGoRound and make contribution.
     */
    function join() public payable {
        if (msg.sender == address(0)) {
            revert MerryGoRound__Invalid_Address();
        }
        if (msg.value < s_minimum_contribution) {
            revert MerryGoRound__Amount_Is_Not_Enough();
        }
        if (!s_open) {
            revert MerryGoRound__Not_Open();
        }
        s_members.push(msg.sender);
        uint256 member_index = s_members.length;
        s_members_index[msg.sender] = member_index;
        s_contributions[member_index] += msg.value;

        // emit event
        emit MerryGoRound_Join(msg.sender, member_index);
    }

    /**
     * @notice Member can withdraw their contribution.
     */
    function withdraw(uint256 amount) public {
        if (msg.sender == address(0)) {
            revert MerryGoRound__Invalid_Address();
        }

        if (s_members_index[msg.sender] == 0) {
            revert MerryGoRound__Member_Not_Joined();
        }

        uint256 member_index = s_members_index[msg.sender];

        if (s_contributions[member_index] <= 0) {
            revert MerryGoRound__Contribution_Not_Enough();
        }
        if (amount > s_contributions[member_index]) {
            revert MerryGoRound__Contribution_Not_Enough();
        }

        s_contributions[member_index] -= amount;

        // Send eth to msg.sender
        (bool sent,) = payable(msg.sender).call{value: amount}("");

        if (!sent) {
            revert MerryGoRound__Transfer_Failed();
        }

        // emit event
        emit MerryGoRound_Withdraw(msg.sender, amount);
    }

    /**
     *  @notice After the payout period has passed, the owner can distribute the contribution to the eligible member.
     * Members with contribution less than minimum contribution are added to the arrears.
     * Todo:
     *     Automate this using chain link automate.
     */
    function payout() public onlyOwner {
        if (!s_open) {
            revert MerryGoRound__Not_Open();
        }

        if (block.timestamp - s_last_payout_timestamp < s_duration) {
            revert MerryGoRound__Payout_Not_Open();
        }

        if (s_index_payout > s_members.length) {
            revert MerryGoRound__Cycle_Complete();
        }

        s_last_payout_timestamp = block.timestamp;

        address receiver = s_members[s_index_payout];
        uint256 payout_amount = 0;
        for (uint256 i = s_index_payout + 1; i < s_members.length; i++) {
            if (s_contributions[i] >= s_minimum_contribution) {
                s_contributions[i] -= s_minimum_contribution;
                payout_amount += s_minimum_contribution;
            } else {
                uint256 balance = s_minimum_contribution - s_contributions[i];
                s_arrears[i] += balance;
                s_payout_balances[s_index_payout] += balance;
                payout_amount += s_contributions[i];
                s_contributions[i] = 0;
            }
        }

        s_contributions[s_index_payout] = payout_amount;
        s_last_payout_timestamp = block.timestamp;

        // Goes not the next elligible member.
        s_index_payout += 1;

        // emit event
        emit MerryGoRound_Payout(receiver, payout_amount);
    }

    /**
     * @dev Distributes the arrears to the pending payouts.
     */
    function _distribute_arrears(uint256 arrears) internal {
        uint256 index = 1;
        while (arrears > 0 && index < s_members.length) {
            if (s_payout_balances[index] > 0) {
                if (s_payout_balances[index] > arrears) {
                    s_payout_balances[index] -= arrears;
                    s_contributions[index] += arrears;
                    arrears = 0;
                } else {
                    arrears -= s_payout_balances[index];
                    s_contributions[index] += s_payout_balances[index];
                }
            }
            index += 1;
        }
    }

    /**
     * @notice Member can check their balances
     */
    function get_balance() public view returns (uint256) {
        if (s_members_index[msg.sender] == 0) {
            revert MerryGoRound__Member_Not_Joined();
        }
        return s_contributions[s_members_index[msg.sender]];
    }

    function checkOpen() public view returns (bool) {
        return s_open;
    }
}
