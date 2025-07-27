// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./RoleManager.sol";
import "./ICakeLifecycle.sol";

contract Auditor is AccessControl {
    bytes32 public constant AUDITOR_ROLE = keccak256("AUDITOR_ROLE");

    enum Verdict { PASS, FAIL, UNCLEAR }

    struct CakeRecord {
        uint256   batchId;
        address   baker;
        address   shipper;
        address   warehouse;
        uint256   createdAt;
        uint8     status;          // use numeric status from lifecycle
        uint256   maxTemperature;
        uint256   minTemperature;
        uint256   maxHumidity;
        uint256   minHumidity;
        bool      isFlaged;
        string    metadataURI;
    }

    struct AuditRecord {
        address auditor;
        uint256 auditedAt;
        bytes32 reportHash;
        string  comments;
        Verdict verdict;
    }

    RoleManager    public roleManager;
    ICakeLifecycle public lifecycle;

    mapping(uint256 => AuditRecord) public audits;  // batchId → record

    event AuditCertified(
        uint256 indexed batchId,
        address indexed auditor,
        uint256 timestamp,
        bytes32 reportHash,
        string comments,
        Verdict verdict
    );

    /* ------------------------------------------------------------------ */

    constructor(
        address admin,
        address roleManagerAddr,
        address lifecycleAddr
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(AUDITOR_ROLE,        admin);

        roleManager = RoleManager(roleManagerAddr);
        lifecycle   = ICakeLifecycle(lifecycleAddr);
    }

    modifier onlyAuditor() {
        require(
            roleManager.checkRole(msg.sender, AUDITOR_ROLE),
            "Caller is not an auditor"
        );
        _;
    }

    /* --------------------------- view helpers -------------------------- */

    /// Convert the tuple returned by lifecycle into a struct that’s easier to use
    function _tupleToStruct(
        uint256 id,
        address baker,
        address shipper,
        address warehouse,
        uint256 createdAt,
        uint8   status,
        uint256 maxT,
        uint256 minT,
        uint256 maxH,
        uint256 minH,
        bool    isFlaged,
        string memory uri
    ) internal pure returns (CakeRecord memory rec) {
        rec = CakeRecord({
            batchId:         id,
            baker:           baker,
            shipper:         shipper,
            warehouse:       warehouse,
            createdAt:       createdAt,
            status:          status,
            maxTemperature:  maxT,
            minTemperature:  minT,
            maxHumidity:     maxH,
            minHumidity:     minH,
            isFlaged:        isFlaged,
            metadataURI:     uri
        });
    }

    /// @notice fetch the full record as a struct
    function viewBatchRecord(uint256 batchId)
        external
        view
        onlyAuditor
        returns (CakeRecord memory)
    {
        return _tupleToStruct(lifecycle.getRecord(batchId));
    }

    /// @notice view status-log strings
    function viewStatusLog(uint256 batchId)
        external
        view
        onlyAuditor
        returns (string[] memory)
    {
        return lifecycle.getLog(batchId);
    }

    /* --------------------------- main action -------------------------- */

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

        // push “audited” status into lifecycle
        lifecycle.auditRecord(batchId, comments);

        audits[batchId] = AuditRecord({
            auditor:    msg.sender,
            auditedAt:  block.timestamp,
            reportHash: reportHash,
            comments:   comments,
            verdict:    verdict
        });

        emit AuditCertified(
            batchId,
            msg.sender,
            block.timestamp,
            reportHash,
            comments,
            verdict
        );
    }

    /* -------------------------- public getter ------------------------- */

    function getAuditRecord(uint256 batchId)
        external
        view
        returns (AuditRecord memory)
    {
        return audits[batchId];
    }
}
