// tests/Shipper_test.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "remix_tests.sol";
import "../contracts/Shipper.sol";
import "../contracts/CakeLifecycleRegistry.sol";

contract ShipperTest {
    CakeLifecycleRegistry cycle;
    Shipper shipper;

    uint256 constant BATCH_ID = 114514;
    string constant metadataURI = "ipfs://bafybeid2jvyr7x7n4rmpn4l7yen3q6acj4wbuoyh6c4j6sl5b4s5qzv6fu/meta.json";
    address immutable SHIPPER = address(this);
    address constant WAREHOUSE = address(0xABCD);
    uint256 constant fromActorId = 1919;
    uint256 constant toActorId = 810;
    string constant GEOLOCATION = "Japan";
    bytes32 constant SNAP_HASH  = keccak256(bytes("quality-snapshot"));

    function beforeAll() public {
        cycle = new CakeLifecycleRegistry(address(this));
        cycle.createRecord(BATCH_ID, metadataURI);
        shipper = new Shipper(SHIPPER, address(cycle));
        cycle.grantRole(cycle.SHIPPER_ROLE(), address(shipper));
    }

    function testInexistentBatch() public {
        try shipper.handOffLog(BATCH_ID + 1, fromActorId, toActorId, GEOLOCATION, SNAP_HASH) {
            Assert.ok(false, "Expected revert but function succeeded");
        } catch Error(string memory reason) {
            Assert.equal(reason, "CakeLifecycle: batch record not found", "Reason mismatch");
        } catch { 
            Assert.ok(false, "Not revert as expected"); 
        }

        try shipper.reportAccident(BATCH_ID + 1, fromActorId, "Cake stolen") {
            Assert.ok(false, "Expected revert but function succeeded");
        } catch Error(string memory reason) {
            Assert.equal(reason, "CakeLifecycle: batch record not found", "Reason mismatch");
        } catch { 
            Assert.ok(false, "Not revert as expected"); 
        }

        try shipper.deliveredToWarehouse(BATCH_ID + 1, WAREHOUSE) {
            Assert.ok(false, "Expected revert but function succeeded");
        } catch Error(string memory reason) {
            Assert.equal(reason, "CakeLifecycle: batch record not found", "Reason mismatch");
        } catch { 
            Assert.ok(false, "Not revert as expected"); 
        }
    }
    
    function testReportAccident() public {
        shipper.reportAccident(BATCH_ID, fromActorId, "Cake stolen");
        Assert.ok(true, "ReportAccident execuated as expected");
    }

    function testHandOffLog() public {
        shipper.handOffLog(BATCH_ID, fromActorId, toActorId, GEOLOCATION, SNAP_HASH);
        Assert.ok(true, "HandOffLog execuated as expected");
    }

    function testDeliveredToWarehouse() public {
        cycle.updateToShipper(BATCH_ID, SHIPPER);
        shipper.deliveredToWarehouse(BATCH_ID, WAREHOUSE);
        (
            ,
            ,
            ,
            address warehouse,
            ,
            uint8 status,

        ) = cycle.getRecord(BATCH_ID);
        Assert.equal(status, 2, "status mismatch");
        Assert.equal(warehouse, address(0xABCD), "warehouse address mismatch");
        Assert.ok(true, "HandOffLog execuated as expected");
    }
}
