// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "remix_tests.sol";
import "../contracts/HelloWorld.sol";

contract HelloWorldTest {
    HelloWorld hello;

    function beforeAll() public {
        hello = new HelloWorld();
    }

    function testInitialMessage() public {
        Assert.equal(hello.message(), "Hi Letao!", " Initial message should be 'Hi Letao!'");
    }

    function testSetMessage() public {
        hello.setMessage("New ColdChain");
        Assert.equal(hello.message(), "New ColdChain", "call setMessage should change message to 'New ColdChain'");
    }
}