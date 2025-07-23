// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./RoleManager.sol";
import "./ICakeLifecycle.sol";

contract Auditor is AccessControl {
    bytes32 public constant AUDITOR_ROLE = keccak256("AUDITOR_ROLE");

    enum Verdict { PASS, FAIL, UNCLEAR }

    RoleManager public roleManager;
    ICakeLifecycle public lifecycle;

    event AuditCertified(
        uint256 indexed batchId,
        address indexed auditor,
        uint256 timestamp,
        bytes32 reportHash,
        string comments,
        Verdict verdict
    );

    /// @param reportHash should be keccak256(IPFS CIDv0/1) or SHA256 of full file
    struct AuditRecord {
        address auditor;
        uint256 auditedAt;
        bytes32 reportHash;  // Off-chain audit report hash for evidence
        string comments;     // Short summary of audit findings
        Verdict verdict;    // PASS, FAIL, or UNCLEAR
    }

    mapping(uint256 => AuditRecord) public audits;  // batchId => AuditRecord

    constructor(address admin, address roleManagerAddr, address lifecycleAddr) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(AUDITOR_ROLE, admin);

        roleManager = RoleManager(roleManagerAddr);
        lifecycle = ICakeLifecycle(lifecycleAddr);
    }

    modifier onlyAuditor() {
        require(
            roleManager.hasRole(msg.sender, AUDITOR_ROLE),
            "Caller is not an auditor"
        );
        _;
    }

    /// @notice View the CakeLifecycle full record
    function viewBatchRecord(uint256 batchId)
        external
        view
        onlyAuditor
        returns (ICakeLifecycle.CakeRecord memory)
    {
        return lifecycle.getRecord(batchId);
    }

    /// @notice View the status log of a batch
    function viewStatusLog(uint256 batchId)
        external
        view
        onlyAuditor
        returns (string[] memory)
    {
        return lifecycle.getLog(batchId);
    }

    /// @notice Certify the audit outcome with an off-chain report hash
    function certifyAudit(
        uint256 batchId,
        bytes32 reportHash,
        string calldata comments,
        Verdict verdict
    )
        external
        onlyAuditor
    {
        require(audits[batchId].auditor == address(0), "Already audited");
        lifecycle.auditRecord(batchId, comments); // Call to lifecycle to update status
        audits[batchId] = AuditRecord({
            auditor: msg.sender,
            auditedAt: block.timestamp,
            reportHash: reportHash,
            comments: comments,
            verdict: verdict
        });

        emit AuditCertified(batchId, msg.sender, block.timestamp, reportHash, comments, verdict);
    }

    /// @notice Retrieve the audit record of a batch
    function getAuditRecord(uint256 batchId)
        external
        view
        returns (AuditRecord memory)
    {
        return audits[batchId];
    }
}