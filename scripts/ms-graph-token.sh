#!/bin/bash
# Auto-refresh Microsoft Graph API token using client credentials flow.
# Usage: source scripts/ms-graph-token.sh
#        or: ACCESS_TOKEN=$(scripts/ms-graph-token.sh)
#
# Requires: AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, AZURE_TENANT_ID

set -euo pipefail

if [ -z "${AZURE_CLIENT_ID:-}" ] || [ -z "${AZURE_CLIENT_SECRET:-}" ] || [ -z "${AZURE_TENANT_ID:-}" ]; then
  echo "Error: AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, and AZURE_TENANT_ID must be set." >&2
  exit 1
fi

TOKEN_RESPONSE=$(curl -s -X POST \
  "https://login.microsoftonline.com/${AZURE_TENANT_ID}/oauth2/v2.0/token" \
  -d "client_id=${AZURE_CLIENT_ID}" \
  -d "client_secret=${AZURE_CLIENT_SECRET}" \
  -d "scope=https://graph.microsoft.com/.default" \
  -d "grant_type=client_credentials")

# Check for error in response
if echo "$TOKEN_RESPONSE" | grep -q '"error"'; then
  ERROR=$(echo "$TOKEN_RESPONSE" | grep -o '"error_description":"[^"]*"' | head -1)
  echo "Token request failed: $ERROR" >&2
  exit 1
fi

# Extract access token
ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"access_token":"[^"]*"' | sed 's/"access_token":"//;s/"$//')

if [ -z "$ACCESS_TOKEN" ]; then
  echo "Failed to extract access token from response." >&2
  exit 1
fi

# If sourced, export the variables. If executed, print the token.
if [ "${BASH_SOURCE[0]}" != "${0}" ] 2>/dev/null || [ "${ZSH_EVAL_CONTEXT:-}" = "toplevel:file" ] 2>/dev/null; then
  export ACCESS_TOKEN
  export MS_GRAPH_TOKEN="$ACCESS_TOKEN"
  echo "Graph API token refreshed successfully." >&2
else
  echo "$ACCESS_TOKEN"
fi
