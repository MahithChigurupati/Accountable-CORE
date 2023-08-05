// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

//////////////////////
// Import statements
//////////////////////
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

////////////////////////////
// libraries & Interfaces
////////////////////////////
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {OracleLib, AggregatorV3Interface} from "./libraries/OracleLib.sol";

//////////////////////
// errors
//////////////////////
error Accountable__RefundFailed();
error Accountable__AlreadyJoined();
error Accountable__TransferFailed();
error Accountable__NotAParticipant();
error Accountable__NotEnoughEthSent();
error Accountable__NeedsMoreThanZero();
error Accountable__CantRemoveYourself();
error Accountable__AlreadyInDeactivation();
error Accountable__NotActive();
error Accountable__StatusIsNotDeactivate();
error Accountable__TokenNotAllowed(address);
error Accountable__NoEthSentToIncreaseStake();
error Accountable_MaximumLimitReached(uint256);
error Accountable__PriceFeedAddressesCantBeZero();
error Accountable__NumberOfParticipantsMustBeMoreThanOne();
error Accountable__CountOfTokenAddressesAndPriceFeedAddressesDontMatch();

/**
 * @title An Accountability application contract
 * @author Mahith Chigurupati
 * @notice This contract is for a group of people who intend to join an agreement for sharing tasks among themselves and
 *         this contract will ensure everyone completes their tasks on time
 *
 * Days of frustation due to your roommate or friend not completing a shared task on time are over!
 * Ever thought of someone making sure everyone does their work feeling the responsibility of doing it?
 * Here you go ------------------>
 * A protocol to make sure everyone in the agreement feel accountable of their actions.
 *
 * @custom:restrictions - You can pay using either base currency of chain (eg: ETH for ethereum, MATIC for Polygon etc.,)
 * or any of the supported ERC20 tokens to join the agreement
 *
 * @custom:important - Incase you are planning to pay using ERC20 tokens as mint fee,
 * make sure to approve this contract's address to spend your tokens equivalent to current price of minting an NFT
 *
 * @notice Incase, you are planning to interact with contract through UI (which is the recommended way),
 *         you will automatically be asked for an approval transaction before an NFT minting transaction
 *
 * you can find the price of joining agreement interms of USD by calling ***********
 * you can find the price of joining agreement in terms of base chain currency or a token by calling **************
 *
 * @dev This contract implements chainlink price feeds for price conversions
 *      This contract also implements chainlink Automation(keepers) for timely execution
 */
contract Accountable is Ownable, AccessControl {
    //////////////////////
    // Type Declarations
    //////////////////////
    using OracleLib for AggregatorV3Interface;
    using Counters for Counters.Counter;

    Counters.Counter public taskId;

    /**
     * custon enum variable to hold status of agreement
     */
    enum Status {
        OPEN,
        ACTIVE,
        DEACTIVATION,
        INACTIVE
    }

    /**
     * a custon struct variable Task to hold a particular task's details
     * tastName: name assigned to each task
     * numberOfParticipants: number of particpicipants task must be assigned to (for group tasks)
     * repetitionPerWeek: number of times task must be performed each week
     * accepted: number of people accepted the task
     * assignedTo: address of person to whom task is assigned to in current iteration
     */
    struct Task {
        string tastName;
        uint256 numberOfParticipants;
        uint256 repetitionPerWeek;
        uint256 accepted;
        address[] assignedTo;
    }

    //////////////////////
    // State variables
    //////////////////////
    string private s_title;
    uint256 private s_numberOfParticipatingParties;
    uint256 private s_participationStake;
    address payable[] private s_participants;
    uint256 private s_deactivationApprovals;
    address private s_currentChainPriceFeed;
    mapping(address participant => uint256 balance) private s_participantBalance;
    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(uint256 taskId => Task task) s_tasks;
    Status private s_status;

    /////////////////
    // Access Roles
    /////////////////
    bytes32 private constant PARTICIPANT_ROLE = keccak256("PARTICIPANT_ROLE");

    //////////////////////
    // Events to emit
    //////////////////////
    event ParticipantJoinedAgreement(address indexed, uint256);
    event PaticipantIncreasedStake(address indexed, uint256 indexed);
    event AgreementActive(uint256, uint256);
    event DeactiveAgreement(address indexed, string indexed);
    event approvedDeactivation(address);
    event StakeRefunded(address indexed, uint256 indexed);
    event ParticipantRemoved(address, address);
    event AccountableContractCreated(address, uint256, uint256);
    event TaskCreated(uint256 indexed);
    event mintFeeTransferedToContract(uint256);

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
     * @param _tokenAddresses: list of supported token addresses on current chain
     * @param _priceFeedAddresses: list of chainlink price feed contract addresses for supported ERC20 tokens
     * @param _priceFeedAddressOfcurrentChain: chainlink price feed contract address of current chain
     */
    constructor(
        string memory _title,
        uint256 _numberOfParticipatingParties,
        uint256 _participationStake,
        address[] memory _tokenAddresses,
        address[] memory _priceFeedAddresses,
        address _priceFeedAddressOfcurrentChain
    ) {
        if (_numberOfParticipatingParties <= 1) {
            revert Accountable__NumberOfParticipantsMustBeMoreThanOne();
        }

        if (_tokenAddresses.length != _priceFeedAddresses.length) {
            revert Accountable__CountOfTokenAddressesAndPriceFeedAddressesDontMatch();
        }

        if (_priceFeedAddressOfcurrentChain == address(0)) {
            revert Accountable__PriceFeedAddressesCantBeZero();
        }

        // These feeds will be the USD pairs
        // For example wETH / USD or wBTC / USD or MATIC / USD or USDC / USD etc.,
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            if (_tokenAddresses[i] == address(0) || _priceFeedAddresses[i] == address(0)) {
                revert Accountable__PriceFeedAddressesCantBeZero();
            }

            s_priceFeeds[_tokenAddresses[i]] = _priceFeedAddresses[i];
        }

        s_currentChainPriceFeed = _priceFeedAddressOfcurrentChain;

        s_title = _title;
        s_numberOfParticipatingParties = _numberOfParticipatingParties;
        s_participationStake = _participationStake;
        s_status = Status.OPEN;

        emit AccountableContractCreated(address(this), block.number, block.timestamp);
    }

    /////////////////////////
    // external functions
    /////////////////////////

    /**
     * Participant can join the agreement by staking required ETH
     * called only if ETH or current chains native currency is used as staking fee
     */
    function joinAgreement() external payable {
        // 1. revert if person already joined or maximum persons joined
        // 2. check to ensure enough stake is sent to join the agreement
        // 3. Add the partcipant to contract on succesful check and emit an event for logging
        // 4. make a note of participant's balance
        // 5. If Number of Participants is equal to Number of People joined the agreement, Contract becomes ACTIVE

        if (s_status != Status.OPEN) {
            revert Accountable__NotActive();
        }

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
        // ETH will be added to current contracts balace by default

        emit ParticipantJoinedAgreement(msg.sender, msg.value);

        _grantRole(PARTICIPANT_ROLE, msg.sender);
        s_participants.push(payable(msg.sender));
        s_participantBalance[msg.sender] = msg.value;

        if (s_participants.length == s_numberOfParticipatingParties) {
            emit AgreementActive(block.number, block.timestamp);
            s_status = Status.ACTIVE;
        }
    }

    /**
     * Participant can join the agreement by staking any of the supported ERC20 tokens
     */
    function joinAgreementWithTokens(address _tokenAddress, uint256 _amount) external payable {
        // 1. revert if person already joined or maximum persons joined
        // 2. check to ensure enough stake is sent to join the agreement
        // 3. Add the partcipant to contract on succesful check and emit an event for logging
        // 4. make a note of participant's balance
        // 5. If Number of Participants is equal to Number of People joined the agreement, Contract becomes ACTIVE

        if (s_status != Status.OPEN) {
            revert Accountable__NotActive();
        }

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

        _grantRole(PARTICIPANT_ROLE, msg.sender);
        s_participants.push(payable(msg.sender));
        s_participantBalance[msg.sender] = msg.value;

        // transfer ERC20 tokens from participant to contracts address
        _transferTokens(_tokenAddress, _amount);

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
        if (s_status != Status.ACTIVE) {
            revert Accountable__NotActive();
        }

        if (msg.value > 0) {
            emit PaticipantIncreasedStake(msg.sender, msg.value);
            s_participantBalance[msg.sender] += msg.value;
        } else {
            revert Accountable__NoEthSentToIncreaseStake();
        }
    }

    /**
     * Participants can increase their stake if falls low on staking balance
     * requirement:
     *   caller must be of PARTICIPANT_ROLE
     */
    function increaseStakeWithTokens(address _tokenAddress, uint256 _amount) external onlyRole(PARTICIPANT_ROLE) {
        if (s_status != Status.ACTIVE) {
            revert Accountable__NotActive();
        }

        if (_amount > 0) {
            emit PaticipantIncreasedStake(msg.sender, _amount);
            _transferTokens(_tokenAddress, _amount);
            s_participantBalance[msg.sender] += _amount;
        } else {
            revert Accountable__NoEthSentToIncreaseStake();
        }
    }

    /**
     * a function called by owner of contract to add support of other tokens
     *
     * @param _tokenAddress: address of token contract
     * @param _tokenPriceFeedAddress: pricefeed address of token address being addded
     */
    function addTokenSupport(address _tokenAddress, address _tokenPriceFeedAddress) external onlyOwner {
        s_priceFeeds[_tokenAddress] = _tokenPriceFeedAddress;
    }

    /**
     * a function must be called by all the participants to accept a task for it to become active
     *
     * @param _taskId: ID of task to accept
     */
    function acceptTask(uint256 _taskId) external {
        if (s_status != Status.ACTIVE) {
            revert Accountable__NotActive();
        }

        Task memory task = s_tasks[_taskId];

        task.accepted += 1;

        if (task.accepted > s_participants.length) {
            assignTask(_taskId);
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

        if (s_status == Status.ACTIVE) {
            revert Accountable__AlreadyInDeactivation();
        }

        if (msg.sender == _participant) {
            revert Accountable__CantRemoveYourself();
        }

        if (s_participantBalance[_participant] > 0) {
            _refundParticipant(_participant);
        }

        _removeParticipants(_participant);
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
            revert Accountable__StatusIsNotDeactivate();
        }

        // ******* check if personal already approved his deactivation ?*******
        ///
        ///
        ///

        emit approvedDeactivation(msg.sender);
        s_deactivationApprovals += 1;

        if (s_deactivationApprovals == getNumberOfParticipatingParties()) {
            _refundEveryone();
            s_status = Status.INACTIVE;
        }

        return s_deactivationApprovals;
    }

    /**
     * a function to initialize deactivation process
     */
    function deactivateContract(string memory reason) external onlyRole(PARTICIPANT_ROLE) {
        if (s_status == Status.ACTIVE) {
            revert Accountable__AlreadyInDeactivation();
        }
        emit DeactiveAgreement(msg.sender, reason);
        s_status = Status.DEACTIVATION;
    }

    //////////////////////
    // public functions
    //////////////////////

    /**
     * a function called by any of the particpants to add a task
     *
     * @param _taskName: name of the task
     * @param _numOfPeople: number of people task must be assigned (for group tasks)
     * @param _repetitionPerWeek: number of times a task must be completed / assigned in each week
     *
     */
    function addTask(string memory _taskName, uint256 _numOfPeople, uint256 _repetitionPerWeek)
        public
        onlyRole(PARTICIPANT_ROLE)
    {
        if (s_status != Status.ACTIVE) {
            revert Accountable__NotActive();
        }

        Task memory task = Task(_taskName, _numOfPeople, _repetitionPerWeek, 0, new address[](0));

        s_tasks[taskId._value] = task;
        taskId.increment();

        emit TaskCreated(taskId._value);
    }

    /**
     * a function called
     *
     *
     *
     *
     */
    function assignTask(uint256 _taskId) public {
        uint256 numberOfAssignees = s_tasks[_taskId].numberOfParticipants;

        for (uint256 i = 0; i < numberOfAssignees; i++) {
            s_tasks[_taskId].assignedTo.push(s_participants[i]);
        }
    }

    //////////////////////////
    // internal functions
    //////////////////////////

    /**
     * an internal function called to transfer funds to owner when sent by users to mint an NFT
     *
     * @custom:note - user must approve this contract to spend his tokens equivalent to mint fee,
     * if not transaction will fail
     */
    function _transferTokens(address _tokenAddress, uint256 _amount) internal {
        emit mintFeeTransferedToContract(_amount);

        bool success = IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
        if (!success) {
            revert Accountable__TransferFailed();
        }
    }

    /**
     * an internal refund participant function called to refund staking balance of a participant if any
     * @param _participant: address of participant to be refunded
     */
    function _refundParticipant(address _participant) internal {
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
    function _removeParticipants(address _participant) internal {
        for (uint256 i = 0; i < s_participants.length; i++) {
            if (s_participants[i] == _participant) {
                emit ParticipantRemoved(_participant, msg.sender);
                _remove(i);
                break;
            }
        }
    }

    /**
     * An internal function called during deactivation to refund staking balance
     * to every participant after receiving approvals
     */
    function _refundEveryone() internal {
        address payable[] memory participants = s_participants;
        for (uint256 i = 0; i < getNumberOfParticipatingParties(); i++) {
            if (s_participantBalance[participants[i]] > 0) {
                _refundParticipant(participants[i]);
            }
        }
    }

    /**
     * an internal function to remove a participant
     * @param _index: accepts index of s_participants to delete
     */
    function _remove(uint256 _index) internal {
        // Move the last element into the place to delete
        s_participants[_index] = s_participants[s_participants.length - 1];
        // Remove the last element
        s_participants.pop();
    }

    //////////////////////////////
    // pure and view function
    /////////////////////////////

    /**
     * a function to get titke of contract
     */
    function getTitle() external view returns (string memory) {
        return s_title;
    }

    /**
     * a function to get number of participants in the agreement
     */
    function getNumberOfParticipantsAllowed() public view returns (uint256) {
        return s_numberOfParticipatingParties;
    }

    /**
     * a function to get number of participants in the agreement
     */
    function getNumberOfParticipatingParties() public view returns (uint256) {
        return s_participants.length;
    }

    /**
     * a function to get the staking fee to join the contract in USD
     */
    function getparticipationStake() external view returns (uint256) {
        return s_participationStake;
    }

    /**
     * a function to get the status of contract
     */
    function getStatus() external view returns (uint256) {
        return uint256(s_status);
    }

    /**
     * a function to get the balance of a particular participant
     */
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
