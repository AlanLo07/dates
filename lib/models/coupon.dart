class CouponGift {
  const CouponGift({
    required this.nombre,
    required this.descripcion,
    this.canjeado = false,
  });

  final String nombre;
  final String descripcion;
  final bool canjeado;

  factory CouponGift.fromJson(Map<String, dynamic> json) {
    return CouponGift(
      nombre: json['nombre']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      canjeado: json['canjeado'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'descripcion': descripcion,
    'canjeado': canjeado,
  };

  CouponGift copyWith({
    String? nombre,
    String? descripcion,
    bool? canjeado,
  }) {
    return CouponGift(
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      canjeado: canjeado ?? this.canjeado,
    );
  }
}