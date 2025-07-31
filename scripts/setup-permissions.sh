#!/bin/bash

# =============================================================================
# SETUP SCRIPT PERMISSIONS
# =============================================================================
#
# Purpose: Set execute permissions for all scripts in the project
# 
# Usage:
#   ./scripts/setup-permissions.sh
#   
# Or if this script doesn't have permissions:
#   chmod +x scripts/setup-permissions.sh && ./scripts/setup-permissions.sh
#
# Author: Lilla Guo
# =============================================================================

echo "Setting up script permissions..."

# Set permissions for all shell scripts in the scripts directory
chmod +x scripts/*.sh

echo "Script permissions set successfully!"
echo ""
echo "You can now run:"
echo "  ./scripts/full-e2e-test.sh"
echo ""
