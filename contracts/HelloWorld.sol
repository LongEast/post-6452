// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract HelloWorld {
    string public message = "Hi Letao!";
    function setMessage(string calldata newMsg) external {
        message = newMsg;
    }
}
