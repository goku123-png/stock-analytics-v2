from datetime import datetime, timezone
from pathlib import Path
import csv

import yfinance as yf


PROJECT_DIR = Path(__file__).resolve().parents[1]
TICKERS = ["AAPL", "AMZN", "GOOGL", "MSFT", "NVDA"]
START_DATE = "2015-01-01"
END_DATE = "2026-04-01" 

run_id = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
output_dir = PROJECT_DIR / "data" / "raw" / "five_stocks" / run_id
output_dir.mkdir(parents=True, exist_ok=True)

price_columns = ["Open", "High", "Low", "Close", "Adj Close", "Volume"]
log_rows = []

for ticker in TICKERS:
    print(f"Downloading {ticker}...")

    try:
        prices = yf.Ticker(ticker).history(
            start=START_DATE,
            end=END_DATE,
            interval="1d",
            auto_adjust=False,
            actions=False,
        )

        if prices.empty:
            raise ValueError("No price data returned")

        missing = [col for col in price_columns if col not in prices.columns]
        if missing:
            raise ValueError(f"Missing columns: {missing}")

        result = prices[price_columns].copy()
        result.insert(0, "Date", [day.date().isoformat() for day in result.index])
        result.insert(0, "ticker", ticker)

        csv_path = output_dir / f"{ticker}.csv"
        result.to_csv(csv_path, index=False)

        log_rows.append({
            "ticker": ticker,
            "status": "DOWNLOADED",
            "row_count": len(result),
            "first_date": result["Date"].iloc[0],
            "last_date": result["Date"].iloc[-1],
            "error": "",
        })
        print(f"Saved {ticker}: {len(result)} rows")

    except Exception as exc:
        log_rows.append({
            "ticker": ticker,
            "status": "FAILED",
            "row_count": 0,
            "first_date": "",
            "last_date": "",
            "error": str(exc),
        })
        print(f"FAILED {ticker}: {exc}")

with (output_dir / "download_log.csv").open("w", newline="", encoding="utf-8") as file:
    writer = csv.DictWriter(file, fieldnames=log_rows[0].keys())
    writer.writeheader()
    writer.writerows(log_rows)

print(f"\nOutput folder: {output_dir}")
print(f"Downloaded: {sum(row['status'] == 'DOWNLOADED' for row in log_rows)}/5")