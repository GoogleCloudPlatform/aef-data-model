#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Define variables using passed arguments
PROJECT_ID="$1"
REGION="$2"
INSTANCE_NAME="$3"

# Define file names and paths
PROXY_EXECUTABLE="cloud-sql-proxy"
SQL_SCRIPT_PATH="../fake-on-prem-postgresql/sample_db_populator.sql"
DB_CONNECTION_STRING="host=127.0.0.1 sslmode=disable dbname=postgres user=user1 password=changeme"

echo "Downloading Cloud SQL Proxy..."
ARCH=$(uname -m)
if [ "$ARCH" == "arm64" ]; then
  curl -o cloud-sql-proxy https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.9.0/cloud-sql-proxy.darwin.arm64
elif [ "$ARCH" == "x86_64" ]; then
  curl -o cloud-sql-proxy https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.15.2/cloud-sql-proxy.linux.amd64
else
  echo "Unsupported architecture: $ARCH"
  echo "Please download the appropriate Cloud SQL Proxy binary manually from:"
  exit 1
fi
echo "Making proxy executable..."
chmod +x "$PROXY_EXECUTABLE"

echo "Starting Cloud SQL Proxy in the background for instance: ${PROJECT_ID}:${REGION}:${INSTANCE_NAME}"
nohup ./"$PROXY_EXECUTABLE" "${PROJECT_ID}:${REGION}:${INSTANCE_NAME}" >/dev/null 2>&1 &

echo "Waiting for proxy to start..."
sleep 3

echo "Populating database..."
psql "$DB_CONNECTION_STRING" -f "$SQL_SCRIPT_PATH"

echo "Finding and killing Cloud SQL Proxy process..."
# Use pgrep for a potentially more robust way to find the process
# Search for the proxy based on its name and connection string argument
PROXY_PID=$(pgrep -f "cloud-sql-proxy.*${PROJECT_ID}:${REGION}:${INSTANCE_NAME}")

if [ -n "$PROXY_PID" ]; then
  echo "Killing proxy process with PID: $PROXY_PID"
  kill -9 "$PROXY_PID"
else
  echo "Could not find the Cloud SQL Proxy process. Skipping kill."
fi

echo "Database initialization complete."