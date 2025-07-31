# COMP6452 Blockchain - Cake Supply Chain

A blockchain-based supply chain management system for premium cakes, implementing cold chain logistics tracking with smart contracts and comprehensive API.

## Quick Start (New Contributors)

**Just cloned the project? Get everything running with one command:**

```bash
./scripts/full-e2e-test.sh
```

This script automatically handles dependencies, blockchain setup, contract deployment, and runs comprehensive tests!

**Prerequisites:** Node.js (v14+) and jq
- **macOS:** `brew install node jq`
- **Ubuntu:** `sudo apt-get install nodejs jq`
 **See [QUICK-START.md](QUICK-START.md) for detailed instructions**

---

## Table of Contents
- [Quick Start Guide](#quick-start-guide)
- [Contract Address Management](#contract-address-management)
- [System Architecture](#system-architecture)
- [Development & Testing](#development--testing)
- [Project Information](#project-information)

---

## Quick Start Guide

### Prerequisites

Before deployment, ensure the following are installed and running:

1. **Ganache CLI** - Local blockchain for development
```bash
npm install -g ganache
```

2. **Required Tools**
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq
```

### Step 1: Database Setup (First time only)
```bash
# Install SQLite dependencies and create data directory
./scripts/setup-database.sh
```

### Step 2: Start Local Blockchain
```bash
# Start Ganache with deterministic accounts
npx ganache --host 127.0.0.1 --port 8546 --deterministic --accounts 10 --account_keys_path keys.json
```

### Step 3: Install Dependencies
```bash
# Install project dependencies including OpenZeppelin contracts
npm install
npm install @openzeppelin/contracts
```

### Step 4: Setup Ethereum Accounts
```bash
# Copy the example accounts file to create your local config
cp eth_accounts/accounts.example.json eth_accounts/accounts.json
```

**What this command does:**
- Creates `accounts.json` with ready-to-use private keys
- Provides 2 standard Ganache accounts (acc0, acc1) 
- No manual editing required - works immediately with default Ganache setup

**The accounts you get:**
- `acc0`: `0x4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d` → `0x90F79bf6EB2c4f870365E785982E1f101E93b906`
- `acc1`: `0x6cbed15c793ce57650b9877cf6fa156fbef513c4e6134f022a85b1ffdd59b2a1` → `0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65`

**Note**: You can customize the private keys later if needed, but the defaults work perfectly with the standard Ganache setup above.

### Step 5: Compile Smart Contracts
```bash
# Compile all Solidity contracts
npm run compile
```

### Step 6: Deploy Contracts
```bash
# Deploy all contracts to Ganache
# Replace addresses with actual Ganache account addresses from step 2
npm run deploy deploy acc0 0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1 0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0
```

**Expected Deployment Output:**
```
Deployed RoleManager → 0xe78A0F7E598Cc8b0Bb87894B0F60dD2a88d6a8Ab
Deployed CakeLifecycleRegistry → 0x5b1869D9A4C187F2EAa108f3062412ecf0526b24
Deployed CakeFactory → 0xCfEB869F69431e42cdB54A4F4f105C19C080A601
Deployed Shipper → 0x254dffcd3277C0b1660F6d42EFbB754edaBAbC2B
Deployed Warehouse → 0xC89Ce4735882C9F0f0FE26686c53074E09B0D550
Deployed SensorOracle → 0xD833215cBcc3f914bD1C9ece3EE7BF8B14f841bb
Deployed Auditor → 0xe982E462b094850F12AF94d21D470e21bE9D0E9C

Deployment summary:
Admin: 0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1
RoleManager: 0xe78A0F7E598Cc8b0Bb87894B0F60dD2a88d6a8Ab
CakeLifecycleRegistry: 0x5b1869D9A4C187F2EAa108f3062412ecf0526b24
CakeFactory: 0xCfEB869F69431e42cdB54A4F4f105C19C080A601
Shipper: 0x254dffcd3277C0b1660F6d42EFbB754edaBAbC2B
Warehouse: 0xC89Ce4735882C9F0f0FE26686c53074E09B0D550
SensorOracle: 0xD833215cBcc3f914bD1C9ece3EE7BF8B14f841bb
Auditor: 0xe982E462b094850F12AF94d21D470e21bE9D0E9C
```

### Step 6: Start API Server
```bash
# Start the backend API server (in a new terminal)
npm run server
```

### Step 7: Configure Contract Addresses
```bash
# Configure deployed contract addresses to API server
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

### Step 8: Verify System Status
```bash
# Check API health
curl http://localhost:3000/

# Verify contract addresses are configured
curl http://localhost:3000/api/admin/contracts
```

---

## Contract Address Management

### How to Query Deployed Contract Addresses

After deployment, you can retrieve contract addresses using the following methods:

#### 1. From Deployment Output (Manual)
```bash
# The deployment command will output all contract addresses
# Copy these addresses for use in Step 7
```

#### 2. Save and Parse Deployment Output (Automated)
```bash
# Save deployment output to file and extract addresses
npm run deploy deploy acc0 0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1 0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0 | tee deployment_log.txt

# Extract specific contract addresses from saved output
grep "Deployed\|Admin:" deployment_log.txt

# Quick search for a specific contract address
grep "CakeFactory" deployment_log.txt
```

#### 3. Via API Server (After Step 6)
```bash
# Query configured addresses via API
curl http://localhost:3000/api/admin/contracts
```

### Managing Contract Addresses

#### Query Currently Configured Addresses
```bash
# Get all configured addresses via API
curl http://localhost:3000/api/admin/contracts
```

#### Query from Deployment Log
```bash
# If you saved deployment output (recommended)
cat deployment_log.txt | grep "Deployed\|Admin:"

# Search for specific contracts
grep -E "(CakeFactory|Warehouse|Shipper)" deployment_log.txt
```

#### Update Addresses After Redeployment
```bash
# Update individual contract address
curl -X POST http://localhost:3000/api/admin/contracts \
  -H "Content-Type: application/json" \
  -d '{"CakeFactory": "0xNewCakeFactoryAddress"}'

# Update multiple addresses at once
curl -X POST http://localhost:3000/api/admin/contracts \
  -H "Content-Type: application/json" \
  -d '{
    "CakeFactory": "0xNewAddress1",
    "Warehouse": "0xNewAddress2"
  }'
```

#### Verify Address Configuration
```bash
# Check if specific contract is configured
curl http://localhost:3000/api/admin/contracts | grep "CakeFactory"

# Test contract connectivity
curl -X POST http://localhost:3000/api/factory/batch \
  -H "Content-Type: application/json" \
  -d '{"batchId": 9999, "maxTemperature": 20, "minTemperature": 0, "maxHumidity": 50, "minHumidity": 20, "metadataURI": "ipfs://test"}'
```

---

## System Architecture

### Deployment Architecture

The deployment process follows a specific sequence to handle contract dependencies:

1. **RoleManager** - Foundation permission management system
2. **CakeLifecycleRegistry** - Core registry that tracks cake batch lifecycle
3. **CakeFactory** - Factory contract that creates batches and integrates with registry
4. **Shipper** - Handles transportation and logistics
5. **Warehouse** - Manages storage and delivery
6. **SensorOracle** - Monitors environmental conditions during transport
7. **Auditor** - Provides final audit and certification capabilities

Each contract is automatically configured with proper role assignments and inter-contract relationships during deployment.

### Technology Stack

- **Smart Contracts**: Solidity, OpenZeppelin
- **Backend**: Node.js, Express.js, TypeScript
- **Database**: SQLite (development), PostgreSQL (production ready)
- **Blockchain**: Ganache (local development)
- **Web3**: Web3.js
- **Testing**: Shell scripts, curl
- **Documentation**: Markdown

### Features

- **Blockchain Integration**: Smart contracts for supply chain management
- **Database Integration**: SQLite for fast queries and data analysis
- **Cold Chain Monitoring**: Real-time sensor data tracking
- **Audit System**: Comprehensive audit trails and reporting
- **RESTful API**: Complete API for all operations

---

## Development & Testing

### API Testing

After successful deployment and configuration, test the system functionality:

```bash
# Test API health check
curl http://localhost:3000/

# Test sensor data submission
curl -X POST http://localhost:3000/api/oracle/sensor-data \
  -H "Content-Type: application/json" \
  -d '{
    "batchId": 1001,
    "temperature": 18,
    "humidity": 45
  }'

# Test batch creation
curl -X POST http://localhost:3000/api/factory/batch \
  -H "Content-Type: application/json" \
  -d '{
    "batchId": 1001,
    "maxTemperature": 20,
    "minTemperature": 0,
    "maxHumidity": 50,
    "minHumidity": 20,
    "metadataURI": "ipfs://QmTestHash123"
  }'

# View batch record
curl http://localhost:3000/api/lifecycle/batch/1001
```

### Development Workflow

```bash
# Run comprehensive API testing
./scripts/test-api.sh

# Run audit functionality testing
./scripts/test-audit.sh

# Restart API server if needed
npm run server

# Redeploy contracts after changes
npm run compile
npm run deploy deploy acc0 [admin_address] [sensor_address]
```

### Complete Test Suite
```bash
# Comprehensive API testing
./scripts/test-api.sh

# Audit functionality testing
./scripts/test-audit.sh
```

---

## Project Information

### Project Structure

```
/Users/lillaguo/COMP6452-blockchain/
├── backend/
│   ├── src/                    # Backend source code
│   └── data/                   # Sample data
├── contracts/                  # Smart contracts
├── scripts/                    # Shell scripts (organized)
│   ├── setup-contracts.sh      # Contract address configuration
│   ├── interactive-setup.sh    # Interactive setup
│   ├── test-api.sh            # API testing
│   ├── test-audit.sh          # Audit testing
│   ├── quick-verify.sh        # Quick verification
│   ├── start-api.sh           # Server startup
│   ├── deploy-and-verify.sh   # Complete workflow
│   ├── setup-database.sh      # Database setup
│   └── README.md              # Scripts documentation
├── tests/                     # Contract tests
└── docs/                      # Documentation files
```

### Scripts Directory

All shell scripts are organized in the `scripts/` directory with comprehensive documentation. See `scripts/README.md` for detailed information about each script.

### Documentation

- [`docs/api-reference.md`](docs/api-reference.md) - Complete API documentation
- [`docs/backend-guide.md`](docs/backend-guide.md) - Backend operation guide
- [`docs/database-integration.md`](docs/database-integration.md) - Database setup and usage
- [`scripts/README.md`](scripts/README.md) - Scripts documentation
