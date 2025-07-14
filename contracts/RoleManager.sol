// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract RoleManager is AccessControl {
    // Seven roles
    bytes32 public constant ADMIN_ROLE     = DEFAULT_ADMIN_ROLE;            // Admin
    bytes32 public constant BAKER_ROLE     = keccak256("BAKER_ROLE");       // Cake factory
    bytes32 public constant SHIPPER_ROLE   = keccak256("SHIPPER_ROLE");     // Shipper
    bytes32 public constant WAREHOUSE_ROLE = keccak256("WAREHOUSE_ROLE");   // Warehouse
    bytes32 public constant REGULATOR_ROLE = keccak256("REGULATOR_ROLE");   // Regulator/arbiter
    bytes32 public constant ORACLE_ROLE    = keccak256("ORACLE_ROLE");      // Sensor oracle
    bytes32 public constant AUDITOR_ROLE   = keccak256("AUDITOR_ROLE");     // Post‐delivery auditor

    constructor(address admin) {
        // Grant the deployer or designated admin the ADMIN_ROLE
        _grantRole(ADMIN_ROLE, admin);
    }

    /// @notice Grant a role to `who`; only callable by ADMIN_ROLE
    function grantRole(address who, bytes32 role)
        external
        onlyRole(ADMIN_ROLE)
    {
        _grantRole(role, who);
    }

    /// @notice Revoke a role from `who`; only callable by ADMIN_ROLE
    function revokeRole(address who, bytes32 role)
        external
        onlyRole(ADMIN_ROLE)
    {
        _revokeRole(role, who);
    }

    /// @notice Check if `who` has been granted `role`
    function hasRole(address who, bytes32 role)
        external
        view
        returns (bool)
    {
        return hasRole(role, who);
    }
}