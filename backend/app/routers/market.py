from fastapi import APIRouter, HTTPException
from typing import List, Dict, Any
from app.services.binance_client import BinanceClient
from app.services.currency_mapper import POPULAR_SYMBOLS, get_name

router = APIRouter()


@router.get("/market-data")
async def get_market_data():
    """
    Get market overview data compatible with CoinGecko format.
    Returns top coins with price and 24h change percentage.
    """
    try:
        # Get 24h ticker data for popular symbols
        tickers = await BinanceClient.get_all_tickers_24h()
        
        # Filter for popular symbols and format to match frontend expectations
        popular_tickers = [
            t for t in tickers 
            if t["symbol"] in POPULAR_SYMBOLS
        ]
        
        # Sort by volume (or price change) and take top 10
        popular_tickers.sort(key=lambda x: float(x.get("quoteVolume", 0)), reverse=True)
        popular_tickers = popular_tickers[:10]
        
        # Format to match CoinGecko response structure
        formatted_data: List[Dict[str, Any]] = []
        
        for ticker in popular_tickers:
            symbol = ticker["symbol"]
            price = float(ticker["lastPrice"])
            price_change_pct = float(ticker["priceChangePercent"])
            name = get_name(symbol)
            
            formatted_data.append({
                "id": symbol.lower().replace("usdt", ""),
                "symbol": symbol.replace("USDT", "").lower(),
                "name": name,
                "image": f"https://assets.coingecko.com/coins/images/1/large/{symbol.replace('USDT', '').lower()}.png",  # Placeholder
                "current_price": price,
                "price_change_percentage_24h": price_change_pct,
                "market_cap": float(ticker.get("quoteVolume", 0)),
                "total_volume": float(ticker.get("volume", 0)),
            })
        
        return formatted_data
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch market data: {str(e)}")

