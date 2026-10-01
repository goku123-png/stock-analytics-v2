from pathlib import Path

import duckdb
import pandas as pd


PROJECT_DIR = Path(__file__).resolve().parents[1]
TICKERS = {"AAPL", "AMZN", "GOOGL", "MSFT", "NVDA"}

report_paths = sorted(
    (PROJECT_DIR / "docs" / "data_quality").glob("*/profiling_summary.csv")
)
if not report_paths:
    raise SystemExit("No data quality report found")

report_path = report_paths[-1]
run_id = report_path.parent.name
report = pd.read_csv(report_path)

if set(report["ticker"]) != TICKERS or not report["status"].eq("PASS").all():
    raise SystemExit(f"Data quality has not passed: {report_path}")

expected = dict(zip(report["ticker"], report["row_count"]))
csv_dir = PROJECT_DIR / "data" / "raw" / "five_stocks" / run_id
csv_files = [csv_dir / f"{ticker}.csv" for ticker in sorted(TICKERS)]

if any(not path.is_file() for path in csv_files):
    raise SystemExit("A validated CSV file is missing")

# Explicit list: download_log.csv must not enter the price table.
files_sql = "[" + ", ".join(
    "'" + str(path).replace("'", "''") + "'" for path in csv_files
) + "]"

db_path = PROJECT_DIR / "warehouse" / "stocks.duckdb"
db_path.parent.mkdir(parents=True, exist_ok=True)

conn = duckdb.connect(str(db_path))
try:
    conn.execute("BEGIN TRANSACTION")
    conn.execute("CREATE SCHEMA IF NOT EXISTS raw")
    conn.execute(f"""
        CREATE OR REPLACE TABLE raw.stock_prices AS
        SELECT
            ticker,
            "Date",
            "Open",
            "High",
            "Low",
            "Close",
            "Adj Close",
            "Volume",
            '{run_id}' AS source_run_id
        FROM read_csv_auto({files_sql}, union_by_name=true)
    """)

    summary = conn.execute("""
        SELECT ticker, COUNT(*) AS row_count,
               MIN("Date") AS first_date,
               MAX("Date") AS last_date
        FROM raw.stock_prices
        GROUP BY ticker
        ORDER BY ticker
    """).fetchall()

    actual = {ticker: count for ticker, count, _, _ in summary}
    if actual != expected:
        raise ValueError(f"Row counts differ: expected {expected}, got {actual}")

    conn.execute("COMMIT")
    print("Database:", db_path)
    print("Source run:", run_id)
    for row in summary:
        print(row)
    print("Total rows:", sum(actual.values()))

except Exception:
    conn.execute("ROLLBACK")
    raise
finally:
    conn.close()