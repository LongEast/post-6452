// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IShipmentAlertSink {
    function checkAlert(uint256 batchId, uint256 timestamp) external;
}