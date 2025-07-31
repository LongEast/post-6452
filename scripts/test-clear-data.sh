#!/bin/bash

# Test script for clear data API functionality
# This demonstrates how to completely reset the database to brand new state

echo "Testing Clear Data API Functionality"
echo "========================================"

API_BASE="http://localhost:3000"

echo ""
echo "1. Testing without confirmation (should fail)..."
curl -X POST $API_BASE/api/admin/clear-data \
  -H "Content-Type: application/json" \
  -d '{"confirm": "wrong"}' \
  -w "\nHTTP Status: %{http_code}\n" 2>/dev/null

echo ""
echo "2. Testing with correct confirmation (should succeed)..."
curl -X POST $API_BASE/api/admin/clear-data \
  -H "Content-Type: application/json" \
  -d '{"confirm": "YES_CLEAR_ALL_DATA"}' \
  -w "\nHTTP Status: %{http_code}\n" 2>/dev/null

echo ""
echo "3. Verifying database is empty..."
curl -X GET $API_BASE/api/database/batches \
  -w "\nHTTP Status: %{http_code}\n" 2>/dev/null

echo ""
echo " Clear data API test completed!"
echo ""
echo " WARNING: If the API server was running, all database data has been cleared!"
echo "To restore test data, run: ./scripts/test-api.sh"
