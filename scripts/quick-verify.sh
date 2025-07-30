#!/bin/bash

# =============================================================================
# QUICK API VERIFICATION SCRIPT
# =============================================================================
#
# Purpose: Quick verification of API functionality with deployed contracts
# 
# Description:
#   This script provides a streamlined way to verify API functionality by
#   prompting for contract addresses and running basic functionality tests.
#   It's designed for quick validation after contract deployment.
#
# Prerequisites:
#   - API server must be running on localhost:3000
#   - Contracts must be deployed to Ganache
#   - Contract addresses must be available from deployment logs
#
# Usage:
#   ./scripts/quick-verify.sh
#
# Input: Interactive input for contract addresses
# Output: Quick verification results for core API functionality
#
# Features:
#   - Interactive address input
#   - Basic API functionality testing
#   - Contract configuration verification
#   - Sample API calls demonstration
#
# Author: Lilla Guo
# =============================================================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Quick API Verification Script${NC}\n"

# Check if API server is running
if ! curl -s -f http://localhost:3000/ > /dev/null 2>&1; then
    echo -e "${RED}ERROR: API server is not running. Please start it first:${NC}"
    echo "   npm run server"
    exit 1
fi

echo -e "${GREEN}SUCCESS: API server is running${NC}\n"

# Prompt user for contract addresses
echo -e "${YELLOW}Please enter your contract addresses:${NC}"
echo "(You can copy these addresses from Ganache deployment logs)"
echo ""

read -p "CakeFactory address: " CAKE_FACTORY
read -p "CakeLifecycleRegistry address: " LIFECYCLE_REGISTRY
read -p "Shipper address: " SHIPPER
read -p "Warehouse address: " WAREHOUSE
read -p "SensorOracle address: " SENSOR_ORACLE
read -p "Auditor address: " AUDITOR
read -p "RoleManager address: " ROLE_MANAGER

echo ""
echo -e "${YELLOW}Setting contract addresses...${NC}"

# Set contract addresses
SETUP_RESULT=$(curl -s -X POST http://localhost:3000/api/admin/contracts \
  -H "Content-Type: application/json" \
  -d "{
    \"CakeFactory\": \"$CAKE_FACTORY\",
    \"CakeLifecycleRegistry\": \"$LIFECYCLE_REGISTRY\",
    \"Shipper\": \"$SHIPPER\",
    \"Warehouse\": \"$WAREHOUSE\",
    \"SensorOracle\": \"$SENSOR_ORACLE\",
    \"Auditor\": \"$AUDITOR\",
    \"RoleManager\": \"$ROLE_MANAGER\"
  }")

if echo "$SETUP_RESULT" | grep -q '"success":true'; then
    echo -e "${GREEN}SUCCESS: Contract addresses configured${NC}"
else
    echo -e "${RED}ERROR: Failed to configure contract addresses${NC}"
    echo "$SETUP_RESULT" | jq .
    exit 1
fi

echo ""
echo -e "${YELLOW}Verifying configuration...${NC}"
curl -s http://localhost:3000/api/admin/contracts | jq .

echo ""
echo -e "${BLUE}Testing core API functionality...${NC}"

# Test 1: Create a cake batch
echo ""
echo -e "${YELLOW}Test 1: Creating cake batch 2001...${NC}"
CREATE_RESULT=$(curl -s -X POST http://localhost:3000/api/factory/batch \
  -H "Content-Type: application/json" \
  -d '{
    "batchId": 2001,
    "maxTemperature": 20,
    "minTemperature": -7,
    "maxHumidity": 50,
    "minHumidity": 20,
    "metadataURI": "ipfs://quick-verify-test"
  }')

echo "$CREATE_RESULT" | jq .

if echo "$CREATE_RESULT" | grep -q '"success":true'; then
    echo -e "${GREEN}SUCCESS: Cake batch created${NC}"
    
    # Test 2: Submit sensor data
    echo ""
    echo -e "${YELLOW}Test 2: Submitting sensor data...${NC}"
    SENSOR_RESULT=$(curl -s -X POST http://localhost:3000/api/oracle/sensor-data \
      -H "Content-Type: application/json" \
      -d '{
        "batchId": 2001,
        "temperature": 18,
        "humidity": 35
      }')
    
    echo "$SENSOR_RESULT" | jq .
    
    if echo "$SENSOR_RESULT" | grep -q '"success":true'; then
        echo -e "${GREEN}SUCCESS: Sensor data submitted${NC}"
    else
        echo -e "${RED}WARNING: Sensor data submission failed${NC}"
    fi
    
    # Test 3: Get batch record
    echo ""
    echo -e "${YELLOW}Test 3: Retrieving batch record...${NC}"
    BATCH_RECORD=$(curl -s http://localhost:3000/api/lifecycle/batch/2001)
    echo "$BATCH_RECORD" | jq .
    
    if echo "$BATCH_RECORD" | grep -q '"success":true'; then
        echo -e "${GREEN}SUCCESS: Batch record retrieved${NC}"
    else
        echo -e "${RED}WARNING: Batch record retrieval failed${NC}"
    fi
    
    # Test 4: Get comprehensive audit data
    echo ""
    echo -e "${YELLOW}Test 4: Getting comprehensive audit data...${NC}"
    AUDIT_DATA=$(curl -s http://localhost:3000/api/auditor/batch/2001/comprehensive)
    echo "$AUDIT_DATA" | jq .
    
    if echo "$AUDIT_DATA" | grep -q '"success":true'; then
        echo -e "${GREEN}SUCCESS: Comprehensive audit data retrieved${NC}"
    else
        echo -e "${RED}WARNING: Audit data retrieval failed${NC}"
    fi
    
else
    echo -e "${RED}ERROR: Failed to create cake batch${NC}"
    echo "This might indicate contract deployment or configuration issues."
fi

echo ""
echo -e "${BLUE}Quick verification complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Run comprehensive tests: ./scripts/test-api.sh"
echo "2. Test audit functionality: ./scripts/test-audit.sh"
echo "3. Check API documentation: API_DOCUMENTATION.md"
echo ""
echo -e "${YELLOW}Available API endpoints:${NC}"
echo "- POST /api/factory/batch                     # Create cake batch"
echo "- POST /api/oracle/sensor-data                # Submit sensor data"
echo "- GET  /api/lifecycle/batch/:id               # Get batch record"
echo "- GET  /api/auditor/batch/:id/comprehensive   # Get audit data"
echo "- POST /api/auditor/certify                   # Submit audit"
