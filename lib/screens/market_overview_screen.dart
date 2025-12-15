import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MarketOverviewScreen extends StatefulWidget {
  const MarketOverviewScreen({super.key});

  @override
  State<MarketOverviewScreen> createState() => _MarketOverviewScreenState();
}

class _MarketOverviewScreenState extends State<MarketOverviewScreen> {
  List<dynamic> _coins = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final data = await ApiService.getMarketData();
    setState(() {
      _coins = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Market Overview"),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: ListView.builder(
                itemCount: _coins.length,
                itemBuilder: (context, index) {
                  final coin = _coins[index];
                  return Card(
                    color: Colors.grey[900],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(coin["image"]),
                        backgroundColor: Colors.black,
                      ),
                      title: Text(
                        coin["name"],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      subtitle: Text(
                        "\$${coin["current_price"].toStringAsFixed(2)}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: Text(
                        "${coin["price_change_percentage_24h"].toStringAsFixed(2)}%",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: coin["price_change_percentage_24h"] >= 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}