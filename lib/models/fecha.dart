import 'package:dates/models/date.dart';
import 'package:flutter/material.dart';

class EventoImportante extends DateEvent {
  IconData icon;

  EventoImportante({
    required super.title,
    required super.description,
    required super.date,
    this.icon = Icons.backpack_outlined,
  }) : super(type: 'evento');
}

// Tu lista de eventos
List<EventoImportante> misEventos = [
  EventoImportante(
    title: "San Luis Potosi",
    date: "14-03-2026",
    description:
        "Vamos a una aveentura con cascadas, un jardis surrealista y mas aventuras",
  ),
];
