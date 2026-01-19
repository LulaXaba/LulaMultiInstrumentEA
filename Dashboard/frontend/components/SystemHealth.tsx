interface HealthBarProps {
    label: string;
    value: number;
    status: 'optimal' | 'warning' | 'critical';
}

function HealthBar({ label, value, status }: HealthBarProps) {
    const color = status === 'optimal' ? 'bg-terminal-green' :
        status === 'warning' ? 'bg-terminal-yellow' :
            'bg-terminal-crimson';

    return (
        <div className="mb-3">
            <div className="flex justify-between text-[9px] text-terminal-gray mb-1">
                <span>{label}</span>
                <span>{value.toFixed(1)}%</span>
            </div>
            <div className="w-full bg-terminal-dark h-1">
                <div
                    className={`${color} h-full transition-all duration-500`}
                    style={{ width: `${value}%` }}
                />
            </div>
        </div>
    );
}

export default function SystemHealth({
    calibration = true,
    score = 94.2
}: {
    calibration?: boolean;
    score?: number;
}) {
    return (
        <div className="terminal-card">
            <div className="terminal-header mb-3">⚙️ SYSTEM HEALTH</div>

            <HealthBar
                label="MODEL CONFIDENCE"
                value={score}
                status="optimal"
            />

            <HealthBar
                label="FEATURE DRIFT"
                value={0.2}
                status="optimal"
            />

            <HealthBar
                label="STATUS: STABLE"
                value={100}
                status="optimal"
            />

            {/* Calibration status */}
            <div className="mt-4 pt-3 border-t border-terminal-grid">
                <div className="flex items-center justify-between text-[10px]">
                    <span className="text-terminal-gray">VOLATILITY IDX:</span>
                    <span className="text-terminal-crimson font-bold">HIGH</span>
                </div>
            </div>

            {/* Additional stats */}
            <div className="mt-3 space-y-2 text-[10px]">
                <div className="flex justify-between">
                    <span className="text-terminal-gray">Momentum (1H):</span>
                    <span className="text-terminal-green">+82%</span>
                </div>
                <div className="flex justify-between">
                    <span className="text-terminal-gray">Momentum (Skip):</span>
                    <span className="text-terminal-crimson">-18%</span>
                </div>
            </div>
        </div>
    );
}
