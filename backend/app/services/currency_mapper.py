"""Currency name to Binance symbol mapping and conversion utilities."""

# Mapping from common currency names to Binance symbols (USDT pairs)
CURRENCY_TO_SYMBOL = {
    "bitcoin": "BTCUSDT",
    "btc": "BTCUSDT",
    "ethereum": "ETHUSDT",
    "eth": "ETHUSDT",
    "tether": "USDTUSDT",  # USDT/USDT is 1:1
    "usdt": "USDTUSDT",
    "cardano": "ADAUSDT",
    "ada": "ADAUSDT",
    "bnb": "BNBUSDT",
    "solana": "SOLUSDT",
    "sol": "SOLUSDT",
    "xrp": "XRPUSDT",
    "ripple": "XRPUSDT",
    "polkadot": "DOTUSDT",
    "dot": "DOTUSDT",
    "dogecoin": "DOGEUSDT",
    "doge": "DOGEUSDT",
    "matic": "MATICUSDT",
    "polygon": "MATICUSDT",
    "usd": "USDTUSDT",  # USD equivalent to USDT for pricing
    "inr": None,  # Fiat, needs special handling
}

# Reverse mapping for display names
SYMBOL_TO_NAME = {
    "BTCUSDT": "Bitcoin",
    "ETHUSDT": "Ethereum",
    "USDTUSDT": "Tether",
    "ADAUSDT": "Cardano",
    "BNBUSDT": "BNB",
    "SOLUSDT": "Solana",
    "XRPUSDT": "Ripple",
    "DOTUSDT": "Polkadot",
    "DOGEUSDT": "Dogecoin",
    "MATICUSDT": "Polygon",
}

# Popular symbols for market overview
POPULAR_SYMBOLS = [
    "BTCUSDT",
    "ETHUSDT",
    "BNBUSDT",
    "SOLUSDT",
    "XRPUSDT",
    "ADAUSDT",
    "DOGEUSDT",
    "DOTUSDT",
    "MATICUSDT",
    "AVAXUSDT",
]


def get_symbol(currency: str) -> Optional[str]:
    """Convert currency name to Binance symbol."""
    currency_lower = currency.lower()
    return CURRENCY_TO_SYMBOL.get(currency_lower)


def get_name(symbol: str) -> str:
    """Get display name for a symbol."""
    return SYMBOL_TO_NAME.get(symbol, symbol.replace("USDT", ""))


def is_fiat(currency: str) -> bool:
    """Check if currency is a fiat currency."""
    return currency.lower() in ["usd", "inr"]

