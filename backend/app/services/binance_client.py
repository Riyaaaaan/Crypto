import httpx
import time
import json
import asyncio
from typing import Dict, List, Optional, Any, Tuple
from datetime import datetime, timedelta
from functools import lru_cache


class BinanceClient:
    """Client for Binance Public API with caching, timeout, and retry logic."""
    
    BASE_URL = "https://api.binance.com/api/v3"
    TIMEOUT = 10.0
    MAX_RETRIES = 3
    RETRY_DELAY = 1.0
    
    # Cache with TTL
    _cache: Dict[str, Tuple[Any, float]] = {}
    _cache_ttl = 20  # seconds
    
    @classmethod
    def _get_cached(cls, key: str) -> Optional[Any]:
        """Get cached value if not expired."""
        if key in cls._cache:
            value, timestamp = cls._cache[key]
            if time.time() - timestamp < cls._cache_ttl:
                return value
            del cls._cache[key]
        return None
    
    @classmethod
    def _set_cache(cls, key: str, value: Any):
        """Cache a value with current timestamp."""
        cls._cache[key] = (value, time.time())
    
    @classmethod
    async def _request_with_retry(
        cls, 
        method: str, 
        endpoint: str, 
        params: Optional[Dict] = None
    ) -> Dict:
        """Make HTTP request with retry logic."""
        url = f"{cls.BASE_URL}{endpoint}"
        
        for attempt in range(cls.MAX_RETRIES):
            try:
                async with httpx.AsyncClient(timeout=cls.TIMEOUT) as client:
                    response = await client.request(method, url, params=params)
                    response.raise_for_status()
                    return response.json()
            except httpx.TimeoutException:
                if attempt == cls.MAX_RETRIES - 1:
                    raise Exception("Request timeout after retries")
                time.sleep(cls.RETRY_DELAY * (attempt + 1))
            except httpx.HTTPStatusError as e:
                if e.response.status_code == 400:
                    raise ValueError(f"Invalid symbol or parameters: {e.response.text}")
                if e.response.status_code == 429:
                    if attempt < cls.MAX_RETRIES - 1:
                        time.sleep(cls.RETRY_DELAY * (attempt + 1))
                        continue
                    raise Exception("Rate limit exceeded")
                raise Exception(f"HTTP error: {e.response.status_code}")
            except Exception as e:
                if attempt == cls.MAX_RETRIES - 1:
                    raise Exception(f"Request failed: {str(e)}")
                time.sleep(cls.RETRY_DELAY * (attempt + 1))
    
    @classmethod
    async def get_price(cls, symbol: str) -> Dict[str, Any]:
        """Get current price for a symbol (e.g., BTCUSDT)."""
        cache_key = f"price:{symbol}"
        cached = cls._get_cached(cache_key)
        if cached is not None:
            return cached
        
        try:
            data = await cls._request_with_retry("GET", "/ticker/price", {"symbol": symbol.upper()})
            cls._set_cache(cache_key, data)
            return data
        except ValueError:
            raise
        except Exception as e:
            raise Exception(f"Failed to fetch price for {symbol}: {str(e)}")
    
    @classmethod
    async def get_prices(cls, symbols: List[str]) -> List[Dict[str, Any]]:
        """Get current prices for multiple symbols efficiently using concurrent requests."""
        symbols_upper = [s.upper() for s in symbols]
        cache_key = f"prices:{','.join(sorted(symbols_upper))}"
        cached = cls._get_cached(cache_key)
        if cached is not None:
            return cached
        
        try:
            # Fetch all prices concurrently for efficiency
            tasks = [cls.get_price(symbol) for symbol in symbols_upper]
            results = await asyncio.gather(*tasks, return_exceptions=True)
            
            # Filter out exceptions and format results
            prices = []
            for result in results:
                if isinstance(result, Exception):
                    continue  # Skip failed symbols
                prices.append(result)
            
            cls._set_cache(cache_key, prices)
            return prices
        except Exception as e:
            raise Exception(f"Failed to fetch prices: {str(e)}")
    
    @classmethod
    async def get_24h_ticker(cls, symbol: str) -> Dict[str, Any]:
        """Get 24h ticker statistics for a symbol."""
        cache_key = f"ticker24h:{symbol}"
        cached = cls._get_cached(cache_key)
        if cached is not None:
            return cached
        
        try:
            data = await cls._request_with_retry("GET", "/ticker/24hr", {"symbol": symbol.upper()})
            cls._set_cache(cache_key, data)
            return data
        except ValueError:
            raise
        except Exception as e:
            raise Exception(f"Failed to fetch 24h ticker for {symbol}: {str(e)}")
    
    @classmethod
    async def get_klines(
        cls,
        symbol: str,
        interval: str = "1h",
        limit: int = 100,
        start_time: Optional[int] = None,
        end_time: Optional[int] = None
    ) -> List[List[Any]]:
        """
        Get candlestick (kline) data.
        
        Intervals: 1m, 3m, 5m, 15m, 30m, 1h, 2h, 4h, 6h, 8h, 12h, 1d, 3d, 1w, 1M
        """
        params = {
            "symbol": symbol.upper(),
            "interval": interval,
            "limit": min(limit, 1000)  # Binance max is 1000
        }
        if start_time:
            params["startTime"] = start_time
        if end_time:
            params["endTime"] = end_time
        
        cache_key = f"klines:{symbol}:{interval}:{limit}:{start_time}:{end_time}"
        cached = cls._get_cached(cache_key)
        if cached is not None:
            return cached
        
        try:
            data = await cls._request_with_retry("GET", "/klines", params)
            cls._set_cache(cache_key, data)
            return data
        except ValueError:
            raise
        except Exception as e:
            raise Exception(f"Failed to fetch klines for {symbol}: {str(e)}")
    
    @classmethod
    async def get_all_tickers_24h(cls) -> List[Dict[str, Any]]:
        """Get 24h ticker statistics for all symbols (cached)."""
        cache_key = "all_tickers_24h"
        cached = cls._get_cached(cache_key)
        if cached is not None:
            return cached
        
        try:
            data = await cls._request_with_retry("GET", "/ticker/24hr")
            cls._set_cache(cache_key, data)
            return data if isinstance(data, list) else [data]
        except Exception as e:
            raise Exception(f"Failed to fetch all tickers: {str(e)}")

