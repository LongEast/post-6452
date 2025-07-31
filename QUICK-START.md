# Cake Supply Chain - Quick Start Guide

## Quick Start (For New Contributors)

If you have just cloned this project, you can test the entire cake supply chain system with a single command!

### One-Click Execution

```bash
# Clone the project
git clone https://github.com/LongEast/COMP6452-blockchain.git
cd COMP6452-blockchain

# Run complete end-to-end tests
./scripts/full-e2e-test.sh
```

That's it! The script will automatically handle all setup and testing.

## Prerequisites

Before running the script, ensure the following are installed on your system:

### macOS
```bash
# Install Node.js (if not already installed)
brew install node

# Install jq (for JSON processing)
brew install jq
```

### Ubuntu/Debian
```bash
# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install jq
sudo apt-get install jq
```

### Windows
```bash
# Using Chocolatey
choco install nodejs jq

# Or download and install manually:
# Node.js: https://nodejs.org/
# jq: https://stedolan.github.io/jq/download/
```

## Automated Script Workflow

The `full-e2e-test.sh` script automatically executes the following steps:

1. **Install Dependencies** - `npm install`
2. **Configure Accounts** - Create test account files
3. **Start Blockchain** - Ganache local network
4. **Compile Contracts** - Compile all Solidity contracts
5. **Deploy Contracts** - Deploy to local network with proper permissions
6. **Start API Server** - Backend service
7. **Configure Contract Addresses** - Dynamically configure deployment addresses
8. **Run Tests** - 15 comprehensive tests

## Expected Results

After successful execution, you should see:

```
================================================
              TEST RESULTS SUMMARY             
================================================
ALL TESTS PASSED! (15/15)
Complete cake supply chain lifecycle tested successfully
All API endpoints working correctly
Contract integration functioning properly

Complete lifecycle created for batch XXXX:
   Status: 0 (Created) → 1 (Quality Checked) → 2 (In Transit) → 3 (Delivered)
```

## Test Coverage

The tests cover the complete cake supply chain lifecycle:

1. **Factory Stage**
   - Create cake batch
   - Quality check
   - Handoff to shipper

2. **Shipping Stage**
   - Sensor data recording (temperature/humidity)
   - GPS location tracking
   - Delivery to warehouse

3. **Warehouse Stage**
   - Confirm receipt
   - Final status update

4. **Audit Stage**
   - Complete audit records
   - Compliance checking
   - Lifecycle tracking

## Manual Execution (Advanced Users)

If you want to run step by step, you can use individual commands:

```bash
# 1. Install dependencies
npm install

# 2. Start Ganache (new terminal)
npm run ganache

# 3. Compile contracts
npm run compile

# 4. Deploy contracts
npm run deploy

# 5. Start API server (new terminal)
npm run server

# 6. Run tests
./scripts/test-real-contracts.sh
```

## Generated Files

After test execution, the following files will be generated:

- `ganache.log` - Blockchain network logs
- `api.log` - API server logs
- `deployment_log.txt` - Contract deployment records
- `backend/blockchain.db` - SQLite database

## Troubleshooting

### Port Conflict Errors
```bash
# If ports are occupied, kill related processes
lsof -ti:3000 | xargs kill -9  # API server
lsof -ti:8546 | xargs kill -9  # Ganache
```

### Permission Issues
```bash
# Ensure script has execute permissions
chmod +x scripts/full-e2e-test.sh
```

### Node.js Version Issues
```bash
# Check Node.js version (requires v14+)
node --version

# If version is too old, update
npm install -g n
n stable
```

## Performance Metrics

- **Total test time**: ~2-3 minutes
- **Number of tests**: 15 comprehensive tests
- **Contract deployments**: 7 smart contracts
- **API endpoints**: 15 different endpoints

## Key Features

- Zero configuration required
- Dynamic addresses - no dependency on hardcoded addresses
- Automatic cleanup - processes stopped automatically after testing
- Detailed logging - complete execution records
- Colored output - clear test result display

## Contributing Guidelines

1. Fork this repository
2. Run `./scripts/full-e2e-test.sh` to ensure all tests pass
3. Make your changes
4. Run tests again to ensure no existing functionality is broken
5. Submit a Pull Request

## Related Documentation

- [API Reference](docs/api-reference.md)
- [Backend Guide](docs/backend-guide.md) 
- [Database Integration](docs/database-integration.md)

---

**Questions or suggestions?** Please submit them in GitHub Issues!

Happy coding!
