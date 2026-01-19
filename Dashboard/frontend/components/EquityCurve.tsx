'use client';

import { useEffect, useState } from 'react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Area, AreaChart } from 'recharts';
import { fetchEquityCurve } from '@/lib/api';

export default function EquityCurve() {
    const [data, setData] = useState<any[]>([]);
    const [period, setPeriod] = useState(7);

    useEffect(() => {
        const loadData = async () => {
            try {
                const result = await fetchEquityCurve(period);
                if (result.data && result.data.length > 0) {
                    const formatted = result.data.map((point: any) => ({
                        time: new Date(point.timestamp).toLocaleDateString(),
                        equity: point.cumulative_pips
                    }));
                    setData(formatted);
                }
            } catch (err) {
                console.error('Failed to load equity curve:', err);
            }
        };

        loadData();
        const interval = setInterval(loadData, 10000); // Refresh every 10s

        return () => clearInterval(interval);
    }, [period]);

    return (
        <div className="terminal-card h-[400px]">
            <div className="terminal-header flex items-center justify-between mb-4">
                <div>
                    <span>CUMULATIVE EQUITY RETURN (UTC)</span>
                    <span className="ml-4 text-terminal-green">+{data.length > 0 ? data[data.length - 1]?.equity.toFixed(1) : '0.0'} PIPS</span>
                </div>

                {/* Period selector */}
                <div className="flex space-x-2 text-[10px]">
                    {[1, 7, 30].map((d) => (
                        <button
                            key={d}
                            onClick={() => setPeriod(d)}
                            className={`px-2 py-1 ${period === d
                                    ? 'bg-terminal-green text-terminal-black'
                                    : 'bg-terminal-dark text-terminal-gray hover:bg-terminal-grid'
                                }`}
                        >
                            {d}D
                        </button>
                    ))}
                </div>
            </div>

            <ResponsiveContainer width="100%" height="85%">
                <AreaChart data={data}>
                    <defs>
                        <linearGradient id="equityGradient" x1="0" y1="0" x2="0" y2="1">
                            <stop offset="5%" stopColor="#00ff41" stopOpacity={0.3} />
                            <stop offset="95%" stopColor="#00ff41" stopOpacity={0} />
                        </linearGradient>
                    </defs>

                    <CartesianGrid strokeDasharray="3 3" stroke="#2a2a2a" />

                    <XAxis
                        dataKey="time"
                        stroke="#666666"
                        tick={{ fill: '#666666', fontSize: 10 }}
                    />

                    <YAxis
                        stroke="#666666"
                        tick={{ fill: '#666666', fontSize: 10 }}
                    />

                    <Tooltip
                        contentStyle={{
                            backgroundColor: '#1a1a1a',
                            border: '1px solid #2a2a2a',
                            borderRadius: 0,
                            color: '#ffffff'
                        }}
                        labelStyle={{ color: '#a0a0a0' }}
                    />

                    <Area
                        type="monotone"
                        dataKey="equity"
                        stroke="#00ff41"
                        strokeWidth={2}
                        fill="url(#equityGradient)"
                    />
                </AreaChart>
            </ResponsiveContainer>
        </div>
    );
}
