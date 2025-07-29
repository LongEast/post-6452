#!/bin/bash

# =============================================================================
# INTERACTIVE CONTRACT ADDRESS SETUP SCRIPT
# =============================================================================
#
# Purpose: Interactive contract address configuration for Cake Supply Chain API
# 
# Description:
#   This script provides an interactive interface for setting up contract addresses.
#   It prompts the user to input each contract address one by one, then sends them
#   to the API server for configuration.
#
# Prerequisites:
#   - API server must be running on localhost:3000
#   - Contracts must be deployed to Ganache
#   - Contract addresses must be available from deployment logs
#
# Usage:
#   1. Deploy contracts to Ganache using: npm run deploy
#   2. Run this script: ./scripts/interactive-setup.sh
#   3. Follow prompts to input each contract address
#
# Input: Interactive user input for each contract address
# Output: Configured API server with contract addresses
#
# Author: Lilla Guo
# =============================================================================

echo "Interactive Contract Address Setup"
echo "=================================="
echo ""
echo "Please copy and paste contract addresses from Ganache deployment logs:"
echo ""

echo -n "CakeFactory address: "
read CAKE_FACTORY

echo -n "CakeLifecycleRegistry address: "
read LIFECYCLE_REGISTRY

echo -n "Shipper address: "
read SHIPPER

echo -n "Warehouse address: "
read WAREHOUSE

echo -n "SensorOracle address: "
read SENSOR_ORACLE

echo -n "Auditor address: "
read AUDITOR

echo -n "RoleManager address: "
read ROLE_MANAGER

echo ""
echo "Setting contract addresses..."

# Send addresses to API server
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
    echo "Run API tests to verify configuration:"
    echo "./scripts/test-api.sh"
else
    echo ""
    echo "ERROR: Configuration failed. Check if API server is running:"
    echo "npm run server"
fi
