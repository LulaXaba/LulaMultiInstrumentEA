@echo off
REM Quick start script for ML API Test Server
REM Run this to start the Python FastAPI server for WebRequest testing

echo ============================================================
echo ML API Test Server - Quick Start
echo ============================================================
echo.

cd /d "%~dp0"

echo Checking Python installation...
python --version
if errorlevel 1 (
    echo ERROR: Python not found! Please install Python 3.8+
    pause
    exit /b 1
)
echo.

echo Starting FastAPI server on http://localhost:8000
echo.
echo Press Ctrl+C to stop the server
echo.
echo API Documentation will be available at:
echo http://localhost:8000/docs
echo.
echo ============================================================
echo.

python test_ml_api.py

pause
