/**
 * API client for ML-Lite backend
 */

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export async function fetchMetrics() {
    const response = await fetch(`${API_URL}/api/metrics`);
    if (!response.ok) {
        throw new Error('Failed to fetch metrics');
    }
    return response.json();
}

export async function fetchEquityCurve(days: number = 7) {
    const response = await fetch(`${API_URL}/api/equity-curve?days=${days}`);
    if (!response.ok) {
        throw new Error('Failed to fetch equity curve');
    }
    return response.json();
}

export async function fetchRecentTrades(limit: number = 20) {
    const response = await fetch(`${API_URL}/api/trades/recent?limit=${limit}`);
    if (!response.ok) {
        throw new Error('Failed to fetch trades');
    }
    return response.json();
}

export async function reloadData() {
    const response = await fetch(`${API_URL}/api/reload`, { method: 'POST' });
    if (!response.ok) {
        throw new Error('Failed to reload data');
    }
    return response.json();
}
