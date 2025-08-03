#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
API_BASE="http://localhost:3000"
GANACHE_PORT=8546
API_PORT=3500

# PIDs to track background processes
GANACHE_PID=""
API_PID=""

# Cleanup function
cleanup() {
    echo -e "\n${YELLOW}Cleaning up background processes...${NC}"
    
    if [ ! -z "$API_PID" ] && kill -0 $API_PID 2>/dev/null; then
        echo "Stopping API server (PID: $API_PID)"
        kill $API_PID 2>/dev/null || true
        wait $API_PID 2>/dev/null || true
    fi
    
    if [ ! -z "$GANACHE_PID" ] && kill -0 $GANACHE_PID 2>/dev/null; then
        echo "Stopping Ganache (PID: $GANACHE_PID)"
        kill $GANACHE_PID 2>/dev/null || true
        wait $GANACHE_PID 2>/dev/null || true
    fi
    
    # Kill any remaining processes on our ports
    lsof -ti:$GANACHE_PORT | xargs kill -9 2>/dev/null || true
    lsof -ti:$API_PORT | xargs kill -9 2>/dev/null || true
    
    echo -e "${GREEN}Cleanup complete${NC}"
}

# Set trap to cleanup on exit
trap cleanup EXIT INT TERM

# Function to wait for service
wait_for_service() {
    local url="$1"
    local service_name="$2"
    local max_attempts=30
    local attempt=1
    
    echo -n "Waiting for $service_name to be ready"
    while [ $attempt -le $max_attempts ]; do
        if [ "$service_name" = "Ganache" ]; then
            # For Ganache, check if port is listening
            if nc -z localhost $GANACHE_PORT 2>/dev/null; then
                echo -e " ${GREEN}READY${NC}"
                return 0
            fi
        else
            # For API, use curl
            if curl -s -f "$url" > /dev/null 2>&1; then
                echo -e " ${GREEN}READY${NC}"
                return 0
            fi
        fi
        echo -n "."
        sleep 1
        attempt=$((attempt + 1))
    done
    
    echo -e " ${RED}FAILED${NC}"
    echo -e "${RED}ERROR: $service_name failed to start after $max_attempts seconds${NC}"
    return 1
}

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
        return 0
    else
        echo -e "   ${RED}FAIL${NC} (Expected HTTP $expected_status, got $http_code)"
        if [ ! -z "$body" ]; then
            echo "   Response: $(echo $body | jq -c . 2>/dev/null || echo $body)"
        fi
        return 1
    fi
}

echo -e "${MAGENTA}================================================${NC}"
echo -e "${MAGENTA}    CAKE SUPPLY CHAIN - FULL E2E TEST         ${NC}"
echo -e "${MAGENTA}================================================${NC}\n"

# Step 1: Install Dependencies
echo -e "${BLUE}Step 1: Installing Dependencies...${NC}"
if [ ! -d "node_modules" ]; then
    npm install
    echo -e "${GREEN}Dependencies installed${NC}\n"
else
    echo -e "${GREEN}Dependencies already installed${NC}\n"
fi

# Step 2: Setup Accounts
echo -e "${BLUE}Step 2: Setting up Accounts...${NC}"
# Create accounts.json with Ganache's standard deterministic accounts
cat > eth_accounts/accounts.json << 'EOF'
{
  "_comment": "Standard Ganache deterministic accounts for testing",
  "_note": "These accounts match the test mnemonic - DO NOT use on real networks",
  "_setup": "Standard Ganache accounts (mnemonic: test test test test test test test test test test test junk)",
  "acc0": { 
    "pvtKey": "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
    "address": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
  },
  "acc1": { 
    "pvtKey": "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d",
    "address": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
  },
  "acc2": { 
    "pvtKey": "0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a",
    "address": "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC"
  }
}
EOF
echo -e "${GREEN}Accounts configured with Ganache deterministic addresses${NC}\n"

# Step 3: Start Ganache
echo -e "${BLUE}Step 3: Starting Ganache Blockchain...${NC}"
# Kill any existing ganache process
lsof -ti:$GANACHE_PORT | xargs kill -9 2>/dev/null || true
sleep 2

npx ganache \
    --port $GANACHE_PORT \
    --accounts 10 \
    --mnemonic "test test test test test test test test test test test junk" \
    --gasLimit 12000000 \
    --gasPrice 20000000000 > ganache.log 2>&1 &

GANACHE_PID=$!
echo "Ganache started with PID: $GANACHE_PID"

# Wait for Ganache to be ready
wait_for_service "localhost:$GANACHE_PORT" "Ganache"

# Step 4: Compile Contracts
echo -e "${BLUE}Step 4: Compiling Smart Contracts...${NC}"
npm run compile
echo -e "${GREEN}Contracts compiled${NC}\n"

# Step 5: Deploy Contracts
echo -e "${BLUE}Step 5: Deploying Smart Contracts...${NC}"
# Use the accounts we just created
ADMIN_ADDR=$(jq -r '.["acc0"].address' eth_accounts/accounts.json)
SENSOR_ADDR=$(jq -r '.["acc1"].address' eth_accounts/accounts.json)
echo "Using admin address: $ADMIN_ADDR"
echo "Using sensor address: $SENSOR_ADDR"
npx ts-node backend/src/deployAll.ts deploy acc0 "$ADMIN_ADDR" "$SENSOR_ADDR" | tee deployment_log.txt
echo -e "${GREEN}Contracts deployed${NC}\n"

# Step 6: Start API Server
echo -e "${BLUE}Step 6: Starting API Server...${NC}"
# Clean up any existing database and processes thoroughly
find . -name "*.db" -delete 2>/dev/null || true
find . -name "blockchain.db*" -delete 2>/dev/null || true
rm -f backend/blockchain.db backend/database.db 2>/dev/null || true
lsof -ti:$API_PORT | xargs kill -9 2>/dev/null || true
sleep 3

npm run server > api.log 2>&1 &
API_PID=$!
echo "API Server started with PID: $API_PID"

# Wait longer for API to be ready and check initialization
sleep 5
wait_for_service "$API_BASE" "API Server"

# Step 7: Configure Contract Addresses
echo -e "${BLUE}Step 7: Configuring Contract Addresses...${NC}"
# Extract contract addresses from deployment output
ROLE_MANAGER=$(grep "RoleManager.*→" deployment_log.txt | awk '{print $NF}')
REGISTRY=$(grep "CakeLifecycleRegistry.*→" deployment_log.txt | awk '{print $NF}')
FACTORY=$(grep "CakeFactory.*→" deployment_log.txt | awk '{print $NF}')
SHIPPER=$(grep "Shipper.*→" deployment_log.txt | awk '{print $NF}')
WAREHOUSE=$(grep "Warehouse.*→" deployment_log.txt | awk '{print $NF}')
ORACLE=$(grep "SensorOracle.*→" deployment_log.txt | awk '{print $NF}')
AUDITOR=$(grep "Auditor.*→" deployment_log.txt | awk '{print $NF}')

CONTRACTS_JSON="{
  \"RoleManager\": \"$ROLE_MANAGER\",
  \"CakeLifecycleRegistry\": \"$REGISTRY\",
  \"CakeFactory\": \"$FACTORY\",
  \"Shipper\": \"$SHIPPER\",
  \"Warehouse\": \"$WAREHOUSE\",
  \"SensorOracle\": \"$ORACLE\",
  \"Auditor\": \"$AUDITOR\"
}"

echo "Setting contract addresses:"
echo "$CONTRACTS_JSON" | jq .

# Set contract addresses via API
curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "$CONTRACTS_JSON" \
    "$API_BASE/api/admin/contracts" | jq .

echo -e "\n${GREEN}Contract addresses configured${NC}\n"

# Step 8: Run Comprehensive Tests
echo -e "${BLUE}Step 8: Running Comprehensive Tests...${NC}\n"

# Generate unique batch ID to avoid conflicts
BATCH_ID=$((RANDOM % 9000 + 1000))
echo -e "${CYAN}Using batch ID: $BATCH_ID${NC}\n"

TOTAL_TESTS=15
PASSED_TESTS=0

# Test 1: Health Check
if test_endpoint "GET" "/" "" 200 "API Health Check"; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
fi
echo ""

# Test 2: Get Contract Addresses (Dynamic)
if test_endpoint "GET" "/api/admin/contracts" "" 200 "Get Contract Addresses"; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
    # Store contract addresses for later use
    CONTRACTS_RESPONSE=$(curl -s http://localhost:3000/api/admin/contracts)
    SHIPPER_ADDRESS=$(echo $CONTRACTS_RESPONSE | jq -r '.addresses.Shipper')
    WAREHOUSE_ADDRESS=$(echo $CONTRACTS_RESPONSE | jq -r '.addresses.Warehouse')
    FACTORY_ADDRESS=$(echo $CONTRACTS_RESPONSE | jq -r '.addresses.CakeFactory')
    
    echo -e "${CYAN}   Dynamically retrieved contract addresses:${NC}"
    echo -e "${CYAN}   Factory: $FACTORY_ADDRESS${NC}"
    echo -e "${CYAN}   Shipper: $SHIPPER_ADDRESS${NC}"
    echo -e "${CYAN}   Warehouse: $WAREHOUSE_ADDRESS${NC}"
fi
echo ""

# Test 3: Create Cake Batch
batch_data="{
  \"batchId\": $BATCH_ID,
  \"maxTemperature\": 20,
  \"minTemperature\": -5,
  \"maxHumidity\": 50,
  \"minHumidity\": 20,
  \"metadataURI\": \"ipfs://e2e-test-$BATCH_ID\"
}"
if test_endpoint "POST" "/api/factory/batch" "$batch_data" 200 "Create Cake Batch"; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
fi
echo ""

# Test 4: Get Batch Record
if test_endpoint "GET" "/api/lifecycle/batch/$BATCH_ID" "" 200 "Get Batch Record"; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
fi
echo ""

# Test 5: Get Batch Log
if test_endpoint "GET" "/api/lifecycle/batch/$BATCH_ID/log" "" 200 "Get Batch Log"; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
fi
echo ""

# Test 6: Submit Invalid Sensor Data

# A: set shipment
SHIPPER_ADDRESS=$(echo $CONTRACTS_RESPONSE | jq -r '.addresses.Shipper')
shipment_body="{\"shipmentAddr\":\"$SHIPPER_ADDRESS\"}"
if test_endpoint "POST" "/api/oracle/set-shipment" "$shipment_body" 200 "Set Shipment Address"; then
    PASSED_TESTS=$((PASSED_TESTS+1))
fi
echo ""

ORACLE_ADDRESS=$(echo $CONTRACTS_RESPONSE | jq -r '.addresses.SensorOracle')
oracle_body="{\"oracleAddr\":\"$ORACLE_ADDRESS\"}"
test_endpoint "POST" "/api/shipper/set-oracle" "$oracle_body" 200 "Set Oracle Address"



# --------------------  Should flag -----------------------------

batch_data="{
  \"batchId\": 1002,
  \"maxTemperature\": 20,
  \"minTemperature\": -5,
  \"maxHumidity\": 50,
  \"minHumidity\": 20,
  \"metadataURI\": \"ipfs://e2e-test-$1002\"
}"
if test_endpoint "POST" "/api/factory/batch" "$batch_data" 200 "Create Cake Batch"; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
fi
echo ""

# 1
sensor_data="{
  \"batchId\": 1002,
  \"temperature\": -10,
  \"humidity\": 60
}"
if test_endpoint "POST" "/api/oracle/sensor-data" "$sensor_data" 200 "Submit Sensor Invalid Data 1"; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
fi
echo ""

# 2
sensor_data="{
  \"batchId\": 1002,
  \"temperature\": -6,
  \"humidity\": 60
}"
if test_endpoint "POST" "/api/oracle/sensor-data" "$sensor_data" 200 "Submit Sensor Invalid Data 2"; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
fi
echo ""

# 3
sensor_data="{
  \"batchId\": 1002,
  \"temperature\": -10,
  \"humidity\": 60
}"
if test_endpoint "POST" "/api/oracle/sensor-data" "$sensor_data" 200 "Submit Sensor Invalid Data 3"; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
fi
echo ""

# Should flag
if test_endpoint "GET" "/api/lifecycle/batch/$BATCH_ID" "" 200 "Check Batch Flag"; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
fi
echo ""




# --------------------  Should not flag -----------------------------

# Create Batch
batch_data="{
  \"batchId\": 1004,
  \"maxTemperature\": 20,
  \"minTemperature\": -5,
  \"maxHumidity\": 50,
  \"minHumidity\": 20,
  \"metadataURI\": \"ipfs://e2e-test-1004\"
}"
if test_endpoint "POST" "/api/factory/batch" "$batch_data" 200 "Create Cake Batch"; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
fi
echo ""

# 1
sensor_data="{
  \"batchId\": 1004,
  \"temperature\": -10,
  \"humidity\": 60
}"
if test_endpoint "POST" "/api/oracle/sensor-data" "$sensor_data" 200 "Submit Sensor Invalid Data 1"; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
fi
echo ""

# 2
sensor_data="{
  \"batchId\": 1004,
  \"temperature\": -6,
  \"humidity\": 60
}"
if test_endpoint "POST" "/api/oracle/sensor-data" "$sensor_data" 200 "Submit Sensor Invalid Data 2"; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
fi
echo ""

# 3
sensor_data="{
  \"batchId\": 1004,
  \"temperature\": 14,
  \"humidity\": 46
}"
if test_endpoint "POST" "/api/oracle/sensor-data" "$sensor_data" 200 "Submit Sensor Valid! Data 3"; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
fi
echo ""

# Should flag
if test_endpoint "GET" "/api/lifecycle/batch/1004" "" 200 "Check Batch No Flag"; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
fi
echo ""