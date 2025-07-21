// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/access/AccessControl.sol";

// This contract is not abstract. All required functions from AccessControl are implemented or inherited.
// Warning from Remix can be safely ignored.
contract SensorOracle is AccessControl {
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    struct SensorReading {
        uint256 timestamp;
        int256  temperature;
        int256  humidity;
    }

    // batchId → history of readings
    mapping(uint256 => SensorReading[]) public readings;

    event SensorReportSubmitted(
        uint256 indexed batchId,
        uint256 timestamp,
        int256  temperature,
        int256  humidity
    );

    /// @param admin       gets DEFAULT_ADMIN_ROLE (can add/remove oracles)
    /// @param sensorAddr  gets ORACLE_ROLE — only this address can call submitSensorData
    constructor(address admin, address sensorAddr) {
        // grant admin the default‐admin role
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        // grant the sensorAddr the ORACLE_ROLE
        _grantRole(ORACLE_ROLE, sensorAddr);
    }

    /// @notice Only the on-chain “sensor” may call this
    function submitSensorData(
        uint256 batchId,
        uint256 timestamp,
        int256  temperature,
        int256  humidity
    )
        external
        onlyRole(ORACLE_ROLE)
    {
        // Sanity checks
        require(timestamp <= block.timestamp, "cannot use future timestamp");
        if (readings[batchId].length > 0) {
            require(
              timestamp > readings[batchId][readings[batchId].length - 1].timestamp,
              "timestamp must increase"
            );
        }
        // require(temperature >= -50 && temperature <= 100, "temp out of range");
        // require(humidity    >=   0 && humidity    <= 100, "hum out of range");

        readings[batchId].push(SensorReading({
          timestamp:   timestamp,
          temperature: temperature,
          humidity:    humidity
        }));

        emit SensorReportSubmitted(batchId, timestamp, temperature, humidity);
    }

    /// @notice How many readings for a batch
    function getReadingCount(uint256 batchId) external view returns (uint256) {
        return readings[batchId].length;
    }

    /// @notice Latest reading for a batch
    function getLastReading(uint256 batchId) external view returns (SensorReading memory) {
        uint256 len = readings[batchId].length;
        require(len > 0, "no readings");
        return readings[batchId][len - 1];
    }
}
