#!/bin/bash
# Restore BloodHound CE databases from persistent storage
# Called from load_user_setup.sh on first container startup

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

SAVE_DIR="/opt/my-resources/setup/bloodhound/data"

# Check if we have saved data
if [ ! -f "$SAVE_DIR/pg_backup.sql" ]; then
    echo -e "${BLUE}[*]${NC} No BloodHound CE backup found, skipping restore"
    return 0 2>/dev/null || exit 0
fi

echo -e "${BLUE}[*]${NC} Restoring BloodHound CE databases..."

# Start PostgreSQL
service postgresql start 2>/dev/null
sleep 2

# Restore PostgreSQL - drop and recreate the database
echo -e "${BLUE}[*]${NC} Restoring PostgreSQL database..."
su - postgres -c "psql -c 'DROP DATABASE IF EXISTS bloodhound;'" 2>/dev/null
su - postgres -c "psql -c 'CREATE DATABASE bloodhound OWNER bloodhound;'" 2>/dev/null
if su - postgres -c "psql bloodhound" < "$SAVE_DIR/pg_backup.sql" >/dev/null 2>&1; then
    echo -e "${GREEN}[+]${NC} PostgreSQL database restored"
else
    echo -e "${RED}[-]${NC} PostgreSQL restore failed"
fi

# Restore Neo4j
if [ -d "$SAVE_DIR/neo4j_dump" ]; then
    echo -e "${BLUE}[*]${NC} Restoring Neo4j from dump..."
    neo4j stop 2>/dev/null
    sleep 2
    neo4j-admin database load neo4j --from-path="$SAVE_DIR/neo4j_dump" --overwrite-destination 2>/dev/null
    chown -R neo4j:neo4j /var/lib/neo4j/data 2>/dev/null
    neo4j start 2>/dev/null
    echo -e "${GREEN}[+]${NC} Neo4j database restored from dump"
elif [ -d "$SAVE_DIR/neo4j_data" ]; then
    echo -e "${BLUE}[*]${NC} Restoring Neo4j from data copy..."
    neo4j stop 2>/dev/null
    sleep 2
    rm -rf /var/lib/neo4j/data
    cp -a "$SAVE_DIR/neo4j_data" /var/lib/neo4j/data
    chown -R neo4j:neo4j /var/lib/neo4j/data 2>/dev/null
    neo4j start 2>/dev/null
    echo -e "${GREEN}[+]${NC} Neo4j database restored from data copy"
else
    echo -e "${BLUE}[*]${NC} No Neo4j backup found, skipping"
fi

# Stop services (bloodhound-ce script will start them when needed)
neo4j stop 2>/dev/null
service postgresql stop 2>/dev/null

echo -e "${GREEN}[+]${NC} BloodHound CE restore complete"
