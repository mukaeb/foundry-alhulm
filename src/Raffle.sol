// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title A simple Rattle Contract 
 * @author Mohammed Alawad
 * @notice this contract is for creating a simple rattle
 * @dev implenents Chinlink VRFv2
 */

contract Raffle {

    error Raffle__NotEnoughEthSent();

    uint256 private immutable i_enteranceFee ;
    address payable[] private s_players;

    /** events الأحداث */

    event RaffleEnter(address indexed player); 

    constructor(uint256 enteranceFee){
        i_enteranceFee = enteranceFee; 
    }
    
    function enterRaffle() public payable {
        if(msg.value < i_enteranceFee){
            revert Raffle__NotEnoughEthSent();
        }

        s_players.push(payable(msg.sender));

        emit RaffleEnter(msg.sender); 

    }

    function pickWinner() public {}

    /** Getter functions  */

    function getEntranceFee() public view returns(uint256){
        return i_enteranceFee;
    }
}