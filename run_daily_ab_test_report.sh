#!/bin/bash
# =================================================================
# Daily AB Test Report Automation
# Runs all three AB test queries and exports results
# =================================================================

set -e  # Exit on error

REPORT_DATE=$(date -v-1d +%Y-%m-%d)  # Yesterday (macOS date format)
OUTPUT_DIR="/Users/aybueke.kayaci/woowa_search_analysis/reports"
QUERY_DIR="/Users/aybueke.kayaci/woowa_search_analysis"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
VENV_DIR="/Users/aybueke.kayaci/woowa_search_analysis/venv"

# User email for notifications
USER_EMAIL="${AB_TEST_EMAIL:-aybueke.kayaci@deliveryhero.com}"

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "==================================================================="
echo "AB Test Daily Report - $REPORT_DATE"
echo "Started at: $(date)"
echo "==================================================================="

# Function to run a query and save results
run_query() {
    local query_file=$1
    local output_name=$2

    echo "Running $output_name query..."

    # Remove comment-only lines (lines starting with --) to prevent bq errors
    # Pipe query to bq (without positional SQL argument)
    # Extract only CSV output (starts with "report_date,")
    grep -v "^--" "$query_file" | \
        bq query --use_legacy_sql=false --format=csv --max_rows=100000 2>&1 | \
        sed -n '/^report_date,/,$p' \
        > "$OUTPUT_DIR/${output_name}_${REPORT_DATE}.csv"

    # Check if successful
    if grep -q "^report_date," "$OUTPUT_DIR/${output_name}_${REPORT_DATE}.csv" 2>/dev/null; then
        local row_count=$(wc -l < "$OUTPUT_DIR/${output_name}_${REPORT_DATE}.csv")
        echo "✓ $output_name results saved ($((row_count - 1)) rows)"
    else
        echo "✗ $output_name query failed - see output below:"
        cat "$OUTPUT_DIR/${output_name}_${REPORT_DATE}.csv"
        exit 1
    fi
}

# Run all three queries
run_query "$QUERY_DIR/overall_comparison_query_ab_test.sql" "overall"
run_query "$QUERY_DIR/head_torso_tail_comparison_query_ab_test.sql" "tier"
run_query "$QUERY_DIR/comprehensive_comparison_query_ab_test.sql" "comprehensive"

echo ""
echo "==================================================================="
echo "All queries completed successfully"
echo "Output directory: $OUTPUT_DIR"
echo "Report date: $REPORT_DATE"
echo "==================================================================="

# List generated files
echo ""
echo "Generated files:"
ls -lh "$OUTPUT_DIR"/*_${REPORT_DATE}.csv

# =================================================================
# Upload to Google Sheets
# =================================================================
echo ""
echo "==================================================================="
echo "Uploading to Google Sheets..."
echo "==================================================================="

# Activate virtual environment
source "$VENV_DIR/bin/activate"

# Check if gcloud authentication is configured (Application Default Credentials)
ADC_FILE="$HOME/.config/gcloud/application_default_credentials.json"
SHEET_URL=""

if [ -f "$ADC_FILE" ]; then
    # Check if we have a saved spreadsheet ID
    SHEET_ID_FILE="$HOME/.claude/woowa_ab_test_sheet_id.txt"
    SHEET_ID=""
    if [ -f "$SHEET_ID_FILE" ]; then
        SHEET_ID=$(cat "$SHEET_ID_FILE")
    fi

    # Upload to Google Sheets (don't fail if upload fails)
    if [ -n "$SHEET_ID" ]; then
        python3 "$QUERY_DIR/upload_to_sheets.py" "$REPORT_DATE" "$SHEET_ID" 2>&1 || echo "⚠️  Google Sheets upload failed (continuing anyway)"
    else
        python3 "$QUERY_DIR/upload_to_sheets.py" "$REPORT_DATE" 2>&1 || echo "⚠️  Google Sheets upload failed (continuing anyway)"
    fi

    # Get the spreadsheet ID (saved by upload script)
    if [ -f "$SHEET_ID_FILE" ]; then
        SHEET_ID=$(cat "$SHEET_ID_FILE")
        SHEET_URL="https://docs.google.com/spreadsheets/d/$SHEET_ID"
    fi
else
    echo "⚠️  Google Cloud authentication not found - skipping upload"
    echo "   CSV files are available in: $OUTPUT_DIR"
    echo "   To enable Google Sheets upload:"
    echo "   Run: gcloud auth application-default login --disable-quota-project"
    echo "   See: SETUP_GOOGLE_SHEETS.md"
fi

# =================================================================
# Send Email Notification
# =================================================================
echo ""
echo "==================================================================="
echo "Sending email notification..."
echo "==================================================================="

if [ -n "$SHEET_URL" ]; then
    python3 "$QUERY_DIR/send_email_report.py" "$REPORT_DATE" "$USER_EMAIL" "$SHEET_URL"
else
    python3 "$QUERY_DIR/send_email_report.py" "$REPORT_DATE" "$USER_EMAIL"
fi

# Deactivate virtual environment
deactivate

# =================================================================
# Final Summary
# =================================================================
echo ""
echo "==================================================================="
echo "✓ AB Test Daily Report Completed Successfully"
echo "==================================================================="
echo "Report Date: $REPORT_DATE"
echo "CSV Files: $OUTPUT_DIR"
if [ -n "$SHEET_URL" ]; then
    echo "Google Sheet: $SHEET_URL"
fi
echo "Email: $USER_EMAIL"
echo "Completed at: $(date)"
echo "==================================================================="
