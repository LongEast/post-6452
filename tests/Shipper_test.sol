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
    bytes32 constant SNAP_HASH  = keccak256(bytes("quality-snapshot"));
    address constant FROM_ACTOR = address(0x000000001919);
    address constant TO_ACTOR   = address(0x000000000810);
    int256  constant LONGITUDE  = 810975;
    int256  constant LATITUDE   = 3568430;

   function beforeAll() public {
        cycle = new CakeLifecycleRegistry(address(this));
        cycle.createRecord(BATCH_ID, 30, 10, 80, 20, metadataURI);
        shipper = new Shipper(SHIPPER, address(cycle));
        cycle.grantRole(cycle.SHIPPER_ROLE(), address(shipper));
        cycle.updateToShipper(BATCH_ID, address(shipper));
    }

    function testInexistentBatch() public {
        uint256 fakeId = BATCH_ID + 1;

        try shipper.handOffLog(fakeId, FROM_ACTOR, TO_ACTOR, LONGITUDE, LATITUDE, SNAP_HASH) {
            Assert.ok(false, "Expected revert but function succeeded");
        } catch Error(string memory reason) {
            Assert.equal(reason, "CakeLifecycle: batch record not found", "Reason mismatch");
        } catch { 
            Assert.ok(false, "Not revert as expected"); 
        }

        try shipper.reportAccident(fakeId, FROM_ACTOR, "Cake stolen") {
            Assert.ok(false, "Expected revert but function succeeded");
        } catch Error(string memory reason) {
            Assert.equal(reason, "CakeLifecycle: batch record not found", "Reason mismatch");
        } catch { 
            Assert.ok(false, "Not revert as expected"); 
        }

        try shipper.deliveredToWarehouse(fakeId, WAREHOUSE) {
            Assert.ok(false, "Expected revert but function succeeded");
        } catch Error(string memory reason) {
            Assert.equal(reason, "CakeLifecycle: batch record not found", "Reason mismatch");
        } catch { 
            Assert.ok(false, "Not revert as expected"); 
        }
    }
    
    function testReportAccident() public {
        shipper.reportAccident(BATCH_ID, FROM_ACTOR, "Cake stolen");
        Assert.ok(true, "ReportAccident executed as expected");
    }

    function testHandOffLog() public {
        shipper.handOffLog(BATCH_ID, FROM_ACTOR, TO_ACTOR, LONGITUDE, LATITUDE, SNAP_HASH);
        Assert.ok(true, "HandOffLog executed as expected");
    }

    function testDeliveredToWarehouse() public {
        shipper.deliveredToWarehouse(BATCH_ID, WAREHOUSE);

        ICakeLifecycle.CakeRecord memory rec = cycle.getRecord(BATCH_ID);

        Assert.equal(uint8(rec.status), uint8(ICakeLifecycle.Status.ArrivedWarehouse), "Status mismatch");
        Assert.equal(rec.warehouse, WAREHOUSE, "Warehouse address mismatch");
    }
}
