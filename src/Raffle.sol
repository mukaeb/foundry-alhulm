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
    uint256 private immutable i_interval ;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp; 

    /** events الأحداث */

    event RaffleEnter(address indexed player); 

    constructor(uint256 enteranceFee, uint256 interval){
        i_enteranceFee = enteranceFee; 
        i_interval = interval; 
        s_lastTimeStamp = block.timestamp; 
    }
    
    function enterRaffle() external payable {
        if(msg.value < i_enteranceFee){
            revert Raffle__NotEnoughEthSent();
        }

        s_players.push(payable(msg.sender));

        emit RaffleEnter(msg.sender); 

    }


    // الأول : أن تحدد رقم عشوائي 
    // الثاني : أن نقوم بإستخدام الرقم العشوائي لتحديد الفائز
    // الثالث : أنها تكون ذاتية التشغيل 
    function pickWinner() external {
        // block.timestamp - s_lastTimeStamp > i_interval ;
        // 500 - 100 < 1000 
        if (block.timestamp - s_lastTimeStamp < i_interval){
            revert();
        }

    }

    /** Getter functions  */

    function getEntranceFee() external view returns(uint256){
        return i_enteranceFee;
    }
}