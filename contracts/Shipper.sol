// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./ICakeLifecycle.sol";

contract Shipper is AccessControl {
    bytes32 public constant SHIPPER_ROLE = keccak256("SHIPPER_ROLE");
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
    constructor(address shipper, address lifecycleAddress) {
        _grantRole(SHIPPER_ROLE, shipper);
        lifecycle = ICakeLifecycle(lifecycleAddress);
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
    {   
        checkBatch(batchId);
        uint256 interval = timestamp - alertLogs[batchId];
        if (interval >= 295 && interval <= 305) {
            alertCount[batchId]++;
        }
        
        else {
            alertCount[batchId] = 1;
        }

        alertLogs[batchId] = timestamp;


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
    
    // Shipper.sol
    function checkBatch(uint256 batchId) private view {
        // grab the whole struct that ICakeLifecycle gives back
        ICakeLifecycle.CakeRecord memory rec = lifecycle.getRecord(batchId);

        // status 1 == HandedToShipper  (use your enum if it’s public)
    // Compare enum to enum
    require(
        rec.status == ICakeLifecycle.Status.HandedToShipper,
        "Batch is not in HandedToShipper status"
    );    
    
}

}