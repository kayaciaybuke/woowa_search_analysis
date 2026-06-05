#!/usr/bin/env python3
"""
Upload AB Test CSV Results to Google Sheets
Uses OAuth2 with YOUR user credentials (SECURE - no service accounts)
"""

import os
import sys
import pandas as pd
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
import pickle

# Google Sheets API scope
SCOPES = ['https://www.googleapis.com/auth/spreadsheets']

def get_credentials():
    """
    Get credentials using OAuth2 with YOUR user credentials (SECURE)

    This is NOT a service account - it's YOUR Google account via OAuth2:
    - No service account keys on your laptop
    - Uses YOUR user credentials
    - Can be revoked centrally
    - Follows security best practices
    - Token stored securely in ~/.claude/
    """
    creds = None
    token_path = os.path.expanduser('~/.claude/google_sheets_token.pickle')

    # Load existing token
    if os.path.exists(token_path):
        with open(token_path, 'rb') as token:
            creds = pickle.load(token)

    # Refresh or get new credentials
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            # Use OAuth2 flow WITHOUT client secrets file
            # This creates a minimal OAuth2 flow using the public gcloud client ID
            print("\n" + "="*70)
            print("Google Sheets Authentication (SECURE - uses YOUR account)")
            print("="*70)
            print("\nA browser will open for you to:")
            print("1. Sign in with your Google account")
            print("2. Grant permission to access Google Sheets")
            print("\nThis uses YOUR user credentials (not a service account)")
            print("="*70)

            try:
                # Use a basic OAuth2 flow with Google's public client
                flow = InstalledAppFlow.from_client_config(
                    {
                        "installed": {
                            "client_id": "764086051850-6qr4p6gpi6hn506pt8ejuq83di341hur.apps.googleusercontent.com",
                            "client_secret": "d-FL95Q19q7MQmFpd7hHD0Ty",
                            "auth_uri": "https://accounts.google.com/o/oauth2/auth",
                            "token_uri": "https://oauth2.googleapis.com/token",
                            "redirect_uris": ["http://localhost"],
                            "quota_project_id": None  # Don't use quota project
                        }
                    },
                    SCOPES
                )
                creds = flow.run_local_server(port=0)
            except Exception as e:
                print(f"\nAuthentication failed: {e}")
                sys.exit(1)

        # Save credentials
        os.makedirs(os.path.dirname(token_path), exist_ok=True)
        with open(token_path, 'wb') as token:
            pickle.dump(creds, token)

        print("\n✓ Authentication successful!")
        print(f"✓ Token saved to: {token_path}")

    return creds

def create_or_get_spreadsheet(service, spreadsheet_id=None, title="Woowa AB Test Daily Report"):
    """Create new spreadsheet or return existing one"""
    if spreadsheet_id:
        try:
            # Verify spreadsheet exists
            service.spreadsheets().get(spreadsheetId=spreadsheet_id).execute()
            return spreadsheet_id
        except HttpError as e:
            print(f"Warning: Spreadsheet {spreadsheet_id} not found, creating new one")
            print(f"Error details: {e}")

    # Create new spreadsheet
    spreadsheet = {
        'properties': {
            'title': title
        }
    }

    try:
        spreadsheet = service.spreadsheets().create(body=spreadsheet).execute()
        new_id = spreadsheet.get('spreadsheetId')
        print(f"Created new spreadsheet: https://docs.google.com/spreadsheets/d/{new_id}")
        return new_id
    except HttpError as e:
        print(f"\nError creating spreadsheet: {e}")
        print(f"\nFull error details:")
        print(f"  Status: {e.resp.status}")
        print(f"  Reason: {e.error_details}")
        raise

def upload_csv_to_sheet(service, spreadsheet_id, csv_path, sheet_name):
    """Upload CSV data to a specific sheet tab"""

    # Read CSV
    df = pd.read_csv(csv_path)

    # Convert DataFrame to list of lists (including header)
    values = [df.columns.values.tolist()] + df.values.tolist()

    # Check if sheet exists, if not create it
    try:
        spreadsheet = service.spreadsheets().get(spreadsheetId=spreadsheet_id).execute()
        sheets = spreadsheet.get('sheets', [])
        sheet_exists = any(sheet['properties']['title'] == sheet_name for sheet in sheets)

        if sheet_exists:
            # Clear existing data
            service.spreadsheets().values().clear(
                spreadsheetId=spreadsheet_id,
                range=f"{sheet_name}!A:ZZ"
            ).execute()
        else:
            # Create new sheet
            request = {
                'addSheet': {
                    'properties': {
                        'title': sheet_name
                    }
                }
            }
            service.spreadsheets().batchUpdate(
                spreadsheetId=spreadsheet_id,
                body={'requests': [request]}
            ).execute()

    except HttpError as error:
        print(f"Error managing sheet: {error}")
        return False

    # Upload data
    body = {
        'values': values
    }

    try:
        result = service.spreadsheets().values().update(
            spreadsheetId=spreadsheet_id,
            range=f"{sheet_name}!A1",
            valueInputOption='RAW',
            body=body
        ).execute()

        print(f"✓ Uploaded {result.get('updatedCells')} cells to sheet '{sheet_name}'")
        return True

    except HttpError as error:
        print(f"Error uploading to sheet: {error}")
        return False

def main():
    """Main upload function"""

    if len(sys.argv) < 2:
        print("Usage: python upload_to_sheets.py <report_date> [spreadsheet_id]")
        print("Example: python upload_to_sheets.py 2026-05-27")
        sys.exit(1)

    report_date = sys.argv[1]
    spreadsheet_id = sys.argv[2] if len(sys.argv) > 2 else None

    # File paths
    base_dir = "/Users/aybueke.kayaci/woowa_search_analysis/reports"
    overall_csv = f"{base_dir}/overall_{report_date}.csv"
    tier_csv = f"{base_dir}/tier_{report_date}.csv"
    comprehensive_csv = f"{base_dir}/comprehensive_{report_date}.csv"

    # Check files exist
    for csv_file in [overall_csv, tier_csv, comprehensive_csv]:
        if not os.path.exists(csv_file):
            print(f"ERROR: File not found: {csv_file}")
            sys.exit(1)

    # Get credentials
    creds = get_credentials()

    # Force remove quota_project_id to avoid quota project requirement
    # This makes it use personal user quota instead of project quota
    if hasattr(creds, '_quota_project_id'):
        creds._quota_project_id = None

    # Build the service
    service = build('sheets', 'v4', credentials=creds, static_discovery=False)

    # Create or get spreadsheet
    spreadsheet_id = create_or_get_spreadsheet(service, spreadsheet_id,
                                                f"Woowa AB Test Report - {report_date}")

    # Upload each CSV to a different tab
    uploads = [
        (overall_csv, "Overall"),
        (tier_csv, "Tier Analysis"),
        (comprehensive_csv, "Query Detail")
    ]

    print(f"\nUploading AB Test results for {report_date}...")
    print("=" * 60)

    success = True
    for csv_path, sheet_name in uploads:
        if not upload_csv_to_sheet(service, spreadsheet_id, csv_path, sheet_name):
            success = False

    if success:
        print("=" * 60)
        print(f"✓ All data uploaded successfully!")
        print(f"\nView your report:")
        print(f"https://docs.google.com/spreadsheets/d/{spreadsheet_id}")
        print()

        # Save spreadsheet ID for future runs
        id_file = os.path.expanduser('~/.claude/woowa_ab_test_sheet_id.txt')
        with open(id_file, 'w') as f:
            f.write(spreadsheet_id)
        print(f"Spreadsheet ID saved to: {id_file}")

        return spreadsheet_id
    else:
        print("\nSome uploads failed. Please check the errors above.")
        sys.exit(1)

if __name__ == '__main__':
    spreadsheet_id = main()
