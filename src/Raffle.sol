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

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

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
    error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

    enum RaffleState {
        OPEN, //0
        CALCULATING //1

    }

    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint32 private constant NUM_WORD = 1;

    uint256 private immutable i_enteranceFee;
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_RaffleState;

    /**
     * events الأحداث
     */
    event RaffleEnter(address indexed player);
    event PickedWinner(address indexed winner);

    constructor(
        uint256 enteranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
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
        if (msg.value < i_enteranceFee) {
            revert Raffle__NotEnoughEthSent();
        }

        if (s_RaffleState != RaffleState.OPEN) {
            revert Raffle__NotOpen();
        }

        s_players.push(payable(msg.sender));

        emit RaffleEnter(msg.sender);
    }

    /**
     * هذه الوظيفه تقوم باٍستخدام أتمتة شاينليك لفحص حاجتنا لإستتدعاء و إختيار الفائز
     * في حالة أنه الشروط تم إيفائها  true أنها حترجع
     * 1. هل مر زمن كافي على أخر سحب
     * 2 هل حالة السحب مفتوح
     * 3. هل العقد في إيث أصلا أو لاعبين
     * 4. هل الإشتراك في لينك لإجراء التحديث و إختيار الفائز
     */
    function checkUpkeep(bytes memory /*checkData*/ )
        public
        view
        returns (bool upkeepNeeded, bytes memory /* performData */ )
    {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool isOpen = RaffleState.OPEN == s_RaffleState;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /* performData */ ) external {
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_RaffleState));
        }

        s_RaffleState = RaffleState.CALCULATING;

        // المعاملة الأولى : بتقوم بإرسال طلب لإصدار رقم عشوائي
        // المعاملة الثانيه : تقوم بإستقبال الرقم العشوائي

        i_vrfCoordinator.requestRandomWords(
            i_gasLane, // خط الغاز
            i_subscriptionId,
            REQUEST_CONFIRMATION,
            i_callbackGasLimit,
            NUM_WORD
        );
    }

    //CEI : check , Effect , Interaction
    // الفحص ، الثاثيرات ، و التفاعلات
    function fulfillRandomWords(uint256, /*requestId*/ uint256[] memory randomWords) internal override {
        //5165161616151651
        // تاثيرات
        uint256 indexOfWinner = randomWords[0] % s_players.length; //1516154544 % 10 = 4
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        s_RaffleState = RaffleState.OPEN;

        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;

        emit PickedWinner(s_recentWinner);
        //التفاعلات
        (bool success,) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TansferFailed();
        }
    }

    /**
     * Getter functions
     */
    function getEntranceFee() external view returns (uint256) {
        return i_enteranceFee;
    }
}
