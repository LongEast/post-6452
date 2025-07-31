# API Documentation

Base URL: `http://localhost:3000`

## Overview

This API provides RESTful endpoints to interact with the Cake Supply Chain smart contracts. The system tracks cakes from production through delivery with blockchain-based immutable records.

## Contract Roles

- **BAKER_ROLE**: Cake factory operations
- **SHIPPER_ROLE**: Transportation management  
- **WAREHOUSE_ROLE**: Warehouse operations
- **ORACLE_ROLE**: Sensor data submission
- **AUDITOR_ROLE**: Final audit certification

## API Endpoints

### Health Check

#### GET /
Returns API status and timestamp.

**Response:**
```json
{
  "message": "Cake Supply Chain API",
  "status": "running", 
  "timestamp": "2025-07-29T02:45:00.000Z"
}
```

---

## Cake Factory Endpoints

### Create Batch
#### POST /api/factory/batch

Create a new cake batch with environmental constraints.

**Request Body:**
```json
{
  "batchId": 1001,
  "maxTemperature": 20,
  "minTemperature": -7,
  "maxHumidity": 50,
  "minHumidity": 20,
  "metadataURI": "ipfs://QmHash..."
}
```

**Response:**
```json
{
  "success": true,
  "batchId": 1001,
  "transaction": {
    "hash": "0x...",
    "blockNumber": 123,
    "gasUsed": 250000
  },
  "error": null
}
```

### Record Quality Check
#### POST /api/factory/quality-check

Record a quality check snapshot for a batch.

**Request Body:**
```json
{
  "batchId": 1001,
  "snapshotHash": "0x1234..."
}
```

### Handoff to Shipper
#### POST /api/factory/handoff

Transfer batch custody to a shipper.

**Request Body:**
```json
{
  "batchId": 1001,
  "shipperAddress": "0xShipperAddress..."
}
```

---

## Lifecycle Registry Endpoints

### Get Batch Record
#### GET /api/lifecycle/batch/:batchId

Retrieve complete batch information.

**Response:**
```json
{
  "success": true,
  "batchId": "1001",
  "record": {
    "batchId": "1001",
    "baker": "0x...",
    "shipper": "0x...",
    "warehouse": "0x...",
    "createdAt": "1690606800",
    "status": "1",
    "maxTemperature": "20",
    "minTemperature": "-7",
    "maxHumidity": "50",
    "minHumidity": "20",
    "isFlagged": false,
    "metadataURI": "ipfs://QmHash..."
  }
}
```

**Status Values:**
- 0: Created
- 1: HandedToShipper  
- 2: ArrivedWarehouse
- 3: Delivered
- 4: Spoiled
- 5: Audited

### Get Batch Log
#### GET /api/lifecycle/batch/:batchId/log

Retrieve status change history.

**Response:**
```json
{
  "success": true,
  "batchId": "1001",
  "log": [
    "Created by BAKER",
    "Handoff to SHIPPER",
    "Arrived at WAREHOUSE",
    "DELIVERED"
  ]
}
```

---

## Shipper Endpoints

### Record Handoff
#### POST /api/shipper/handoff

Log handoff between transportation actors.

**Request Body:**
```json
{
  "batchId": 1001,
  "fromActor": "0x...",
  "toActor": "0x...",
  "longitude": -74005973,
  "latitude": 40712776,
  "snapshotHash": "0x..."
}
```

### Report Accident
#### POST /api/shipper/accident

Report transportation incidents.

**Request Body:**
```json
{
  "batchId": 1001,
  "actor": "0x...",
  "accident": "Minor temperature spike during loading"
}
```

### Deliver to Warehouse
#### POST /api/shipper/deliver

Mark delivery to destination warehouse.

**Request Body:**
```json
{
  "batchId": 1001,
  "warehouseAddress": "0x..."
}
```

---

## Warehouse Endpoints

### Confirm Delivery
#### POST /api/warehouse/confirm-delivery

Confirm batch arrival and update status to Delivered.

**Request Body:**
```json
{
  "batchId": 1001
}
```

### Quality Check
#### POST /api/warehouse/quality-check

Perform warehouse quality inspection.

**Request Body:**
```json
{
  "batchId": 1001,
  "snapshotHash": "0x..."
}
```

**Note:** Quality checks are:
- **Mandatory** for flagged batches
- **30% random** for unflagged batches

---

## Sensor Oracle Endpoints

### Submit Sensor Data
#### POST /api/oracle/sensor-data

Submit temperature and humidity readings.

**Request Body:**
```json
{
  "batchId": 1001,
  "temperature": 18,
  "humidity": 45
}
```

**Threshold Violations:**
- Temperature: -7°C to 20°C
- Humidity: 20% to 50%

**Alert System:**
- 3 consecutive violations (5-minute intervals) → Batch flagged

### Get Sensor Readings
#### GET /api/oracle/batch/:batchId/readings

Retrieve sensor data summary.

**Response:**
```json
{
  "success": true,
  "batchId": "1001",
  "readingCount": 24,
  "lastReading": {
    "timestamp": "1690606800",
    "temperature": "18",
    "humidity": "45"
  }
}
```

### Get Alerts
#### GET /api/oracle/batch/:batchId/alerts

Retrieve environmental alert history for a batch.

**Response:**
```json
{
  "success": true,
  "batchId": "1001",
  "alerts": [
    {
      "timestamp": "1690606800",
      "reason": "Temperature threshold exceeded",
      "severity": "high"
    }
  ]
}
```

**Note:** Currently returns placeholder response. Full implementation requires blockchain event indexing.

---

## Auditor Endpoints

### Certify Audit
#### POST /api/auditor/certify

Submit final audit certification.

**Request Body:**
```json
{
  "batchId": 1001,
  "reportHash": "0x...",
  "comments": "Batch meets all quality standards",
  "verdict": 0
}
```

**Verdict Values:**
- 0: PASS
- 1: FAIL  
- 2: UNCLEAR

### Get Audit Record
#### GET /api/auditor/batch/:batchId

Retrieve audit certification details.

**Response:**
```json
{
  "success": true,
  "batchId": "1001", 
  "audit": {
    "auditor": "0x...",
    "auditedAt": "1690606800",
    "reportHash": "0x...",
    "comments": "Batch meets all quality standards",
    "verdict": "0"
  }
}
```

### Get Comprehensive Audit Data
#### GET /api/auditor/batch/:batchId/comprehensive

Retrieve complete batch information for auditing purposes, including all lifecycle data, sensor readings, and compliance analysis.

**Response:**
```json
{
  "success": true,
  "batchId": "1001",
  "auditTimestamp": "2025-07-29T03:15:00.000Z",
  "batchRecord": {
    "batchId": "1001",
    "baker": "0x...",
    "shipper": "0x...",
    "warehouse": "0x...",
    "createdAt": "1690606800",
    "status": "3",
    "maxTemperature": "20",
    "minTemperature": "-7",
    "maxHumidity": "50",
    "minHumidity": "20",
    "isFlagged": false,
    "metadataURI": "ipfs://QmHash..."
  },
  "statusHistory": [
    "Created by BAKER",
    "Handoff to SHIPPER",
    "Arrived at WAREHOUSE",
    "DELIVERED"
  ],
  "sensorData": {
    "readingCount": 24,
    "lastReading": {
      "timestamp": "1690606800",
      "temperature": "18",
      "humidity": "45"
    }
  },
  "auditRecord": {
    "auditor": "0x...",
    "auditedAt": "1690606800",
    "reportHash": "0x...",
    "comments": "Previous audit comments",
    "verdict": "0"
  },
  "complianceAnalysis": {
    "temperatureCompliance": true,
    "humidityCompliance": true,
    "isFlagged": false,
    "statusCompleted": true
  }
}
```

**Purpose:** This endpoint provides auditors with a comprehensive view of the batch for thorough verification, including compliance analysis and historical data.

---

## Admin Endpoints

### Set Contract Addresses
#### POST /api/admin/contracts

Update contract addresses for the API.

**Request Body:**
```json
{
  "CakeFactory": "0x...",
  "CakeLifecycleRegistry": "0x...",
  "Shipper": "0x...",
  "Warehouse": "0x...",
  "SensorOracle": "0x...",
  "Auditor": "0x...",
  "RoleManager": "0x..."
}
```

### Get Contract Addresses
#### GET /api/admin/contracts

Retrieve current contract addresses.

### Clear All Data (ADMIN ONLY)
#### POST /api/admin/clear-data

**WARNING: This permanently deletes ALL database records!**

Reset the database to a brand new state by clearing all tables.

**Request Body:**
```json
{
  "confirm": "YES_CLEAR_ALL_DATA"
}
```

**Response (Success):**
```json
{
  "success": true,
  "message": "All database data cleared successfully",
  "timestamp": "2025-07-29T14:30:00.000Z",
  "warning": "Database has been reset to brand new state"
}
```

**Response (Missing Confirmation):**
```json
{
  "error": "Missing or incorrect confirmation",
  "message": "To clear all data, send: { \"confirm\": \"YES_CLEAR_ALL_DATA\" }",
  "warning": "This action will permanently delete ALL database records"
}
```

**Safety Features:**
- Requires explicit confirmation string: `"YES_CLEAR_ALL_DATA"`
- Only affects database tables, not blockchain state
- Logs clear operations with timestamps
- Cannot be undone

**What Gets Cleared:**
- All cake batch records
- All audit records  
- All sensor alerts
- All handoff records
- All quality check records
- All shipping accident records
- All status logs

---

## Error Responses

All endpoints return errors in this format:

```json
{
  "error": "Error description",
  "message": "Detailed error message"
}
```

**Common HTTP Status Codes:**
- 200: Success
- 400: Bad Request (missing parameters)
- 404: Not Found (batch/resource not found)
- 500: Internal Server Error

---

## Getting Started

1. **Deploy Contracts**: Use `npm run deploy` to deploy all contracts
2. **Update Addresses**: Set contract addresses via `POST /api/admin/contracts`
3. **Start API**: Run `npm run server` to start the API server
4. **Test Endpoints**: Use the provided endpoints to interact with your contracts

## Example Workflow

1. Create batch: `POST /api/factory/batch`
2. Handoff to shipper: `POST /api/factory/handoff`  
3. Submit sensor data: `POST /api/oracle/sensor-data`
4. Deliver to warehouse: `POST /api/shipper/deliver`
5. Confirm delivery: `POST /api/warehouse/confirm-delivery`
6. Review comprehensive audit data: `GET /api/auditor/batch/:batchId/comprehensive`
7. Perform audit certification: `POST /api/auditor/certify`
8. Check final audit result: `GET /api/auditor/batch/:batchId`
9. Check final status: `GET /api/lifecycle/batch/:batchId`

**Enhanced Audit Process:**
- Use the comprehensive endpoint to gather all necessary data for auditing
- Review batch lifecycle, sensor readings, and compliance status
- Submit certification with verdict (PASS/FAIL/UNCLEAR)
- Verify audit record was properly stored

## Development & Testing

**For Development/Testing Purposes:**
- Use `POST /api/admin/clear-data` to reset database to clean state
- Useful for testing different scenarios without residual data
- **CAUTION**: Only use in development environment - permanently deletes all data

**Testing Script:**
```bash
# Reset database to brand new state
./scripts/test-clear-data.sh
```
