#!/usr/bin/env python3
"""
Export BigQuery Data Marts to CSV Files

This script exports all data marts from BigQuery to CSV files
for use in the static marimo dashboard deployment.
"""

import os
from google.cloud import bigquery
import pandas as pd

# Configuration
PROJECT_ID = 'dw-health-insurance-bipm'
DATASET_ID = 'raw_dataset_data_marts'
OUTPUT_DIR = 'data'

# Data marts to export
DATA_MARTS = [
    'dm_customer_360',
    'dm_health_by_demographics',
    'dm_insurance_profitability',
    'dm_sleep_health_analysis',
    'dm_data_quality_dashboard'
]

def export_datamarts():
    """Export all data marts to CSV files."""

    # Create output directory if it doesn't exist
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # Initialize BigQuery client
    print(f"Connecting to BigQuery project: {PROJECT_ID}")
    client = bigquery.Client(project=PROJECT_ID)

    # Export each data mart
    for table_name in DATA_MARTS:
        print(f"\nExporting {table_name}...")

        query = f"""
        SELECT *
        FROM `{PROJECT_ID}.{DATASET_ID}.{table_name}`
        """

        try:
            # Execute query
            df = client.query(query).to_dataframe()

            # Save to CSV
            output_path = os.path.join(OUTPUT_DIR, f"{table_name}.csv")
            df.to_csv(output_path, index=False)

            print(f"  ✅ Exported {len(df)} rows to {output_path}")
            print(f"  📊 Columns: {', '.join(df.columns[:5])}{'...' if len(df.columns) > 5 else ''}")
            print(f"  💾 File size: {os.path.getsize(output_path) / 1024:.2f} KB")

        except Exception as e:
            print(f"  ❌ Error exporting {table_name}: {e}")

    print("\n✨ Export complete!")
    print(f"📁 CSV files saved to: {os.path.abspath(OUTPUT_DIR)}")

if __name__ == "__main__":
    export_datamarts()
