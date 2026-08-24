import 'package:flutter/material.dart';

class BotonAccesibilidad extends StatelessWidget {
  final VoidCallback onPressed;
  final bool modoAccesibleActivo;
  final bool esFlotante;

  const BotonAccesibilidad({
    Key? key,
    required this.onPressed,
    required this.modoAccesibleActivo,
    this.esFlotante = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (esFlotante) {
      return Semantics(
        label: modoAccesibleActivo
            ? 'Desactivar Vista Accesible'
            : 'Activar Vista Accesible para Baja Visión',
        button: true,
        child: FloatingActionButton.extended(
          heroTag: 'btn_accesibilidad_flotante',
          onPressed: onPressed,
          backgroundColor: modoAccesibleActivo
              ? const Color(0xFF1B3B2B)
              : theme.primaryColor,
          icon: Icon(
            modoAccesibleActivo ? Icons.visibility : Icons.accessibility_new,
            color: Colors.white,
            size: modoAccesibleActivo ? 30 : 24,
          ),
          label: Text(
            modoAccesibleActivo ? 'VISTA ESTÁNDAR' : 'VISTA ACCESIBLE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: modoAccesibleActivo ? 16 : 13,
            ),
          ),
        ),
      );
    }

    return Semantics(
      label: modoAccesibleActivo
          ? 'Desactivar Vista Accesible de letra grande'
          : 'Activar Vista Accesible de letra grande',
      button: true,
      child: Tooltip(
        message: 'Cambiar a Vista Accesible (Baja Visión / Alto Contraste)',
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  modoAccesibleActivo
                      ? Icons.visibility
                      : Icons.accessibility_new,
                  size: modoAccesibleActivo ? 32 : 26,
                  color: theme.colorScheme.onSurface,
                ),
                if (modoAccesibleActivo) ...[
                  const SizedBox(width: 4),
                  const Text(
                    'AA',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}