from fastapi import APIRouter, HTTPException, Query
from typing import Optional, List
from app.services.binance_client import BinanceClient

router = APIRouter()


@router.get("/klines/{symbol}")
async def get_klines(
    symbol: str,
    interval: str = Query("1h", description="Kline interval (1m, 5m, 1h, 1d, etc.)"),
    limit: int = Query(100, ge=1, le=1000, description="Number of klines to return"),
    start_time: Optional[int] = Query(None, description="Start time in milliseconds"),
    end_time: Optional[int] = Query(None, description="End time in milliseconds"),
):
    """
    Get candlestick (kline) data for charts.
    
    Returns array of klines:
    [
        [
            open_time,
            open,
            high,
            low,
            close,
            volume,
            close_time,
            quote_volume,
            trades,
            ...
        ],
        ...
    ]
    """
    try:
        klines = await BinanceClient.get_klines(
            symbol=symbol,
            interval=interval,
            limit=limit,
            start_time=start_time,
            end_time=end_time
        )
        
        # Format response
        formatted_klines = []
        for k in klines:
            formatted_klines.append({
                "open_time": k[0],
                "open": float(k[1]),
                "high": float(k[2]),
                "low": float(k[3]),
                "close": float(k[4]),
                "volume": float(k[5]),
                "close_time": k[6],
                "quote_volume": float(k[7]),
                "trades": k[8],
            })
        
        return formatted_klines
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

