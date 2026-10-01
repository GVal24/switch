import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../services/contacto_service.dart';
import '../theme/app_theme.dart';

/// Buzón donde llegan las preguntas, comentarios y pedidos de ayuda que
/// escribe la gente.
///
/// Lo que llega primero es lo que todavía no tiene respuesta: eso es lo que hay
/// que hacer. Los mensajes ya respondidos quedan más abajo, como historial, y
/// se puede volver a responder cualquiera de los dos.
///
/// El aviso de "hay N mensajes sin responder" sale en el panel de
/// administración, así que la bandeja no hay que abrirla para saber si hay algo
/// pendiente.
class MensajesContactoScreen extends StatefulWidget {
  final bool modoAccesibleActivo;
  final VoidCallback? alResponder;

  const MensajesContactoScreen({
    Key? key,
    this.modoAccesibleActivo = false,
    this.alResponder,
  }) : super(key: key);

  @override
  State<MensajesContactoScreen> createState() => _MensajesContactoScreenState();
}

class _MensajesContactoScreenState extends State<MensajesContactoScreen> {
  List<dynamic> _mensajes = [];
  bool _soloPendientes = true;
  bool _cargando = true;
  bool _procesando = false;
  int _pendientes = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  bool get _esAccesible => widget.modoAccesibleActivo;

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final res = await AdminService.obtenerMensajesContacto(
      soloPendientes: _soloPendientes,
    );
    if (!mounted) return;
    setState(() {
      _mensajes = (res['mensajes'] as List?) ?? [];
      _pendientes = (res['pendientes'] as num?)?.toInt() ?? 0;
      _cargando = false;
    });
  }

  void _avisar(String mensaje, bool exito) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
          style: TextStyle(fontSize: _esAccesible ? 16 : 14),
        ),
        backgroundColor: exito ? AppTheme.acentoVerdeEco : Colors.redAccent,
        duration: Duration(seconds: exito ? 2 : 4),
      ),
    );
  }

  Future<void> _responder(Map<String, dynamic> mensaje) async {
    final id = int.tryParse((mensaje['id'] ?? '').toString()) ?? -1;
    if (id < 0) return;

    final respuesta = await showDialog<String>(
      context: context,
      builder: (_) => _DialogoRespuesta(
        mensaje: mensaje,
        esAccesible: _esAccesible,
      ),
    );
    if (respuesta == null) return;

    setState(() => _procesando = true);
    final res = await AdminService.responderMensajeContacto(id, respuesta);
    if (!mounted) return;
    setState(() => _procesando = false);

    _avisar(res['mensaje'] ?? 'Sin respuesta del servidor.', res['exito'] == true);
    if (res['exito'] == true) {
      widget.alResponder?.call();
      _cargar();
    }
  }

  Future<void> _eliminar(Map<String, dynamic> mensaje) async {
    final id = int.tryParse((mensaje['id'] ?? '').toString()) ?? -1;
    if (id < 0) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.superficieTarjeta,
        title: Text(
          '¿Borrar este mensaje?',
          style:
              TextStyle(color: Colors.white, fontSize: _esAccesible ? 20 : 17),
        ),
        content: Text(
          'Desaparece de la bandeja y no se puede recuperar. Si sólo querés '
          'sacarlo de la lista sin responder, usá el filtro.',
          style: TextStyle(
              color: Colors.white70, fontSize: _esAccesible ? 16 : 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'CANCELAR',
              style: TextStyle(
                  color: Colors.grey, fontSize: _esAccesible ? 16 : 13),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'BORRAR',
              style: TextStyle(
                color: Colors.white,
                fontSize: _esAccesible ? 16 : 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _procesando = true);
    final exito = await AdminService.eliminarMensajeContacto(id);
    if (!mounted) return;
    setState(() => _procesando = false);

    _avisar(exito ? 'Mensaje borrado.' : 'No se pudo borrar.', exito);
    if (exito) {
      widget.alResponder?.call();
      _cargar();
    }
  }

  Widget _chip(String texto, Color color, {bool grave = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: grave ? 0.25 : 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: grave ? 1.5 : 1),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontSize: _esAccesible ? 13 : 11,
          fontWeight: grave ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _tarjeta(Map<String, dynamic> mensaje) {
    final contestado = mensaje['respuesta'] != null;
    final asunto = (mensaje['asunto'] ?? 'CONTACTO').toString();
    final id = int.tryParse((mensaje['id'] ?? '').toString()) ?? -1;
    final dni = (mensaje['autor_dni'] ?? '').toString();
    final telefono = (mensaje['autor_telefono'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.superficieTarjeta,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: contestado ? Colors.white12 : AppTheme.acentoNaranja,
          width: contestado ? 1 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  (mensaje['autor_nombre'] ?? 'Sin nombre').toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _esAccesible ? 17 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _chip(
                contestado ? 'RESPONDIDO' : 'SIN RESPONDER',
                contestado ? AppTheme.acentoVerdeEco : AppTheme.acentoNaranja,
                grave: !contestado,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _chip(ContactoService.etiquetaAsunto(asunto),
                  AppTheme.acentoAzulTurquesa),
              Text(
                mensaje['creado_legible']?.toString() ?? 'sin fecha',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: _esAccesible ? 12 : 10,
                ),
              ),
            ],
          ),
          if (dni.isNotEmpty || telefono.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              [
                if (dni.isNotEmpty) 'DNI $dni',
                if (telefono.isNotEmpty) 'Tel $telefono',
              ].join('   ·   '),
              style: TextStyle(
                color: Colors.white54,
                fontSize: _esAccesible ? 13 : 10,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              (mensaje['mensaje'] ?? '').toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: _esAccesible ? 15 : 12,
                height: 1.4,
              ),
            ),
          ),
          if (contestado) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.acentoVerdeEco.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.acentoVerdeEco.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Le respondiste${mensaje['respondio_nombre'] != null ? ' (${mensaje['respondio_nombre']})' : ''}:',
                    style: TextStyle(
                      color: AppTheme.acentoVerdeEco,
                      fontSize: _esAccesible ? 13 : 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (mensaje['respuesta'] ?? '').toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _esAccesible ? 15 : 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(contestado ? Icons.edit_outlined : Icons.reply,
                      size: 18),
                  label: Text(
                    contestado ? 'CAMBIAR RESPUESTA' : 'RESPONDER',
                    style: TextStyle(
                      fontSize: _esAccesible ? 13 : 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.acentoVerdeEco,
                  ),
                  onPressed: (_procesando || id < 0) ? null : () => _responder(mensaje),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.delete_outline, size: _esAccesible ? 24 : 20),
                color: Colors.white38,
                tooltip: 'Borrar mensaje',
                onPressed:
                    (_procesando || id < 0) ? null : () => _eliminar(mensaje),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mensajes de la gente',
          style: TextStyle(fontSize: _esAccesible ? 20 : 17),
        ),
        actions: [
          if (_pendientes > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.acentoNaranja,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_pendientes',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: _esAccesible ? 18 : 14,
                    ),
                  ),
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.refresh, size: _esAccesible ? 28 : 24),
            tooltip: 'Actualizar',
            onPressed: _cargar,
          ),
        ],
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.acentoVerdeEco))
          : RefreshIndicator(
              onRefresh: _cargar,
              color: AppTheme.acentoVerdeEco,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filtro: lo que hay que hacer primero, o todo el historial.
                    Row(
                      children: [
                        Expanded(
                          child: _BotonFiltro(
                            texto: 'SIN RESPONDER',
                            activo: _soloPendientes,
                            onTap: () {
                              setState(() => _soloPendientes = true);
                              _cargar();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _BotonFiltro(
                            texto: 'TODOS',
                            activo: !_soloPendientes,
                            onTap: () {
                              setState(() => _soloPendientes = false);
                              _cargar();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_mensajes.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(30),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.mark_email_read_outlined,
                              color: AppTheme.acentoVerdeEco,
                              size: 44,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _soloPendientes
                                  ? 'No hay mensajes esperando respuesta.'
                                  : 'Todavía nadie escribió nada.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: _esAccesible ? 15 : 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ..._mensajes
                          .map((e) => _tarjeta(e as Map<String, dynamic>)),
                    if (_procesando)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.acentoVerdeEco),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Botón del filtro "sin responder" / "todos".
class _BotonFiltro extends StatelessWidget {
  final String texto;
  final bool activo;
  final VoidCallback onTap;

  const _BotonFiltro({
    required this.texto,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: activo
            ? AppTheme.acentoVerdeEco.withValues(alpha: 0.18)
            : Colors.transparent,
        foregroundColor: activo ? AppTheme.acentoVerdeEco : Colors.white54,
        side: BorderSide(
          color: activo ? AppTheme.acentoVerdeEco : Colors.white24,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        texto,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

/// Escribe la respuesta de la administración.
///
/// StatefulWidget a propósito: el `TextEditingController` se libera en su propio
/// `dispose`. Si se crea en la pantalla y se destruye apenas vuelve el
/// `showDialog`, el `TextField` sigue montado durante la animación de cierre y
/// revienta con "A TextEditingController was used after being disposed".
class _DialogoRespuesta extends StatefulWidget {
  final Map<String, dynamic> mensaje;
  final bool esAccesible;

  const _DialogoRespuesta({required this.mensaje, required this.esAccesible});

  @override
  State<_DialogoRespuesta> createState() => _DialogoRespuestaState();
}

class _DialogoRespuestaState extends State<_DialogoRespuesta> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esAccesible = widget.esAccesible;

    return AlertDialog(
      backgroundColor: AppTheme.superficieTarjeta,
      title: Text(
        'Tu respuesta',
        style: TextStyle(color: Colors.white, fontSize: esAccesible ? 20 : 17),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Le escribió ${widget.mensaje['autor_nombre'] ?? 'alguien'}:',
              style: TextStyle(
                color: Colors.white70,
                fontSize: esAccesible ? 15 : 12,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                (widget.mensaje['mensaje'] ?? '').toString(),
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: esAccesible ? 14 : 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Alto explícito: dentro de un AlertDialog el TextField recibe altura
            // libre y el diálogo termina desbordando la pantalla.
            SizedBox(
              height: esAccesible ? 150 : 120,
              child: TextField(
                controller: _controller,
                maxLines: 5,
                maxLength: 2000,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Escribí la respuesta',
                  hintStyle: const TextStyle(color: Colors.white38),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.acentoVerdeEco),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'CANCELAR',
            style:
                TextStyle(color: Colors.grey, fontSize: esAccesible ? 16 : 13),
          ),
        ),
        ElevatedButton(
          style:
              ElevatedButton.styleFrom(backgroundColor: AppTheme.acentoVerdeEco),
          onPressed: () {
            final texto = _controller.text.trim();
            if (texto.isEmpty) return;
            Navigator.pop(context, texto);
          },
          child: const Text(
            'GUARDAR',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
