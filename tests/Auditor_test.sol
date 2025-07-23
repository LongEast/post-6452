// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "remix_tests.sol";
import "../contracts/Auditor.sol";
import "../contracts/RoleManager.sol";
import "../contracts/CakeLifecycleRegistry.sol";

contract AuditorTest {

    RoleManager roleManager;
    CakeLifecycleRegistry lifecycle;
    Auditor auditor;

    address admin;
    address auditorAddr;
    uint256 testBatchId = 101;

    // === Setup before tests ===
    function beforeAll() public {
        admin = address(this); // test runner = admin
        auditorAddr = address(this);

        // Deploy contracts
        roleManager = new RoleManager(admin);
        lifecycle = new CakeLifecycleRegistry(admin);
        auditor = new Auditor(admin, address(roleManager), address(lifecycle));

        // Grant auditor role
        roleManager.grantRole(auditorAddr, auditor.AUDITOR_ROLE());

        // Register a fake cake batch for audit
        lifecycle.createRecord(
            testBatchId,
            30, 5,    // maxTemp, minTemp
            90, 20,   // maxHumid, minHumid
            "ipfs://batch/meta101"
        );

        // Simulate full delivery flow
        lifecycle.updateToShipper(testBatchId, address(0xBEEF));
        lifecycle.updateToWarehouse(testBatchId, address(0xCAFE));
        lifecycle.confirmDelivered(testBatchId); // Now it's auditable
    }

    // === Test audit certification ===
    function testCertifyAudit() public {
        bytes32 fakeHash = keccak256(abi.encodePacked("ipfs://audit/101"));
        string memory comment = "Temp spiked at 33C, outside range";
        Auditor.Verdict verdict = Auditor.Verdict.FAIL;

        auditor.certifyAudit(testBatchId, fakeHash, comment, verdict);

        // Fetch audit record
        Auditor.AuditRecord memory rec = auditor.getAuditRecord(testBatchId);
        Assert.equal(rec.auditor, auditorAddr, "Auditor address mismatch");
        Assert.equal(rec.reportHash, fakeHash, "Report hash mismatch");
        Assert.equal(rec.comments, comment, "Comment mismatch");
        Assert.equal(uint(rec.verdict), uint(verdict), "Verdict mismatch");
        Assert.ok(rec.auditedAt > 0, "Audit timestamp should be set");
    }

    // === Prevent double audit ===
    function testPreventDoubleAudit() public {
        try auditor.certifyAudit(testBatchId, keccak256("new"), "Should fail", Auditor.Verdict.PASS) {
            Assert.ok(false, "Expected to revert due to double audit");
        } catch Error(string memory reason) {
            Assert.equal(reason, "Already audited", "Wrong revert reason");
        }
    }

    // === View CakeRecord via viewBatchRecord ===
    function testViewCakeRecord() public {
        ICakeLifecycle.CakeRecord memory rec = auditor.viewBatchRecord(testBatchId);

        Assert.equal(rec.batchId, testBatchId, "Batch ID mismatch");
        Assert.equal(rec.baker, admin, "Baker should be admin");
        Assert.equal(uint8(rec.status), uint8(ICakeLifecycle.Status.Audited), "Should be audited");
        Assert.equal(rec.metadataURI, "ipfs://batch/meta101", "Metadata URI mismatch");
    }

    // === View status log ===
    function testStatusLogHasAudit() public {
        string[] memory logs = auditor.viewStatusLog(testBatchId);

        Assert.ok(logs.length > 0, "Log must exist");
        Assert.equal(logs[logs.length - 1], "Audited: Temp spiked at 33C, outside range", "Audit log mismatch");
    }
}