import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import '../services/api_service.dart';

enum ConversionState { idle, loading, success, error, rateLimited }

class _CacheEntry {
  final double rate;
  final DateTime timestamp;
  _CacheEntry(this.rate, this.timestamp);
}

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  final TextEditingController _amountController =
      TextEditingController(text: "1.0");
  String _fromCurrency = "bitcoin";
  String _toCurrency = "ethereum";
  double? _convertedValue;
  double? _rate;

  ConversionState _state = ConversionState.idle;
  String _errorMessage = "";

  final Map<String, _CacheEntry> _rateCache = {};
  Timer? _debounce;
  bool _isRequestInProgress = false;

  final Map<String, String> _currencySymbols = {
    "bitcoin": "BTC",
    "ethereum": "ETH",
    "tether": "USDT",
    "usd": "USD",
    "inr": "INR",
    "cardano": "ADA"
  };

  final Map<String, IconData> _currencyIcons = {
    "bitcoin": Icons.currency_bitcoin,
    "ethereum": Icons.currency_exchange,
    "tether": Icons.money,
    "usd": Icons.attach_money,
    "inr": Icons.currency_rupee,
    "cardano": Icons.album_outlined
  };

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
    _convert();
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onAmountChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      _convert(forceNetwork: false);
    });
  }

  Future<void> _convert({bool forceNetwork = true}) async {
    if (_isRequestInProgress) return;

    final String cacheKey = '$_fromCurrency-$_toCurrency';
    final now = DateTime.now();

    // 1. Check for valid cache
    if (!forceNetwork && _rateCache.containsKey(cacheKey)) {
      final entry = _rateCache[cacheKey]!;
      if (now.difference(entry.timestamp).inSeconds < 60) {
        _updateSuccessState(entry.rate);
        return;
      }
    }

    if (_amountController.text.isEmpty) return;

    setState(() {
      _isRequestInProgress = true;
      _state = ConversionState.loading;
      _errorMessage = "";
    });

    try {
      final rate =
          await ApiService.getConversionRate(_fromCurrency, _toCurrency);
      _rateCache[cacheKey] = _CacheEntry(rate, now);
      _updateSuccessState(rate);
    } on RateLimitException {
      if (_rateCache.containsKey(cacheKey)) {
        final entry = _rateCache[cacheKey]!;
        _updateRateLimitedState(entry.rate);
      } else {
        _updateErrorState("Rate limit reached. Please try again later.");
      }
    } on ApiException catch (e) {
      _updateErrorState(e.message);
    } catch (e) {
      _updateErrorState("An unexpected error occurred.");
    } finally {
      if (mounted) {
        setState(() {
          _isRequestInProgress = false;
        });
      }
    }
  }

  void _updateSuccessState(double rate) {
    if (!mounted) return;
    final amount = double.tryParse(_amountController.text) ?? 0;
    setState(() {
      _rate = rate;
      _convertedValue = amount * rate;
      _state = ConversionState.success;
    });
  }

  void _updateRateLimitedState(double staleRate) {
    if (!mounted) return;
    final amount = double.tryParse(_amountController.text) ?? 0;
    setState(() {
      _rate = staleRate;
      _convertedValue = amount * staleRate;
      _state = ConversionState.rateLimited;
      _errorMessage = "Using last available rate.";
    });
  }

  void _updateErrorState(String message) {
    if (!mounted) return;
    setState(() {
      _rate = null;
      _convertedValue = null;
      _state = ConversionState.error;
      _errorMessage = message;
    });
  }

  void _swapCurrencies() {
    setState(() {
      String temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
    _convert(forceNetwork: true);
  }

  void _onCurrencyChanged() {
    _convert(forceNetwork: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Text(
                  "Crypto Converter",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Convert cryptocurrencies with real-time rates",
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 30),
                _buildConverterCard(),
                const SizedBox(height: 20),
                _buildSummaryCard(),
                const SizedBox(height: 20),
                _buildQuickConversionButtons(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConverterCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Convert",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          _buildCurrencyRow(
            label: "From",
            currency: _fromCurrency,
            onCurrencyChanged: (val) {
              if (val != null) {
                setState(() => _fromCurrency = val);
                _onCurrencyChanged();
              }
            },
            child: TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: "0.0",
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSwapButton(),
          const SizedBox(height: 16),
          _buildCurrencyRow(
            label: "To",
            currency: _toCurrency,
            onCurrencyChanged: (val) {
              if (val != null) {
                setState(() => _toCurrency = val);
                _onCurrencyChanged();
              }
            },
            child: _buildResultWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultWidget() {
    Widget child;
    switch (_state) {
      case ConversionState.loading:
        child = const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal),
        );
        break;
      case ConversionState.error:
        child = Text(
          _errorMessage,
          textAlign: TextAlign.right,
          style: const TextStyle(color: Colors.redAccent, fontSize: 14),
        );
        break;
      case ConversionState.rateLimited:
      case ConversionState.success:
      case ConversionState.idle:
        final resultText = _convertedValue?.toStringAsFixed(6) ?? "-";
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              resultText,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            if (_state == ConversionState.rateLimited)
              const Text(
                "(recent)",
                style: TextStyle(color: Colors.amber, fontSize: 12),
              )
          ],
        );
        break;
    }
    return Container(
      alignment: Alignment.centerRight,
      height: 48,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: child,
      ),
    );
  }

  Widget _buildCurrencyRow({
    required String label,
    required String currency,
    required ValueChanged<String?> onCurrencyChanged,
    required Widget child,
  }) {
    return Row(
      children: [
        _buildCurrencySelector(label, currency, onCurrencyChanged),
        const SizedBox(width: 16),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildCurrencySelector(
      String label, String currency, ValueChanged<String?> onCurrencyChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currency,
          dropdownColor: Colors.grey[800],
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          onChanged: onCurrencyChanged,
          items: _currencySymbols.keys.map((String key) {
            return DropdownMenuItem<String>(
              value: key,
              child: Row(
                children: [
                  Icon(_currencyIcons[key], color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    _currencySymbols[key]!,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSwapButton() {
    return Center(
      child: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[700]!),
          ),
          child: const Icon(Icons.swap_vert, color: Colors.teal, size: 24),
        ),
        onPressed: _swapCurrencies,
      ),
    );
  }

  Widget _buildSummaryCard() {
    if (_state == ConversionState.error || _rate == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          Text(
            "1 ${_currencySymbols[_fromCurrency]} = ${_rate?.toStringAsFixed(4)} ${_currencySymbols[_toCurrency]}",
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_state == ConversionState.rateLimited)
                const Icon(Icons.history_toggle_off,
                    color: Colors.amber, size: 16),
              if (_state == ConversionState.rateLimited)
                const SizedBox(width: 4),
              Text(
                _state == ConversionState.rateLimited
                    ? "Recent rate"
                    : "Real-time rate",
                style: TextStyle(
                    color: _state == ConversionState.rateLimited
                        ? Colors.amber
                        : Colors.grey[400],
                    fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _state == ConversionState.loading
                  ? null
                  : () => _convert(forceNetwork: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                disabledBackgroundColor: Colors.teal.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
              child: _state == ConversionState.loading && _isRequestInProgress
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      "Refresh Rate",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickConversionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Quick Conversions",
            style: TextStyle(
                color: Colors.grey[300],
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _quickButton("bitcoin", "ethereum"),
              _quickButton("ethereum", "cardano"),
              _quickButton("bitcoin", "usd"),
            ],
          ),
        )
      ],
    );
  }

  Widget _quickButton(String from, String to) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _fromCurrency = from;
          _toCurrency = to;
        });
        _convert(forceNetwork: true);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[700]!)),
        child: Row(
          children: [
            Text("${_currencySymbols[from]} → ${_currencySymbols[to]}",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
