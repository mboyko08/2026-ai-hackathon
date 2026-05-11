#!/usr/bin/env bash
set -euo pipefail

# Azure PostgreSQL OLTP source database provisioning script
# Database: db-oltp-pfl-1

RESOURCE_GROUP="${RESOURCE_GROUP:-rg-cdc-hackathon}"
LOCATION="${LOCATION:-westus}"
SERVER_NAME="${SERVER_NAME:-psql-oltp-pfl-1}"
DB_NAME="db-oltp-pfl-1"
SKU="${SKU:-Standard_B1ms}"
TIER="${TIER:-Burstable}"
PG_VERSION="${PG_VERSION:-17}"
ADMIN_USER="${ADMIN_USER:-pgadmin}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:?ADMIN_PASSWORD env var is required}"

echo "==> Creating resource group: $RESOURCE_GROUP in $LOCATION"
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --output none

echo "==> Creating Azure Database for PostgreSQL Flexible Server: $SERVER_NAME"
az postgres flexible-server create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$SERVER_NAME" \
  --location "$LOCATION" \
  --admin-user "$ADMIN_USER" \
  --admin-password "$ADMIN_PASSWORD" \
  --sku-name "$SKU" \
  --tier "$TIER" \
  --version "$PG_VERSION" \
  --public-access 0.0.0.0 \
  --storage-size 32 \
  --output none

echo "==> Creating database: $DB_NAME on server $SERVER_NAME"
az postgres flexible-server db create \
  --resource-group "$RESOURCE_GROUP" \
  --server-name "$SERVER_NAME" \
  --database-name "$DB_NAME" \
  --output none

echo "==> Enabling logical replication (required for CDC)"
az postgres flexible-server parameter set \
  --resource-group "$RESOURCE_GROUP" \
  --server-name "$SERVER_NAME" \
  --name wal_level \
  --value logical \
  --output none

echo ""
echo "Done."
echo "  Server:   $SERVER_NAME.postgres.database.azure.com"
echo "  Database: $DB_NAME"
echo "  User:     $ADMIN_USER"
echo ""
echo "Connection string:"
echo "  postgresql://$ADMIN_USER:<password>@$SERVER_NAME.postgres.database.azure.com/$DB_NAME?sslmode=require"
echo ""

# ------------------------------------------------------------
# Apply schema (tables + stored procedure)
# ------------------------------------------------------------
SCHEMA_FILE="$(dirname "$0")/schema/01-postgresql-oltp-schema.sql"
if [[ -f "$SCHEMA_FILE" ]]; then
  echo "==> Applying schema from $SCHEMA_FILE"
  PGPASSWORD="$ADMIN_PASSWORD" psql \
    "postgresql://$ADMIN_USER@$SERVER_NAME.postgres.database.azure.com/$DB_NAME?sslmode=require" \
    -f "$SCHEMA_FILE"
  echo "==> Schema applied successfully"
else
  echo "WARNING: Schema file not found at $SCHEMA_FILE — skipping"
fi
