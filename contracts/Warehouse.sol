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
        require(batch_exists(batchId), "Batch not exist");

        lifecycle.confirmDelivered(batchId);
        emit BatchDelivered(batchId, msg.sender, block.timestamp);
    }

    /// @notice record a warehouse quality check snapshot
    function checkQuality(uint256 batchId, bytes32 snapshotHash)
        external
        onlyRole(WAREHOUSE_ROLE)
    {
        require(batch_exists(batchId), "Batch not exist");
        emit QualityChecked(batchId, snapshotHash, block.timestamp);
        lifecycle.recordQualityCheck(batchId, snapshotHash);
    }


    /// @dev check batchId exists in Registry (id != 0)
    function batch_exists(uint256 batchId) private view returns (bool) {
        (uint256 id,,,,,,) = lifecycle.getRecord(batchId);
        return id != 0;
    }
}
