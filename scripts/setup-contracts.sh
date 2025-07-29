#!/bin/bash

# =============================================================================
# CONTRACT ADDRESS SETUP SCRIPT
# =============================================================================
#
# Purpose: Configure contract addresses for the Cake Supply Chain API
# 
# Description:
#   This script sets up contract addresses by sending them to the running API
#   server via HTTP POST request. It includes validation to ensure real addresses
#   are provided before attempting to configure the system.
#
# Prerequisites:
#   - API server must be running on localhost:3000
#   - Contracts must be deployed to Ganache
#   - Real contract addresses must replace the placeholder values below
#
# Usage:
#   1. Deploy contracts to Ganache using: npm run deploy
#   2. Copy the deployed contract addresses from deployment logs
#   3. Replace the placeholder addresses in this script with real addresses
#   4. Run this script: ./scripts/setup-contracts.sh
#
# Input: Contract addresses (to be edited in this file)
# Output: Configured API server with contract addresses
#
# Author: Lilla Guo
# =============================================================================

echo "Configuring Cake Supply Chain contract addresses..."
echo ""

# CONTRACT ADDRESSES
# Replace the placeholder addresses below with actual deployed contract addresses
# Example format: 0x5FbDB2315678afecb367f032d93F642f64180aa3

CAKE_FACTORY="0xREPLACE_WITH_CAKE_FACTORY_ADDRESS"
LIFECYCLE_REGISTRY="0xREPLACE_WITH_LIFECYCLE_REGISTRY_ADDRESS"
SHIPPER="0xREPLACE_WITH_SHIPPER_ADDRESS"
WAREHOUSE="0xREPLACE_WITH_WAREHOUSE_ADDRESS"
SENSOR_ORACLE="0xREPLACE_WITH_SENSOR_ORACLE_ADDRESS"
AUDITOR="0xREPLACE_WITH_AUDITOR_ADDRESS"
ROLE_MANAGER="0xREPLACE_WITH_ROLE_MANAGER_ADDRESS"

echo "Contract addresses to be configured:"
echo "CakeFactory: $CAKE_FACTORY"
echo "CakeLifecycleRegistry: $LIFECYCLE_REGISTRY"
echo "Shipper: $SHIPPER"
echo "Warehouse: $WAREHOUSE"
echo "SensorOracle: $SENSOR_ORACLE"
echo "Auditor: $AUDITOR"
echo "RoleManager: $ROLE_MANAGER"
echo ""

# Validate that placeholder addresses have been replaced
if [[ $CAKE_FACTORY == *"REPLACE_WITH"* ]]; then
    echo "ERROR: Placeholder addresses detected. Please replace with actual contract addresses."
    echo ""
    echo "Required steps:"
    echo "1. Deploy contracts to Ganache"
    echo "2. Copy contract addresses from deployment logs"
    echo "3. Replace placeholder addresses in this script"
    echo "4. Re-run this script"
    exit 1
fi

# Send contract addresses to API server
echo "Sending contract addresses to API server..."
RESULT=$(curl -s -X POST http://localhost:3000/api/admin/contracts \
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

echo "$RESULT" | jq .

if echo "$RESULT" | grep -q '"success":true'; then
    echo ""
    echo "SUCCESS: Contract addresses configured successfully"
    echo ""
    echo "Verifying configuration:"
    curl -s http://localhost:3000/api/admin/contracts | jq .
    
    echo ""
    echo "System is ready for testing. Example API calls:"
    echo "Create cake batch:"
    echo "curl -X POST http://localhost:3000/api/factory/batch -H 'Content-Type: application/json' -d '{\"batchId\": 1001, \"maxTemperature\": 20, \"minTemperature\": -7, \"maxHumidity\": 50, \"minHumidity\": 20, \"metadataURI\": \"ipfs://test\"}'"
    echo ""
    echo "Get comprehensive audit data:"
    echo "curl http://localhost:3000/api/auditor/batch/1001/comprehensive"
else
    echo ""
    echo "ERROR: Configuration failed. Please ensure API server is running:"
    echo "npm run server"
fi
