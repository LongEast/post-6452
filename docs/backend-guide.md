# Backend Operation Guide

## Project Overview

This project implements a blockchain-based cake supply chain tracking system backend API. The system manages the complete lifecycle of cake production, transportation, storage, and auditing through smart contracts.

## System Architecture

### Smart Contract Architecture
- **CakeLifecycleRegistry**: Core registry recording complete cake batch lifecycle
- **CakeFactory**: Manages cake production and quality checks
- **Shipper**: Handles transportation process handoffs and accident reporting
- **Warehouse**: Manages storage confirmations and quality checks
- **SensorOracle**: Collects and validates sensor data
- **Auditor**: Provides independent audit certification
- **RoleManager**: Manages system participant permissions

### Backend API Architecture
- **Express.js**: Web framework
- **Web3.js**: Blockchain interaction
- **TypeScript**: Type-safe development language
- **RESTful API**: Standardized interface design

## Environment Setup

### Prerequisites
1. Node.js (v16 or higher)
2. npm or yarn package manager
3. Ganache (installed via npm: `npm install -g ganache`)
4. curl or Postman (API testing)
5. jq (JSON processing tool for scripts)

### Install Dependencies
```bash
cd <project-directory>
npm install
npm install @openzeppelin/contracts
```

### Compile Smart Contracts
```bash
npm run compile
```

## Deployment Process

### Step 1: Start Ganache
Start local blockchain network:
```bash
npx ganache --host 127.0.0.1 --port 8546 --deterministic --accounts 10 --account_keys_path keys.json
```

This will generate deterministic accounts with the following addresses:
- Account #0: `0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1` (Admin)
- Account #1: `0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0` (Sensor)
- Account #2: `0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65` 
- And so on...

Or use Ganache GUI with configuration:
- Port: 8546
- Network ID: 1337
- Account count: 10
- Deterministic: true

### Initial Setup for New Users

**First-time setup (required for new users):**
```bash
# Copy the example accounts configuration
cp eth_accounts/accounts.example.json eth_accounts/accounts.json
```

The `accounts.example.json` file contains standard Ganache deterministic accounts that work with the default setup. This file is tracked in git, while `accounts.json` is ignored for security.

**What's in the accounts files:**
- `accounts.example.json` → Template with standard Ganache accounts (tracked in git)
- `accounts.json` → Your local configuration (ignored by git, created from template)

**Account Configuration:**
The project uses account identifiers defined in `eth_accounts/accounts.json`:
- `acc0` → Account #0 private key (for transaction signing)
- `acc1` → Account #1 private key (if needed)

**Why use `acc0`?**
- `acc0` is used to specify which account's private key to use for signing deployment transactions
- The actual Admin and Sensor addresses are passed as separate parameters
- This design allows flexibility: you can deploy with one account but assign admin rights to another

**Customizing Account Configuration:**
If you want to add more accounts or use different private keys, edit `eth_accounts/accounts.json`:
```json
{
  "acc0": { "pvtKey": "0x4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d" },
  "acc1": { "pvtKey": "0x6cbed15c793ce57650b9877cf6fa156fbef513c4e6134f022a85b1ffdd59b2a1" },
  "acc2": { "pvtKey": "0x6370fd033278c143179d81c5526140625662b8daa446c22ee2d73db3707e620c" }
}
```

### Step 2: Deploy Smart Contracts
Run deployment script with account configuration:

**Using Default Deterministic Accounts (Recommended):**
```bash
# Using predefined account configuration
npm run deploy deploy acc0 0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1 0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0
```

**Using Custom Accounts (Alternative):**
```bash
# If you want to use different accounts, replace the addresses accordingly
# npm run deploy deploy acc0 <ADMIN_ADDRESS> <SENSOR_ADDRESS>
```

**Parameter Explanation:**
- `deploy` - Deployment mode
- `acc0` - Account identifier from `eth_accounts/accounts.json` (used for transaction signing)
- `<ADMIN_ADDRESS>` - Administrator address for contract management
- `<SENSOR_ADDRESS>` - Sensor oracle address for environmental data

**Note:** Due to deterministic mode, the addresses shown above will always be the same when using `--deterministic` flag.

**Save deployment output** (recommended):
```bash
# Save deployment output for later reference
npm run deploy deploy acc0 0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1 0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0 | tee deployment_log.txt
```

Record contract addresses from deployment output, format:
```
Deployed RoleManager → 0xe78A0F7E598Cc8b0Bb87894B0F60dD2a88d6a8Ab
Deployed CakeLifecycleRegistry → 0x5b1869D9A4C187F2EAa108f3062412ecf0526b24
Deployed CakeFactory → 0xCfEB869F69431e42cdB54A4F4f105C19C080A601
Deployed Shipper → 0x254dffcd3277C0b1660F6d42EFbB754edaBAbC2B
Deployed Warehouse → 0xC89Ce4735882C9F0f0FE26686c53074E09B0D550
Deployed SensorOracle → 0xD833215cBcc3f914bD1C9ece3EE7BF8B14f841bb
Deployed Auditor → 0xe982E462b094850F12AF94d21D470e21bE9D0E9C
```

### Step 3: Start API Server
```bash
npm run server
```

Server will start on port 3000. Verify startup:
```bash
curl http://localhost:3000/
```

Expected output:
```json
{
  "message": "Cake Supply Chain API",
  "status": "running",
  "timestamp": "2025-07-29T03:00:00.000Z"
}
```

## Contract Address Configuration

### Method 1: Using Configuration Script (Recommended)
1. Edit `scripts/setup-contracts.sh` file
2. Replace placeholder addresses with actual deployed contract addresses:
```bash
CAKE_FACTORY="0xCfEB869F69431e42cdB54A4F4f105C19C080A601"
LIFECYCLE_REGISTRY="0x5b1869D9A4C187F2EAa108f3062412ecf0526b24"
SHIPPER="0x254dffcd3277C0b1660F6d42EFbB754edaBAbC2B"
WAREHOUSE="0xC89Ce4735882C9F0f0FE26686c53074E09B0D550"
SENSOR_ORACLE="0xD833215cBcc3f914bD1C9ece3EE7BF8B14f841bb"
AUDITOR="0xe982E462b094850F12AF94d21D470e21bE9D0E9C"
ROLE_MANAGER="0xe78A0F7E598Cc8b0Bb87894B0F60dD2a88d6a8Ab"
```
3. Run configuration script:
```bash
./scripts/setup-contracts.sh
```

### Method 2: Using Interactive Script
Run interactive configuration:
```bash
./scripts/interactive-setup.sh
```

Follow prompts to input each contract address.

### Method 3: Direct API Call
```bash
curl -X POST http://localhost:3000/api/admin/contracts \
  -H "Content-Type: application/json" \
  -d '{
    "CakeFactory": "0xCfEB869F69431e42cdB54A4F4f105C19C080A601",
    "CakeLifecycleRegistry": "0x5b1869D9A4C187F2EAa108f3062412ecf0526b24",
    "Shipper": "0x254dffcd3277C0b1660F6d42EFbB754edaBAbC2B",
    "Warehouse": "0xC89Ce4735882C9F0f0FE26686c53074E09B0D550",
    "SensorOracle": "0xD833215cBcc3f914bD1C9ece3EE7BF8B14f841bb",
    "Auditor": "0xe982E462b094850F12AF94d21D470e21bE9D0E9C",
    "RoleManager": "0xe78A0F7E598Cc8b0Bb87894B0F60dD2a88d6a8Ab"
  }'
```

**Note:** All the addresses shown above are examples from a sample deployment. Replace them with your actual deployed contract addresses.

### Verify Configuration
Check contract addresses are set successfully:
```bash
curl http://localhost:3000/api/admin/contracts
```

## API Endpoint Details

### Management Endpoints
- `GET /` - Health check
- `GET /api/admin/contracts` - Get contract address configuration
- `POST /api/admin/contracts` - Set contract addresses
- `POST /api/admin/clear-data` - Clear all database data (ADMIN ONLY)

### Cake Factory Endpoints
- `POST /api/factory/batch` - Create new cake batch
- `POST /api/factory/quality-check` - Record quality check
- `POST /api/factory/handoff` - Handoff to shipper

### Lifecycle Registry Endpoints
- `GET /api/lifecycle/batch/:batchId` - Get batch record
- `GET /api/lifecycle/batch/:batchId/log` - Get batch status log

### Shipper Endpoints
- `POST /api/shipper/handoff` - Record transportation handoff
- `POST /api/shipper/accident` - Report transportation accident
- `POST /api/shipper/deliver` - Deliver to warehouse

### Warehouse Endpoints
- `POST /api/warehouse/confirm-delivery` - Confirm delivery
- `POST /api/warehouse/quality-check` - Warehouse quality check

### Sensor Oracle Endpoints
- `POST /api/oracle/sensor-data` - Submit sensor data
- `GET /api/oracle/batch/:batchId/readings` - Get sensor readings
- `GET /api/oracle/batch/:batchId/alerts` - Get sensor alerts for batch

### Auditor Endpoints
- `POST /api/auditor/certify` - Certify audit
- `GET /api/auditor/batch/:batchId` - Get audit record
- `GET /api/auditor/batch/:batchId/comprehensive` - Get comprehensive audit data

### Database Query Endpoints
- `GET /api/database/batches` - Get all cake batches from database
- `GET /api/database/batch/:batchId` - Get specific batch from database
- `GET /api/database/batch/:batchId/audit` - Get audit data from database

### Auditor Endpoints Detail

#### 1. Get Comprehensive Audit Data
```bash
curl http://localhost:3000/api/auditor/batch/1001/comprehensive
```

This endpoint provides auditors with complete batch information including:
- Basic batch record (creator, handlers, timestamps, etc.)
- Complete status change history
- Sensor data summary and latest readings
- Existing audit records (if any)
- Automatic compliance analysis
  - Temperature within allowed range
  - Humidity within allowed range
  - Batch flagged status
  - Status completion

#### 2. Submit Audit Certification
```bash
curl -X POST http://localhost:3000/api/auditor/certify \
  -H "Content-Type: application/json" \
  -d '{
    "batchId": 1001,
    "reportHash": "0xjkl901mno234",
    "comments": "Quality standards met, all compliance requirements satisfied",
    "verdict": 0
  }'
```

#### 3. Query Audit Record
```bash
curl http://localhost:3000/api/auditor/batch/1001
```

## Complete Business Process Example

### 1. Create Cake Batch
```bash
curl -X POST http://localhost:3000/api/factory/batch \
  -H "Content-Type: application/json" \
  -d '{
    "batchId": 1001,
    "maxTemperature": 20,
    "minTemperature": -7,
    "maxHumidity": 50,
    "minHumidity": 20,
    "metadataURI": "ipfs://QmExample123"
  }'
```

### 2. Record Quality Check
```bash
curl -X POST http://localhost:3000/api/factory/quality-check \
  -H "Content-Type: application/json" \
  -d '{
    "batchId": 1001,
    "snapshotHash": "0xabc123def456"
  }'
```

### 3. Handoff to Shipper
```bash
curl -X POST http://localhost:3000/api/factory/handoff \
  -H "Content-Type: application/json" \
  -d '{
    "batchId": 1001,
    "shipperAddress": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
  }'
```

### 4. Submit Sensor Data
```bash
curl -X POST http://localhost:3000/api/oracle/sensor-data \
  -H "Content-Type: application/json" \
  -d '{
    "batchId": 1001,
    "temperature": 15,
    "humidity": 35
  }'
```

### 5. Transportation Handoff Record
```bash
curl -X POST http://localhost:3000/api/shipper/handoff \
  -H "Content-Type: application/json" \
  -d '{
    "batchId": 1001,
    "fromActor": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
    "toActor": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
    "longitude": "151.2093",
    "latitude": "-33.8688",
    "snapshotHash": "0xdef789ghi012"
  }'
```

### 6. Deliver to Warehouse
```bash
curl -X POST http://localhost:3000/api/shipper/deliver \
  -H "Content-Type: application/json" \
  -d '{
    "batchId": 1001,
    "warehouseAddress": "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC"
  }'
```

### 7. Warehouse Confirm Delivery
```bash
curl -X POST http://localhost:3000/api/warehouse/confirm-delivery \
  -H "Content-Type: application/json" \
  -d '{
    "batchId": 1001
  }'
```

### 8. Warehouse Quality Check
```bash
curl -X POST http://localhost:3000/api/warehouse/quality-check \
  -H "Content-Type: application/json" \
  -d '{
    "batchId": 1001,
    "snapshotHash": "0xghi345jkl678"
  }'
```

### 9. Audit Certification
```bash
curl -X POST http://localhost:3000/api/auditor/certify \
  -H "Content-Type: application/json" \
  -d '{
    "batchId": 1001,
    "reportHash": "0xjkl901mno234",
    "comments": "Quality standards met",
    "verdict": 0
  }'
```

### 10. Query Complete Record
```bash
curl http://localhost:3000/api/lifecycle/batch/1001
```

## Complete Audit Process Example

### Step 1: Get Comprehensive Audit Data
```bash
curl http://localhost:3000/api/auditor/batch/1001/comprehensive
```

Auditor can get:
- Complete batch lifecycle information
- All environmental monitoring data
- Automatic compliance analysis results
- Historical processing records

### Step 2: Make Audit Decision Based on Data
Auditor analyzes based on complete data:
- Check if temperature and humidity are always within allowed range
- Verify processing workflow meets standards
- Confirm no abnormal events or alerts
- Evaluate overall quality compliance

### Step 3: Submit Audit Result
```bash
curl -X POST http://localhost:3000/api/auditor/certify \
  -H "Content-Type: application/json" \
  -d '{
    "batchId": 1001,
    "reportHash": "0xAuditReportHash",
    "comments": "Audit opinion based on complete data analysis",
    "verdict": 0
  }'
```

Verdict values:
- 0: PASS - Audit passed
- 1: FAIL - Audit failed
- 2: UNCLEAR - Requires further review

## Database Management

### Clear All Data (Reset to Brand New State)

**WARNING: This will permanently delete ALL database records!**

This API endpoint completely clears all database tables and resets the system to a brand new state. Use with extreme caution.

```bash
curl -X POST http://localhost:3000/api/admin/clear-data \
  -H "Content-Type: application/json" \
  -d '{
    "confirm": "YES_CLEAR_ALL_DATA"
  }'
```

**Response:**
```json
{
  "success": true,
  "message": "All database data cleared successfully",
  "timestamp": "2025-07-29T14:30:00.000Z",
  "warning": "Database has been reset to brand new state"
}
```

**Safety Features:**
- Requires explicit confirmation string: `"YES_CLEAR_ALL_DATA"`
- Will fail without correct confirmation
- Logs the clear operation with timestamp
- Only affects database, not blockchain state

**What gets cleared:**
- All cake batch records
- All audit records
- All sensor alerts
- All handoff records
- All quality check records
- All shipping accident records
- All status logs
- Resets auto-increment counters

## Data Queries

### Get Batch Complete Information
```bash
curl http://localhost:3000/api/lifecycle/batch/1001
```

### Get Sensor Readings
```bash
curl http://localhost:3000/api/oracle/batch/1001/readings
```

### Get Audit Record
```bash
curl http://localhost:3000/api/auditor/batch/1001
```

### Get Status Log
```bash
curl http://localhost:3000/api/lifecycle/batch/1001/log
```

## Error Handling

### Common Error Codes
- `400 Bad Request`: Missing or incorrectly formatted request parameters
- `404 Not Found`: Resource does not exist (e.g., batch ID does not exist)
- `500 Internal Server Error`: Server internal error (usually contract call failure)

### Error Response Format
```json
{
  "error": "Missing required parameters",
  "message": "batchId is required"
}
```

### Success Response Format
```json
{
  "success": true,
  "batchId": 1001,
  "transaction": {
    "hash": "0x1234567890abcdef",
    "blockNumber": 123,
    "gasUsed": 45000
  }
}
```

## Testing and Verification

### Using Test Scripts
Run complete API test:
```bash
./scripts/test-api.sh
```

Run quick verification:
```bash
./scripts/quick-verify.sh
```

### Manual Test Checklist
1. Check API server status
2. Verify contract address configuration
3. Test create cake batch
4. Test data query functionality
5. Verify error handling mechanism

## Development Tools

### Recommended Development Tools
- **VS Code**: Primary development environment
- **Ganache**: Local blockchain
- **Postman**: API testing
- **jq**: JSON processing tool
- **curl**: Command line HTTP client

### Debugging Tips
1. Check Ganache logs for transaction details
2. Use `console.log` in server code for debugging information
3. Verify account balance and gas fees
4. Check if contract addresses are correctly set

## Production Environment Deployment

### Environment Variable Configuration
Set environment variables in your production environment:
```bash
export NODE_ENV=production
export PORT=3000
export WEB3_PROVIDER_URL=https://mainnet.infura.io/v3/YOUR_PROJECT_ID
export PRIVATE_KEY=your_private_key
export LIFECYCLE_REGISTRY_ADDRESS=0x...
export CAKE_FACTORY_ADDRESS=0x...
export SHIPPER_ADDRESS=0x...
export WAREHOUSE_ADDRESS=0x...
export SENSOR_ORACLE_ADDRESS=0x...
export AUDITOR_ADDRESS=0x...
export ROLE_MANAGER_ADDRESS=0x...
```

**Alternative Configuration Methods:**
1. **API Configuration**: Use `POST /api/admin/contracts` to set addresses dynamically
2. **Config File**: Update `backend/config/contracts.json` directly
3. **Setup Scripts**: Use `scripts/setup-contracts.sh` or `scripts/interactive-setup.sh`

### Security Considerations
1. Use environment variables to manage sensitive information
2. Implement authentication and authorization
3. Enable HTTPS
4. Configure rate limiting
5. Implement logging and monitoring

### Performance Optimization
1. Enable connection pooling
2. Implement caching mechanism
3. Optimize database queries
4. Configure load balancing
5. Monitor application performance

## Troubleshooting

### Common Issue Solutions

#### API Server Cannot Start
- Check if port 3000 is occupied
- Verify dependencies are correctly installed
- Check TypeScript compilation errors

#### Contract Call Failure
- Verify contract addresses are correct
- Check if account balance is sufficient to pay gas fees
- Confirm Ganache is running

#### Transaction Failure
- Check if function parameters are correct
- Verify caller has appropriate permissions
- Confirm contract state allows the operation

#### Network Connection Issues
- Verify Web3 provider URL is correct
- Check network connection status
- Confirm firewall settings

## Appendix

### Project File Structure
```
<project-directory>/
├── README.md                  # Project overview and quick start guide
├── package.json               # Node.js dependencies and scripts
├── tsconfig.json              # TypeScript configuration
├── backend/
│   ├── config/
│   │   └── contracts.json     # Contract address configuration
│   ├── data/
│   │   └── cakes.json         # Sample cake batch data
│   ├── database/
│   │   └── schemes/           # Database schema definitions
│   │       ├── audit_records.sql
│   │       ├── cake_batches.sql
│   │       ├── handoffs.sql
│   │       ├── oracle_alerts.sql
│   │       ├── quality_checks.sql
│   │       ├── shipping_accidents.sql
│   │       └── status_logs.sql
│   └── src/
│       ├── server.ts          # Main API server
│       ├── database.ts        # Database connection and operations
│       ├── web3-lib.ts        # Web3 interaction library
│       ├── solc-lib.ts        # Solidity compiler wrapper
│       ├── compile.ts         # Contract compilation script
│       ├── deploy.ts          # Single contract deployment
│       ├── deployAll.ts       # All contracts deployment script
│       ├── pushInvalidCakes.ts # Test data generation
│       └── validateReadings.ts # Sensor data validation
├── contracts/                 # Smart contract source code
│   ├── CakeLifecycleRegistry.sol
│   ├── CakeFactory.sol
│   ├── Shipper.sol
│   ├── Warehouse.sol
│   ├── SensorOracle.sol
│   ├── Auditor.sol
│   ├── RoleManager.sol
│   ├── ICakeLifecycle.sol     # Interface definitions
│   ├── IShipmentAlertSink.sol
│   └── HelloWorld.sol         # Example contract
├── tests/                     # Smart contract test files
│   ├── CakeLifecycleRegistry_test.sol
│   ├── CakeFactory_test.sol
│   ├── Shipper_test.sol
│   ├── Warehouse_test.sol
│   ├── Auditor_test.sol
│   ├── RoleManager_test.sol
│   └── HelloWorld_test.sol
├── scripts/                   # Shell scripts for automation
│   ├── README.md              # Scripts documentation
│   ├── setup-contracts.sh     # Contract address configuration
│   ├── interactive-setup.sh   # Interactive configuration
│   ├── deploy-and-verify.sh   # Deploy and verify contracts
│   ├── setup-database.sh      # Database initialization
│   ├── start-api.sh           # Start API server
│   ├── test-api.sh            # API test script
│   ├── test-audit.sh          # Audit workflow test
│   └── quick-verify.sh        # Quick verification script
├── docs/                      # Documentation
│   ├── api-reference.md       # API endpoint documentation
│   ├── backend-guide.md       # This file - backend setup guide
│   └── database-integration.md # Database integration guide
├── eth_accounts/
│   └── accounts.json          # Ethereum account configuration
└── eth_providers/
    └── providers.json         # Blockchain provider configuration
```

### Related Documentation
- API detailed documentation: `docs/api-reference.md`
- Database integration guide: `docs/database-integration.md`
- Scripts documentation: `scripts/README.md`

### Technical Support
If you encounter issues, please check:
1. Error logs and stack traces
2. Network and contract status
3. Parameter format and data types
4. Permission and access control settings
