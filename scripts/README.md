# Scripts Directory

This directory contains all shell scripts for the Cake Supply Chain project. Each script is documented with clear purpose, prerequisites, and usage instructions.

**Author**: Lilla Guo  
**Project**: COMP6452 Blockchain - Cake Supply Chain

## Available Scripts

### Complete End-to-End Testing

#### full-e2e-test.sh ⭐ **RECOMMENDED FOR NEW USERS**
**Purpose**: Complete automated setup and testing for cake supply chain

**Usage**: 
```bash
./scripts/full-e2e-test.sh
```

**Prerequisites**:
- Node.js and npm installed
- jq installed for JSON processing

**Description**: This is the main script for new contributors. It provides a complete end-to-end test that can be run by anyone who clones the project. It handles all setup automatically including dependency installation, account setup, Ganache startup, contract compilation, deployment, API server startup, and comprehensive testing. Perfect for validating the entire system functionality.

**Features**:
- Zero configuration required
- Dynamic contract addresses
- Automatic cleanup
- 15 comprehensive tests
- Colored output

---

### Contract Testing Scripts

#### test-real-contracts.sh
**Purpose**: Test all API endpoints with real deployed contracts

**Usage**: 
```bash
./scripts/test-real-contracts.sh
```

**Prerequisites**:
- API server running on localhost:3000
- Real contracts deployed and configured
- jq installed for JSON processing

**Description**: Tests all API functionality using real deployed contracts, providing comprehensive end-to-end validation of the system. Generates unique batch IDs to avoid conflicts and demonstrates complete lifecycle functionality.

---

#### test-api.sh
**Purpose**: Comprehensive testing of all API endpoints with mock data

**Usage**: 
```bash
./scripts/test-api.sh
```

**Prerequisites**:
- API server running on localhost:3000
- jq installed for JSON processing

**Description**: Tests all API endpoints including health checks, contract configuration, factory operations, shipping, warehouse, sensor data, and audit functions. Uses predefined test data for API structure validation.

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

**Description**: Tests the complete audit workflow including comprehensive data retrieval, compliance analysis, and audit certification. Demonstrates the audit capabilities of the system.

---

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

### Deployment and Verification Scripts

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

**Description**: Provides complete automated workflow for deploying contracts, configuring API server, and running verification tests. Includes contract compilation, deployment, and basic functionality testing.

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

**Description**: Provides streamlined verification by prompting for contract addresses and running basic functionality tests. Ideal for quick system validation.

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

**Description**: Automates startup process by checking dependencies, compiling contracts if needed, and starting the server. Includes comprehensive pre-startup validation.

---

#### setup-database.sh
**Purpose**: Initialize and setup the SQLite database

**Usage**: 
```bash
./scripts/setup-database.sh
```

**Prerequisites**:
- Node.js environment available

**Description**: Sets up the database schemas and initializes the SQLite database for the cake supply chain system. Creates all necessary tables and structures.

---

#### demo-account-setup.sh
**Purpose**: Setup demo accounts for testing purposes

**Usage**: 
```bash
./scripts/demo-account-setup.sh
```

**Prerequisites**:
- Ganache or blockchain network available

**Description**: Creates and configures demo accounts with appropriate balances for testing the cake supply chain system.

---

#### setup-permissions.sh
**Purpose**: Set execute permissions for all scripts in the project

**Usage**: 
```bash
./scripts/setup-permissions.sh
```

**Prerequisites**:
- Shell environment with chmod available

**Description**: Sets execute permissions for all shell scripts in the project. Useful when scripts lose permissions or for fresh project setups.

---

### Database Management Scripts

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

## Usage Recommendations

### For New Contributors (RECOMMENDED)
```bash
# One-command complete setup and testing
./scripts/full-e2e-test.sh
```

### For First-Time Manual Setup
1. `./scripts/deploy-and-verify.sh` - Complete automated setup
2. `./scripts/test-real-contracts.sh` - Real contract testing

### For Regular Development
1. `./scripts/start-api.sh` - Start the API server
2. `./scripts/setup-contracts.sh` - Configure addresses (edit file first)
3. `./scripts/quick-verify.sh` - Quick functionality check

### For Testing and Validation
1. `./scripts/test-real-contracts.sh` - Real contract testing (RECOMMENDED)
2. `./scripts/test-api.sh` - API structure testing
3. `./scripts/test-audit.sh` - Audit functionality testing
4. `./scripts/test-clear-data.sh` - Database clear functionality testing (⚠️ clears data!)

### For Interactive Use
1. `./scripts/interactive-setup.sh` - Interactive address setup
2. `./scripts/quick-verify.sh` - Interactive verification

## Common Workflows

### Complete Setup from Scratch (Recommended)
```bash
# Single command does everything
./scripts/full-e2e-test.sh
```

### Manual Setup for Development
```bash
# 1. Start API server
./scripts/start-api.sh

# 2. Deploy contracts (in another terminal)
npm run deploy

# 3. Configure addresses (edit script first)
./scripts/setup-contracts.sh

# 4. Test functionality
./scripts/test-real-contracts.sh
```

### Quick Testing After Changes
```bash
# Test with real contracts
./scripts/test-real-contracts.sh

# Test audit features
./scripts/test-audit.sh
```

### Database Management
```bash
# Setup fresh database
./scripts/setup-database.sh

# Clear all data (⚠️ Warning: destructive)
./scripts/test-clear-data.sh
```

## Script Features

- **Professional Design**: All scripts include comprehensive documentation headers
- **Color-coded Output**: Scripts use color-coded output for better readability
- **Error Handling**: Robust error handling with appropriate exit codes
- **Prerequisite Checking**: Prerequisites are validated before execution where applicable
- **Zero Configuration**: Main testing script requires no manual configuration
- **Dynamic Addresses**: No dependency on hardcoded contract addresses
- **Automatic Cleanup**: Background processes are automatically terminated


**Author**: Lilla Guo  
**Project**: COMP6452 Blockchain - Cake Supply Chain  
**Institution**: University of New South Wales  


**Questions or issues?** Please refer to the main project documentation or submit issues in the project repository.
