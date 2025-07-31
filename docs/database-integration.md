# Database Integration Guide

## Overview

Your blockchain cake supply chain project now has SQLite database integration for storing and querying business data. The database works in parallel with the blockchain to provide fast queries and data analysis capabilities.

## Database Schema

The database contains the following main tables:

### 1. `cake_batches` - Cake Batches
- `batch_id` - Batch ID (primary key)
- `created_at` - Creation timestamp
- `baker_address` - Baker's address
- `metadata_uri` - Metadata URI
- `min_temp/max_temp` - Temperature range
- `min_humidity/max_humidity` - Humidity range
- `is_flagged` - Whether flagged for issues
- `status` - Current status

### 2. `audit_records` - Audit Records
- `batch_id` - Related batch ID
- `auditor` - Auditor address
- `audited_at` - Audit timestamp
- `report_hash` - Report hash
- `comments` - Comments
- `verdict` - Audit verdict

### 3. `oracle_alerts` - Sensor Alerts
- `batch_id` - Related batch ID
- `alert_type` - Alert type
- `message` - Alert message
- `created_at` - Creation timestamp

## Setup Steps

### 1. Install Dependencies
```bash
./scripts/setup-database.sh
```

### 2. Start Server
```bash
npm run server
```

The database will automatically initialize and create all necessary tables.

## API Endpoints

### Database Query Endpoints

#### Get All Batches
```bash
GET /api/database/batches
```

#### Get Specific Batch
```bash
GET /api/database/batch/:batchId
```

#### Get Audit Records
```bash
GET /api/database/batch/:batchId/audit
```

#### Clear All Data (ADMIN ONLY)
```bash
POST /api/admin/clear-data
Content-Type: application/json

{
  "confirm": "YES_CLEAR_ALL_DATA"
}
```

**WARNING:** This permanently deletes ALL database records and resets to brand new state!

#### Update Batch Status
```bash
PATCH /api/database/batch/:batchId/status
Content-Type: application/json

{
  "status": "HandedToShipper"
}
```

Valid status values:
- `Created`
- `HandedToShipper`
- `ArrivedWarehouse`
- `Delivered`
- `Spoiled`
- `Audited`

## Data Synchronization

### Blockchain to Database Sync

1. **Batch Creation**: When creating batches via `POST /api/factory/batch`, successful blockchain transactions automatically sync to database
2. **Sensor Data**: When sensor data exceeds safe ranges, alerts are automatically recorded to database
3. **Status Updates**: Batch status can be manually updated via API in the database

### Advantages

- **Fast Queries**: Database queries are much faster than blockchain queries
- **Data Analysis**: Supports complex SQL queries and data analysis
- **Alert Monitoring**: Automatically records sensor anomalies and business events
- **Audit Trail**: Complete operation history tracking

## Usage Examples

### Create Batch and Query
```bash
# 1. Create batch (syncs to blockchain and database)
curl -X POST http://localhost:3000/api/factory/batch \
  -H "Content-Type: application/json" \
  -d '{
    "batchId": 1001,
    "maxTemperature": 20,
    "minTemperature": -5,
    "maxHumidity": 60,
    "minHumidity": 30,
    "metadataURI": "ipfs://example"
  }'

# 2. Query batch from database
curl http://localhost:3000/api/database/batch/1001

# 3. Submit sensor data (may trigger alerts)
curl -X POST http://localhost:3000/api/oracle/sensor-data \
  -H "Content-Type: application/json" \
  -d '{
    "batchId": 1001,
    "temperature": 25,
    "humidity": 45
  }'

# 4. Update batch status
curl -X PATCH http://localhost:3000/api/database/batch/1001/status \
  -H "Content-Type: application/json" \
  -d '{"status": "HandedToShipper"}'
```

## Database File Locations

- Database file: `backend/data/blockchain_cake.db`
- Schema files: `backend/database/schemes/*.sql`

## Important Notes

1. **Data Consistency**: Database serves as blockchain complement, not authoritative source
2. **Backup**: Regular backup of database file recommended
3. **Performance**: SQLite suitable for development and small-medium applications, consider PostgreSQL for production
4. **Error Handling**: Database operation failures do not affect blockchain operations

## Extension Suggestions

### Upgrade to PostgreSQL (Production)

```typescript
// Replace connection config in database.ts
import { Client } from 'pg';

const client = new Client({
  host: 'localhost',
  database: 'blockchain_cake',
  user: 'your_user',
  password: 'your_password',
  port: 5432,
});
```

### Additional Analytics Features

- Batch success rate statistics
- Sensor data trend analysis
- Supply chain timing analysis
- Anomaly detection and alerts
