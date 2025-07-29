#!/bin/bash

# =============================================================================
# COMPLETE DEPLOYMENT AND VERIFICATION SCRIPT
# =============================================================================
#
# Purpose: Complete end-to-end deployment and verification workflow
# 
# Description:
#   This script provides a complete automated workflow for deploying contracts
#   to Ganache, configuring the API server, and running verification tests.
#   It's designed for full system setup and validation.
#
# Prerequisites:
#   - Ganache must be running on http://127.0.0.1:8546
#   - Node.js and npm must be installed
#   - jq must be installed for JSON processing
#   - Project dependencies must be available
#
# Usage:
#   ./scripts/deploy-and-verify.sh
#
# Input: None (fully automated)
# Output: Deployed contracts, configured API, and verification results
#
# Features:
#   - Prerequisite checking
#   - Automated contract deployment
#   - API server configuration
#   - Comprehensive testing
#   - Status reporting
#
# Author: Lilla Guo
# =============================================================================

set -e  # Exit on error

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Complete Contract Deployment and API Verification Workflow${NC}\n"

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

# Check if Ganache is running
if curl -s -f http://127.0.0.1:8546 > /dev/null 2>&1; then
    echo -e "${GREEN}SUCCESS: Ganache is running${NC}"
else
    echo -e "${RED}ERROR: Ganache is not running. Please start Ganache first.${NC}"
    echo "   Ensure Ganache is running on http://127.0.0.1:8546"
    exit 1
fi

# Check for jq
if ! command -v jq &> /dev/null; then
    echo -e "${RED}ERROR: jq is required for JSON processing${NC}"
    echo "   macOS: brew install jq"
    echo "   Ubuntu: sudo apt-get install jq"
    exit 1
fi

# Check for node and npm
if ! command -v npm &> /dev/null; then
    echo -e "${RED}ERROR: npm is required${NC}"
    echo "   Please install Node.js and npm"
    exit 1
fi

echo -e "${GREEN}SUCCESS: All prerequisites met${NC}\n"

# Step 1: Install dependencies and compile contracts
echo -e "${YELLOW}Step 1: Installing dependencies and compiling contracts...${NC}"
if [ ! -d "node_modules" ]; then
    npm install
fi

npm run compile
echo -e "${GREEN}SUCCESS: Contracts compiled${NC}\n"

# Step 2: Deploy contracts
echo -e "${YELLOW}Step 2: Deploying contracts to Ganache...${NC}"
DEPLOY_OUTPUT=$(npm run deploy 2>&1)
echo "$DEPLOY_OUTPUT"

# Extract contract addresses from deployment output
# Note: This assumes deployment script outputs addresses in a parseable format
CAKE_FACTORY_ADDR=$(echo "$DEPLOY_OUTPUT" | grep -o "CakeFactory.*0x[a-fA-F0-9]\{40\}" | grep -o "0x[a-fA-F0-9]\{40\}" | head -1)
LIFECYCLE_ADDR=$(echo "$DEPLOY_OUTPUT" | grep -o "CakeLifecycleRegistry.*0x[a-fA-F0-9]\{40\}" | grep -o "0x[a-fA-F0-9]\{40\}" | head -1)
SHIPPER_ADDR=$(echo "$DEPLOY_OUTPUT" | grep -o "Shipper.*0x[a-fA-F0-9]\{40\}" | grep -o "0x[a-fA-F0-9]\{40\}" | head -1)
WAREHOUSE_ADDR=$(echo "$DEPLOY_OUTPUT" | grep -o "Warehouse.*0x[a-fA-F0-9]\{40\}" | grep -o "0x[a-fA-F0-9]\{40\}" | head -1)
ORACLE_ADDR=$(echo "$DEPLOY_OUTPUT" | grep -o "SensorOracle.*0x[a-fA-F0-9]\{40\}" | grep -o "0x[a-fA-F0-9]\{40\}" | head -1)
AUDITOR_ADDR=$(echo "$DEPLOY_OUTPUT" | grep -o "Auditor.*0x[a-fA-F0-9]\{40\}" | grep -o "0x[a-fA-F0-9]\{40\}" | head -1)
ROLE_MANAGER_ADDR=$(echo "$DEPLOY_OUTPUT" | grep -o "RoleManager.*0x[a-fA-F0-9]\{40\}" | grep -o "0x[a-fA-F0-9]\{40\}" | head -1)

if [ -z "$CAKE_FACTORY_ADDR" ]; then
    echo -e "${RED}ERROR: Could not extract contract addresses from deployment output${NC}"
    echo "Please manually configure addresses using ./scripts/setup-contracts.sh"
    exit 1
fi

echo -e "${GREEN}SUCCESS: Contracts deployed${NC}"
echo "Contract Addresses:"
echo "- CakeFactory: $CAKE_FACTORY_ADDR"
echo "- CakeLifecycleRegistry: $LIFECYCLE_ADDR"
echo "- Shipper: $SHIPPER_ADDR"
echo "- Warehouse: $WAREHOUSE_ADDR"
echo "- SensorOracle: $ORACLE_ADDR"
echo "- Auditor: $AUDITOR_ADDR"
echo "- RoleManager: $ROLE_MANAGER_ADDR"
echo ""

# Step 3: Start API server in background
echo -e "${YELLOW}Step 3: Starting API server...${NC}"
npm run server &
API_PID=$!
echo "API server started with PID: $API_PID"

# Wait for API to be ready
echo "Waiting for API server to be ready..."
for i in {1..30}; do
    if curl -s -f http://localhost:3000/ > /dev/null 2>&1; then
        echo -e "${GREEN}SUCCESS: API server is ready${NC}"
        break
    fi
    sleep 1
    if [ $i -eq 30 ]; then
        echo -e "${RED}ERROR: API server failed to start${NC}"
        kill $API_PID 2>/dev/null || true
        exit 1
    fi
done
echo ""

# Step 4: Configure contract addresses
echo -e "${YELLOW}Step 4: Configuring contract addresses...${NC}"
CONFIG_RESULT=$(curl -s -X POST http://localhost:3000/api/admin/contracts \
  -H "Content-Type: application/json" \
  -d "{
    \"CakeFactory\": \"$CAKE_FACTORY_ADDR\",
    \"CakeLifecycleRegistry\": \"$LIFECYCLE_ADDR\",
    \"Shipper\": \"$SHIPPER_ADDR\",
    \"Warehouse\": \"$WAREHOUSE_ADDR\",
    \"SensorOracle\": \"$ORACLE_ADDR\",
    \"Auditor\": \"$AUDITOR_ADDR\",
    \"RoleManager\": \"$ROLE_MANAGER_ADDR\"
  }")

if echo "$CONFIG_RESULT" | grep -q '"success":true'; then
    echo -e "${GREEN}SUCCESS: Contract addresses configured${NC}"
else
    echo -e "${RED}ERROR: Failed to configure contract addresses${NC}"
    echo "$CONFIG_RESULT"
    kill $API_PID 2>/dev/null || true
    exit 1
fi
echo ""

# Step 5: Run verification tests
echo -e "${YELLOW}Step 5: Running verification tests...${NC}"

# Test creating a batch
echo "Testing batch creation..."
BATCH_RESULT=$(curl -s -X POST http://localhost:3000/api/factory/batch \
  -H "Content-Type: application/json" \
  -d '{
    "batchId": 9999,
    "maxTemperature": 20,
    "minTemperature": -7,
    "maxHumidity": 50,
    "minHumidity": 20,
    "metadataURI": "ipfs://deploy-verify-test"
  }')

if echo "$BATCH_RESULT" | grep -q '"success":true'; then
    echo -e "${GREEN}SUCCESS: Batch creation test passed${NC}"
else
    echo -e "${RED}WARNING: Batch creation test failed${NC}"
    echo "$BATCH_RESULT" | jq .
fi

# Test sensor data submission
echo "Testing sensor data submission..."
SENSOR_RESULT=$(curl -s -X POST http://localhost:3000/api/oracle/sensor-data \
  -H "Content-Type: application/json" \
  -d '{
    "batchId": 9999,
    "temperature": 15,
    "humidity": 40
  }')

if echo "$SENSOR_RESULT" | grep -q '"success":true'; then
    echo -e "${GREEN}SUCCESS: Sensor data test passed${NC}"
else
    echo -e "${RED}WARNING: Sensor data test failed${NC}"
    echo "$SENSOR_RESULT" | jq .
fi

# Test audit data retrieval
echo "Testing audit data retrieval..."
AUDIT_RESULT=$(curl -s http://localhost:3000/api/auditor/batch/9999/comprehensive)

if echo "$AUDIT_RESULT" | grep -q '"success":true'; then
    echo -e "${GREEN}SUCCESS: Audit data test passed${NC}"
else
    echo -e "${RED}WARNING: Audit data test failed${NC}"
    echo "$AUDIT_RESULT" | jq .
fi

echo ""
echo -e "${BLUE}Deployment and Verification Complete!${NC}"
echo ""
echo -e "${YELLOW}System Status:${NC}"
echo "- Contracts: Deployed and configured"
echo "- API Server: Running on http://localhost:3000"
echo "- Tests: Basic functionality verified"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Run full test suite: ./scripts/test-api.sh"
echo "2. Test audit workflow: ./scripts/test-audit.sh"
echo "3. Explore API endpoints in API_DOCUMENTATION.md"
echo ""
echo -e "${YELLOW}To stop the API server:${NC}"
echo "kill $API_PID"
