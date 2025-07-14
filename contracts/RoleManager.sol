// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract RoleManager is AccessControl {
    bytes32 public constant BAKER_ROLE     = keccak256("BAKER_ROLE");
    bytes32 public constant SHIPPER_ROLE   = keccak256("SHIPPER_ROLE");
    bytes32 public constant WAREHOUSE_ROLE = keccak256("WAREHOUSE_ROLE");
    bytes32 public constant RETAILER_ROLE  = keccak256("RETAILER_ROLE");
    bytes32 public constant REGULATOR_ROLE = keccak256("REGULATOR_ROLE");
    bytes32 public constant ORACLE_ROLE    = keccak256("ORACLE_ROLE");

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function grantRoleTo(bytes32 role, address account) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        _grantRole(role, account);
    }

    function revokeRoleFrom(bytes32 role, address account) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        _revokeRole(role, account);
    }

    function hasRoleFor(bytes32 role, address account) 
        external 
        view 
        returns (bool) 
    {
        return hasRole(role, account);
    }
}