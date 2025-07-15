// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./ICakeLifecycle.sol";

contract Shipper is AccessControl {
    bytes32 public constant SHIPPER_ROLE = keccak256("SHIPPER_ROLE");
    ICakeLifecycle public lifecycle;

    event BatchHandOff(
        uint batchId,
        uint fromActorId,
        uint toActorId,
        uint timestamp,
        string geolocation,
        bytes32 snapshotHash
    );
    
    event ShippingAccident(
        uint batchId,
        uint timestamp,
        uint actorId,
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
    function handOffLog(uint batchId, uint fromActorId, uint toActorId, string calldata geolocation, bytes32 snapshotHash) 
        external
        onlyRole(SHIPPER_ROLE) 
    {
        lifecycle.getRecord(batchId);
        emit BatchHandOff(batchId, fromActorId, toActorId, block.timestamp, geolocation, snapshotHash);
    }
    
    /// @notice record any accident during shipping
    function reportAccident(uint batchId, uint actorId, string calldata accident) 
        external 
        onlyRole(SHIPPER_ROLE)
    {
        lifecycle.getRecord(batchId);
        emit ShippingAccident(batchId, block.timestamp, actorId, accident);
    }
    
    /// @notice record arrival to warehouse
    function deliveredToWarehouse(uint batchId, address warehouse)
        external
        onlyRole(SHIPPER_ROLE)  
    {    
        lifecycle.getRecord(batchId);
        emit BatchDelivered(batchId, block.timestamp, warehouse);
        lifecycle.updateToWarehouse(batchId, warehouse);
    }

}
