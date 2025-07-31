// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./ICakeLifecycle.sol";

contract Warehouse is AccessControl {
    bytes32 public constant WAREHOUSE_ROLE = keccak256("WAREHOUSE_ROLE");
    ICakeLifecycle public lifecycle;

    event BatchDelivered(
        uint256 indexed batchId,
        address indexed warehouse,
        uint256 timestamp
    );
    event QualityFlagged(
        uint256 indexed batchId,
        address indexed warehouse,
        uint256 timestamp
    );
    event QualitySampled(
        uint256 indexed batchId,
        address indexed warehouse,
        uint256 timestamp,
        uint rand
    );
    event QualityChecked(
        uint256 indexed batchId,
        bytes32 snapshotHash,
        uint256 timestamp
    );

    /// @param admin            initial admin (gets DEFAULT_ADMIN_ROLE & WAREHOUSE_ROLE)
    /// @param lifecycleAddress the deployed CakeLifecycleRegistry address
    constructor(address admin, address lifecycleAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(WAREHOUSE_ROLE,     admin);
        lifecycle = ICakeLifecycle(lifecycleAddress);
    }

    /// @notice confirm the batch has arrived at warehouse
    function confirmDelivered(uint256 batchId)
        external
        onlyRole(WAREHOUSE_ROLE)
    {
        ICakeLifecycle.CakeRecord memory rec = lifecycle.getRecord(batchId);
        require(rec.batchId != 0, "Batch not exist");
        require(
            rec.status == ICakeLifecycle.Status.ArrivedWarehouse,
            "Batch not in the warehouse"
        );

        lifecycle.confirmDelivered(batchId);
        emit BatchDelivered(batchId, msg.sender, block.timestamp);
    }

    /// @notice record a warehouse quality check snapshot
    function checkQuality(uint256 batchId, bytes32 snapshotHash)
        external
        onlyRole(WAREHOUSE_ROLE)
    {
        ICakeLifecycle.CakeRecord memory rec = lifecycle.getRecord(batchId);
        require(rec.batchId != 0, "Batch not exist");

        bool doCheck = false;

        if (rec.isFlagged) {
            doCheck = true;
            emit QualityFlagged(batchId, msg.sender, block.timestamp);
        } else {
            uint rand = uint(
                keccak256(abi.encodePacked(block.timestamp, msg.sender, batchId))
            ) % 100;
            if (rand < 30) {
                doCheck = true;
                emit QualitySampled(batchId, msg.sender, block.timestamp, rand);
            }
        }

        if (doCheck) {
            emit QualityChecked(batchId, snapshotHash, block.timestamp);
            lifecycle.recordQualityCheck(batchId, snapshotHash);
        }
    }
    
}
