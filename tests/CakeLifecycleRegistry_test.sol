// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "remix_tests.sol";
import "../contracts/CakeLifecycleRegistry.sol";

contract CakeLifecycleRegistryTest {
    CakeLifecycleRegistry registry;

    enum Status { Created, HandedToShipper, ArrivedWarehouse, Delivered, Spoiled, Audited }

    function beforeAll() public {

        registry = new CakeLifecycleRegistry(address(this));

        registry.grantRole(registry.BAKER_ROLE(),     address(this));
        registry.grantRole(registry.SHIPPER_ROLE(),   address(this));
        registry.grantRole(registry.WAREHOUSE_ROLE(), address(this));
        registry.grantRole(registry.ORACLE_ROLE(),    address(this));
        registry.grantRole(registry.AUDITOR_ROLE(),   address(this));
    }

    function testCreateRecord() public {
        uint256 batchId = 1;
        string memory uri = "ipfs://cake1";

        registry.createRecord(batchId, uri);

        // Tuple 解构：跳过 createdAt，只取我们关心的字段
        (, address baker, , , , uint8 status, string memory metadataURI) = registry.getRecord(batchId);

        Assert.equal(baker,       address(this),         "baker should be this contract");
        Assert.equal(status,      uint8(Status.Created), "status should be Created");
        Assert.equal(metadataURI, uri,                   "metadataURI should match");
    }

    function testUpdateToShipper() public {
        uint256 batchId = 2;
        registry.createRecord(batchId, "");
        address shipperAddr = address(0x123);

        registry.updateToShipper(batchId, shipperAddr);

        (, , address shipper, , , uint8 status, ) = registry.getRecord(batchId);

        Assert.equal(shipper, shipperAddr,                      "shipper should be set");
        Assert.equal(status,  uint8(Status.HandedToShipper),    "status should be HandedToShipper");
    }

    function testUpdateToWarehouse() public {
        uint256 batchId = 3;
        registry.createRecord(batchId, "");
        registry.updateToShipper(batchId, address(this));
        address warehouseAddr = address(0x456);

        registry.updateToWarehouse(batchId, warehouseAddr);

        (, , , address warehouse, , uint8 status, ) = registry.getRecord(batchId);

        Assert.equal(warehouse, warehouseAddr,                   "warehouse should be set");
        Assert.equal(status,    uint8(Status.ArrivedWarehouse),  "status should be ArrivedWarehouse");
    }

    function testConfirmDelivered() public {
        uint256 batchId = 4;
        registry.createRecord(batchId, "");
        registry.updateToShipper(batchId, address(this));
        registry.updateToWarehouse(batchId, address(this));

        registry.confirmDelivered(batchId);

        (, , , , , uint8 status, ) = registry.getRecord(batchId);

        Assert.equal(status, uint8(Status.Delivered), "status should be Delivered");
    }

    function testMarkSpoiled() public {
        uint256 batchId = 5;
        registry.createRecord(batchId, "");

        registry.markSpoiled(batchId);

        (, , , , , uint8 status, ) = registry.getRecord(batchId);

        Assert.equal(status, uint8(Status.Spoiled), "status should be Spoiled");
    }

    function testAuditAfterSpoiled() public {
        uint256 batchId = 6;
        registry.createRecord(batchId, "");
        registry.markSpoiled(batchId);

        registry.auditRecord(batchId, "batch bad");

        (, , , , , uint8 status, ) = registry.getRecord(batchId);

        Assert.equal(status, uint8(Status.Audited), "status should be Audited");
    }

    function testAuditAfterDelivered() public {
        uint256 batchId = 7;
        registry.createRecord(batchId, "");
        registry.updateToShipper(batchId, address(this));
        registry.updateToWarehouse(batchId, address(this));
        registry.confirmDelivered(batchId);

        registry.auditRecord(batchId, "batch good");

        (, , , , , uint8 status, ) = registry.getRecord(batchId);

        Assert.equal(status, uint8(Status.Audited), "status should be Audited");
    }

    function testGetLog() public {
        uint256 batchId = 8;
        registry.createRecord(batchId, "");
        registry.updateToShipper(batchId, address(this));

        string[] memory logEntries = registry.getLog(batchId);

        Assert.equal(logEntries.length,        2,                            "should have two log entries");
        Assert.equal(logEntries[0],            "Created by BAKER",           "first log entry mismatch");
        Assert.equal(logEntries[1],            "Handoff to SHIPPER",         "second log entry mismatch");
    }
}