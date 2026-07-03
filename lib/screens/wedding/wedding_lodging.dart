// lib/screens/wedding/wedding_lodging.dart
import 'package:flutter/material.dart';
import 'models/boda.dart';
import 'widgets/proveedor_list_screen.dart';

class WeddingLodgingScreen extends StatelessWidget {
  const WeddingLodgingScreen({super.key});

  static final List<ProveedorBoda> _seed = [
    ProveedorBoda(id: '1', nombre: 'Hotel Fiesta Inn', categoria: 'Hotel', costo: 1500, estado: EstadoProveedor.pendiente),
  ];

  @override
  Widget build(BuildContext context) {
    return ProveedorListScreen(
      titulo: 'Hospedaje',
      emojiHeader: '🏨',
      contactoLabel: 'Teléfono',
      categoriaOptions: const ['Hotel', 'Airbnb', 'Transporte', 'Otro'],
      seed: _seed,
    );
  }
}