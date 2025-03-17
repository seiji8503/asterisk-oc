#!/bin/bash
# Script to update Asterisk configuration files and reload services
# Created for Nelson on March 16, 2025

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo"
  exit 1
fi

# Define colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Define file paths
CONFIG_DIR="/home/opc"
ASTERISK_DIR="/etc/asterisk"
PJSIP_FILE="pjsip.conf"
EXTENSIONS_FILE="extensions.conf"

# Function to update a configuration file
update_config() {
  local file=$1
  
  # Check if source file exists
  if [ ! -f "${CONFIG_DIR}/${file}" ]; then
    echo -e "${RED}Error: Source file ${CONFIG_DIR}/${file} not found${NC}"
    return 1
  fi
  
  # Backup existing file if it exists
  if [ -f "${ASTERISK_DIR}/${file}" ]; then
    cp "${ASTERISK_DIR}/${file}" "${ASTERISK_DIR}/${file}.bak.$(date +%Y%m%d%H%M%S)"
    echo -e "${YELLOW}Backup created: ${ASTERISK_DIR}/${file}.bak.$(date +%Y%m%d%H%M%S)${NC}"
  fi
  
  # Copy the file
  cp "${CONFIG_DIR}/${file}" "${ASTERISK_DIR}/${file}"
  
  # Set ownership and permissions
  chown asterisk:asterisk "${ASTERISK_DIR}/${file}"
  chmod 640 "${ASTERISK_DIR}/${file}"
  
  echo -e "${GREEN}Updated ${file} successfully${NC}"
  return 0
}

# Function to reload Asterisk configuration
reload_asterisk() {
  echo "Reloading Asterisk configurations..."
  
  # Reload dialplan
  if asterisk -rx "dialplan reload" > /dev/null 2>&1; then
    echo -e "${GREEN}Dialplan reloaded successfully${NC}"
  else
    echo -e "${RED}Failed to reload dialplan${NC}"
  fi
  
  # Reload PJSIP
  if asterisk -rx "pjsip reload" > /dev/null 2>&1; then
    echo -e "${GREEN}PJSIP reloaded successfully${NC}"
  else
    echo -e "${RED}Failed to reload PJSIP${NC}"
  fi
}

echo "===== Asterisk Configuration Update ====="
echo "Starting update at $(date)"

# Update pjsip.conf
echo "Updating PJSIP configuration..."
update_config "$PJSIP_FILE"
PJSIP_RESULT=$?

# Update extensions.conf
echo "Updating Extensions configuration..."
update_config "$EXTENSIONS_FILE"
EXTENSIONS_RESULT=$?

# Reload Asterisk if any configuration was updated successfully
if [ $PJSIP_RESULT -eq 0 ] || [ $EXTENSIONS_RESULT -eq 0 ]; then
  reload_asterisk
else
  echo -e "${RED}No configurations were updated. Skipping reload.${NC}"
fi

echo "Update completed at $(date)"
echo "====================================="