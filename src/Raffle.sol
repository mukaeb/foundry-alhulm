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

import {VRFCoordinatorV2Interface} from  "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from  "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

/**
 * @title A simple Rattle Contract 
 * @author Mohammed Alawad
 * @notice this contract is for creating a simple rattle
 * @dev implenents Chinlink VRFv2
 */


contract Raffle is VRFConsumerBaseV2 {

    error Raffle__NotEnoughEthSent();
    error Raffle__TansferFailed();
    error Raffle__NotOpen();

    enum RaffleState{
        OPEN,
        CALCULATING
    }

    uint16 private constant REQUEST_CONFIRMATION = 3; 
    uint32 private constant NUM_WORD = 1 ; 

    uint256 private immutable i_enteranceFee ;
    uint256 private immutable i_interval ;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    address payable[] private s_players;
    uint256 private s_lastTimeStamp; 
    address private s_recentWinner; 
    RaffleState private s_RaffleState; 


    /** events الأحداث */

    event RaffleEnter(address indexed player); 

    constructor(uint256 enteranceFee, uint256 interval, address vrfCoordinator , bytes32 gasLane, uint64 subscriptionId, uint32 callbackGasLimit) VRFConsumerBaseV2(vrfCoordinator){
        i_enteranceFee = enteranceFee; 
        i_interval = interval; 
        s_lastTimeStamp = block.timestamp; 
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator); 
        i_gasLane = gasLane; 
        i_subscriptionId = subscriptionId; 
        i_callbackGasLimit = callbackGasLimit; 
        s_RaffleState = RaffleState.OPEN;
    }
    
    function enterRaffle() external payable {
        if(msg.value < i_enteranceFee){
            revert Raffle__NotEnoughEthSent();
        }

        if(s_RaffleState != RaffleState.OPEN){
            revert Raffle__NotOpen();
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

        s_RaffleState = RaffleState.CALCULATING;

        // المعاملة الأولى : بتقوم بإرسال طلب لإصدار رقم عشوائي 
        // المعاملة الثانيه : تقوم بإستقبال الرقم العشوائي 

         uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,// خط الغاز 
            i_subscriptionId,
            REQUEST_CONFIRMATION,
            i_callbackGasLimit,
            NUM_WORD
        );

    }


    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        //5165161616151651
        uint256 indexOfWinner = randomWords[0] % s_players.length; //1516154544 % 10 = 4 
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner ; 
        s_RaffleState = RaffleState.OPEN;
        (bool success,) = winner.call{value:address(this).balance}("");
        if (!success){
            revert Raffle__TansferFailed();
        }

    }

    /** Getter functions  */

    function getEntranceFee() external view returns(uint256){
        return i_enteranceFee;
    }
}