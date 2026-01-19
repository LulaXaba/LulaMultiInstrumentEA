interface TierRow {
    id: string;
    label: string;
    icon: string;
    count: number;
    winRate: number;
    netPL: number;
    status: 'ACTIVE' | 'HOLD' | 'HALTED';
    color: string;
}

export default function TierAnalysis({ tiers }: { tiers?: any }) {
    if (!tiers) return null;

    const rows: TierRow[] = [
        {
            id: 'high',
            label: 'HIGH CONFIDENCE',
            icon: '🟢',
            count: tiers.high_tier?.signals_taken || 0,
            winRate: (tiers.high_tier?.win_rate || 0) * 100,
            netPL: tiers.high_tier?.net_pips || 0,
            status: 'ACTIVE',
            color: 'terminal-green'
        },
        {
            id: 'med',
            label: 'MED CONFIDENCE',
            icon: '🟡',
            count: tiers.medium_tier?.signals_taken || 0,
            winRate: (tiers.medium_tier?.win_rate || 0) * 100,
            netPL: tiers.medium_tier?.net_pips || 0,
            status: 'HOLD',
            color: 'terminal-yellow'
        },
        {
            id: 'low',
            label: 'LOW CONFIDENCE',
            icon: '🔴',
            count: tiers.low_tier?.signals_taken || 0,
            winRate: (tiers.low_tier?.win_rate || 0) * 100,
            netPL: tiers.low_tier?.net_pips || 0,
            status: 'HALTED',
            color: 'terminal-crimson'
        }
    ];

    return (
        <div className="terminal-card">
            <div className="terminal-header mb-3">📊 TIER ANALYSIS MATRIX</div>

            <table className="w-full text-[10px]">
                <thead>
                    <tr className="border-b border-terminal-grid text-terminal-gray">
                        <th className="text-left py-2">TIER ID</th>
                        <th className="text-right py-2">COUNT</th>
                        <th className="text-right py-2">WIN %</th>
                        <th className="text-right py-2">NET P/L</th>
                        <th className="text-center py-2">STATUS</th>
                    </tr>
                </thead>
                <tbody>
                    {rows.map((row) => (
                        <tr key={row.id} className="border-b border-terminal-grid hover:bg-terminal-dark">
                            <td className="py-2 flex items-center space-x-2">
                                <span>{row.icon}</span>
                                <span className={`text-${row.color}`}>{row.label}</span>
                            </td>
                            <td className="text-right">{row.count}</td>
                            <td className={`text-right ${row.winRate > 60 ? 'text-terminal-green' : 'text-terminal-crimson'}`}>
                                {row.winRate.toFixed(1)}%
                            </td>
                            <td className={`text-right ${row.netPL > 0 ? 'text-terminal-green' : 'text-terminal-crimson'}`}>
                                {row.netPL > 0 ? '+' : ''}{row.netPL.toFixed(0)}
                            </td>
                            <td className="text-center">
                                <span className={`px-2 py-0.5 text-[9px] ${row.status === 'ACTIVE' ? 'status-active' :
                                        row.status === 'HOLD' ? 'status-hold' :
                                            'status-halted'
                                    }`}>
                                    {row.status}
                                </span>
                            </td>
                        </tr>
                    ))}
                </tbody>
            </table>
        </div>
    );
}
