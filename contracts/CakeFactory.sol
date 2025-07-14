// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract CakeFactory is AccessControl {
    bytes32 public constant BAKER_ROLE = keccak256("BAKER_ROLE");

    struct BatchInfo {
        uint256 batchId;
        string  metadataURI;
        uint256 createdAt;
    }

    mapping(uint256 => BatchInfo) public batches;

    event BatchCreated(
        uint256 indexed batchId,
        address indexed baker,
        string metadataURI,
        uint256 timestamp
    );
    event QualityChecked(
        uint256 indexed batchId,
        bytes32 snapshotHash,
        uint256 timestamp
    );
    event BatchHandoff(
        uint256 indexed batchId,
        address indexed from,
        address indexed to,
        uint256 timestamp
    );
    event BatchCancelled(
        uint256 indexed batchId,
        string reason,
        uint256 timestamp
    );

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(BAKER_ROLE, admin);
    }

    // go on chain

    function createBatch(uint256 batchId, string calldata metadataURI)
        external
        onlyRole(BAKER_ROLE)
    {
        require(batches[batchId].batchId == 0, "Already exists");
        batches[batchId] = BatchInfo(batchId, metadataURI, block.timestamp);
        emit BatchCreated(batchId, msg.sender, metadataURI, block.timestamp);
    }

    // record 
    function recordQualityCheck(uint256 batchId, bytes32 snapshotHash)
        external
        onlyRole(BAKER_ROLE)
    {
        require(batches[batchId].batchId != 0, "Batch not exist");
        emit QualityChecked(batchId, snapshotHash, block.timestamp);
    }

    // hand the specific batch to shipper
    function handoffToShipper(uint256 batchId, address shipper)
        external
        onlyRole(BAKER_ROLE)
    {
        require(batches[batchId].batchId != 0, "Batch not exist");
        emit BatchHandoff(batchId, msg.sender, shipper, block.timestamp);
    }

    // cancel the issue batch
    function cancelBatch(uint256 batchId, string calldata reason)
        external
        onlyRole(BAKER_ROLE)
    {
        require(batches[batchId].batchId != 0, "Batch not exist");
        emit BatchCancelled(batchId, reason, block.timestamp);
    }
}
