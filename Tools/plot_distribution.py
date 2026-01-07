"""
ML-Lite Score Distribution Visualizer
Creates visual plots of score distributions and performance metrics.

Usage:
    python plot_distribution.py signals_2026-01.csv

Requirements:
    pip install pandas matplotlib seaborn

Outputs:
    - score_distribution.png
    - win_rate_by_score.png
    - performance_comparison.png
"""

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import sys
from pathlib import Path

# Set style
sns.set_style("whitegrid")
plt.rcParams['figure.figsize'] = (12, 8)

def load_data(filepath):
    """Load CSV data."""
    try:
        df = pd.read_csv(filepath)
        print(f"✅ Loaded {len(df)} signals")
        return df
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

def plot_score_distribution(df, output_dir="."):
    """Plot score distribution histogram."""
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 6))
    
    # Histogram
    ax1.hist(df['OverallScore'], bins=20, edgecolor='black', alpha=0.7)
    ax1.axvline(0.50, color='orange', linestyle='--', label='Low Threshold (0.50)')
    ax1.axvline(0.60, color='green', linestyle='--', label='Default Threshold (0.60)')
    ax1.axvline(0.70, color='red', linestyle='--', label='High Threshold (0.70)')
    ax1.set_xlabel('Score')
    ax1.set_ylabel('Count')
    ax1.set_title('Signal Score Distribution')
    ax1.legend()
    ax1.grid(alpha=0.3)
    
    # Box plot by tier
    df['Tier'] = pd.cut(df['OverallScore'], 
                        bins=[0, 0.50, 0.70, 1.0],
                        labels=['Low (<0.50)', 'Medium (0.50-0.69)', 'High (≥0.70)'])
    
    df.boxplot(column='OverallScore', by='Tier', ax=ax2)
    ax2.set_xlabel('Tier')
    ax2.set_ylabel('Score')
    ax2.set_title('Score Distribution by Tier')
    plt.suptitle('')  # Remove default title
    
    output = Path(output_dir) / 'score_distribution.png'
    plt.tight_layout()
    plt.savefig(output, dpi=150, bbox_inches='tight')
    print(f"✅ Saved: {output}")
    plt.close()

def plot_win_rate_by_score(df, output_dir="."):
    """Plot win rate vs score."""
    completed = df[df['ActualOutcome'].notna()].copy()
    
    if len(completed) < 10:
        print("⚠️  Not enough completed trades for win rate plot")
        return
    
    # Bin scores
    completed['ScoreBin'] = pd.cut(completed['OverallScore'], 
                                   bins=[0, 0.50, 0.55, 0.60, 0.65, 0.70, 0.75, 0.80, 0.85, 0.90, 1.0])
    
    # Calculate win rate per bin
    win_rates = []
    counts = []
    labels = []
    
    for bin_range in completed['ScoreBin'].cat.categories:
        bin_data = completed[completed['ScoreBin'] == bin_range]
        if len(bin_data) > 0:
            wr = len(bin_data[bin_data['ActualOutcome'] == 'WIN']) / len(bin_data) * 100
            win_rates.append(wr)
            counts.append(len(bin_data))
            labels.append(f"{bin_range.left:.2f}-{bin_range.right:.2f}")
    
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 10))
    
    # Win rate plot
    bars1 = ax1.bar(range(len(win_rates)), win_rates, color='steelblue', alpha=0.7)
    ax1.axhline(y=50, color='red', linestyle='--', label='50% Baseline', alpha=0.5)
    ax1.axhline(y=60, color='green', linestyle='--', label='60% Target', alpha=0.5)
    ax1.set_xlabel('Score Range')
    ax1.set_ylabel('Win Rate (%)')
    ax1.set_title('Win Rate by Score Range')
    ax1.set_xticks(range(len(labels)))
    ax1.set_xticklabels(labels, rotation=45, ha='right')
    ax1.legend()
    ax1.grid(alpha=0.3)
    
    # Add count labels on bars
    for i, (bar, count) in enumerate(zip(bars1, counts)):
        height = bar.get_height()
        ax1.text(bar.get_x() + bar.get_width()/2., height + 1,
                f'n={count}', ha='center', va='bottom', fontsize=8)
    
    # Trade count plot
    ax2.bar(range(len(counts)), counts, color='coral', alpha=0.7)
    ax2.set_xlabel('Score Range')
    ax2.set_ylabel('Number of Trades')
    ax2.set_title('Trade Count by Score Range')
    ax2.set_xticks(range(len(labels)))
    ax2.set_xticklabels(labels, rotation=45, ha='right')
    ax2.grid(alpha=0.3)
    
    output = Path(output_dir) / 'win_rate_by_score.png'
    plt.tight_layout()
    plt.savefig(output, dpi=150, bbox_inches='tight')
    print(f"✅ Saved: {output}")
    plt.close()

def plot_tier_comparison(df, output_dir="."):
    """Compare performance across tiers."""
    completed = df[df['ActualOutcome'].notna()].copy()
    
    if len(completed) < 10:
        print("⚠️  Not enough data for tier comparison")
        return
    
    # Define tiers
    completed['Tier'] = pd.cut(completed['OverallScore'],
                               bins=[0, 0.50, 0.70, 1.0],
                               labels=['Low', 'Medium', 'High'])
    
    fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(14, 10))
    
    # Win rate by tier
    tier_wr = completed.groupby('Tier').apply(
        lambda x: len(x[x['ActualOutcome'] == 'WIN']) / len(x) * 100 if len(x) > 0 else 0
    )
    tier_wr.plot(kind='bar', ax=ax1, color=['red', 'orange', 'green'], alpha=0.7)
    ax1.axhline(y=50, color='gray', linestyle='--', alpha=0.5)
    ax1.set_ylabel('Win Rate (%)')
    ax1.set_title('Win Rate by Tier')
    ax1.set_xticklabels(ax1.get_xticklabels(), rotation=0)
    
    # Trade count by tier
    tier_count = completed.groupby('Tier').size()
    tier_count.plot(kind='bar', ax=ax2, color=['red', 'orange', 'green'], alpha=0.7)
    ax2.set_ylabel('Count')
    ax2.set_title('Trade Count by Tier')
    ax2.set_xticklabels(ax2.get_xticklabels(), rotation=0)
    
    # Avg P/L by tier
    tier_pl = completed.groupby('Tier')['ProfitPips'].mean()
    tier_pl.plot(kind='bar', ax=ax3, color=['red', 'orange', 'green'], alpha=0.7)
    ax3.axhline(y=0, color='black', linestyle='-', linewidth=0.5)
    ax3.set_ylabel('Average P/L (pips)')
    ax3.set_title('Average P/L by Tier')
    ax3.set_xticklabels(ax3.get_xticklabels(), rotation=0)
    
    # Profit factor by tier
    tier_pf = completed.groupby('Tier').apply(
        lambda x: x[x['ProfitPips'] > 0]['ProfitPips'].sum() / 
                 abs(x[x['ProfitPips'] < 0]['ProfitPips'].sum()) 
                 if len(x[x['ProfitPips'] < 0]) > 0 else 0
    )
    tier_pf.plot(kind='bar', ax=ax4, color=['red', 'orange', 'green'], alpha=0.7)
    ax4.axhline(y=1.0, color='gray', linestyle='--', alpha=0.5)
    ax4.set_ylabel('Profit Factor')
    ax4.set_title('Profit Factor by Tier')
    ax4.set_xticklabels(ax4.get_xticklabels(), rotation=0)
    
    output = Path(output_dir) / 'tier_comparison.png'
    plt.tight_layout()
    plt.savefig(output, dpi=150, bbox_inches='tight')
    print(f"✅ Saved: {output}")
    plt.close()

def main():
    if len(sys.argv) < 2:
        print("Usage: python plot_distribution.py <csv_file>")
        sys.exit(1)
    
    filepath = Path(sys.argv[1])
    
    if not filepath.exists():
        print(f"❌ File not found: {filepath}")
        sys.exit(1)
    
    output_dir = filepath.parent
    
    print("Creating visualizations...")
    df = load_data(filepath)
    
    plot_score_distribution(df, output_dir)
    plot_win_rate_by_score(df, output_dir)
    plot_tier_comparison(df, output_dir)
    
    print(f"\n✅ All plots saved to: {output_dir}")
    print("\nGenerated files:")
    print("  - score_distribution.png")
    print("  - win_rate_by_score.png")
    print("  - tier_comparison.png")

if __name__ == "__main__":
    main()
