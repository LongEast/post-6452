// SPDX‑License‑Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract SensorOracle is AccessControl {
    using ECDSA for bytes32;

    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    address public trustedSensor;

    struct SignedProof {
        bytes32 dataHash;   // Hash of the off chain sensor data. Can be used to verify the data isnt tampered
        address signer;     // The Ethereum address that signed the dataHash
        uint256 timestamp;  // The original time the sensor collected the data
    }

    // Organize sensor data by delivery batch
    mapping(uint256 => SignedProof[]) public proofs;

    // Enables off chain filtering and checking
    event SensorReportSubmitted(
        uint256 indexed batchId,
        bytes32 indexed dataHash,
        address indexed signer,
        uint256 timestamp
    );

    constructor(address admin, address sensorSigner) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        trustedSensor = sensorSigner;
    }

    function submitSignedProof(
        uint256 batchId,
        bytes32 dataHash,
        uint256 timestamp,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        // manually prepend the Ethereum signed‑message header:
        bytes32 ethSignedHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                dataHash
            )
        );

        // recover the signer
        address signer = ECDSA.recover(ethSignedHash, v, r, s);
        require(signer == trustedSensor, "Invalid signature");
        
        // Only store the info when the signer is trusted
        proofs[batchId].push(SignedProof({
            dataHash: dataHash,
            signer: signer,
            timestamp: timestamp
        }));

        // Emit the event so the system can see the report is created
        emit SensorReportSubmitted(batchId, dataHash, signer, timestamp);
    }

    /// @notice how many proofs we have for a given batch
    function getProofCount(uint256 batchId) external view returns (uint256) {
        return proofs[batchId].length;
    }

    /// @notice get the latest proof
    function getLastProof(uint256 batchId) external view returns (SignedProof memory) {
        uint256 len = proofs[batchId].length;
        require(len > 0, "No proofs");
        return proofs[batchId][len - 1];
    }

    /// @notice get all the proofs
    function getAllProofs(uint256 batchId) external view returns (SignedProof[] memory) {
        return proofs[batchId];
    }


    // To check if the provided dataHash was really signed by the trusted sensor.
    function verifyProof(
        bytes32 dataHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external view returns (bool) {
        bytes32 ethSignedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)
        );

        address signer = ECDSA.recover(ethSignedHash, v, r, s);
        return signer == trustedSensor;
    }

}
