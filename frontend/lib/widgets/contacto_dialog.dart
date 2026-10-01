import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'contacto_form.dart';

/// Ventana para escribirle a la administración desde cualquier pantalla.
///
/// Es la versión en diálogo de [ContactoForm]: el mismo formulario, pero
/// encima de lo que se estaba viendo. Se usa desde los botones que se agregan
/// en las pantallas.
///
/// El formulario acepta con o sin sesión: una persona a la que le acaban de
/// bloquear la cuenta no tiene token válido, y es justo cuando más puede
/// necesitar preguntar algo.
class ContactoDialog extends StatelessWidget {
  final bool esAccesible;

  const ContactoDialog({Key? key, this.esAccesible = false}) : super(key: key);

  /// Abre la ventana y devuelve true si el mensaje se envió.
  static Future<bool?> mostrar(BuildContext context,
      {bool esAccesible = false}) {
    return showDialog<bool>(
      context: context,
      builder: (_) => ContactoDialog(esAccesible: esAccesible),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.superficieTarjeta,
      title: Text(
        'Escribinos',
        style: TextStyle(color: Colors.white, fontSize: esAccesible ? 20 : 17),
      ),
      content: SingleChildScrollView(
        // Alto acotado: sin esto el diálogo con un formulario largo se pasa de
        // la pantalla y el botón de enviar queda inalcanzable.
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
            maxWidth: 420,
          ),
          child: ContactoForm(
            esAccesible: esAccesible,
            alEnviar: () => Navigator.pop(context, true),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'CERRAR',
            style:
                TextStyle(color: Colors.grey, fontSize: esAccesible ? 16 : 13),
          ),
        ),
      ],
    );
  }
}
