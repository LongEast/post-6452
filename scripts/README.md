# Scripts Directory

This directory contains all shell scripts for the Cake Supply Chain project. Each script is documented with clear purpose, prerequisites, and usage instructions.

## Available Scripts

### Contract Setup Scripts

#### setup-contracts.sh
**Purpose**: Configure contract addresses for the Cake Supply Chain API

**Usage**: 
```bash
./scripts/setup-contracts.sh
```

**Prerequisites**:
- API server running on localhost:3000
- Contracts deployed to Ganache
- Real contract addresses edited in the script

**Description**: Sets up contract addresses by editing placeholder values in the script and sending them to the API server via HTTP POST.

---

#### interactive-setup.sh
**Purpose**: Interactive contract address configuration

**Usage**: 
```bash
./scripts/interactive-setup.sh
```

**Prerequisites**:
- API server running on localhost:3000
- Contracts deployed to Ganache
- Contract addresses available from deployment logs

**Description**: Provides an interactive interface for inputting contract addresses one by one.

---

### Testing Scripts

#### test-api.sh
**Purpose**: Comprehensive testing of all API endpoints

**Usage**: 
```bash
./scripts/test-api.sh
```

**Prerequisites**:
- API server running on localhost:3000
- jq installed for JSON processing

**Description**: Tests all API endpoints including health checks, contract configuration, factory operations, shipping, warehouse, sensor data, and audit functions.

---

#### test-audit.sh
**Purpose**: Test audit functionality for comprehensive batch data verification

**Usage**: 
```bash
./scripts/test-audit.sh
```

**Prerequisites**:
- API server running on localhost:3000
- Contract addresses configured
- jq installed for JSON processing

**Description**: Tests the complete audit workflow including comprehensive data retrieval, compliance analysis, and audit certification.

---

#### test-clear-data.sh
**Purpose**: Test the database clear functionality and safety mechanisms

**Usage**: 
```bash
./scripts/test-clear-data.sh
```

**Prerequisites**:
- API server running on localhost:3000
- Database functionality enabled

**Description**: Tests the `/api/admin/clear-data` endpoint to demonstrate how to completely reset the database to a brand new state. Includes safety confirmation testing.

**WARNING**: This script will actually clear all database data if the API server is running! Use with caution.

---

#### quick-verify.sh
**Purpose**: Quick verification of API functionality with deployed contracts

**Usage**: 
```bash
./scripts/quick-verify.sh
```

**Prerequisites**:
- API server running on localhost:3000
- Contracts deployed to Ganache

**Description**: Provides streamlined verification by prompting for contract addresses and running basic functionality tests.

---

### Utility Scripts

#### start-api.sh
**Purpose**: Start the Cake Supply Chain API server with dependency checks

**Usage**: 
```bash
./scripts/start-api.sh
```

**Prerequisites**:
- Node.js and npm installed
- Project in correct directory

**Description**: Automates startup process by checking dependencies, compiling contracts if needed, and starting the server.

---

#### deploy-and-verify.sh
**Purpose**: Complete end-to-end deployment and verification workflow

**Usage**: 
```bash
./scripts/deploy-and-verify.sh
```

**Prerequisites**:
- Ganache running on http://127.0.0.1:8546
- Node.js and npm installed
- jq installed for JSON processing

**Description**: Provides complete automated workflow for deploying contracts, configuring API server, and running verification tests.

---

## Usage Recommendations

### For First-Time Setup
1. `./scripts/deploy-and-verify.sh` - Complete automated setup
2. `./scripts/test-api.sh` - Comprehensive testing

### For Regular Development
1. `./scripts/start-api.sh` - Start the API server
2. `./scripts/setup-contracts.sh` - Configure addresses (edit file first)
3. `./scripts/quick-verify.sh` - Quick functionality check

### For Testing
1. `./scripts/test-api.sh` - Full API testing
2. `./scripts/test-audit.sh` - Audit functionality testing
3. `./scripts/test-clear-data.sh` - Database clear functionality testing (⚠️ clears data!)

### For Interactive Use
1. `./scripts/interactive-setup.sh` - Interactive address setup
2. `./scripts/quick-verify.sh` - Interactive verification

## Common Workflows

### Complete Setup from Scratch
```bash
# 1. Start Ganache (external)
# 2. Run complete deployment and verification
./scripts/deploy-and-verify.sh
```

### Manual Setup
```bash
# 1. Start API server
./scripts/start-api.sh

# 2. Deploy contracts (in another terminal)
npm run deploy

# 3. Configure addresses (edit script first)
./scripts/setup-contracts.sh

# 4. Test functionality
./scripts/test-api.sh
```

### Quick Testing
```bash
# After contracts are deployed and API is running
./scripts/quick-verify.sh
./scripts/test-audit.sh
```

## Notes

- All scripts include comprehensive documentation headers
- Scripts use color-coded output for better readability
- Error handling is implemented with appropriate exit codes
- Prerequisites are checked before execution where applicable
- All scripts are emoji-free for professional use
