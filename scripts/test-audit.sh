#!/bin/bash

# =============================================================================
# AUDIT FUNCTIONALITY TESTING SCRIPT
# =============================================================================
#
# Purpose: Test audit functionality for comprehensive batch data verification
# 
# Description:
#   This script tests the complete audit workflow including getting comprehensive
#   batch data, analyzing compliance, and submitting audit results. It simulates
#   the auditor's workflow for verifying cake batch quality and compliance.
#
# Prerequisites:
#   - API server must be running on localhost:3000
#   - Contract addresses must be configured
#   - jq must be installed for JSON processing
#   - Test batch data should exist (batch ID 1001)
#
# Usage:
#   ./scripts/test-audit.sh
#
# Input: None (uses predefined test batch ID 1001)
# Output: Audit test results and workflow demonstration
#
# Features:
#   - Tests comprehensive audit data retrieval
#   - Demonstrates compliance analysis
#   - Tests audit certification submission
#   - Validates audit record storage
#
# Author: Lilla Guo
# =============================================================================

echo "Audit Functionality Testing Script"
echo "=================================="
echo ""

# Check API server status
echo "1. Checking API server status..."
SERVER_STATUS=$(curl -s http://localhost:3000/ | jq -r '.status' 2>/dev/null)
if [ "$SERVER_STATUS" != "running" ]; then
    echo "ERROR: API server is not running. Please start the server first."
    echo "Run: npm run server"
    exit 1
fi
echo "API server is running"
echo ""

# Test batch ID
BATCH_ID=1001

echo "2. Testing comprehensive audit data retrieval..."
echo "GET /api/auditor/batch/$BATCH_ID/comprehensive"
echo ""

AUDIT_DATA=$(curl -s http://localhost:3000/api/auditor/batch/$BATCH_ID/comprehensive)
echo "Audit data response:"
echo "$AUDIT_DATA" | jq .
echo ""

# Check if data was retrieved successfully
if echo "$AUDIT_DATA" | grep -q '"success":true'; then
    echo "SUCCESS: Comprehensive audit data retrieved successfully"
    
    # Extract key information for analysis
    echo ""
    echo "3. Audit data analysis:"
    
    BATCH_STATUS=$(echo "$AUDIT_DATA" | jq -r '.batchRecord.status // "unknown"')
    IS_FLAGGED=$(echo "$AUDIT_DATA" | jq -r '.batchRecord.isFlagged // false')
    TEMP_COMPLIANCE=$(echo "$AUDIT_DATA" | jq -r '.complianceAnalysis.temperatureCompliance // "unknown"')
    HUMIDITY_COMPLIANCE=$(echo "$AUDIT_DATA" | jq -r '.complianceAnalysis.humidityCompliance // "unknown"')
    
    echo "- Batch Status: $BATCH_STATUS"
    echo "- Flagged: $IS_FLAGGED"
    echo "- Temperature Compliance: $TEMP_COMPLIANCE"
    echo "- Humidity Compliance: $HUMIDITY_COMPLIANCE"
    
    echo ""
    echo "4. Testing audit certification submission..."
    
    # Determine audit verdict based on compliance analysis
    if [ "$TEMP_COMPLIANCE" = "true" ] && [ "$HUMIDITY_COMPLIANCE" = "true" ] && [ "$IS_FLAGGED" = "false" ]; then
        VERDICT=0  # PASS
        COMMENTS="All compliance checks passed, batch quality meets standards"
    else
        VERDICT=2  # UNCLEAR - requires further review
        COMMENTS="Compliance issues detected, requires further review"
    fi
    
    echo "Submitting audit certification:"
    echo "POST /api/auditor/certify"
    
    AUDIT_RESULT=$(curl -s -X POST http://localhost:3000/api/auditor/certify \
      -H "Content-Type: application/json" \
      -d "{
        \"batchId\": $BATCH_ID,
        \"reportHash\": \"0x$(date +%s | sha256sum | cut -d' ' -f1)\",
        \"comments\": \"$COMMENTS\",
        \"verdict\": $VERDICT
      }")
    
    echo ""
    echo "Audit certification response:"
    echo "$AUDIT_RESULT" | jq .
    
    if echo "$AUDIT_RESULT" | grep -q '"success":true'; then
        echo ""
        echo "SUCCESS: Audit certification submitted successfully"
        
        echo ""
        echo "5. Verifying audit record storage..."
        echo "GET /api/auditor/batch/$BATCH_ID"
        
        AUDIT_RECORD=$(curl -s http://localhost:3000/api/auditor/batch/$BATCH_ID)
        echo ""
        echo "Stored audit record:"
        echo "$AUDIT_RECORD" | jq .
        
    else
        echo ""
        echo "ERROR: Audit certification submission failed"
    fi
    
else
    echo "INFO: Batch $BATCH_ID does not exist or has no data"
    echo "Recommendation: Create a test batch first:"
    echo ""
    echo "curl -X POST http://localhost:3000/api/factory/batch -H 'Content-Type: application/json' -d '{"
    echo "  \"batchId\": $BATCH_ID,"
    echo "  \"maxTemperature\": 20,"
    echo "  \"minTemperature\": -7,"
    echo "  \"maxHumidity\": 50,"
    echo "  \"minHumidity\": 20,"
    echo "  \"metadataURI\": \"ipfs://test-audit\""
    echo "}'"
fi

echo ""
echo "Audit functionality testing complete"
echo ""
echo "Available audit API endpoints:"
echo "- GET /api/auditor/batch/:batchId/comprehensive  # Get comprehensive audit data"
echo "- POST /api/auditor/certify                      # Submit audit certification"
echo "- GET /api/auditor/batch/:batchId                # Query audit record"
