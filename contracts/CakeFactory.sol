// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./ICakeLifecycle.sol";

contract CakeFactory is AccessControl {
    bytes32 public constant BAKER_ROLE = keccak256("BAKER_ROLE");
    ICakeLifecycle public lifecycle;

    struct BatchInfo {
        uint256 batchId;
        string  metadataURI;
        uint256 createdAt;
    }

    mapping(uint256 => BatchInfo) public batches;

    event BatchCreated(
        uint256 indexed batchId,
        address indexed baker,
        string metadataURI,
        uint256 timestamp
    );
    event QualityChecked(
        uint256 indexed batchId,
        bytes32 snapshotHash,
        uint256 timestamp
    );
    event BatchHandoff(
        uint256 indexed batchId,
        address indexed from,
        address indexed to,
        uint256 timestamp
    );
    event BatchCancelled(
        uint256 indexed batchId,
        string reason,
        uint256 timestamp
    );

    /// @param admin            initial admin (gets DEFAULT_ADMIN_ROLE & BAKER_ROLE)
    /// @param lifecycleAddress the deployed CakeLifecycleRegistry address
    constructor(address admin, address lifecycleAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(BAKER_ROLE, admin);
        lifecycle = ICakeLifecycle(lifecycleAddress);
    }

    /// @notice register a new cake batch on‐chain and in the lifecycle registry
    function createBatch(
        uint256 batchId, 
        int256 maxTemperature,
        int256 minTemperature,
        uint256 maxHumidity,
        uint256 minHumidity,
        string calldata metadataURI
    )
        external
        onlyRole(BAKER_ROLE)
    {
        require(batches[batchId].batchId == 0, "Already exists");
        batches[batchId] = BatchInfo(batchId, metadataURI, block.timestamp);
        emit BatchCreated(batchId, msg.sender, metadataURI, block.timestamp);

        // record in the central lifecycle registry
        lifecycle.createRecord(batchId, maxTemperature, minTemperature, maxHumidity, minHumidity, metadataURI);
    }

    /// @notice record a factory quality check snapshot
    function recordQualityCheck(uint256 batchId, bytes32 snapshotHash)
        external
        onlyRole(BAKER_ROLE)
    {
        require(batches[batchId].batchId != 0, "Batch not exist");
        emit QualityChecked(batchId, snapshotHash, block.timestamp);
    }

    /// @notice hand off the batch to the shipper and update registry
    function handoffToShipper(uint256 batchId, address shipper)
        external
        onlyRole(BAKER_ROLE)
    {
        require(batches[batchId].batchId != 0, "Batch not exist");
        emit BatchHandoff(batchId, msg.sender, shipper, block.timestamp);

        // update lifecycle registry
        lifecycle.updateToShipper(batchId, shipper);
    }

    /// @notice cancel a batch before it ships
    function cancelBatch(uint256 batchId, string calldata reason)
        external
        onlyRole(BAKER_ROLE)
    {
        require(batches[batchId].batchId != 0, "Batch not exist");
        emit BatchCancelled(batchId, reason, block.timestamp);
    }
}