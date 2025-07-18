// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

// bring in Remix’s test and accounts helpers
import "remix_tests.sol";
import "remix_accounts.sol";

import "../contracts/SensorOracle.sol";

contract TestSensorOracle {
    SensorOracle oracle;
    address admin;
    address sensor;
    address other;

    // — these need to be computed off-chain, e.g. with ethers.js or web3.eth.sign —  
    //   over: keccak256(abi.encodePacked(batchId, temperature, humidity, timestamp))
    //   signed by the `sensor` private key
    uint256 constant B = 42;                /// batchId
    uint256 constant TMS = 1_700_000_000;   /// timestamp
    int256  constant TEMP = 25;             /// temperature
    int256  constant HUM  = 60;             /// humidity
    bytes32 constant DATA_HASH = 0x1111111111111111111111111111111111111111111111111111111111111111;
    uint8   constant V = 28;
    bytes32 constant R = 0x2222222222222222222222222222222222222222222222222222222222222222;
    bytes32 constant S = 0x3333333333333333333333333333333333333333333333333333333333333333;

    function beforeAll() public {
        // accounts[0] = admin, [1] = sensor, [2] = other
        admin  = TestsAccounts.getAccount(0);
        sensor = TestsAccounts.getAccount(1);
        other  = TestsAccounts.getAccount(2);

        // deploy with admin, trustedSensor
        oracle = new SensorOracle(admin, sensor);
    }

    /// [1] Initial proof count is zero
    function testInitialCount() public {
        uint256 c = oracle.getProofCount(B);
        Assert.equal(c, 0, "proof count should start at zero");
    }

    /// [2] should accept a valid signature
    
}