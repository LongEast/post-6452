// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "remix_tests.sol";        // this import is for Remix’s test runner
import "remix_accounts.sol";     // this import gives you access to test accounts

import "../contracts/SensorOracle.sol";

contract TestSensorOracle {
    SensorOracle authOracle;
    SensorOracle unauthOracle;
    address admin;
    address sensor; // we’ll make the test contract itself the “sensor”
    address other;  // some other account

    /// @notice this runs once before all tests
    function beforeAll() public {
        admin  = TestsAccounts.getAccount(0);
        other  = TestsAccounts.getAccount(1);
        sensor = address(this);

        // authOracle trusts our test contract as the sensor
        authOracle   = new SensorOracle(admin, sensor);
        // unauthOracle trusts the OTHER account instead, so our test contract is unauthorized
        unauthOracle = new SensorOracle(admin, other);
    }

    /// initial reading count must be zero
    function initialCountIsZero() public {
        uint256 cnt = authOracle.getReadingCount(123);
        Assert.equal(cnt, uint256(0), "expected zero readings initially");
    }

    /// only the “sensor” (this contract) can submit, and data must be stored
    function authorizedCanSubmit() public {
        uint256 batchId     = 123;
        uint256 ts          = block.timestamp;
        int256  temperature = 22;
        int256  humidity    = 55;

        // this contract has ORACLE_ROLE on authOracle
        authOracle.submitSensorData(batchId, ts, temperature, humidity);

        uint256 cnt = authOracle.getReadingCount(batchId);
        Assert.equal(cnt, uint256(1), "one reading should be stored");

        // verify getLastReading
        SensorOracle.SensorReading memory r = authOracle.getLastReading(batchId);
        Assert.equal(r.timestamp,   ts,          "timestamp mismatch");
        Assert.equal(r.temperature, temperature, "temperature mismatch");
        Assert.equal(r.humidity,    humidity,    "humidity mismatch");
    }

    /// unauthorized submissions must revert
    function unauthorizedReverts() public {
        uint256 batchId     = 456;
        uint256 ts          = block.timestamp;
        int256  temperature = 30;
        int256  humidity    = 70;

        // call unauthOracle from this contract (which is NOT its sensor role)
        (bool ok, ) = address(unauthOracle).call(
            abi.encodeWithSelector(
                unauthOracle.submitSensorData.selector,
                batchId, ts, temperature, humidity
            )
        );
        Assert.ok(!ok, "unauthorized submit should revert");
    }

    /// timestamp must strictly increase for each batch
    function monotonicTimestampRequired() public {
        uint256 batchId     = 789;
        uint256 ts          = block.timestamp;
        int256  temperature = 18;
        int256  humidity    = 40;

        // first submission OK
        authOracle.submitSensorData(batchId, ts, temperature, humidity);

        // second submission with same ts → revert
        (bool ok, ) = address(authOracle).call(
            abi.encodeWithSelector(
                authOracle.submitSensorData.selector,
                batchId, ts, temperature, humidity
            )
        );
        Assert.ok(!ok, "must revert when timestamp doesn't increase");
    }
}
