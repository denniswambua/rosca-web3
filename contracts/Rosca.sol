// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @author  Dennis Wambua
 * @title   Rosca Smart Contract.
 * @dev     Uses Ownable openzeppelin contract for access control.
 * @notice  This contract enable a use to create Rotating savings and credit association (ROSCA).
 *   Once created, the owner can lock and no new member can join and contribution can start.
 *   Members come together to save and borrow for a specific time period.
 *   Members contribute a fixed amount (s_minimum_contribution) each period then the contribution is given to one member.
 *   Once a member is given the contribution, they can withdraw it and wont be eligible until everyone else has been given.
 *         TODO:
 *   The risk of this arrangement is that members who are early in the payout rotation have an incentive to drop out of the Rosca after they have been paid
 */
contract Rosca is Ownable {
    error Rosca__Not_Active();
    error Rosca__Invalid_Address();
    error Rosca__Contribution_Not_Enough();
    error Rosca__Payout_Not_Open();
    error Rosca__Not_Started_or_Cycle_Complete();
    error Rosca__Member_Not_Joined();
    error Rosca__Transfer_Failed();

    address[] s_members; // List of all the Rosca members.
    uint256 immutable s_duration; // The duration cycle of the Rosca in seconds.
    uint256 immutable s_minimum_contribution; // Rosca minimum periodic contribution.
    bool s_is_active; // Rosca open to add new members.
    uint256 s_index_payout; // Tracks member payouts.
    uint256 s_last_payout_timestamp;

    address s_owner;

    mapping(address => uint256) s_members_index; // Stores member address index in member array.
    mapping(uint256 => uint256) s_contributions; // Stores member contribution.

    event Rosca_Deposit(address indexed member, uint256 value);
    event Rosca_Join(address indexed member, uint256 index);
    event Rosca_Withdraw(address indexed member, uint256 value);
    event Rosca_Payout(address indexed member, uint256 value);
    event Rosca_Disburse(address indexed member, uint256 value);

    constructor(uint256 _duration, uint256 _minimum_contribution) Ownable(msg.sender) {
        s_duration = _duration;
        s_minimum_contribution = _minimum_contribution;
        s_last_payout_timestamp = block.timestamp;
        s_is_active = false;
        s_owner = msg.sender;
        s_members.push(address(0));
    }

    /**
     * @notice Only owner can activate the Rosca by contributing the minimum contribution and being the first member.
     */
    function activate() public payable onlyOwner {
        if (msg.value < s_minimum_contribution) {
            revert Rosca__Contribution_Not_Enough();
        }
        s_members.push(msg.sender);
        uint256 member_index = s_members.length - 1;
        s_members_index[msg.sender] = member_index;
        s_contributions[member_index] += msg.value;
        s_index_payout = member_index;
        s_is_active = true;
    }

    /**
     * @notice Member can deposit their contribution.
     *  Arrears are cleared first before adding contribution.
     */
    function deposit() public payable {
        if (msg.sender == address(0)) {
            revert Rosca__Invalid_Address();
        }

        if (!s_is_active) {
            revert Rosca__Not_Active();
        }

        if (s_members_index[msg.sender] == 0) {
            revert Rosca__Member_Not_Joined();
        }
        uint256 member_index = s_members_index[msg.sender];

        s_contributions[member_index] += msg.value;

        // emit event
        emit Rosca_Deposit(msg.sender, msg.value);
    }

    /**
     * @notice Once open members can join the Rosca and make contribution.
     */
    function join() public payable {
        if (msg.sender == address(0)) {
            revert Rosca__Invalid_Address();
        }
        if (msg.value < s_minimum_contribution) {
            revert Rosca__Contribution_Not_Enough();
        }
        if (!s_is_active) {
            revert Rosca__Not_Active();
        }
        s_members.push(msg.sender);
        uint256 member_index = s_members.length - 1;
        s_members_index[msg.sender] = member_index;
        s_contributions[member_index] += msg.value;

        // emit event
        emit Rosca_Join(msg.sender, member_index);
    }

    /**
     * @notice Member can withdraw their contribution.
     */
    function withdraw(uint256 amount) public {
        if (msg.sender == address(0)) {
            revert Rosca__Invalid_Address();
        }

        if (s_members_index[msg.sender] == 0) {
            revert Rosca__Member_Not_Joined();
        }

        uint256 member_index = s_members_index[msg.sender];

        if (s_contributions[member_index] <= 0 || amount > s_contributions[member_index]) {
            revert Rosca__Contribution_Not_Enough();
        }

        s_contributions[member_index] -= amount;

        // Send eth to msg.sender
        (bool sent,) = payable(msg.sender).call{value: amount}("");

        if (!sent) {
            revert Rosca__Transfer_Failed();
        }

        // emit event
        emit Rosca_Withdraw(msg.sender, amount);
    }

    /**
     *  @notice After the payout period has passed, the owner can distribute the contribution to the eligible member.
     *  Members with contribution less than minimum contribution payout function reverts and payout fails.
     *  Payout only works when all members have contributed for that period.
     *  Todo:
     *     Automate this using chain link automate.
     */
    function payout() public onlyOwner {
        if (!s_is_active) {
            revert Rosca__Not_Active();
        }

        if (block.timestamp - s_last_payout_timestamp < s_duration) {
            revert Rosca__Payout_Not_Open();
        }

        if (s_index_payout > s_members.length || s_members.length == 2) {
            revert Rosca__Not_Started_or_Cycle_Complete();
        }

        s_last_payout_timestamp = block.timestamp;

        uint256 payout_amount = 0;
        // Starting at index 1 as index 0 is the default address(0)
        for (uint256 i = 1; i < s_members.length; i++) {
            if (i == s_index_payout) {
                // Member receiving payout wont contribute
                continue;
            }
            if (s_contributions[i] >= s_minimum_contribution) {
                s_contributions[i] -= s_minimum_contribution;
                payout_amount += s_minimum_contribution;

                emit Rosca_Disburse(s_members[i], s_minimum_contribution);
            } else {
                // Payout fails and reverts.
                revert Rosca__Contribution_Not_Enough();
            }
        }

        s_contributions[s_index_payout] += payout_amount;
        address receiver = s_members[s_index_payout];
        s_last_payout_timestamp = block.timestamp;

        // Goes not the next elligible member.
        s_index_payout += 1;

        // emit event
        emit Rosca_Payout(receiver, payout_amount);
    }

    /**
     * @notice Member can check their balances
     */
    function get_balance() public view returns (uint256) {
        if (s_members_index[msg.sender] == 0) {
            revert Rosca__Member_Not_Joined();
        }
        return s_contributions[s_members_index[msg.sender]];
    }

    function checkActive() public view returns (bool) {
        return s_is_active;
    }

    function get_next_payout_member() public view returns (address) {
        return s_members[s_index_payout];
    }

    function get_owner() public view returns (address) {
        return s_owner;
    }

    function get_members_count() public view returns (uint256) {
        return s_members.length - 1;
    }
}
