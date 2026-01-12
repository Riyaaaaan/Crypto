from fastapi import APIRouter, HTTPException
from app.services.binance_client import BinanceClient
from app.services.currency_mapper import get_symbol, is_fiat

router = APIRouter()


@router.get("/rate/{from_currency}/{to_currency}")
async def get_conversion_rate(from_currency: str, to_currency: str):
    """
    Get conversion rate between two currencies.
    Compatible with frontend's getConversionRate method.
    
    Returns: rate (float) - how many units of to_currency per 1 unit of from_currency
    """
    if from_currency.lower() == to_currency.lower():
        return 1.0
    
    try:
        # Handle USD/USDT as base
        if from_currency.lower() == "usd" or from_currency.lower() == "usdt":
            if to_currency.lower() == "usd" or to_currency.lower() == "usdt":
                return 1.0
            to_symbol = get_symbol(to_currency)
            if not to_symbol:
                raise HTTPException(status_code=400, detail=f"Unsupported currency: {to_currency}")
            if to_symbol == "USDTUSDT":
                return 1.0
            to_price = await BinanceClient.get_price(to_symbol)
            return 1.0 / float(to_price["price"])
        
        if to_currency.lower() == "usd" or to_currency.lower() == "usdt":
            from_symbol = get_symbol(from_currency)
            if not from_symbol:
                raise HTTPException(status_code=400, detail=f"Unsupported currency: {from_currency}")
            if from_symbol == "USDTUSDT":
                return 1.0
            from_price = await BinanceClient.get_price(from_symbol)
            return float(from_price["price"])
        
        # Both are crypto - convert via USDT
        from_symbol = get_symbol(from_currency)
        to_symbol = get_symbol(to_currency)
        
        if not from_symbol:
            raise HTTPException(status_code=400, detail=f"Unsupported currency: {from_currency}")
        if not to_symbol:
            raise HTTPException(status_code=400, detail=f"Unsupported currency: {to_currency}")
        
        if from_symbol == "USDTUSDT":
            if to_symbol == "USDTUSDT":
                return 1.0
            to_price = await BinanceClient.get_price(to_symbol)
            return 1.0 / float(to_price["price"])
        
        if to_symbol == "USDTUSDT":
            from_price = await BinanceClient.get_price(from_symbol)
            return float(from_price["price"])
        
        # Get both prices in USDT and calculate ratio
        from_price_data = await BinanceClient.get_price(from_symbol)
        to_price_data = await BinanceClient.get_price(to_symbol)
        
        from_price_usdt = float(from_price_data["price"])
        to_price_usdt = float(to_price_data["price"])
        
        if to_price_usdt == 0:
            raise HTTPException(status_code=400, detail=f"Rate for {to_currency} is zero")
        
        return from_price_usdt / to_price_usdt
        
    except HTTPException:
        raise
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get conversion rate: {str(e)}")

