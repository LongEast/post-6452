// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract RoleManager is AccessControl {
    bytes32 public constant ADMIN_ROLE     = DEFAULT_ADMIN_ROLE;
    bytes32 public constant BAKER_ROLE     = keccak256("BAKER_ROLE");
    bytes32 public constant SHIPPER_ROLE   = keccak256("SHIPPER_ROLE");
    bytes32 public constant WAREHOUSE_ROLE = keccak256("WAREHOUSE_ROLE");
    bytes32 public constant RETAILER_ROLE  = keccak256("RETAILER_ROLE");
    bytes32 public constant REGULATOR_ROLE = keccak256("REGULATOR_ROLE");
    bytes32 public constant ORACLE_ROLE    = keccak256("ORACLE_ROLE");

    constructor(address admin) {
        _grantRole(ADMIN_ROLE, admin);
    }

    function grantRole(address who, bytes32 role)
        external
        onlyRole(ADMIN_ROLE)
    {
        _grantRole(role, who);
    }

    function revokeRole(address who, bytes32 role)
        external
        onlyRole(ADMIN_ROLE)
    {
        _revokeRole(role, who);
    }

    function hasRole(address who, bytes32 role)
        external
        view
        returns (bool)
    {
        return hasRole(role, who);
    }
}