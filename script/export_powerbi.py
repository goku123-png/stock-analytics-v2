from pathlib import Path

import duckdb

PROJECT_FOLDER = Path(__file__).resolve().parents[1]
DB_FILE = PROJECT_FOLDER / "warehouse" / "stocks.duckdb"
OUTPUT_FOLDER = PROJECT_FOLDER / "data" / "processed" / "powerbi"

OUTPUT_FOLDER.mkdir(parents=True, exist_ok=True)

exports = {
    "dim_company": "company_key",
    "dim_date": "date_key",
    "fct_daily_stock": "company_key, date_key",
    "fct_monthly_stock": "company_key, month_date_key",
    "mart_january_effect": "company_key, year",
}

with duckdb.connect(str(DB_FILE), read_only=True) as conn:
    for table_name, order_columns in exports.items():
        data = conn.execute(
            f"""
            SELECT *
            FROM analytics_marts.{table_name}
            ORDER BY {order_columns}
            """
        ).fetchdf()

        if data.empty:
            raise RuntimeError(f"Table is empty: {table_name}")

        output_file = OUTPUT_FOLDER / f"{table_name}.csv"

        data.to_csv(
            output_file,
            index=False,
            date_format="%Y-%m-%d",
        )

        print(f"Exported {table_name}: {len(data):,} rows")

print(f"\nOutput folder: {OUTPUT_FOLDER}")