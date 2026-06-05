#!/usr/bin/env python3
"""
Send AB Test Report Email Notification
"""

import sys
import os
import pandas as pd
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime

def generate_summary(overall_csv, tier_csv):
    """Generate email summary from CSV files"""

    # Read overall results
    overall_df = pd.read_csv(overall_csv)

    # Read tier results
    tier_df = pd.read_csv(tier_csv)

    summary = []
    summary.append("=" * 70)
    summary.append(f"WOOWA AB TEST DAILY REPORT")
    summary.append(f"Report Date: {overall_df['report_date'].iloc[0]}")
    summary.append("=" * 70)
    summary.append("")

    # Overall Summary
    summary.append("📊 OVERALL RESULTS")
    summary.append("-" * 70)

    for _, row in overall_df.iterrows():
        vertical = row['search_vertical']
        summary.append(f"\n🔍 {vertical} Tab:")
        summary.append(f"   Traffic Split: {row['treatment_traffic_pct']:.1f}% Treatment")
        summary.append(f"   Control Searches: {int(row['control_searches']):,}")
        summary.append(f"   Treatment Searches: {int(row['treatment_searches']):,}")
        summary.append("")

        # CTR
        ctr_change = row['ctr_pct_change']
        ctr_sig = row['ctr_statistically_significant']
        ctr_emoji = "✅" if ctr_sig == 'Yes' and ctr_change > 0 else "⚠️" if ctr_sig == 'Yes' else "—"
        summary.append(f"   CTR (Click-Through Rate):")
        summary.append(f"      Control:   {row['control_ctr']:.2%}")
        summary.append(f"      Treatment: {row['treatment_ctr']:.2%}")
        summary.append(f"      Change:    {ctr_change:+.1f}% {ctr_emoji} {'(Significant)' if ctr_sig == 'Yes' else '(Not Significant)'}")
        summary.append("")

        # CVR
        cvr_change = row['cvr_pct_change']
        cvr_sig = row['cvr_statistically_significant']
        cvr_emoji = "✅" if cvr_sig == 'Yes' and cvr_change > 0 else "⚠️" if cvr_sig == 'Yes' else "—"
        summary.append(f"   CVR (Conversion Rate):")
        summary.append(f"      Control:   {row['control_cvr']:.2%}")
        summary.append(f"      Treatment: {row['treatment_cvr']:.2%}")
        summary.append(f"      Change:    {cvr_change:+.1f}% {cvr_emoji} {'(Significant)' if cvr_sig == 'Yes' else '(Not Significant)'}")
        summary.append("")

    # Tier Breakdown
    summary.append("")
    summary.append("📈 TIER BREAKDOWN (Head/Torso/Tail)")
    summary.append("-" * 70)

    for _, row in tier_df.iterrows():
        vertical = row['search_vertical']
        tier = row['frequency_tier']
        summary.append(f"\n{vertical} - {tier}:")
        summary.append(f"   Unique Queries: {int(row['control_unique_queries']) + int(row['treatment_unique_queries']):,}")

        # Handle both column name formats (tier uses short names, overall uses long names)
        ctr_sig_col = 'ctr_stat_sig' if 'ctr_stat_sig' in row else 'ctr_statistically_significant'
        cvr_sig_col = 'cvr_stat_sig' if 'cvr_stat_sig' in row else 'cvr_statistically_significant'

        summary.append(f"   CTR Change: {row['ctr_pct_change']:+.1f}% {'(Sig)' if row[ctr_sig_col] == 'Yes' else ''}")
        summary.append(f"   CVR Change: {row['cvr_pct_change']:+.1f}% {'(Sig)' if row[cvr_sig_col] == 'Yes' else ''}")

    summary.append("")
    summary.append("=" * 70)
    summary.append("📝 Key Insights:")
    summary.append("")

    # Auto-generate insights
    insights = []
    for _, row in overall_df.iterrows():
        vertical = row['search_vertical']

        # Handle both column name formats
        ctr_sig_col = 'ctr_stat_sig' if 'ctr_stat_sig' in row else 'ctr_statistically_significant'
        cvr_sig_col = 'cvr_stat_sig' if 'cvr_stat_sig' in row else 'cvr_statistically_significant'

        if row[ctr_sig_col] == 'Yes':
            direction = "improved" if row['ctr_pct_change'] > 0 else "decreased"
            insights.append(f"• {vertical}: CTR {direction} by {abs(row['ctr_pct_change']):.1f}% (significant)")

        if row[cvr_sig_col] == 'Yes':
            direction = "improved" if row['cvr_pct_change'] > 0 else "decreased"
            insights.append(f"• {vertical}: CVR {direction} by {abs(row['cvr_pct_change']):.1f}% (significant)")

    if not insights:
        insights.append("• No statistically significant changes detected")

    summary.extend(insights)
    summary.append("")
    summary.append("=" * 70)

    return "\n".join(summary)

def send_email(to_email, subject, body, sheet_url=None):
    """Send email notification (uses local mail command)"""

    full_body = body

    if sheet_url:
        full_body += f"\n\n📊 View detailed results:\n{sheet_url}\n"

    full_body += f"\n\nGenerated at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"

    # Use local mail command (simple approach)
    try:
        msg = MIMEMultipart('alternative')
        msg['Subject'] = subject
        msg['From'] = 'woowa-ab-test@automated-report.local'
        msg['To'] = to_email

        # Plain text version
        text_part = MIMEText(full_body, 'plain')
        msg.attach(text_part)

        # For now, just print to console (mail command setup varies by system)
        print("\n" + "=" * 70)
        print("EMAIL NOTIFICATION (would be sent to:", to_email, ")")
        print("=" * 70)
        print()
        print(full_body)
        print()
        print("=" * 70)

        # Optionally save to file
        email_file = f"/Users/aybueke.kayaci/woowa_search_analysis/reports/email_{datetime.now().strftime('%Y%m%d')}.txt"
        with open(email_file, 'w') as f:
            f.write(f"To: {to_email}\n")
            f.write(f"Subject: {subject}\n\n")
            f.write(full_body)
        print(f"Email saved to: {email_file}")

        return True

    except Exception as e:
        print(f"Error sending email: {e}")
        return False

def main():
    """Main email notification function"""

    if len(sys.argv) < 3:
        print("Usage: python send_email_report.py <report_date> <email_address> [sheet_url]")
        print("Example: python send_email_report.py 2026-05-27 you@example.com")
        sys.exit(1)

    report_date = sys.argv[1]
    to_email = sys.argv[2]
    sheet_url = sys.argv[3] if len(sys.argv) > 3 else None

    # File paths
    base_dir = "/Users/aybueke.kayaci/woowa_search_analysis/reports"
    overall_csv = f"{base_dir}/overall_{report_date}.csv"
    tier_csv = f"{base_dir}/tier_{report_date}.csv"

    # Check files exist
    for csv_file in [overall_csv, tier_csv]:
        if not os.path.exists(csv_file):
            print(f"ERROR: File not found: {csv_file}")
            sys.exit(1)

    # Generate summary
    summary = generate_summary(overall_csv, tier_csv)

    # Send email
    subject = f"Woowa AB Test Report - {report_date}"
    send_email(to_email, subject, summary, sheet_url)

    print("\n✓ Email notification generated successfully")

if __name__ == '__main__':
    main()
