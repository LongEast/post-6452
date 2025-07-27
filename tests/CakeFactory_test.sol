// SPDX-License-Identifier: GPL-3.0
        
pragma solidity >=0.4.22 <0.9.0;

// This import is automatically injected by Remix
import "remix_tests.sol"; 

// This import is required to use custom transaction context
// Although it may fail compilation in 'Solidity Compiler' plugin
// But it will work fine in 'Solidity Unit Testing' plugin
import "remix_accounts.sol";
import "../contracts/CakeFactory.sol";
import "../contracts/CakeLifecycleRegistry.sol";

contract CakeFactoryTest {
    CakeLifecycleRegistry registry;
    CakeFactory factory;

    uint256 constant BATCH_ID   = 1001;
    string  constant META_URI   = "ipfs://cakes/1001/meta.json";
    address constant SHIPPER    = address(0xB0B);
    bytes32 constant SNAP_HASH  = keccak256("quality-snapshot");

    function beforeAll() public {
        registry = new CakeLifecycleRegistry(address(this));
        factory  = new CakeFactory(address(this), address(registry));
        registry.grantRole(registry.BAKER_ROLE(), address(factory));
    }

    function checkCreateBatch() public {
        factory.createBatch(BATCH_ID, 28, 5, 75, 30, META_URI);

        ICakeLifecycle.CakeRecord memory rec = registry.getRecord(BATCH_ID);

        Assert.equal(rec.batchId, BATCH_ID, "record.id mismatch");
        Assert.equal(rec.baker, address(factory), "baker should be factory");
        Assert.equal(uint8(rec.status), uint8(ICakeLifecycle.Status.Created), "status should be Created (0)");
        Assert.equal(rec.metadataURI, META_URI, "Metadata URI mismatch");
    }

    function checkHandoffToShipper() public {
        factory.handoffToShipper(BATCH_ID, SHIPPER);

        ICakeLifecycle.CakeRecord memory rec = registry.getRecord(BATCH_ID);

        Assert.equal(rec.shipper, SHIPPER, "shipper address mismatch");
        Assert.equal(uint8(rec.status), uint8(ICakeLifecycle.Status.HandedToShipper), "status should be HandedToShipper (1)");
    }

    function checkQualityCheck() public {
        factory.recordQualityCheck(BATCH_ID, SNAP_HASH);
        Assert.ok(true, "recordQualityCheck executed");
    }
    
    function checkCancelBatch() public {
        factory.cancelBatch(BATCH_ID, "test-cancel");
        Assert.ok(true, "cancelBatch executed");
    }
}