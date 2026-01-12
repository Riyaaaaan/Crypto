# Migration Notes: CoinGecko to Binance API

## Summary

The crypto price API integration has been replaced with Binance Free Public API. All CoinGecko API calls have been removed and replaced with a new FastAPI backend that uses Binance endpoints.

## Changes Made

### Backend (New)
- **Location**: `backend/`
- **Framework**: FastAPI (Python)
- **API Provider**: Binance Public API (https://api.binance.com)
- **No API Keys Required**: Uses public endpoints only

### Frontend Updates
- **File**: `lib/services/api_service.dart`
- **Change**: Updated `_baseUrl` to point to backend (`http://localhost:8000/api/v1`)
- **Backward Compatible**: All method signatures unchanged, response formats maintained

## Backend Endpoints

### Core Endpoints
- `GET /api/v1/price/{symbol}` - Single symbol price (e.g., BTCUSDT)
- `GET /api/v1/prices?symbols=BTCUSDT,ETHUSDT` - Multiple symbols
- `GET /api/v1/klines/{symbol}?interval=1h&limit=100` - Candlestick data

### Frontend-Compatible Endpoints
- `GET /api/v1/rate/{from}/{to}` - Conversion rate (returns number)
- `GET /api/v1/market-data` - Market overview (returns array with `name`, `current_price`, `price_change_percentage_24h`, `image`, etc.)

## Features Implemented

✅ In-memory caching (20-second TTL)
✅ Timeout handling (10 seconds)
✅ Retry logic (3 retries with exponential backoff)
✅ Error handling for invalid symbols
✅ CORS enabled for frontend
✅ Concurrent requests for multiple symbols

## Running the Backend

```bash
cd backend
pip install -r requirements.txt
python main.py
```

Or with uvicorn:
```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

## Configuration

### Frontend Base URL
Update `lib/services/api_service.dart` line 20 if your backend runs on a different host/port:
```dart
static const String _baseUrl = "http://localhost:8000/api/v1";
```

For production, use your actual backend URL (e.g., `https://your-api.com/api/v1`)

## Currency Mapping

The backend automatically maps currency names to Binance symbols:
- `bitcoin` → `BTCUSDT`
- `ethereum` → `ETHUSDT`
- `cardano` → `ADAUSDT`
- etc.

See `backend/app/services/currency_mapper.py` for the full mapping.

## Notes

- **Image URLs**: Market data endpoint uses placeholder image URLs. You may want to use a proper image service or store images locally.
- **Fiat Currencies**: USD/USDT is handled as 1:1. INR and other fiats may need special handling if required.
- **No Breaking Changes**: Frontend API contract is maintained - no changes required to screen components.

## Testing

1. Start the backend server
2. Test endpoints:
   - `http://localhost:8000/docs` - Swagger UI
   - `http://localhost:8000/api/v1/price/BTCUSDT`
   - `http://localhost:8000/api/v1/rate/bitcoin/ethereum`
   - `http://localhost:8000/api/v1/market-data`

## Removed

- All CoinGecko API calls
- CoinGecko API configuration
- Old API integration code (replaced with Binance client)

