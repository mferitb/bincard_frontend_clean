import 'package:flutter/material.dart';
import '../services/routes_service.dart';

class FavoriteRoutesScreen extends StatelessWidget {
  const FavoriteRoutesScreen({Key? key}) : super(key: key);

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
        future: RoutesService().getFavoriteRoutes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Favori rotalar yüklenemedi.'));
          }
          final routes = snapshot.data ?? [];
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
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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