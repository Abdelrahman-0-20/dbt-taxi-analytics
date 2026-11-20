"""One-time download of the source files (same public data as project #1)."""
import shutil
import urllib.request
from pathlib import Path

TRIPS_URL = "https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-01.parquet"
ZONES_URL = "https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv"
ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "data" / "raw"


def download(url: str, dest: Path) -> None:
    if dest.exists() and dest.stat().st_size > 0:
        print(f"present: {dest.name} ({dest.stat().st_size:,} bytes)")
        return
    dest.parent.mkdir(parents=True, exist_ok=True)
    tmp = dest.with_suffix(dest.suffix + ".part")
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 (portfolio-dbt)"})
    with urllib.request.urlopen(req, timeout=120) as resp, open(tmp, "wb") as out:
        shutil.copyfileobj(resp, out)
    tmp.replace(dest)
    print(f"downloaded: {dest.name} ({dest.stat().st_size:,} bytes)")


if __name__ == "__main__":
    download(TRIPS_URL, RAW / "yellow_tripdata_2024-01.parquet")
    download(ZONES_URL, RAW / "taxi_zone_lookup.csv")
