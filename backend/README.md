# Crypto API Backend

FastAPI backend that integrates with Binance Public API for cryptocurrency price data.

## Features

- **Single Symbol Price**: Get current price for a symbol (e.g., BTCUSDT)
- **Multiple Symbols Prices**: Get prices for multiple symbols efficiently
- **Candlestick Data**: Get kline/candlestick data for charts
- **Conversion Rates**: Get conversion rates between currencies (compatible with frontend)
- **Market Data**: Get market overview data (compatible with frontend format)
- **Caching**: In-memory caching with 20-second TTL to reduce API calls
- **Retry Logic**: Automatic retry with exponential backoff
- **Timeout Handling**: 10-second timeout for all requests
- **Error Handling**: Graceful error handling for invalid symbols

## Setup

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Run the server:
```bash
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Or directly:
```bash
python main.py
```

The API will be available at `http://localhost:8000`

## API Endpoints

### Health Check
- `GET /health` - Health check endpoint
- `GET /` - API information

### Prices
- `GET /api/v1/price/{symbol}` - Get current price for a symbol (e.g., `/api/v1/price/BTCUSDT`)
- `GET /api/v1/prices?symbols=BTCUSDT,ETHUSDT` - Get prices for multiple symbols

### Candlestick Data
- `GET /api/v1/klines/{symbol}?interval=1h&limit=100` - Get candlestick data

### Conversion Rates (Frontend Compatible)
- `GET /api/v1/rate/{from_currency}/{to_currency}` - Get conversion rate (e.g., `/api/v1/rate/bitcoin/ethereum`)
  - Returns: `1.2345` (JSON number)

### Market Data (Frontend Compatible)
- `GET /api/v1/market-data` - Get market overview data
  - Returns: Array of coin objects with `name`, `current_price`, `price_change_percentage_24h`, `image`, etc.

## API Documentation

Once the server is running, visit:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## Configuration

- Cache TTL: 20 seconds (configurable in `app/services/binance_client.py`)
- Request Timeout: 10 seconds
- Max Retries: 3
- Retry Delay: 1 second (with exponential backoff)

## Notes

- No API keys required (uses Binance public endpoints)
- All endpoints are CORS-enabled for frontend integration
- Currency names are automatically mapped to Binance symbols (e.g., "bitcoin" → "BTCUSDT")

