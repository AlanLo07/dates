// lib/screens/wedding/wedding_flowers.dart
import 'package:flutter/material.dart';
import 'models/boda.dart';
import 'widgets/proveedor_list_screen.dart';

class WeddingFlowersScreen extends StatelessWidget {
  const WeddingFlowersScreen({super.key});

  static final List<ProveedorBoda> _seed = [
    ProveedorBoda(id: '1', nombre: 'Florería Luna', categoria: 'Ramo de novia', costo: 1800, estado: EstadoProveedor.pendiente),
    ProveedorBoda(id: '2', nombre: 'Centros de mesa blancos', categoria: 'Centros de mesa', costo: 4500, estado: EstadoProveedor.confirmado),
  ];

  @override
  Widget build(BuildContext context) {
    return ProveedorListScreen(
      titulo: 'Flores',
      emojiHeader: '🌸',
      contactoLabel: 'Contacto',
      categoriaOptions: const [
        'Ramo de novia',
        'Centros de mesa',
        'Arco / Ceremonia',
        'Decoración salón',
        'Boutonnieres',
        'Otro',
      ],
      seed: _seed,
    );
  }
}