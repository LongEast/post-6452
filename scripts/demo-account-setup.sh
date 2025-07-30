#!/bin/bash

# Demo script to show how new users get private keys with one command
# Author: Lilla Guo

echo "=== Demo: How new users get private keys with one command ==="
echo

echo "1. New user clones the project and sees:"
echo "   - eth_accounts/accounts.example.json (template with private keys)"
echo "   - eth_accounts/accounts.json is missing (ignored by git)"
echo

echo "2. Template file contains:"
cat eth_accounts/accounts.example.json
echo

echo "3. User runs ONE COMMAND:"
echo "   cp eth_accounts/accounts.example.json eth_accounts/accounts.json"
echo

echo "4. Now user has working private key configuration!"
echo "   ✅ Ready to deploy contracts"
echo "   ✅ Works with standard Ganache"
echo "   ✅ No manual editing needed"
echo

echo "=== The private keys they get: ==="
echo "acc0: 0x4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d"
echo "acc1: 0x6cbed15c793ce57650b9877cf6fa156fbef513c4e6134f022a85b1ffdd59b2a1"
echo

echo "=== Corresponding addresses: ==="
echo "acc0: 0x90F79bf6EB2c4f870365E785982E1f101E93b906"
echo "acc1: 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65"
echo

echo "=== Security: ==="
echo "✅ accounts.json is in .gitignore (won't be committed)"
echo "✅ accounts.example.json is tracked (available to new users)"
echo "✅ Standard keys are safe for local development only"
