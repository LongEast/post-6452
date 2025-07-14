// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "remix_tests.sol";
import "../contracts/RoleManager.sol";

contract RoleManagerTest {
    RoleManager rm;
    address admin = address(this);
    address alice = address(0x123);


    function beforeAll() public {
        rm = new RoleManager(admin);
    }


    function testAdminRole() public {
        bytes32 ADMIN = rm.DEFAULT_ADMIN_ROLE();
        Assert.equal(
            rm.hasRoleFor(ADMIN, admin),
            true,
            "Admin should have default role"
        );
    }

    function testGrantAndRevoke() public {
        bytes32 BAKER = rm.BAKER_ROLE();
        rm.grantRoleTo(BAKER, alice);
        Assert.equal(
            rm.hasRoleFor(BAKER, alice),
            true,
            "Grant role failed"
        );

        rm.revokeRoleFrom(BAKER, alice);
        Assert.equal(
            rm.hasRoleFor(BAKER, alice),
            false,
            "Revoke role failed"
        );
    }
}