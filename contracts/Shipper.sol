// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./ICakeLifecycle.sol";

contract Shipper is AccessControl {
    bytes32 public constant SHIPPER_ROLE = keccak256("SHIPPER_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    ICakeLifecycle public lifecycle;
    
    mapping (uint256 => uint256) private alertLogs;
    mapping (uint256 => uint256) private alertCount;
    mapping (uint256 => bool) private hasFlagged;

    event BatchHandOff(
        uint256 batchId,
        address indexed fromActor,
        address indexed toActor,
        uint256 timestamp,
        int256 longitude,
        int256 latitude,
        bytes32 snapshotHash
    );
    
    event ShippingAccident(
        uint256 batchId,
        uint256 timestamp,
        address actor,
        string accident
    );

    event BatchDelivered(
        uint256 batchID,
        uint256 timestamp,
        address warehouse
    );


    /// @param shipper the shipper (gets SHIPPER_ROLE)
    /// @param lifecycleAddress the deployed CakeLifecycleRegistry address
    constructor(address admin, address shipper, address lifecycleAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(SHIPPER_ROLE, shipper);
        lifecycle = ICakeLifecycle(lifecycleAddress);
    }
    
    function setOracle(address oracleAdd)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _grantRole(ORACLE_ROLE, oracleAdd);
    }

    /// @notice record the handoff to next actor
    function handOffLog(uint256 batchId, address fromActor, address toActor, int256 longitude, int256 latitude, bytes32 snapshotHash) 
        external
        onlyRole(SHIPPER_ROLE) 
    {
        checkBatch(batchId);
        emit BatchHandOff(batchId, fromActor, toActor, block.timestamp, longitude, latitude, snapshotHash);
    }
    
    /// @notice record any accident during shipping
    function reportAccident(uint256 batchId, address actor, string calldata accident) 
        external 
        onlyRole(SHIPPER_ROLE)
    {
        checkBatch(batchId);
        emit ShippingAccident(batchId, block.timestamp, actor, accident);
    }
    
    function checkAlert(uint256 batchId, uint256 timestamp)
        external 
        onlyRole(ORACLE_ROLE)
    {   
        alertCount[batchId]++;

        if (alertCount[batchId] == 3 && hasFlagged[batchId] == false) {
            lifecycle.flagBatch(batchId, timestamp);
            hasFlagged[batchId] = true;
        }
    }
    
    /// @notice record arrival to warehouse
    function deliveredToWarehouse(uint256 batchId, address warehouse)
        external
        onlyRole(SHIPPER_ROLE)  
    {    
        checkBatch(batchId);
        emit BatchDelivered(batchId, block.timestamp, warehouse);
        lifecycle.updateToWarehouse(batchId, warehouse);
    }
    
    /// @notice helper function to check whether a batch exists and is in HandedToShipper status
    function checkBatch(uint256 batchId) private view {
        ICakeLifecycle.CakeRecord memory rec = lifecycle.getRecord(batchId);
        require(
                rec.status == ICakeLifecycle.Status.HandedToShipper,
            "Batch is not in HandedToShipper status"
        );
    }

}
