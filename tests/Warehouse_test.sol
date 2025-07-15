// SPDX-License-Identifier: GPL-3.0
        
pragma solidity >=0.4.22 <0.9.0;

// This import is automatically injected by Remix
import "remix_tests.sol"; 

// This import is required to use custom transaction context
// Although it may fail compilation in 'Solidity Compiler' plugin
// But it will work fine in 'Solidity Unit Testing' plugin
import "remix_accounts.sol";
import "../contracts/Warehouse.sol";
import "../contracts/CakeLifecycleRegistry.sol";

contract WarehouseTest {

    CakeLifecycleRegistry registry;
    Warehouse warehouse;

    uint256 constant BATCH_ID   = 1001;
    string  constant META_URI   = "ipfs://cakes/1001/meta.json";
    bytes32 constant SNAP_HASH  = keccak256("quality-snapshot");

    function beforeAll() public {
        registry  = new CakeLifecycleRegistry(address(this));
        warehouse = new Warehouse(address(this), address(registry));

        registry.grantRole(registry.BAKER_ROLE(),     address(this)); 
        registry.grantRole(registry.SHIPPER_ROLE(),   address(this)); 
        registry.grantRole(registry.WAREHOUSE_ROLE(), address(warehouse)); 

        registry.createRecord(BATCH_ID, META_URI);
        registry.updateToShipper(BATCH_ID, address(0xB0B));
        registry.updateToWarehouse(BATCH_ID, address(warehouse));
    }



    function checkConfirmDelivered() public {
        warehouse.confirmDelivered(BATCH_ID);

        (
            uint256 id,
            ,
            ,
            address warehouseAddr,
            ,
            uint8 status,

        ) = registry.getRecord(BATCH_ID);

        Assert.equal(id, BATCH_ID, "batch id mismatch");
        Assert.equal(warehouseAddr, address(warehouse), "warehouse address mismatch");
        Assert.equal(status, 3, "status should be ConfirmedDelivered (3)");
    }

    function checkQualityCheck() public {
        warehouse.checkQuality(BATCH_ID, SNAP_HASH);
        Assert.ok(true, "checkQuality executed");
    }
}
    