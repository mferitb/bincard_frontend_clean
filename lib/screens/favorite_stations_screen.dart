import 'package:flutter/material.dart';
import '../models/station_model.dart';
import '../services/station_service.dart';
import '../theme/app_theme.dart';

class FavoriteStationsScreen extends StatelessWidget {
  const FavoriteStationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text('Favori Durakların', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<StationModel>>(
        future: StationService().getFavoriteStations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Favori duraklar yüklenemedi.'));
          }
          final stations = snapshot.data ?? [];
          if (stations.isEmpty) {
            return const Center(child: Text('Favori durağınız yok.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: stations.length,
            itemBuilder: (context, index) {
              final station = stations[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(Icons.directions_bus, color: AppTheme.primaryColor),
                  title: Text(station.name),
                  subtitle: Text('${station.city}, ${station.district}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 