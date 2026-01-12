from fastapi import APIRouter, HTTPException, Query
from typing import List, Optional
from app.services.binance_client import BinanceClient

router = APIRouter()


@router.get("/price/{symbol}")
async def get_price(symbol: str):
    """
    Get current price for a single symbol (e.g., BTCUSDT).
    
    Returns: {"symbol": "BTCUSDT", "price": "50000.00"}
    """
    try:
        result = await BinanceClient.get_price(symbol)
        return {
            "symbol": result["symbol"],
            "price": float(result["price"])
        }
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/prices")
async def get_prices(symbols: str = Query(..., description="Comma-separated symbols (e.g., BTCUSDT,ETHUSDT)")):
    """
    Get current prices for multiple symbols efficiently.
    
    Returns: [{"symbol": "BTCUSDT", "price": "50000.00"}, ...]
    """
    try:
        symbol_list = [s.strip().upper() for s in symbols.split(",")]
        if not symbol_list:
            raise HTTPException(status_code=400, detail="At least one symbol is required")
        
        results = await BinanceClient.get_prices(symbol_list)
        return [
            {"symbol": r["symbol"], "price": float(r["price"])}
            for r in results
        ]
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

