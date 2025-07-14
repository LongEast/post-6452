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

    function testAdminRoleExists() public {
        bytes32 ADMIN = rm.ADMIN_ROLE();
        Assert.equal(
            rm.hasRole(admin, ADMIN),
            true,
            "Admin should have ADMIN_ROLE"
        );
    }

    function testGrantAndRevoke() public {
        bytes32 BAKER = rm.BAKER_ROLE();
        rm.grantRole(alice, BAKER);
        Assert.equal(
            rm.hasRole(alice, BAKER),
            true,
            "Alice should have BAKER_ROLE"
        );

        rm.revokeRole(alice, BAKER);
        Assert.equal(
            rm.hasRole(alice, BAKER),
            false,
            "Alice's BAKER_ROLE should be revoked"
        );
    }
}