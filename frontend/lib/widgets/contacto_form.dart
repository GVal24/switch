import 'package:flutter/material.dart';
import '../services/contacto_service.dart';
import '../theme/app_theme.dart';

/// El formulario para escribirle a la administración.
///
/// Va en su propio widget y no dentro de la pantalla ni del diálogo a
/// propósito: se usa en los dos lugares y así hay una sola copia. Si el texto
/// de ayuda o el contador de caracteres cambiaran, cambian en los dos.
///
/// El contador va a la vista porque el backend corta en 2000 caracteres: es
/// mejor que la persona vea que le queda poco lugar a que le vuelva un error
/// después de escribir todo.
class ContactoForm extends StatefulWidget {
  final bool esAccesible;

  /// Se llama con el mensaje ya escrito cuando el envío termina bien.
  final VoidCallback? alEnviar;

  /// Texto del botón. El diálogo y la pantalla usan palabras distintas.
  final String textoBoton;

  const ContactoForm({
    Key? key,
    this.esAccesible = false,
    this.alEnviar,
    this.textoBoton = 'ENVIAR',
  }) : super(key: key);

  @override
  State<ContactoForm> createState() => _ContactoFormState();
}

class _ContactoFormState extends State<ContactoForm> {
  static const int _maximo = 2000;

  final TextEditingController _mensaje = TextEditingController();
  final TextEditingController _nombre = TextEditingController();
  String _asunto = 'PREGUNTA';
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _mensaje.dispose();
    _nombre.dispose();
    super.dispose();
  }

  bool get _esAccesible => widget.esAccesible;

  Future<void> _enviar() async {
    final texto = _mensaje.text.trim();
    if (texto.isEmpty) {
      setState(() => _error = 'Escribí tu consulta antes de enviarla.');
      return;
    }

    setState(() {
      _enviando = true;
      _error = null;
    });

    final error = await ContactoService.enviar(
      asunto: _asunto,
      mensaje: texto,
      nombre: _nombre.text.trim(),
    );

    if (!mounted) return;
    if (error != null) {
      setState(() {
        _enviando = false;
        _error = error;
      });
      return;
    }

    // El botón se vuelve a habilitar y los campos se limpian. Si se dejara
    // girando, el spinner quedaría animándose para siempre y `pumpAndSettle`
    // nunca terminaría: en la pantalla real tampoco pararía de girar.
    setState(() {
      _enviando = false;
      _mensaje.clear();
      _nombre.clear();
    });
    widget.alEnviar?.call();
  }

  /// Cambia el texto sin pasarlo por setState: el controller ya notifica.
  void _alEscribir(_) => setState(() {});

  @override
  Widget build(BuildContext context) {
    final restantes = _maximo - _mensaje.text.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Tenés una pregunta, un comentario o un problema? Mandalo por acá '
          'y te respondemos.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: _esAccesible ? 15 : 12,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '¿Sobre qué es?',
          style: TextStyle(
            color: Colors.white70,
            fontSize: _esAccesible ? 14 : 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        // Wrap manual en vez de ChoiceChip con spacing, que no existe en todas
        // las versiones de Flutter que usa el proyecto.
        ..._envoltura([
          for (final asunto in ContactoService.asuntos)
            _pastilla(
              ContactoService.etiquetaAsunto(asunto),
              _asunto == asunto,
              () => setState(() => _asunto = asunto),
            ),
        ]),
        const SizedBox(height: 16),
        Text(
          'Tu mensaje',
          style: TextStyle(
            color: Colors.white70,
            fontSize: _esAccesible ? 14 : 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: _esAccesible ? 180 : 140,
          child: TextField(
            controller: _mensaje,
            maxLines: 6,
            maxLength: _maximo,
            style: const TextStyle(color: Colors.white),
            onChanged: _alEscribir,
            decoration: const InputDecoration(
              hintText: 'Escribí acá tu consulta',
              hintStyle: TextStyle(color: Colors.white38),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppTheme.acentoVerdeEco),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$restantes caracteres',
            style: TextStyle(
              color: restantes < 100 ? Colors.redAccent : Colors.white38,
              fontSize: _esAccesible ? 13 : 10,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Si no estás conectado, dejá tu nombre para que sabemos de quién se '
          'trata.',
          style: TextStyle(
            color: Colors.white38,
            fontSize: _esAccesible ? 13 : 10,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: _esAccesible ? 70 : 55,
          child: TextField(
            controller: _nombre,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Tu nombre (opcional)',
              hintStyle: TextStyle(color: Colors.white38),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppTheme.acentoAzulTurquesa),
              ),
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.redAccent),
            ),
            child: Text(
              _error!,
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: _esAccesible ? 14 : 11,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: _enviando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send, size: 18),
            label: Text(
              _enviando ? 'ENVIANDO...' : widget.textoBoton,
              style: TextStyle(
                fontSize: _esAccesible ? 16 : 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.acentoVerdeEco),
            onPressed: _enviando ? null : _enviar,
          ),
        ),
      ],
    );
  }

  Widget _pastilla(String texto, bool activo, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor:
              activo ? AppTheme.acentoVerdeEco.withValues(alpha: 0.20) : null,
          foregroundColor: activo ? AppTheme.acentoVerdeEco : Colors.white54,
          side: BorderSide(
              color: activo ? AppTheme.acentoVerdeEco : Colors.white24),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        child: Text(
          texto,
          style: TextStyle(
            fontSize: _esAccesible ? 14 : 12,
            fontWeight: activo ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// Parte los botones en filas para que ninguno quede cortado a la mitad.
  List<Widget> _envoltura(List<Widget> children) {
    final filas = <Widget>[];
    var fila = <Widget>[];
    for (final hijo in children) {
      fila.add(hijo);
      if (fila.length == 3) {
        filas.add(Wrap(children: fila));
        fila = <Widget>[];
      }
    }
    if (fila.isNotEmpty) filas.add(Wrap(children: fila));
    return filas;
  }
}
