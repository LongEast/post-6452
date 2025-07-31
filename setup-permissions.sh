#!/bin/bash

# =============================================================================
# SETUP SCRIPT PERMISSIONS
# =============================================================================
#
# Purpose: Set execute permissions for all scripts in the project
# 
# Usage:
#   ./setup-permissions.sh
#   
# Or if this script doesn't have permissions:
#   chmod +x setup-permissions.sh && ./setup-permissions.sh
#
# =============================================================================

echo "Setting up script permissions..."

# Set permissions for all shell scripts
chmod +x scripts/*.sh
chmod +x *.sh

echo "✓ Script permissions set successfully!"
echo ""
echo "You can now run:"
echo "  ./scripts/full-e2e-test.sh"
echo ""
