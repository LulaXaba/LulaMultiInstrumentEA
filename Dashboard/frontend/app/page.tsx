'use client';

import { useEffect, useState } from 'react';
import Header from '@/components/Header';
import MetricsGrid from '@/components/MetricsGrid';
import EquityCurve from '@/components/EquityCurve';
import TierAnalysis from '@/components/TierAnalysis';
import SystemHealth from '@/components/SystemHealth';
import { fetchMetrics } from '@/lib/api';

export default function Dashboard() {
    const [metrics, setMetrics] = useState<any>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        const loadMetrics = async () => {
            try {
                const data = await fetchMetrics();
                setMetrics(data);
                setError(null);
            } catch (err) {
                setError('Failed to load data. Check if backend is running.');
                console.error(err);
            } finally {
                setLoading(false);
            }
        };

        loadMetrics();
        const interval = setInterval(loadMetrics, 5000); // Refresh every 5s

        return () => clearInterval(interval);
    }, []);

    if (loading) {
        return (
            <div className="h-screen flex items-center justify-center">
                <div className="text-terminal-green text-xl animate-pulse">
                    INITIALIZING PROTOCOL...
                </div>
            </div>
        );
    }

    if (error) {
        return (
            <div className="h-screen flex items-center justify-center">
                <div className="terminal-card max-w-xl">
                    <div className="text-terminal-crimson text-lg mb-2">❌ CONNECTION ERROR</div>
                    <div className="text-terminal-gray">{error}</div>
                    <div className="mt-4 text-xs text-terminal-gray-dark">
                        Make sure backend is running: python backend/main.py
                    </div>
                </div>
            </div>
        );
    }

    return (
        <div className="h-screen flex flex-col bg-terminal-black overflow-hidden">
            <Header metrics={metrics?.overall} />

            <div className="flex-1 overflow-auto p-3">
                {/* Top metrics grid */}
                <MetricsGrid metrics={metrics} />

                {/* Main content grid */}
                <div className="grid grid-cols-3 gap-3 mt-3">
                    {/* Equity curve - 2 columns */}
                    <div className="col-span-2">
                        <EquityCurve />
                    </div>

                    {/* Right sidebar */}
                    <div className="space-y-3">
                        <SystemHealth
                            calibration={metrics?.is_calibrated}
                            score={metrics?.calibration_score}
                        />
                        <TierAnalysis tiers={metrics} />
                    </div>
                </div>
            </div>
        </div>
    );
}
