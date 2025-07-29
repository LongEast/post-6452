#!/bin/bash

# Database setup script
# Check dependencies and initialize database

echo "Checking database dependencies..."

# Check if SQLite related dependencies are installed
if npm list sqlite sqlite3 @types/sqlite3 >/dev/null 2>&1; then
    echo "SQLite dependencies are already installed"
else
    echo "Installing SQLite related dependencies..."
    npm install sqlite sqlite3 @types/sqlite3
    echo "Dependencies installation completed"
fi

# Create data directory
mkdir -p backend/data

echo "Database setup completed"
echo "You can now run the server, database will initialize automatically"
echo ""
echo "Usage:"
echo "  npm run server    # Start server (auto-initialize database)"
