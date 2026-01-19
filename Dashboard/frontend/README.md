# ML-Lite Dashboard - Frontend

Next.js frontend for ML-Lite performance dashboard with Bloomberg Terminal aesthetic.

## Quick Start

```bash
# Install dependencies
npm install

# Set environment variable
echo NEXT_PUBLIC_API_URL=http://localhost:8000 > .env.local

# Run development server
npm run dev

# Open browser
# Visit: http://localhost:3000
```

## Features

- **Bloomberg Terminal Aesthetic**
  - Dark theme (#0a0a0a background)
  - Neon green (#00ff41) for gains
  - Crimson (#ff0844) for losses
  - Monospace fonts (JetBrains Mono)

- **Real-Time Updates**
  - Auto-refresh every 5 seconds
  - Live equity curve
  - Performance metrics

- **Components**
  - Header with system stats
  - Metrics grid (4 key metrics)
  - Equity curve chart
  - Tier analysis table
  - System health panel

## Project Structure

```
frontend/
├── app/
│   ├── page.tsx         # Main dashboard page
│   ├── layout.tsx       # Root layout
│   └── globals.css      # Bloomberg theme styles
├── components/
│   ├── Header.tsx       # Top bar
│   ├── MetricsGrid.tsx  # Metric cards
│   ├── EquityCurve.tsx  # Main chart
│   ├── TierAnalysis.tsx # Tier table
│   └── SystemHealth.tsx # Health panel
├── lib/
│   └── api.ts           # API client
└── package.json
```

## Configuration

Create `.env.local`:
```
NEXT_PUBLIC_API_URL=http://localhost:8000
```

## Build for Production

```bash
npm run build
npm start
```

## Requirements

- Node.js 18+
- Backend running on port 8000

## Tech Stack

- Next.js 14
- TypeScript
- Tailwind CSS
- Recharts
