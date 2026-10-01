import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/contacto_form.dart';

/// Pantalla para escribirle a la administración.
///
/// Está en la barra de navegación de abajo, así que cualquier persona la
/// encuentra sin conocer la app. También se puede abrir en modo diálogo desde
/// los botones de las otras pantallas: el formulario es el mismo.
///
/// No hace falta estar conectado. A una persona a la que le acaban de
/// bloquear la cuenta no le queda ningún otro canal para preguntar algo.
class ContactoScreen extends StatefulWidget {
  final bool modoAccesibleActivo;

  const ContactoScreen({Key? key, this.modoAccesibleActivo = false})
      : super(key: key);

  @override
  State<ContactoScreen> createState() => _ContactoScreenState();
}

class _ContactoScreenState extends State<ContactoScreen> {
  bool _enviado = false;

  void _alEnviar() => setState(() => _enviado = true);

  @override
  Widget build(BuildContext context) {
    final esAccesible = widget.modoAccesibleActivo;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Escribinos',
          style: TextStyle(fontSize: esAccesible ? 20 : 17),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_enviado)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      AppTheme.acentoVerdeEco.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.acentoVerdeEco),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: AppTheme.acentoVerdeEco, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Listo, ya lo leímos. Te vamos a responder lo antes '
                        'posible.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: esAccesible ? 16 : 13,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      AppTheme.acentoAzulTurquesa.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.acentoAzulTurquesa
                        .withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  'Este mensaje va directo a la administración de Switch.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: esAccesible ? 15 : 12,
                  ),
                ),
              ),
            ContactoForm(
              esAccesible: esAccesible,
              alEnviar: _alEnviar,
              textoBoton: 'ENVIAR MENSAJE',
            ),
          ],
        ),
      ),
    );
  }
}
