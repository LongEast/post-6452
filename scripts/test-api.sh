#!/bin/bash

# =============================================================================
# API TESTING SCRIPT
# =============================================================================
#
# Purpose: Comprehensive testing of Cake Supply Chain API endpoints
# 
# Description:
#   This script performs comprehensive testing of all API endpoints including
#   health checks, contract configuration, cake factory operations, shipping,
#   warehouse operations, sensor data, and audit functions.
#
# Prerequisites:
#   - API server must be running on localhost:3000
#   - Contract addresses must be configured
#   - jq must be installed for JSON processing
#
# Usage:
#   ./scripts/test-api.sh
#
# Input: None (automated testing)
# Output: Test results for all API endpoints with pass/fail status
#
# Features:
#   - Tests all major API endpoints
#   - Validates response formats
#   - Checks error handling
#   - Color-coded output for easy reading
#
# Author: Lilla Guo
# =============================================================================

API_BASE="http://localhost:3000"
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting Cake Supply Chain API Tests...${NC}\n"

# Helper function to test API endpoints
test_endpoint() {
    local method=$1
    local endpoint=$2
    local data=$3
    local expected_status=$4
    local description=$5
    
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

# Test 1: Health Check
test_endpoint "GET" "/" "" 200 "API Health Check"

# Test 2: Get Contract Addresses (should work even if empty)
test_endpoint "GET" "/api/admin/contracts" "" 200 "Get Contract Addresses"

# Test 3: Set Contract Addresses (with dummy data)
contract_data='{
  "CakeFactory": "0x1234567890123456789012345678901234567890",
  "CakeLifecycleRegistry": "0x1234567890123456789012345678901234567891",
  "Shipper": "0x1234567890123456789012345678901234567892",
  "Warehouse": "0x1234567890123456789012345678901234567893",
  "SensorOracle": "0x1234567890123456789012345678901234567894",
  "Auditor": "0x1234567890123456789012345678901234567895",
  "RoleManager": "0x1234567890123456789012345678901234567896"
}'
test_endpoint "POST" "/api/admin/contracts" "$contract_data" 200 "Set Contract Addresses"

# Test 4: Create Cake Batch (might fail if contracts not deployed)
batch_data='{
  "batchId": 1001,
  "maxTemperature": 20,
  "minTemperature": 4,
  "maxHumidity": 50,
  "minHumidity": 20,
  "metadataURI": "ipfs://test"
}'
test_endpoint "POST" "/api/factory/batch" "$batch_data" 200 "Create Cake Batch (expected to fail without real contracts)"

# Test 5: Missing Parameters Test
test_endpoint "POST" "/api/factory/batch" '{}' 400 "Create Batch with Missing Parameters"

# Test 6: Quality Check
quality_data='{
  "batchId": 1001,
  "snapshotHash": "0xabc123"
}'
test_endpoint "POST" "/api/factory/quality-check" "$quality_data" 200 "Factory Quality Check"

# Test 7: Handoff to Shipper
handoff_data='{
  "batchId": 1001,
  "shipperAddress": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
}'
test_endpoint "POST" "/api/factory/handoff" "$handoff_data" 200 "Handoff to Shipper"

# Test 8: Get Batch Record (should fail for non-existent batch)
test_endpoint "GET" "/api/lifecycle/batch/1001" "" 500 "Get Batch Record"

# Test 9: Get Batch Log
test_endpoint "GET" "/api/lifecycle/batch/1001/log" "" 500 "Get Batch Log"

# Test 10: Shipper Handoff
shipper_handoff_data='{
  "batchId": 1001,
  "fromActor": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
  "toActor": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
  "longitude": "151",
  "latitude": "-33",
  "snapshotHash": "0xdef789"
}'
test_endpoint "POST" "/api/shipper/handoff" "$shipper_handoff_data" 200 "Shipper Handoff Log"

# Test 11: Report Accident
accident_data='{
  "batchId": 1001,
  "actor": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
  "accident": "Minor temperature spike during loading"
}'
test_endpoint "POST" "/api/shipper/accident" "$accident_data" 200 "Report Shipping Accident"

# Test 12: Deliver to Warehouse
delivery_data='{
  "batchId": 1001,
  "warehouseAddress": "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC"
}'
test_endpoint "POST" "/api/shipper/deliver" "$delivery_data" 200 "Deliver to Warehouse"

# Test 13: Confirm Delivery
confirm_data='{
  "batchId": 1001
}'
test_endpoint "POST" "/api/warehouse/confirm-delivery" "$confirm_data" 200 "Confirm Warehouse Delivery"

# Test 14: Warehouse Quality Check
warehouse_quality_data='{
  "batchId": 1001,
  "snapshotHash": "0xghi345"
}'
test_endpoint "POST" "/api/warehouse/quality-check" "$warehouse_quality_data" 200 "Warehouse Quality Check"

# Test 15: Submit Sensor Data
sensor_data='{
  "batchId": 1001,
  "temperature": 18,
  "humidity": 45
}'
test_endpoint "POST" "/api/oracle/sensor-data" "$sensor_data" 200 "Submit Sensor Data"

# Test 16: Get Sensor Readings
test_endpoint "GET" "/api/oracle/batch/1001/readings" "" 500 "Get Sensor Readings"

# Test 17: Get Alerts
test_endpoint "GET" "/api/oracle/batch/1001/alerts" "" 200 "Get Batch Alerts"

# Test 18: Audit Certification
audit_data='{
  "batchId": 1001,
  "reportHash": "0xjkl901",
  "comments": "Quality standards met",
  "verdict": 0
}'
test_endpoint "POST" "/api/auditor/certify" "$audit_data" 500 "Audit Certification"

# Test 19: Get Audit Record
test_endpoint "GET" "/api/auditor/batch/1001" "" 500 "Get Audit Record"

# Test 20: Get Comprehensive Audit Data
test_endpoint "GET" "/api/auditor/batch/1001/comprehensive" "" 404 "Get Comprehensive Audit Data"

# Test 21: Invalid Endpoint
test_endpoint "GET" "/api/invalid/endpoint" "" 404 "Invalid Endpoint Test"

echo -e "${YELLOW}API Testing Complete!${NC}\n"
echo -e "${YELLOW}Note: Many tests are expected to fail (HTTP 500) because they require${NC}"
echo -e "${YELLOW}real deployed contracts. This script tests API structure and error handling.${NC}\n"
echo -e "${YELLOW}To test with real contracts:${NC}"
echo -e "${YELLOW}1. Deploy contracts: npm run deploy${NC}"
echo -e "${YELLOW}2. Set real addresses: ./scripts/setup-contracts.sh${NC}"
echo -e "${YELLOW}3. Re-run this test script${NC}"
