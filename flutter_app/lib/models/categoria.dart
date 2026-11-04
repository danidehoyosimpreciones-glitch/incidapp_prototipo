class Categoria {
  final String id;
  final String nombre;
  final String descripcion;
  final bool requiereVisibilidadRestringida;

  Categoria({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.requiereVisibilidadRestringida,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      requiereVisibilidadRestringida: json['requiereVisibilidadRestringida'] ?? false,
    );
  }
}
