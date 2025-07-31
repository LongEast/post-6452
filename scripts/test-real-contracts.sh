#!/bin/bash

# =============================================================================
# REAL CONTRACT TESTING SCRIPT
# =============================================================================
#
# Purpose: Test all API endpoints with real deployed contracts
# 
# Description:
#   This script tests all API functionality using real deployed contracts,
#   providing a comprehensive end-to-end validation of the system.
#
# Prerequisites:
#   - API server running on localhost:3000
#   - Real contracts deployed and configured
#   - jq installed for JSON processing
#
# Usage:
#   ./scripts/test-real-contracts.sh
#
# Author: AI Assistant
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

API_BASE="http://localhost:3000"

# Function to test an endpoint
test_endpoint() {
    local method="$1"
    local endpoint="$2"
    local data="$3"
    local expected_status="$4"
    local description="$5"
    
    echo -e "${YELLOW}Testing: $description${NC}"
    echo "   $method $endpoint"
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$API_BASE$endpoint")
    else
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X "$method" \
            -H "Content-Type: application/json" \
            -d "$data" \
            "$API_BASE$endpoint")
    fi
    
    http_code=$(echo $response | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    body=$(echo $response | sed -E 's/HTTPSTATUS:[0-9]{3}$//')
    
    if [ "$http_code" -eq "$expected_status" ]; then
        echo -e "   ${GREEN}PASS${NC} (HTTP $http_code)"
        if [ ! -z "$body" ]; then
            echo "   Response: $(echo $body | jq -c . 2>/dev/null || echo $body)"
        fi
    else
        echo -e "   ${RED}FAIL${NC} (Expected HTTP $expected_status, got $http_code)"
        if [ ! -z "$body" ]; then
            echo "   Response: $(echo $body | jq -c . 2>/dev/null || echo $body)"
        fi
    fi
    echo ""
}

echo -e "${BLUE}Testing Cake Supply Chain API with Real Contracts${NC}\n"

# Check if API is running
if ! curl -s -f http://localhost:3000/ > /dev/null 2>&1; then
    echo -e "${RED}ERROR: API server is not running. Please start it first:${NC}"
    echo "   npm run server"
    exit 1
fi

echo -e "${GREEN}SUCCESS: API server is running${NC}\n"

# Generate unique batch ID to avoid conflicts
BATCH_ID=$((3000 + RANDOM % 1000))
echo -e "${BLUE}Using batch ID: $BATCH_ID${NC}\n"

# Test 1: Health Check
test_endpoint "GET" "/" "" 200 "API Health Check"

# Test 2: Get Contract Addresses
test_endpoint "GET" "/api/admin/contracts" "" 200 "Get Contract Addresses"

# Test 3: Create Cake Batch
batch_data="{
  \"batchId\": $BATCH_ID,
  \"maxTemperature\": 20,
  \"minTemperature\": -5,
  \"maxHumidity\": 50,
  \"minHumidity\": 20,
  \"metadataURI\": \"ipfs://test$BATCH_ID\"
}"
test_endpoint "POST" "/api/factory/batch" "$batch_data" 200 "Create Cake Batch"

# Test 4: Get Batch Record (should work now)
test_endpoint "GET" "/api/lifecycle/batch/$BATCH_ID" "" 200 "Get Batch Record"

# Test 5: Get Batch Log
test_endpoint "GET" "/api/lifecycle/batch/$BATCH_ID/log" "" 200 "Get Batch Log"

# Test 6: Quality Check
quality_data="{
  \"batchId\": $BATCH_ID,
  \"snapshotHash\": \"0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef\"
}"
test_endpoint "POST" "/api/factory/quality-check" "$quality_data" 200 "Factory Quality Check"

# Test 7: Submit Sensor Data
sensor_data="{
  \"batchId\": $BATCH_ID,
  \"temperature\": 15,
  \"humidity\": 35
}"
test_endpoint "POST" "/api/oracle/sensor-data" "$sensor_data" 200 "Submit Sensor Data"

# Test 8: Get Sensor Readings
test_endpoint "GET" "/api/oracle/batch/$BATCH_ID/readings" "" 200 "Get Sensor Readings"

# Test 9: Handoff to Shipper
# First get the current contract addresses to use real shipper address
CONTRACTS_RESPONSE=$(curl -s http://localhost:3000/api/admin/contracts)
SHIPPER_ADDRESS=$(echo $CONTRACTS_RESPONSE | jq -r '.addresses.Shipper')
WAREHOUSE_ADDRESS=$(echo $CONTRACTS_RESPONSE | jq -r '.addresses.Warehouse')

handoff_data="{
  \"batchId\": $BATCH_ID,
  \"shipperAddress\": \"$SHIPPER_ADDRESS\"
}"
test_endpoint "POST" "/api/factory/handoff" "$handoff_data" 200 "Handoff to Shipper"

# Test 10: Shipper Handoff Log
shipper_handoff_data="{
  \"batchId\": $BATCH_ID,
  \"fromActor\": \"0xaD888d0Ade988EbEe74B8D4F39BF29a8d0fe8A8D\",
  \"toActor\": \"$SHIPPER_ADDRESS\",
  \"longitude\": 151209300,
  \"latitude\": -33868800,
  \"snapshotHash\": \"0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890\"
}"
test_endpoint "POST" "/api/shipper/handoff" "$shipper_handoff_data" 200 "Shipper Handoff Log"

# Test 11: Deliver to Warehouse
deliver_data="{
  \"batchId\": $BATCH_ID,
  \"warehouseAddress\": \"$WAREHOUSE_ADDRESS\"
}"
test_endpoint "POST" "/api/shipper/deliver" "$deliver_data" 200 "Deliver to Warehouse"

# Test 12: Confirm Warehouse Delivery
confirm_data="{
  \"batchId\": $BATCH_ID
}"
test_endpoint "POST" "/api/warehouse/confirm-delivery" "$confirm_data" 200 "Confirm Warehouse Delivery"

# Test 13: Get Updated Batch Record
test_endpoint "GET" "/api/lifecycle/batch/$BATCH_ID" "" 200 "Get Updated Batch Record"

# Test 14: Get Comprehensive Audit Data
test_endpoint "GET" "/api/auditor/batch/$BATCH_ID/comprehensive" "" 200 "Get Comprehensive Audit Data"

# Test 15: Get Batch Alerts
test_endpoint "GET" "/api/oracle/batch/$BATCH_ID/alerts" "" 200 "Get Batch Alerts"

echo -e "${BLUE}Real Contract Testing Complete!${NC}"
echo -e "${GREEN}All tests completed with batch ID: $BATCH_ID${NC}"
echo ""
echo -e "${YELLOW}To view the complete lifecycle of this batch:${NC}"
echo "curl http://localhost:3000/api/auditor/batch/$BATCH_ID/comprehensive | jq ."
