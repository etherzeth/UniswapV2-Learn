// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

abstract contract Context {
    function _msgsender() internal view returns (address) {
        return msg.sender;
    }
}