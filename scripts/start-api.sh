#!/bin/bash

# =============================================================================
# API SERVER STARTUP SCRIPT
# =============================================================================
#
# Purpose: Start the Cake Supply Chain API server with dependency checks
# 
# Description:
#   This script automates the startup process for the API server by checking
#   for dependencies, compiling contracts if needed, and starting the server.
#   It provides a one-command startup solution.
#
# Prerequisites:
#   - Node.js and npm must be installed
#   - Project must be in the correct directory
#
# Usage:
#   ./scripts/start-api.sh
#
# Input: None
# Output: Running API server on localhost:3000
#
# Features:
#   - Automatic dependency installation
#   - Contract compilation check
#   - Server startup with status feedback
#
# Author: Lilla Guo
# =============================================================================

echo "Starting Cake Supply Chain API..."

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install
fi

# Check if build directory exists
if [ ! -d "build" ]; then
    echo "Compiling contracts..."
    npm run compile
fi

# Start the API server
echo "Starting API server..."
npm run server
