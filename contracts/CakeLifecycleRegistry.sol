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
    function recordQualityCheck(uint256 batchId, bytes32 snapshotHash)
        external
        onlyRole(WAREHOUSE_ROLE)
        {
        CakeRecord storage rec = records[batchId];
        require(
            rec.status == Status.ArrivedWarehouse || rec.status == Status.Delivered,
            "Wrong status for QC"
        );
            statusLog[batchId].push(
                string(abi.encodePacked("Warehouse QC: ", snapshotHash))
            );
        emit RecordUpdated(batchId, rec.status, msg.sender);
    }

    /// @inheritdoc ICakeLifecycle
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

    /// @inheritdoc ICakeLifecycle
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

    /// @inheritdoc ICakeLifecycle
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
    function getLog(uint256 batchId)
        external
        view
        returns (string[] memory)
    {
        return statusLog[batchId];
    }
}