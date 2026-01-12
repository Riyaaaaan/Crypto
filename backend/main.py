from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from typing import List, Optional
import uvicorn

from app.routers import prices, rates, market, klines

app = FastAPI(title="Crypto API", version="1.0.0")

# CORS middleware for Flutter frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(prices.router, prefix="/api/v1", tags=["prices"])
app.include_router(rates.router, prefix="/api/v1", tags=["rates"])
app.include_router(market.router, prefix="/api/v1", tags=["market"])
app.include_router(klines.router, prefix="/api/v1", tags=["klines"])


@app.get("/")
async def root():
    return {"message": "Crypto API - Binance Integration"}


@app.get("/health")
async def health():
    return {"status": "healthy"}


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)

