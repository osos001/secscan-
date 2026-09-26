#!/bin/bash
# ==============================================================================
# Script Name: secscan.sh
# Developer: Youssef Tarek
# Description: Automated Network & Service Enumeration Tool
# ==============================================================================

# Check if target argument is provided
if [ -z "$1" ]; then
    echo "[!] Usage: $0 <TARGET_IP1> [TARGET_IP2 ...] OR $0 <targets_file.txt>"
    exit 1
fi

# ANSI Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Ensure required directories exist
mkdir -p reports

# Step 1: Check Dependencies
echo -e "${BLUE}[*] Checking dependencies...${NC}"
if command -v nmap >/dev/null 2>&1 && command -v ping >/dev/null 2>&1; then
    echo -e "${GREEN}[+] All dependencies available.${NC}"
else
    echo -e "${RED}[!] Missing required dependencies. Exiting.${NC}"
    exit 1
fi

# Parse targets (Check if input is a file or a list of IPs)
TARGETS=()
if [ -f "$1" ]; then
    # Read targets from file
    while IFS= read -r line; do
        [ -n "$line" ] && TARGETS+=("$line")
    done < "$1"
else
    # Read targets from arguments
    TARGETS=("$@")
fi

# Main Loop over each Target
for TARGET in "${TARGETS[@]}"; do
    echo -e "\n=================================================="
    echo -e "${BLUE}[*] Starting Scan for Target: ${TARGET}${NC}"
    echo -e "=================================================="

    # Step 2: Check Reachability
    echo -e "${BLUE}[*] Checking target reachability: ${TARGET}${NC}"
    if ! ping -c 1 -W 2 "$TARGET" > /dev/null 2>&1; then
        echo -e "${RED}[!] Target ${TARGET} is unreachable. Skipping.${NC}"
        continue
    fi
    echo -e "${GREEN}[+] Target is reachable.${NC}"

    # Step 3: Run Port Enumeration
    echo -e "${BLUE}[*] Running port and service enumeration...${NC}"
    echo -e "${GREEN}[+] Open ports discovered:${NC}"

    # Separate report files per target
    CLEAN_IP=$(echo "$TARGET" | tr '.' '_')
    SCAN_FILE="reports/scan_${CLEAN_IP}.txt"
    FINDINGS_FILE="reports/findings_${CLEAN_IP}.txt"
    SUMMARY_FILE="reports/summary_${CLEAN_IP}.txt"
    HTML_FILE="reports/report_${CLEAN_IP}.html"

    nmap -sV -F "$TARGET" -oN "$SCAN_FILE" | grep "open" | while read -r line; do
        echo "    $line"
    done

    # Step 4: Run Service Modules
    echo -e "${YELLOW}[*] Triggering service-specific modules...${NC}"

    echo "=== Service Enumeration Evidence ===" > "$FINDINGS_FILE"
    echo "Target: $TARGET | Date: $(date)" >> "$FINDINGS_FILE"

    grep "open" "$SCAN_FILE" | while read -r line; do
        SERVICE=$(echo "$line" | awk '{print $3}')

        if [ -f "modules/${SERVICE}.sh" ]; then
            echo -e "${GREEN}[+] Running module for: ${SERVICE}${NC}"
            bash "modules/${SERVICE}.sh" "$TARGET" >> "$FINDINGS_FILE" 2>&1
        fi
    done

    # Step 5: Generate Summary Reports
    {
        echo "Security Assessment Summary"
        echo "Target: $TARGET"
        echo "Date: $(date)"
        echo ""
        echo "Open Ports:"
        grep "open" "$SCAN_FILE"
    } > "$SUMMARY_FILE"

    # Export variables for envsubst HTML generation
    export TARGET
    export SCAN_DATE=$(date)
    export SCAN_DATA=$(grep "open" "$SCAN_FILE")
    export FINDINGS_DATA=$(cat "$FINDINGS_FILE")

    envsubst '$TARGET $SCAN_DATE $SCAN_DATA $FINDINGS_DATA' << 'EOF' > "$HTML_FILE"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Enumeration Report - $TARGET</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #0f172a; color: #f8fafc; margin: 0; padding: 40px; }
        .card { background: #1e293b; border-radius: 12px; padding: 25px; box-shadow: 0 10px 25px rgba(0,0,0,0.3); max-width: 900px; margin: 0 auto; border: 1px solid #334155; }
        h1 { color: #38bdf8; border-bottom: 2px solid #334155; padding-bottom: 10px; margin-top: 0; }
        h2 { color: #818cf8; margin-top: 25px; }
        .info { background: #0f172a; padding: 15px; border-radius: 8px; border-left: 4px solid #38bdf8; margin-bottom: 20px; }
        pre { background: #090d16; color: #4ade80; padding: 15px; border-radius: 8px; overflow-x: auto; font-family: 'Courier New', Courier, monospace; }
    </style>
</head>
<body>
    <div class="card">
        <h1>SecScan Security Assessment Report</h1>
        <div class="info">
            <p><strong>Target IP:</strong> $TARGET</p>
            <p><strong>Scan Date:</strong> $SCAN_DATE</p>
        </div>
        
        <h2>Discovered Ports & Services</h2>
        <pre>$SCAN_DATA</pre>

        <h2>Service Enumeration Evidence</h2>
        <pre>$FINDINGS_DATA</pre>
    </div>
</body>
</html>
EOF

    echo -e "${GREEN}[+] Scan for ${TARGET} completed. Report saved to ${HTML_FILE}${NC}"
done

echo ""
echo -e "${GREEN}[+] All scans finished successfully.${NC}"

