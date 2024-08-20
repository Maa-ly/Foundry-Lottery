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
// internal & private view & pure functions
// external & public view & pure functions  @chainlink/contracts@1.1.1/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol;

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/dev/vrf/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/dev/vrf/libraries/VRFV2PlusClient.sol";

/**
 * @title A Sample Raffle contract
 * @author Lydia Gyamfi Ahenkorah
 * @notice This contract is for creating a simple Raffle contract
 * @dev Implements Chainlink VRFv2.5
 */
contract Raffle is VRFConsumerBaseV2Plus {
    /*Errors*/
    error Raffle__SendMoreEthToEnterRaffle();
    error Raffle__TranferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(
        uint256 balance,
        uint256 playersLength,
        uint256 RaffleState
    );

    /*Type Declration*/
    enum RaffleState {
        OPEN, //0
        CALCULATING //1
    }

    uint256 private immutable i_entranceFee;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;
    uint32 private immutable i_callbackGasLimit;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    address payable[] public s_players;
    address private s_recentWinner;
    RaffleState private s_raffleState;
    //bool s_calculatingWinner = false;

    /*Events*/
    event RaffleEntered(address indexed s_player);
    event winnerPicked(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_subscriptionId = subscriptionId;
        i_keyHash = gasLane;
        i_callbackGasLimit = callbackGasLimit;

        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreEthToEnterRaffle();
        }

        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        s_players.push(payable(msg.sender));

        //makes migration easier
        emit RaffleEntered(msg.sender);
        //require(msg.value >= i_entranceFee, SendMoreEthToEnterRaffle());
        //require(msg.value <= i_entranceFee, "Not enough Eth sent!")
    }

    /**
     * @dev This is the function that the Chainlink node will call to see
     * if the lottery is ready to have a winner picked.
     * the following should be true in order for upkeepNeeded to be true
     * 1. The time interval has passed between raffle runs
     * 2. The Lottery is OPEN
     * 3.The contract has ETH
     * 4.Implicitly your subscription has Link
     * @param -- ignored
     * @return upkeepNeeded -- true if its tie to start the lottery
     * @return --ignored
     */
    function checkUpkeeep(
        bytes memory
    ) public view returns (bool upkeepNeeded, bytes memory) {
        bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) >=
            i_interval);
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = timeHasPassed && isOpen && hasPlayers && hasBalance;
        return (upkeepNeeded, "");
    }

    //1. get random number
    //2. use random number to pick player
    //3. be automatically called
    function performUpkeep(bytes calldata) external {
        //check to see if enough time has passed
        (bool upkeepNeeded, ) = checkUpkeeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }

        s_raffleState = RaffleState.CALCULATING;
        // Get our random number 2.5
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: i_keyHash, // Hash for VRF key
                subId: i_subscriptionId, // Subscription ID
                requestConfirmations: REQUEST_CONFIRMATIONS, // Number of confirmations
                callbackGasLimit: i_callbackGasLimit, // Gas limit for callback
                numWords: NUM_WORDS, // Number of random words requested
                extraArgs: VRFV2PlusClient._argsToBytes( // Extra arguments converted to bytes
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });
        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);

        emit RequestedRaffleWinner(requestId);
    }

    // Will revert if subscription is not set and funded.
    //requestId = s_vrfCoordinator.requestRandomWords()

    function fulfillRandomWords(
        uint256,
        uint256[] memory randomWords
    ) internal override {
        //checks
        //requires/conditional

        //randnum =12
        //s_player = 10
        //12%10=2

        //Effect internal contract state changes
        uint256 indexOfwiner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfwiner];
        s_recentWinner = recentWinner;

        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;

        emit winnerPicked(s_recentWinner);

        // Interaction (External contract Interactions)
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TranferFailed();
        }
    }

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (uint256) {
        return uint256(s_raffleState);
    }

    function getPlayer(uint256 indexOfPlayer) external view returns (address) {
        return s_players[indexOfPlayer];
    }

    function getLastTimeStamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }
}
