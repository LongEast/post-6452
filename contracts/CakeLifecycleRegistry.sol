// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./ICakeLifecycle.sol";

contract CakeLifecycleRegistry is AccessControl, ICakeLifecycle {
    bytes32 public constant ADMIN_ROLE     = DEFAULT_ADMIN_ROLE;
    bytes32 public constant BAKER_ROLE     = keccak256("BAKER_ROLE");
    bytes32 public constant SHIPPER_ROLE   = keccak256("SHIPPER_ROLE");
    bytes32 public constant WAREHOUSE_ROLE = keccak256("WAREHOUSE_ROLE");
    bytes32 public constant ORACLE_ROLE    = keccak256("ORACLE_ROLE");
    bytes32 public constant AUDITOR_ROLE   = keccak256("AUDITOR_ROLE");

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
        string metadataURI;
    }

    mapping(uint256 => CakeRecord) private records;
    mapping(uint256 => string[]) private statusLog;

    event RecordCreated(uint256 indexed batchId, address indexed baker, string metadataURI);
    event RecordUpdated(uint256 indexed batchId, Status newStatus, address indexed actor);
    event RecordAudited(uint256 indexed batchId, address indexed auditor, string remarks);

    constructor(address admin) {
        _grantRole(ADMIN_ROLE, admin);
        _grantRole(BAKER_ROLE, admin);
        _grantRole(SHIPPER_ROLE, admin);
        _grantRole(WAREHOUSE_ROLE, admin);
        _grantRole(ORACLE_ROLE, admin);
        _grantRole(AUDITOR_ROLE, admin);
    }

    /// @inheritdoc ICakeLifecycle
    /// @notice Creates a new cake record for a given batch ID with associated metadata.
    /// @dev Only accounts with the BAKER_ROLE can call this function. Ensures that a record for the given batch ID does not already exist.
    /// @param batchId The unique identifier for the cake batch.
    /// @param metadataURI The URI pointing to the metadata associated with the cake batch.
    /// @custom:emit Emits a {RecordCreated} event upon successful creation.
    function createRecord(uint256 batchId, string calldata metadataURI)
        external
        onlyRole(BAKER_ROLE)
    {
        require(records[batchId].batchId == 0, "Batch already exists");
        records[batchId] = CakeRecord({
            batchId: batchId,
            baker: msg.sender,
            shipper: address(0),
            warehouse: address(0),
            createdAt: block.timestamp,
            status: Status.Created,
            metadataURI: metadataURI
        });
        statusLog[batchId].push("Created by BAKER");
        emit RecordCreated(batchId, msg.sender, metadataURI);
    }

    /// @inheritdoc ICakeLifecycle
    /**
     * @notice Updates the status of a cake batch to indicate it has been handed off to the shipper.
     * @dev Only callable by accounts with the BAKER_ROLE.
     * @param batchId The unique identifier of the cake batch to update.
     * @param shipper The address of the shipper receiving the batch.
     * Requirements:
     * - The batch must be in the 'Created' status.
     * - Caller must have the BAKER_ROLE.
     * Emits a {RecordUpdated} event upon successful update.
     */
    function updateToShipper(uint256 batchId, address shipper)
        external
        onlyRole(BAKER_ROLE)
    {
        CakeRecord storage rec = records[batchId];
        require(rec.status == Status.Created, "Invalid status");
        rec.shipper = shipper;
        rec.status = Status.HandedToShipper;
        statusLog[batchId].push("Handoff to SHIPPER");
        emit RecordUpdated(batchId, Status.HandedToShipper, msg.sender);
    }

    /// @inheritdoc ICakeLifecycle
    /**
     * @notice Updates the status of a cake batch to indicate it has arrived at the warehouse.
     * @dev Can only be called by an account with the SHIPPER_ROLE.
     *      Requires that the current status of the batch is HandedToShipper.
     *      Updates the warehouse address, sets the status to ArrivedWarehouse,
     *      logs the status change, and emits a RecordUpdated event.
     * @param batchId The unique identifier of the cake batch.
     * @param warehouse The address of the warehouse where the batch has arrived.
     */
    function updateToWarehouse(uint256 batchId, address warehouse)
        external
        onlyRole(SHIPPER_ROLE)
    {
        CakeRecord storage rec = records[batchId];
        require(rec.status == Status.HandedToShipper, "Not shipped yet");
        rec.warehouse = warehouse;
        rec.status = Status.ArrivedWarehouse;
        statusLog[batchId].push("Arrived at WAREHOUSE");
        emit RecordUpdated(batchId, Status.ArrivedWarehouse, msg.sender);
    }

 
    function confirmDelivered(uint256 batchId)
        external
        onlyRole(WAREHOUSE_ROLE)
    {
        CakeRecord storage rec = records[batchId];
        require(rec.status == Status.ArrivedWarehouse, "Not in warehouse");
        rec.status = Status.Delivered;
        statusLog[batchId].push("DELIVERED");
        emit RecordUpdated(batchId, Status.Delivered, msg.sender);
    }


    function markSpoiled(uint256 batchId)
        external
        onlyRole(ORACLE_ROLE)
    {
        CakeRecord storage rec = records[batchId];
        require(rec.status != Status.Spoiled, "Already spoiled");
        rec.status = Status.Spoiled;
        statusLog[batchId].push("SPOILED by ORACLE");
        emit RecordUpdated(batchId, Status.Spoiled, msg.sender);
    }

    function auditRecord(uint256 batchId, string calldata remarks)
        external
        onlyRole(AUDITOR_ROLE)
    {
        CakeRecord storage rec = records[batchId];
        require(
            rec.status == Status.Delivered || rec.status == Status.Spoiled,
            "Must be end state"
        );
        rec.status = Status.Audited;
        statusLog[batchId].push(string.concat("Audited: ", remarks));
        emit RecordAudited(batchId, msg.sender, remarks);
    }

    /// @inheritdoc ICakeLifecycle
    /**
     * @notice Retrieves the details of a cake batch record by its batch ID.
     * @param batchId The unique identifier of the cake batch.
     * @return id The batch ID of the cake record.
     * @return baker The address of the baker associated with the batch.
     * @return shipper The address of the shipper responsible for the batch.
     * @return warehouse The address of the warehouse storing the batch.
     * @return createdAt The timestamp when the batch record was created.
     * @return status The current status of the batch as an unsigned 8-bit integer.
     * @return metadataURI The URI pointing to additional metadata for the batch.
     */
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
        )
    {
        CakeRecord storage rec = records[batchId];
        return (
            rec.batchId,
            rec.baker,
            rec.shipper,
            rec.warehouse,
            rec.createdAt,
            uint8(rec.status),
            rec.metadataURI
        );
    }

    /// @inheritdoc ICakeLifecycle
    /// @notice Retrieves the status log for a specific batch.
    /// @param batchId The unique identifier of the batch whose log is to be retrieved.
    /// @return An array of strings representing the status log entries for the specified batch.
    function getLog(uint256 batchId)
        external
        view
        returns (string[] memory)
    {
        return statusLog[batchId];
    }
}
