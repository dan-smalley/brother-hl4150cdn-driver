#!/bin/bash
#
# Uninstall the open-source Brother MFC-9460CDN CUPS driver.
#
set -euo pipefail

# Installation paths
LIB_DIR="/usr/local/lib/brmfc9460cdn"

# Detect OS-specific CUPS paths
CUPS_PPD_DIR="/usr/share/cups/model"
if [[ "$(uname)" == "Darwin" ]]; then
    CUPS_FILTER_DIR="/usr/libexec/cups/filter"
else
    CUPS_FILTER_DIR="/usr/lib/cups/filter"
fi

REMOVE_PRINTER=false

usage() {
    echo "Usage: $0 [--remove-printer]"
    echo ""
    echo "Options:"
    echo "  --remove-printer  Also remove the CUPS printer queue"
    echo ""
    echo "This script must be run with sudo."
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --remove-printer)
            REMOVE_PRINTER=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Check root
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run with sudo."
    exit 1
fi

echo "Uninstalling Brother MFC-9460CDN open-source driver..."

# Remove printer queue if requested
if $REMOVE_PRINTER; then
    if lpstat -p Brother_MFC-9460CDN &>/dev/null; then
        echo "Removing printer queue 'Brother_MFC-9460CDN'..."
        lpadmin -x Brother_MFC-9460CDN
    else
        echo "Printer queue 'Brother_MFC-9460CDN' not found (skipping)."
    fi
fi

# Remove CUPS filter
if [[ -f "$CUPS_FILTER_DIR/brmfc9460cdn-filter" ]]; then
    echo "Removing CUPS filter..."
    rm -f "$CUPS_FILTER_DIR/brmfc9460cdn-filter"
fi

# Remove PPD
if [[ -f "$CUPS_PPD_DIR/brmfc9460cdn.ppd" ]]; then
    echo "Removing PPD..."
    rm -f "$CUPS_PPD_DIR/brmfc9460cdn.ppd"
fi

# Remove library directory
if [[ -d "$LIB_DIR" ]]; then
    echo "Removing library files from $LIB_DIR..."
    rm -rf "$LIB_DIR"
fi

echo ""
echo "Uninstallation complete."

if ! $REMOVE_PRINTER; then
    if lpstat -p Brother_MFC-9460CDN &>/dev/null; then
        echo ""
        echo "Note: Printer queue 'Brother_MFC-9460CDN' still exists."
        echo "To remove it, run: sudo $0 --remove-printer"
        echo "Or manually: sudo lpadmin -x Brother_MFC-9460CDN"
    fi
fi
