#!/usr/bin/env python3
import argparse
import subprocess
import sys

def filter_list_download(args) -> int:
    urls = sorted(list(set(args.urls)))
    for url in urls:
        if not url.startswith("https://"):
            continue
        sys.stderr.write(f"Downloading {url}...\n")
        try:
            res = subprocess.run(
                ["curl", "-sSL", "--connect-timeout", "15", "-m", "60", "-A", "Mozilla/5.0 (X11; Linux x86_64)", url],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=True
            )
            args.output.write(res.stdout)
            sys.stderr.write(f"Downloaded {len(res.stdout)} bytes\n")
        except Exception as e:
            sys.stderr.write(f"Warning: could not download {url}: {e}\n")
    return 0

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--urls", nargs="+", help="URLs to download")
    parser.add_argument("--output", required=True, type=argparse.FileType("wb"), default=sys.stdout)
    sys.exit(filter_list_download(parser.parse_args(sys.argv[1:])))
