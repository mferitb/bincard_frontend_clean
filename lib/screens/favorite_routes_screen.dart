import 'package:flutter/material.dart';
import '../services/routes_service.dart';
import '../widgets/custom_message.dart';

class FavoriteRoutesScreen extends StatefulWidget {
  const FavoriteRoutesScreen({Key? key}) : super(key: key);

  @override
  State<FavoriteRoutesScreen> createState() => _FavoriteRoutesScreenState();
}

class _FavoriteRoutesScreenState extends State<FavoriteRoutesScreen> {
  late Future<List<RouteNameDTO>> _futureRoutes;
  List<RouteNameDTO> _routes = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _futureRoutes = _loadRoutes();
  }

  Future<List<RouteNameDTO>> _loadRoutes() async {
    final routes = await RoutesService().getFavoriteRoutes();
    _routes = routes;
    return routes;
  }

  Future<void> _removeFavorite(int routeId) async {
    setState(() { _loading = true; });
    final success = await RoutesService().removeFavoriteRoute(routeId);
    setState(() { _loading = false; });
    if (success) {
      setState(() {
        _routes.removeWhere((r) => r.id == routeId);
      });
      CustomMessage.show(
        context,
        message: 'Favorilerden kaldırıldı',
        type: MessageType.info,
      );
    } else {
      CustomMessage.show(
        context,
        message: 'Favorilerden kaldırma başarısız',
        type: MessageType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favori Rotaların'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: FutureBuilder<List<RouteNameDTO>>(
        future: _futureRoutes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _routes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Favori rotalar yüklenemedi.'));
          }
          final routes = _routes;
          if (routes.isEmpty) {
            return const Center(child: Text('Favori rotanız yok.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: routes.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final route = routes[index];
              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.star, color: Colors.amber, size: 24),
                  ),
                  title: Text(route.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${route.startStationName} → ${route.endStationName}'),
                  trailing: _loading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : IconButton(
                          icon: const Icon(Icons.star, color: Colors.amber),
                          tooltip: 'Favorilerden kaldır',
                          onPressed: () => _removeFavorite(route.id),
                        ),
                  onTap: () {
                    // Detay ekranına yönlendirme eklenebilir
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}