// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./ICakeLifecycle.sol";

contract Shipper is AccessControl {
    bytes32 public constant SHIPPER_ROLE = keccak256("SHIPPER_ROLE");
    ICakeLifecycle public lifecycle;

    event BatchHandOff(
        uint batchId,
        address indexed fromActor,
        address indexed toActor,
        uint timestamp,
        int256 longitude,
        int256 latitude,
        bytes32 snapshotHash
    );
    
    event ShippingAccident(
        uint batchId,
        uint timestamp,
        address actor,
        string accident
    );

    event BatchDelivered(
        uint batchID,
        uint timestamp,
        address warehouse
    );


    /// @param shipper the shipper (gets SHIPPER_ROLE)
    /// @param lifecycleAddress the deployed CakeLifecycleRegistry address
    constructor(address shipper, address lifecycleAddress) {
        _grantRole(SHIPPER_ROLE, shipper);
        lifecycle = ICakeLifecycle(lifecycleAddress);
    }
    
    /// @notice record the handoff to next actor
    function handOffLog(uint batchId, address fromActor, address toActor, int256 longitude, int256 latitude, bytes32 snapshotHash) 
        external
        onlyRole(SHIPPER_ROLE) 
    {
        checkBatch(batchId);
        emit BatchHandOff(batchId, fromActor, toActor, block.timestamp, longitude, latitude, snapshotHash);
    }
    
    /// @notice record any accident during shipping
    function reportAccident(uint batchId, address actor, string calldata accident) 
        external 
        onlyRole(SHIPPER_ROLE)
    {
        checkBatch(batchId);
        emit ShippingAccident(batchId, block.timestamp, actor, accident);
    }
    
    /// @notice record arrival to warehouse
    function deliveredToWarehouse(uint batchId, address warehouse)
        external
        onlyRole(SHIPPER_ROLE)  
    {    
        checkBatch(batchId);
        emit BatchDelivered(batchId, block.timestamp, warehouse);
        lifecycle.updateToWarehouse(batchId, warehouse);
    }
    
    /// @notice helper function to check whether a batch exists and is in HandedToShipper status
    function checkBatch(uint batchId) private view {
        (
            ,
            ,
            ,
            ,
            ,
            uint8 status,
        ) = lifecycle.getRecord(batchId);
        require(status == 1, "Batch is not in HandedToShipper status");
    }

}
