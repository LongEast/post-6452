// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface ICakeLifecycle {

    enum Status {
        Created,
        HandedToShipper,
        ArrivedWarehouse,
        Delivered,
        Spoiled,
        Audited
    }

    struct CakeRecord {
        uint256 batchId;
        address baker;
        address shipper;
        address warehouse;
        uint256 createdAt;
        Status status;
        uint256 maxTemperature;
        uint256 minTemperature;
        uint256 maxHumidity;
        uint256 minHumidity;
        bool isFlaged;
        string metadataURI;
    }
    
    function updateToShipper(uint256 batchId, address shipper) external;
    function flagBatch(uint256 batchId, uint256 timestamp) external;
    function updateToWarehouse(uint256 batchId, address warehouse) external;
    function confirmDelivered(uint256 batchId) external;
    function recordQualityCheck(uint256 batchId, bytes32 snapshotHash) external;
    function markSpoiled(uint256 batchId) external;
    function auditRecord(uint256 batchId, string calldata remarks) external;

    function getRecord(uint256 batchId) external view returns (CakeRecord memory);
    function getLog(uint256 batchId) external view returns (string[] memory);
}
