#!/bin/bash

# --- CONFIGURATION ---
DOMAIN="getvanish.io" # Your domain from Terraform
INTERVAL=2            # Seconds between checks

echo "🚀 Starting High-Availability Monitor for $DOMAIN"
echo "Press [CTRL+C] to stop."
echo "--------------------------------------------------------"

while true; do
    # 1. Check DNS Resolution
    # We use +short to get just the IP or ALB DNS name
    DNS_TARGET=$(dig +short "$DOMAIN" | tail -n1)
    
    # 2. Check Web Content & Region
    # -s: Silent mode
    # -L: Follow redirects (important for HTTPS)
    # --max-time: Don't get stuck if the site is down
    # grep: Look for the Region name in your HTML (e.g., "VIRGINIA" or "LONDON")
    RESPONSE=$(curl -sL --max-time 3 "http://$DOMAIN")
    
    # Identify region based on your index.php content
    if echo "$RESPONSE" | grep -q "VIRGINIA"; then
        REGION="🇺🇸 PRIMARY (VIRGINIA)"
    elif echo "$RESPONSE" | grep -q "LONDON"; then
        REGION="🇬🇧 SECONDARY (LONDON)"
    elif [[ -z "$RESPONSE" ]]; then
        REGION="❌ SITE DOWN (Connection Timeout)"
    else
        REGION="⚠️ UNKNOWN/503 ERROR"
    fi

    # 3. Output Results
    TIME=$(date +%H:%M:%S)
    if [ -z "$DNS_TARGET" ]; then
        echo "[$TIME] DNS: [NOT FOUND] | App: $REGION"
    else
        echo "[$TIME] DNS: [$DNS_TARGET] | App: $REGION"
    fi

    sleep $INTERVAL
done