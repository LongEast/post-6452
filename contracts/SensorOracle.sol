// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./IShipmentAlertSink.sol";

// This contract is not abstract. All required functions from AccessControl are implemented or inherited.
// Warning from Remix can be safely ignored.
contract SensorOracle is AccessControl {
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    IShipmentAlertSink public shipment;


    int256 public maxTemp      = 20;   // °C
    int256 public minTemp      = -7;
    int256 public MAX_HUMIDITY = 50;   // %
    int256 public MIN_HUMIDITY = 20;


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

    event ThresholdAlert(
        uint256 indexed batchId,
        uint256 timestamp,
        string  reason
    );

    event TESTThresholdAlert(
        uint256 indexed batchId
    );

    


    /// @param admin       gets DEFAULT_ADMIN_ROLE (can add/remove oracles)
    /// @param sensorAddr  gets ORACLE_ROLE — only this address can call submitSensorData
    constructor(address admin, address sensorAddr) {
        // grant admin the default‐admin role
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        // grant the sensorAddr the ORACLE_ROLE
        _grantRole(ORACLE_ROLE, sensorAddr);
    }

    function setShipment(address shipmentAddr)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        shipment = IShipmentAlertSink(shipmentAddr);
    }
        // onlyRole(ORACLE_ROLE)

    /// @notice Only the on-chain “sensor” may call this
    function submitSensorData(
        uint256 batchId,
        int256  temperature,
        int256  humidity
    )
        external
    {
        // uint256 timestamp = block.timestamp;
        // readings[batchId].push(SensorReading({
        //   timestamp:   timestamp,
        //   temperature: temperature,
        //   humidity:    humidity
        // }));

        emit TESTThresholdAlert(batchId); // works
        // return;
        // string memory reason = "";
        // bool violated;

        // if (temperature > maxTemp)      { violated = true; reason = "TEMP_HIGH"; }
        // else if (temperature < minTemp) { violated = true; reason = "TEMP_LOW"; }
        // else if (humidity > MAX_HUMIDITY){ violated = true; reason = "HUM_HIGH"; }
        // else if (humidity < MIN_HUMIDITY){ violated = true; reason = "HUM_LOW"; }

        // if (violated) {
        //     emit ThresholdAlert(batchId, timestamp, reason);

        //     // Push alert to Shipment — swallow errors so Oracle doesn’t get stuck
        //     if (address(shipment) != address(0)) {
        //         try shipment.checkAlert(batchId, timestamp) {
        //             // ok
        //         } catch {
        //             // you could emit a “FailedPush” event here for debugging
        //         }
        //     }
        // }

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
