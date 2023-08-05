// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract AccountableTaskAutomation {
    address private s_cronUpKeepFactoryAddress;
    address private S_keeperRegistry;
    address private s_keeperRegistrar;
    address private s_linkTokenAddress;

    constructor(
        address _cronUpKeepFactoryAddress,
        address _keeperRegistry,
        address _keeperRegistrar,
        address _linkTokenAddress
    ) {
        s_cronUpKeepFactoryAddress = _cronUpKeepFactoryAddress;
        S_keeperRegistry = _keeperRegistry;
        s_keeperRegistrar = _keeperRegistrar;
        s_linkTokenAddress = _linkTokenAddress;
    }

    function getEncodeSelector() external pure returns (bytes4 selector) {
        selector = bytes4(keccak256(bytes("encodeCronJob(address,bytes,string)")));
    }

    function getHandler() external pure returns (bytes memory handler) {
        handler = abi.encode("setCount()");
    }

    function getLinkTokenAddress() external view returns (address) {
        return s_linkTokenAddress;
    }

    function getkeeperRegistrar() external view returns (address) {
        return s_keeperRegistrar;
    }

    function getkeeperRegistry() external view returns (address) {
        return S_keeperRegistry;
    }

    function getcronUpKeepFactoryAddress() external view returns (address) {
        return s_cronUpKeepFactoryAddress;
    }
}
