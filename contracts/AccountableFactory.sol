// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

//////////////////////
// Import statements
//////////////////////
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Accountable} from "./Accountable.sol";

////////////////////////////
// libraries & Interfaces
////////////////////////////
import {OracleLib, AggregatorV3Interface} from "./libraries/OracleLib.sol";

//////////////////////
// errors
//////////////////////
error AccountableFactory__CountOfTokenAddressesAndPriceFeedAddressesDontMatch();
error AccountableFactory__PriceFeedAddressesCantBeZero();

/**
 * @title An Accountability application contract
 * @author Mahith Chigurupati
 * @notice This contract is for a group of people who intend to join an agreement for sharing tasks among themselves and
 *         this contract will ensure everyone completes their tasks on time
 */
contract AccountableFactory is Ownable {
    //////////////////////
    // Type Declarations
    //////////////////////
    using OracleLib for AggregatorV3Interface;

    /**
     * custon enum variable to hold status of agreement
     */
    enum Status {
        CREATED,
        OPEN,
        ACTIVE,
        DEACTIVATION,
        INACTIVE
    }

    //////////////////////
    // State variables
    //////////////////////
    Status private s_status;
    mapping(address accountable => Status status) private s_contractStatus;
    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address participant => address token) private s_participantAsset;
    address private s_currentChainPriceFeed;
    mapping(address creator => address[] contractsCreated) private s_ownerToContracts;

    ///////////////////
    // Functions
    ///////////////////

    /**
     * @param _tokenAddresses: list of supported token addresses on current chain
     * @param _priceFeedAddresses: list of chainlink price feed contract addresses for supported ERC20 tokens
     * @param _priceFeedAddressOfcurrentChain: chainlink price feed contract address of current chain
     */
    constructor(
        address[] memory _tokenAddresses,
        address[] memory _priceFeedAddresses,
        address _priceFeedAddressOfcurrentChain
    ) {
        if (_tokenAddresses.length != _priceFeedAddresses.length) {
            revert AccountableFactory__CountOfTokenAddressesAndPriceFeedAddressesDontMatch();
        }

        if (_priceFeedAddressOfcurrentChain == address(0)) {
            revert AccountableFactory__PriceFeedAddressesCantBeZero();
        }

        // These feeds will be the USD pairs
        // For example wETH / USD or wBTC / USD or MATIC / USD or USDC / USD etc.,
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            if (_tokenAddresses[i] == address(0) || _priceFeedAddresses[i] == address(0)) {
                revert AccountableFactory__PriceFeedAddressesCantBeZero();
            }

            s_priceFeeds[_tokenAddresses[i]] = _priceFeedAddresses[i];
        }

        s_currentChainPriceFeed = _priceFeedAddressOfcurrentChain;
    }

    /**
     * a function call to create an agreement by a user
     *
     * @param _title: A title for Agreement
     * @param _numberOfParticipatingParties: Total Number of participating parties/roommates in the contract
     * @param _participationStake: Amount need to be staked by each participant to join the agreement
     */
    function createAgreement(string memory _title, uint256 _numberOfParticipatingParties, uint256 _participationStake)
        external
    {
        Accountable accountable = new Accountable(
            _title, _numberOfParticipatingParties, _participationStake
            );

        s_contractStatus[address(accountable)] = Status.CREATED;
        s_ownerToContracts[msg.sender].push(address(accountable));
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

    function setTaskAutomationContractAddress(address _taskAutomationContract) external onlyOwner {}

    /*
    * a function call to get all the created agreement of a user
    * 
    * @param _user: user for which created contracts are needed
    */
    function getCreatedagreements(address _user) external view {
        s_ownerToContracts[_user];
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
    function getEthPriceFromUsd(uint256 _amount) external view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_currentChainPriceFeed);
        return priceFeed.getEthAmountFromUsd(_amount);
    }

    /**
     * a function to get price conversion from USD to token equivalent price
     *
     * @param _tokenAddress: conversion in which token equivalent is needed
     */
    function getTokenPriceFromUsd(address _tokenAddress, uint256 _amount) external view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[_tokenAddress]);
        return priceFeed.getEthAmountFromUsd(_amount);
    }
}
