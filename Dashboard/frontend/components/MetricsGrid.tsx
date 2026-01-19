interface MetricCardProps {
    label: string;
    value: string | number;
    change?: string;
    trend?: 'up' | 'down' | 'neutral';
    icon?: string;
}

function MetricCard({ label, value, change, trend, icon }: MetricCardProps) {
    const trendColor = trend === 'up' ? 'positive' : trend === 'down' ? 'negative' : 'neutral';
    const trendIcon = trend === 'up' ? '↗' : trend === 'down' ? '↘' : '→';

    return (
        <div className="terminal-card">
            <div className="terminal-header flex items-center justify-between">
                <span>{label}</span>
                {icon && <span className="text-terminal-blue">{icon}</span>}
            </div>
            <div className={`metric-value ${trendColor}`}>
                {value}
            </div>
            {change && (
                <div className={`text-xs mt-1 ${trendColor}`}>
                    {trendIcon} {change}
                </div>
            )}
        </div>
    );
}

export default function MetricsGrid({ metrics }: { metrics?: any }) {
    if (!metrics) return null;

    const { overall, high_tier } = metrics;

    // Format profit factor
    const pf = overall?.profit_factor?.toFixed(2) || '0.00';
    const pfChange = overall?.profit_factor > 1.5 ? '+8.05%' : '-2.1%';
    const pfTrend = overall?.profit_factor > 1.5 ? 'up' : 'down';

    // Format sharpe ratio
    const sr = overall?.sharpe_ratio?.toFixed(2) || '0.00';

    // Format avg pip gain
    const avgPips = high_tier?.expectancy?.toFixed(1) || '0.0';
    const pipTrend = parseFloat(avgPips) > 0 ? 'up' : 'down';

    // Signal / Taken ratio
    const signalTaken = overall?.take_rate?.toFixed(2) || '0.00';

    return (
        <div className="grid grid-cols-4 gap-3">
            <MetricCard
                label="PROFIT FACTOR"
                value={pf}
                change={pfChange}
                trend={pfTrend}
                icon="📊"
            />

            <MetricCard
                label="SHARPE RATIO"
                value={sr}
                change="+0.91%"
                trend="up"
                icon="📈"
            />

            <MetricCard
                label="AVG PIP GAIN"
                value={`+${avgPips}`}
                change="+1.2%"
                trend={pipTrend}
                icon="💹"
            />

            <MetricCard
                label="SIGNAL / TAKEN"
                value={signalTaken}
                change="-2.0%"
                trend="down"
                icon="⚡"
            />
        </div>
    );
}
