// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface ICakeLifecycle {
    function createRecord(uint256 batchId, string calldata metadataURI) external;
    function updateToShipper(uint256 batchId, address shipper) external;
    function updateToWarehouse(uint256 batchId, address warehouse) external;
    function confirmDelivered(uint256 batchId) external;
    function recordQualityCheck(uint256 batchId, bytes32 snapshotHash) external;
    function markSpoiled(uint256 batchId) external;
    function auditRecord(uint256 batchId, string calldata remarks) external;

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
            string memory metadataURI
        );
    function getLog(uint256 batchId) external view returns (string[] memory);
}