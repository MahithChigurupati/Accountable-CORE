// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {OracleLib, AggregatorV3Interface} from "./libraries/OracleLib.sol";

contract Accountable is Ownable, AccessControl {
    using Counters for Counters.Counter;

    Counters.Counter public taskId;

    using OracleLib for AggregatorV3Interface;

    /**
     * Errors
     */
    error Accountable__NotEnoughEthSent();
    error Accountable__NoEthSentToIncreaseStake();
    error Accountable__RefundFailed();
    error Accountable__AlreadyJoined();
    // error Accountable__NotAParticipant();
    error Accountable__CantRemoveYourself();
    error Accountable__NeedsMoreThanZero();
    error Accountable__TokenNotAllowed(address);

    error Accountable_MaximumLimitReached(uint256);
    error Accountable__StatusIsNotDeactivate(Status);
    error Accountable__TokenAddressesAndPriceFeedAddressesAmountsDontMatch();

    /**
     * Interfaces
     */

    /**
     * Type Declarations
     */
    enum Status {
        OPEN,
        ACTIVE,
        DEACTIVATION,
        INACTIVE
    }

    struct Task {
        string tastName;
        uint256 numberOfParticipants;
        uint256 repetitionPerWeek;
        uint256 accepted;
        address[] assignedTo;
    }

    /**
     * State Variables
     */
    string private s_title;
    uint256 private s_numberOfParticipatingParties;
    uint256 private s_participationStake;
    address payable[] private s_participants;
    mapping(address => uint256) private s_participantBalance;
    mapping(uint256 tokenId => string tokenUri) private s_tokenIdToUri;
    mapping(address token => address priceFeed) private s_priceFeeds;
    address private s_currentChainPriceFeed;

    // Tasks
    mapping(uint256 => Task) s_tasks;

    // other variables
    Status private s_status;
    uint256 private s_deactivationApprovals;

    /**
     * Access Roles
     */
    bytes32 private constant PARTICIPANT_ROLE = keccak256("PARTICIPANT_ROLE");

    /**
     * Events to emit
     */
    event ParticipantJoinedAgreement(address indexed, uint256);
    event PaticipantIncreasedStake(address indexed, uint256 indexed);
    event AgreementActive(uint256, uint256);
    event DeactiveAgreement(address indexed, string indexed);
    event approvedDeactivation(address);
    event StakeRefunded(address indexed, uint256 indexed);
    event ParticipantRemoved(address, address);
    event AccountableContractCreated(address, uint256, uint256);
    event TaskCreated(uint256 indexed);

    ///////////////////
    // Modifiers
    ///////////////////
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert Accountable__NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert Accountable__TokenNotAllowed(token);
        }
        _;
    }

    ///////////////////
    // Functions
    ///////////////////

    /**
     * Constructor called only once during contract deployment
     * @param _title: A title for Agreement
     * @param _numberOfParticipatingParties: Total Number of participating parties/roommates in the contract
     * @param _participationStake: Amount need to be staked by each participant to join the agreement
     */
    constructor(
        string memory _title,
        uint256 _numberOfParticipatingParties,
        uint256 _participationStake,
        address[] memory _tokenAddresses,
        address[] memory _priceFeedAddresses,
        address _priceFeedAddressOfcurrentChain
    ) {
        if (_tokenAddresses.length != _priceFeedAddresses.length) {
            revert Accountable__TokenAddressesAndPriceFeedAddressesAmountsDontMatch();
        }

        // These feeds will be the USD pairs
        // For example wETH / USD or wBTC / USD or MATIC / USD or USDC / USD etc.,
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            s_priceFeeds[_tokenAddresses[i]] = _priceFeedAddresses[i];
        }

        s_currentChainPriceFeed = _priceFeedAddressOfcurrentChain;

        s_title = _title;
        s_numberOfParticipatingParties = _numberOfParticipatingParties;
        s_participationStake = _participationStake;

        s_status = Status.OPEN;

        emit AccountableContractCreated(address(this), block.number, block.timestamp);
    }

    /**
     * Participant can join the agreement by staking required ETH
     */
    function joinAgreement() external payable {
        // 1. revert if person already joined or maximum persons joined
        // 2. check to ensure enough stake is sent to join the agreement
        // 3. Add the partcipant to contract on succesful check and emit an event for logging
        // 4. make a note of participant's balance
        // 5. If Number of Participants is equal to Number of People joined the agreement, Contract becomes ACTIVE

        if (s_numberOfParticipatingParties == s_participants.length) {
            revert Accountable_MaximumLimitReached(s_numberOfParticipatingParties);
        }

        if (hasRole(PARTICIPANT_ROLE, msg.sender)) {
            revert Accountable__AlreadyJoined();
        }

        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_currentChainPriceFeed);

        // a check to see if correct amount of funds are sent to mint an NFT
        if (priceFeed.getUsdValue(msg.value) < s_participationStake) {
            revert Accountable__NotEnoughEthSent();
        }

        emit ParticipantJoinedAgreement(msg.sender, msg.value);

        s_participants.push(payable(msg.sender));
        s_participantBalance[msg.sender] = msg.value;
        _grantRole(PARTICIPANT_ROLE, msg.sender);

        if (s_participants.length == s_numberOfParticipatingParties) {
            emit AgreementActive(block.number, block.timestamp);
            s_status = Status.ACTIVE;
        }
    }

    /**
     * Participant can join the agreement by staking required ETH
     */
    function joinAgreementWithTokens(address _tokenAddress, uint256 _amount) external payable {
        // 1. revert if person already joined or maximum persons joined
        // 2. check to ensure enough stake is sent to join the agreement
        // 3. Add the partcipant to contract on succesful check and emit an event for logging
        // 4. make a note of participant's balance
        // 5. If Number of Participants is equal to Number of People joined the agreement, Contract becomes ACTIVE

        if (s_numberOfParticipatingParties == s_participants.length) {
            revert Accountable_MaximumLimitReached(s_numberOfParticipatingParties);
        }

        if (hasRole(PARTICIPANT_ROLE, msg.sender)) {
            revert Accountable__AlreadyJoined();
        }

        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[_tokenAddress]);

        // a check to see if correct amount of funds are sent to mint an NFT
        if (priceFeed.getUsdValue(_amount) < s_participationStake) {
            revert Accountable__NotEnoughEthSent();
        }

        emit ParticipantJoinedAgreement(msg.sender, msg.value);

        s_participants.push(payable(msg.sender));
        s_participantBalance[msg.sender] = msg.value;
        _grantRole(PARTICIPANT_ROLE, msg.sender);

        if (s_participants.length == s_numberOfParticipatingParties) {
            emit AgreementActive(block.number, block.timestamp);
            s_status = Status.ACTIVE;
        }
    }

    /**
     * Participants can increase their stake if falls low on staking balance
     * requirement:
     *   caller must be of PARTICIPANT_ROLE
     */
    function increaseStake() external payable onlyRole(PARTICIPANT_ROLE) {
        if (msg.value > 0) {
            emit PaticipantIncreasedStake(msg.sender, msg.value);
            s_participantBalance[msg.sender] += msg.value;
        } else {
            revert Accountable__NoEthSentToIncreaseStake();
        }
    }

    /**
     * a function called by owner of contract to add support of buying NFT in other tokens
     *
     * @param _tokenAddress: address of token contract
     * @param _tokenPriceFeedAddress: pricefeed address of token address being addded
     */
    function addTokenSupport(address _tokenAddress, address _tokenPriceFeedAddress) external onlyOwner {
        s_priceFeeds[_tokenAddress] = _tokenPriceFeedAddress;
    }

    function addTask(string memory taskName, uint256 numOfPeople, uint256 repetitionPerWeek)
        public
        onlyRole(PARTICIPANT_ROLE)
    {
        Task memory task = Task(taskName, numOfPeople, repetitionPerWeek, 0, new address[](0));

        s_tasks[taskId._value] = task;
        taskId.increment();

        emit TaskCreated(taskId._value);
    }

    function acceptTask(uint256 _taskId) external {
        Task memory task = s_tasks[_taskId];

        task.accepted += 1;

        if (task.accepted > s_participants.length) {
            assignTask(_taskId);
        }
    }

    function assignTask(uint256 _taskId) public {
        uint256 numberOfAssignees = s_tasks[_taskId].numberOfParticipants;

        for (uint256 i = 0; i < numberOfAssignees; i++) {
            s_tasks[_taskId].assignedTo.push(s_participants[i]);
        }
    }

    /**
     * a function called to remove participant from contract
     * @param _participant: address of participant to be removed
     *
     * requirement:
     *   caller must be of PARTICIPANT_ROLE
     */
    function removeParticipant(address _participant) external onlyRole(PARTICIPANT_ROLE) {
        // 1. Participant cannot remove himself
        // 2. check if participant requested for removal has any dues to clear
        // 3. refund participants staking balance on successful checks
        // 4. remove participant from EVM state

        if (msg.sender == _participant) {
            revert Accountable__CantRemoveYourself();
        }

        if (s_participantBalance[_participant] > 0) {
            refundParticipant(_participant);
        }

        removeParticipants(_participant);
    }

    /**
     * a function called by all the participants to cast their approval for contract's deactivation
     * @return approvalCount: returns number of approvals received
     *
     * Requirements:
     *   caller must be of PARTICIPANT_ROLE
     */
    function approveDeactivation() external onlyRole(PARTICIPANT_ROLE) returns (uint256) {
        // 1. check if decativation is started
        // 2. check if participant casting the vote has any dues to clear
        // 3. increment the approvalReceived
        // 4. if every participant casts their approval, refund their staking balances of participants if any

        if (s_status != Status.DEACTIVATION) {
            revert Accountable__StatusIsNotDeactivate(s_status);
        }

        emit approvedDeactivation(msg.sender);
        s_deactivationApprovals += 1;

        if (s_deactivationApprovals == getNumberOfParticipatingParties()) {
            refundEveryone();
            s_status = Status.INACTIVE;
        }

        return s_deactivationApprovals;
    }

    /**
     * a function to initialize deactivation process
     */
    function deactivateContract(string memory reason) external {
        emit DeactiveAgreement(msg.sender, reason);
        s_status = Status.DEACTIVATION;
    }

    /**
     * Public functions
     */

    /**
     * Internal functions
     * (can only be called by other functions of this contract
     */

    /**
     * an internal refund participant function called to refund staking balance of a participant if any
     * @param _participant: address of participant to be refunded
     */
    function refundParticipant(address _participant) internal {
        uint256 participantBalance = s_participantBalance[_participant];
        (
            bool success,
            /**
             * data *
             */
        ) = payable(_participant).call{value: participantBalance}("");

        if (success == true) {
            emit StakeRefunded(_participant, s_participantBalance[_participant]);

            s_participantBalance[_participant] -= participantBalance;
        } else {
            revert Accountable__RefundFailed();
        }
    }

    /**
     * an internal function called to remove a participant from list of participants
     * @param _participant: address of participant to be removed
     */
    function removeParticipants(address _participant) internal {
        for (uint256 i = 0; i < s_participants.length; i++) {
            if (s_participants[i] == _participant) {
                emit ParticipantRemoved(_participant, msg.sender);
                remove(i);
                break;
            }
        }
    }

    /**
     * An internal function called during deactivation to refund staking balance
     * to every participant after receiving approvals
     */
    function refundEveryone() internal {
        address payable[] memory participants = s_participants;
        for (uint256 i = 0; i < getNumberOfParticipatingParties(); i++) {
            if (s_participantBalance[participants[i]] > 0) {
                refundParticipant(participants[i]);
            }
        }
    }

    /**
     * an internal function to remove a participant
     * @param index: accepts index of s_participants to delete
     */
    function remove(uint256 index) internal {
        // Move the last element into the place to delete
        s_participants[index] = s_participants[s_participants.length - 1];
        // Remove the last element
        s_participants.pop();
    }

    /**
     * Getter functions
     */
    function getTitle() external view returns (string memory) {
        return s_title;
    }

    function getNumberOfParticipatingParties() public view returns (uint256) {
        return s_participants.length;
    }

    function getparticipationStake() external view returns (uint256) {
        return s_participationStake;
    }

    function getStatus() external view returns (uint256) {
        return uint256(s_status);
    }

    function getBalance(address account) external view returns (uint256) {
        return s_participantBalance[account];
    }

    /**
     * a function call to return current chain price feed address
     */
    function getNativeChainPriceFeed() external view returns (address) {
        return s_currentChainPriceFeed;
    }

    /**
     * a function called to get price feed address of a token
     *
     * @param _token: token for which price feed address is needed
     */
    function getTokenPriceFeed(address _token) external view returns (address) {
        return s_priceFeeds[_token];
    }

    /**
     * a function called to get usd price in eth
     */
    function getEthPriceFromUsd() external view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_currentChainPriceFeed);
        return priceFeed.getEthAmountFromUsd(s_participationStake);
    }

    /**
     * a function to get price conversion from USD to token equivalent price
     *
     * @param _tokenAddress: conversion in which token equivalent is needed
     */
    function getTokenPriceFromUsd(address _tokenAddress) external view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[_tokenAddress]);
        return priceFeed.getEthAmountFromUsd(s_participationStake);
    }
}
