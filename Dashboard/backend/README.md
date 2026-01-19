# ML-Lite Dashboard Backend

FastAPI backend server for ML-Lite performance dashboard.

## Features

- CSV file monitoring and processing
- Performance metrics calculation
- REST API endpoints
- Real-time WebSocket updates (Phase 2)
- CORS enabled for frontend

## Setup

```bash
# Create virtual environment
python -m venv venv
venv\Scripts\activate  # Windows

# Install dependencies
pip install -r requirements.txt

# Run server
python main.py
```

## API Endpoints

- `GET /api/metrics` - Current performance metrics
- `GET /api/equity-curve` - Equity curve data
- `GET /api/tier-analysis` - Tier breakdown
- `GET /api/trades/recent` - Recent trades

## Configuration

Edit `config.py` to set:
- CSV file path
- Server port
- CORS origins

## Development

```bash
# Run with auto-reload
uvicorn main:app --reload --port 8000
```

## Project Structure

```
backend/
├── main.py              # FastAPI app entry
├── config.py            # Configuration
├── models.py            # Pydantic models
├── data_processor.py    # CSV processing & metrics
├── requirements.txt     # Dependencies
└── README.md           # This file
```
