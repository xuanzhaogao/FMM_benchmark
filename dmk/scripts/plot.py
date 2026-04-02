#!/usr/bin/env python3
"""Generate runtime and speedup plots for DMK benchmark."""

import csv
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker

THREAD_COUNTS = [1, 2, 4, 8, 16, 32, 48, 64, 80, 96]
COLORS = {
    1: "#1f77b4", 2: "#ff7f0e", 4: "#2ca02c", 8: "#d62728",
    16: "#9467bd", 32: "#8c564b", 48: "#e377c2", 64: "#7f7f7f",
    80: "#bcbd22", 96: "#17becf",
}
DMK_DIR = Path(__file__).resolve().parent.parent


def load_csv(path: Path) -> tuple:
    ns, times = [], []
    with path.open() as f:
        reader = csv.DictReader(f)
        for row in reader:
            ns.append(int(row["ns"]))
            times.append(float(row["time"]))
    return ns, times


def plot_digits(digits_dir: Path, label: str, output_stem: str):
    data = {}
    for t in THREAD_COUNTS:
        p = digits_dir / f"dmk_benchmark_{t}.csv"
        if p.exists():
            data[t] = load_csv(p)

    if not data:
        print(f"No data found in {digits_dir}, skipping")
        return

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5))

    # Left panel: runtime
    for t in THREAD_COUNTS:
        if t not in data:
            continue
        ns, times = data[t]
        ax1.plot(ns, times, marker="o", color=COLORS[t],
                 label=f"{t} thread{'s' if t > 1 else ''}", linewidth=2)

    ax1.set_xscale("log")
    ax1.set_yscale("log")
    ax1.set_xlabel("Number of points")
    ax1.set_ylabel("Time (s)")
    ax1.set_title(f"DMK Run Time ({label})")
    ax1.grid(True, which="both", alpha=0.3)

    # Right panel: speedup
    if 1 in data:
        ns_ref, t_ref = data[1]
        for t in THREAD_COUNTS:
            if t <= 1 or t not in data:
                continue
            ns, times = data[t]
            n = min(len(t_ref), len(times))
            speedup = [t_ref[i] / times[i] for i in range(n)]
            ax2.plot(ns[:n], speedup, marker="o", color=COLORS[t],
                     label=f"{t} threads", linewidth=2)

        ax2.plot(ns_ref, [1] * len(ns_ref), "--", color="gray",
                 linewidth=1, label="ideal=1")

    ax2.set_xscale("log")
    ax2.set_yscale("log")
    ax2.set_xlabel("Number of points")
    ax2.set_ylabel("Speedup")
    ax2.set_title(f"DMK Speedup ({label})")
    ax2.yaxis.set_major_formatter(ticker.ScalarFormatter())
    ax2.yaxis.set_minor_formatter(ticker.NullFormatter())
    ax2.grid(True, which="both", alpha=0.3)

    handles, labels = ax1.get_legend_handles_labels()
    fig.legend(handles, labels, loc="center right", fontsize=9,
               bbox_to_anchor=(1.12, 0.5))

    fig.tight_layout()
    out_dir = DMK_DIR / "plots"
    out_dir.mkdir(exist_ok=True)
    fig.savefig(out_dir / f"{output_stem}.svg", format="svg",
                bbox_inches="tight")
    fig.savefig(out_dir / f"{output_stem}.png", dpi=150,
                bbox_inches="tight")
    print(f"Saved {out_dir / output_stem}.{{svg,png}}")
    plt.close(fig)


def main():
    data_dir = DMK_DIR / "data"
    plot_digits(data_dir / "3digits", "3 digits / eps=1e-3", "dmk_3digits")
    plot_digits(data_dir / "6digits", "6 digits / eps=1e-6", "dmk_6digits")


if __name__ == "__main__":
    main()
