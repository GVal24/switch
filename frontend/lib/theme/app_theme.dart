import 'package:flutter/material.dart';

class AppTheme {
  // Paleta Dark Navy Profesional (Inspirada en el modelo de la slide)
  static const Color fondoAzulOscuro =
      Color(0xFF0B132B); // Fondo azul noche muy profundo
  static const Color superficieTarjeta =
      Color(0xFF1C2541); // Tarjetas azul marino elegante
  static const Color textoClaro =
      Color(0xFFF8F9FA); // Blanco hueso súper legible
  static const Color textoSecundario =
      Color(0xFF8D99AE); // Gris perla para subtítulos
  static const Color acentoVerdeEco =
      Color(0xFF10B981); // Verde Esmeralda vibrante
  static const Color acentoAzulTurquesa = Color(0xFF3B82F6); // Azul eléctrico
  static const Color acentoNaranja = Color(0xFFF59E0B); // Ámbar/Terracota

  static ThemeData get temaEstandar {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: fondoAzulOscuro,
      primaryColor: acentoVerdeEco,
      colorScheme: const ColorScheme.dark(
        surface: superficieTarjeta,
        primary: acentoVerdeEco,
        secondary: acentoAzulTurquesa,
        onSurface: textoClaro,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: fondoAzulOscuro,
        foregroundColor: textoClaro,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: textoClaro,
            letterSpacing: -0.5),
        titleMedium: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600, color: textoClaro),
        bodyLarge: TextStyle(fontSize: 15, height: 1.5, color: textoClaro),
        bodyMedium:
            TextStyle(fontSize: 13, height: 1.4, color: textoSecundario),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: acentoVerdeEco,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      // Definido en los 4 temas para que la transición entre paletas pueda
      // interpolar los estilos sin fallar (mismos campos especificados).
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textoClaro,
          side: const BorderSide(color: textoSecundario),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  static ThemeData get temaVistaAccesible {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.black,
      primaryColor: const Color(0xFF22C55E),
      colorScheme: const ColorScheme.dark(
        surface: Color(0xFF111827),
        primary: Color(0xFF22C55E),
        secondary: Colors.white,
        onSurface: Colors.white,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
            fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white),
        titleMedium: TextStyle(
            fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        bodyLarge: TextStyle(
            fontSize: 22,
            height: 1.6,
            color: Colors.white,
            fontWeight: FontWeight.w500),
        bodyMedium: TextStyle(fontSize: 18, height: 1.5, color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF22C55E),
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 64),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white, width: 2),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  // Paleta de Alto Contraste: negro puro, blanco puro y acentos amarillos.
  // Pensada para baja visión: bordes gruesos y máximo contraste en todo.
  static ThemeData get temaAltoContraste {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.black,
      primaryColor: Colors.yellow,
      colorScheme: const ColorScheme.dark(
        surface: Colors.black,
        primary: Colors.yellow,
        secondary: Colors.yellow,
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5),
        titleMedium: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
        bodyLarge: TextStyle(
            fontSize: 17,
            height: 1.5,
            color: Colors.white,
            fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(
            fontSize: 15,
            height: 1.4,
            color: Colors.white,
            fontWeight: FontWeight.w500),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.yellow,
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Colors.white, width: 2),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white, width: 2),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.white, width: 2)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.yellow, width: 3)),
        hintStyle: const TextStyle(color: Colors.white70),
        labelStyle: const TextStyle(color: Colors.white),
      ),
    );
  }

  // Paleta Suave (Calma): tonos pastel de baja saturación, sin colores
  // vibrantes ni contrastes agresivos. Pensada para personas del espectro
  // autista o sensibles a la sobreestimulación visual.
  static ThemeData get temaPaletaSuave {
    const fondo = Color(0xFFF6F3EE); // Beige cálido muy claro
    const tarjeta = Color(0xFFFFFFFF); // Blanco puro para las tarjetas
    const texto = Color(0xFF4A4A45); // Gris cálido oscuro (no negro puro)
    const textoSuave = Color(0xFF8A877E); // Gris cálido medio
    const verde = Color(0xFF8FB79B); // Verde salvia apagado
    const azul = Color(0xFF9DB4C0); // Azul grisáceo suave

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: fondo,
      primaryColor: verde,
      colorScheme: const ColorScheme.light(
        surface: tarjeta,
        primary: verde,
        secondary: azul,
        onSurface: texto,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: fondo,
        foregroundColor: texto,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: texto,
            letterSpacing: -0.5),
        titleMedium:
            TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: texto),
        bodyLarge: TextStyle(fontSize: 15, height: 1.6, color: texto),
        bodyMedium: TextStyle(fontSize: 13, height: 1.5, color: textoSuave),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: verde,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: texto,
          side: BorderSide(color: textoSuave.withValues(alpha: 0.4)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tarjeta,
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: textoSuave.withValues(alpha: 0.4))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: verde, width: 1.5)),
      ),
      dividerTheme: DividerThemeData(color: textoSuave.withValues(alpha: 0.25)),
      cardTheme: CardThemeData(
          elevation: 0,
          color: tarjeta,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
    );
  }
}

/// Colores que respetan la paleta activa. Usar estos getters en lugar de
/// AppTheme.fondoAzulOscuro / superficieTarjeta / Colors.white para que las
/// pantallas se vean bien también con la Paleta Suave (fondo claro).
extension ColoresSegunPaleta on BuildContext {
  Color get colorFondo => Theme.of(this).scaffoldBackgroundColor;
  Color get colorTarjeta => Theme.of(this).colorScheme.surface;
  Color get colorTexto => Theme.of(this).colorScheme.onSurface;
  Color get colorTextoSuave =>
      Theme.of(this).textTheme.bodyMedium?.color ??
      Theme.of(this).colorScheme.onSurface.withValues(alpha: 0.65);
}
