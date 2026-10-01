from pathlib import Path

import pandas as pd


PROJECT_DIR = Path(__file__).resolve().parents[1]
TICKERS = ["AAPL", "AMZN", "GOOGL", "MSFT", "NVDA"]
PRICE_COLUMNS = ["Open", "High", "Low", "Close", "Adj Close"]
REQUIRED = ["ticker", "Date", *PRICE_COLUMNS, "Volume"]

raw_dir = PROJECT_DIR / "data" / "raw" / "five_stocks"
runs = sorted(
    folder for folder in raw_dir.iterdir()
    if folder.is_dir() and (folder / "download_log.csv").is_file()
)
if not runs:
    raise SystemExit("No download folder found")

input_dir = runs[-1]
report_dir = PROJECT_DIR / "docs" / "data_quality" / input_dir.name
report_dir.mkdir(parents=True, exist_ok=True)

results = []

for ticker in TICKERS:
    path = input_dir / f"{ticker}.csv"
    issues = []

    if not path.is_file():
        results.append({"ticker": ticker, "status": "REVIEW", "issues": "CSV missing"})
        continue

    data = pd.read_csv(path, dtype=str)
    missing_columns = [col for col in REQUIRED if col not in data.columns]

    if missing_columns:
        results.append({
            "ticker": ticker,
            "status": "REVIEW",
            "issues": f"Missing columns: {missing_columns}",
        })
        continue

    checked = data[REQUIRED].replace(r"^\s*$", pd.NA, regex=True)
    dates = pd.to_datetime(checked["Date"], format="%Y-%m-%d", errors="coerce")
    numbers = checked[PRICE_COLUMNS + ["Volume"]].apply(
        pd.to_numeric, errors="coerce"
    )

    if data.empty:
        issues.append("empty file")
    if checked.isna().any().any():
        issues.append("missing values")
    if dates.isna().any():
        issues.append("invalid dates")
    if not dates.is_monotonic_increasing:
        issues.append("dates not sorted")
    if dates.duplicated().any():
        issues.append("duplicate dates")
    if checked["ticker"].str.strip().str.upper().ne(ticker).any():
        issues.append("unexpected ticker")
    if numbers.isna().any().any():
        issues.append("invalid numbers")
    if (numbers[PRICE_COLUMNS] <= 0).any().any():
        issues.append("nonpositive prices")
    if (numbers["Volume"] < 0).any():
        issues.append("negative volume")
    if (numbers["Volume"].dropna() % 1 != 0).any():
        issues.append("fractional volume")

    invalid_ohlc = (
        (numbers["High"] < numbers["Low"])
        | (numbers["High"] < numbers["Open"])
        | (numbers["High"] < numbers["Close"])
        | (numbers["Low"] > numbers["Open"])
        | (numbers["Low"] > numbers["Close"])
    )
    if invalid_ohlc.any():
        issues.append("invalid High/Low relationship")

    results.append({
        "ticker": ticker,
        "status": "PASS" if not issues else "REVIEW",
        "row_count": len(data),
        "first_date": dates.min().date() if dates.notna().any() else "",
        "last_date": dates.max().date() if dates.notna().any() else "",
        "issues": "; ".join(issues),
    })

report = pd.DataFrame(results)
report_path = report_dir / "profiling_summary.csv"
report.to_csv(report_path, index=False)

print("\nInput folder:", input_dir)
print(report.to_string(index=False))
print("Report:", report_path)

if (report["status"] != "PASS").any():
    raise SystemExit("Data quality failed; review the report")

print("Data quality: 5/5 PASS")