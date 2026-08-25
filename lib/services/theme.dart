import 'package:flutter/material.dart';

class AlmaTheme {
  // Colores base de la App (Paleta Oscura/Morada)
  static const Color background = Color(0xFF141229); // Fondo muy oscuro
  static const Color card = Color(0xFF1E1B3F);       // Fondo de tarjetas/paneles
  static const Color secondary = Color(0xFF2A2458); // Fondo secundario (seleccionados)
  
  static const Color primary = Color(0xFF7C4DFF);    // Morado principal
  static const Color primaryForeground = Colors.white;
  
  // Nuevos colores necesarios para la UI de ajustes
  static const Color border = Color(0xFF353066);     // Borde de contenedores
  static const Color mutedForeground = Color(0xFFA5A0C9); // Texto secundario/apagado
  static const Color accent = Color(0xFFFFC107);  
  static const Color muted = Color(0xFF2A2458);   // Amarillo para advertencias
  
  // Puedes añadir estilos de texto globales aquí si lo deseas, 
  // aunque ya usas GoogleFonts directamente en las vistas.
}