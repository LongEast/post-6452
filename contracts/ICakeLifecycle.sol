// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/// @title Interface for CakeLifecycleRegistry
/// @notice Defines the functions for recording and querying a cake batch's lifecycle
interface ICakeLifecycle {
    function createRecord(
        uint256 batchId,
        uint256 maxTemperature,
        uint256 minTemperature,
        uint256 maxHumidity,
        uint256 minHumidity,
        string calldata metadataURI
    ) external;
    function updateToShipper(uint256 batchId, address shipper) external;
    function flagBatch(uint256 batchId, uint256 timestamp) external;
    function updateToWarehouse(uint256 batchId, address warehouse) external;
    function recordQualityCheck(uint256 batchId, bytes32 snapshotHash) external;
    function confirmDelivered(uint256 batchId) external;
    function markSpoiled(uint256 batchId) external;
    function auditRecord(uint256 batchId, string calldata remarks) external;

    /// @notice Retrieve the full record data for a given batch
    function getRecord(uint256 batchId)
        external
        view
        returns (
            uint256 id,
            address baker,
            address shipper,
            address warehouse,
            uint256 createdAt,
            uint8 status,
            uint256 maxTemperature,
            uint256 minTemperature,
            uint256 maxHumidity,
            uint256 minHumidity,
            bool isFlaged,
            string memory metadataURI
        );

    /// @notice Retrieve the status history log for a given batch
    function getLog(uint256 batchId) external view returns (string[] memory);
}
