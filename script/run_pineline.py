from pathlib import Path
import subprocess
import sys
import time


PROJECT_FOLDER = Path(__file__).resolve().parents[1]
PYTHON = sys.executable

# Find dbt beside the Python executable in the same environment.
DBT = Path(PYTHON).parent / "dbt"

STEPS = [
    (
        "Extract stock data",
        [PYTHON, "script/extract_five_stocks.py"],
    ),
    (
        "Check data quality",
        [PYTHON, "script/profile_five_stocks.py"],
    ),
    (
        "Load raw data into DuckDB",
        [PYTHON, "script/load_raw.py"],
    ),
    (
        "Build dbt models and run tests",
        [str(DBT), "build", "--profiles-dir", "."],
    ),
    (
        "Export CSV files for Power BI",
        [PYTHON, "script/export_powerbi.py"],
    ),
]


def main():
    if not DBT.is_file():
        raise SystemExit(
            f"dbt executable not found: {DBT}\n"
            "Run this script using the project .venv Python."
        )

    started = time.perf_counter()

    for number, (name, command) in enumerate(STEPS, start=1):
        print(
            f"\n=== STEP {number}/{len(STEPS)}: {name} ===",
            flush=True,
        )

        try:
            subprocess.run(
                command,
                cwd=PROJECT_FOLDER,
                check=True,
            )
        except subprocess.CalledProcessError as error:
            print(
                f"\nPIPELINE FAILED at step {number}: {name}",
                flush=True,
            )
            raise SystemExit(error.returncode)

    elapsed = time.perf_counter() - started

    print(f"\nPIPELINE SUCCESS — {elapsed:.1f} seconds")
    print(
        "Power BI CSV folder:",
        PROJECT_FOLDER / "data" / "processed" / "powerbi",
    )


if __name__ == "__main__":
    main()