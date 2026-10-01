import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../theme/app_theme.dart';

/// Cuentas bloqueadas o penalizadas, y la forma de levantarlas.
///
/// Es el camino inverso al bloqueo. Sin esta pantalla la administración puede
/// penalizar a alguien pero se queda sin manera de deshacerlo, y una sanción
/// puesta por error queda sin arreglo.
///
/// Hay dos situaciones y se muestran separadas porque no son lo mismo:
///   - Bloqueo permanente: la cuenta no puede ni entrar a la plataforma.
///   - Penalización: entra pero no puede publicar, hasta una fecha.
///
/// Una penalización cuyo plazo ya venció se marca como tal: el sistema la
/// levanta sola la próxima vez que esa persona entra, pero acá queda a la vista
/// para que la administración sepa qué había pasado.
class UsuariosBloqueadosScreen extends StatefulWidget {
  final bool modoAccesibleActivo;

  const UsuariosBloqueadosScreen({
    Key? key,
    this.modoAccesibleActivo = false,
  }) : super(key: key);

  @override
  State<UsuariosBloqueadosScreen> createState() =>
      _UsuariosBloqueadosScreenState();
}

class _UsuariosBloqueadosScreenState extends State<UsuariosBloqueadosScreen> {
  List<dynamic> _usuarios = [];
  bool _cargando = true;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  bool get _esAccesible => widget.modoAccesibleActivo;

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final lista = await AdminService.obtenerUsuariosBloqueados();
    if (!mounted) return;
    setState(() {
      _usuarios = lista;
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

  Future<void> _reactivar(Map<String, dynamic> usuario) async {
    final nombre = '${usuario['nombre'] ?? ''} ${usuario['apellido'] ?? ''}'
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
    final id = int.tryParse((usuario['id'] ?? '').toString()) ?? -1;
    if (id < 0) return;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.superficieTarjeta,
        title: Text(
          '¿Dar de alta a $nombre?',
          style:
              TextStyle(color: Colors.white, fontSize: _esAccesible ? 20 : 17),
        ),
        content: SingleChildScrollView(
          child: Text(
            'La cuenta vuelve a estar activa: la persona entra a la plataforma y '
            'puede publicar de nuevo.\n\n'
            'Lo que la persona había publicado antes sigue como estaba. Las '
            'publicaciones que estaban esperando revisión vuelven a la cola.',
            style: TextStyle(
                color: Colors.white70, fontSize: _esAccesible ? 16 : 13),
          ),
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
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.acentoVerdeEco),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'DAR DE ALTA',
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

    if (confirmado != true) return;

    setState(() => _procesando = true);
    final res = await AdminService.reactivarUsuario(id);
    if (!mounted) return;
    setState(() => _procesando = false);

    _avisar(res['mensaje'] ?? 'Sin respuesta del servidor.', res['exito'] == true);
    if (res['exito'] == true) _cargar();
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

  /// Explica en palabras simples por qué esa cuenta está bloqueada.
  List<Widget> _situacion(Map<String, dynamic> usuario) {
    final deshabilitado = usuario['deshabilitado'] == true;
    final vencido = usuario['suspension_vencida'] == true;
    final dias = (usuario['dias_restantes'] as num?)?.toInt();

    if (deshabilitado) {
      return [
        _chip('CUENTA BLOQUEADA', Colors.redAccent, grave: true),
        const SizedBox(height: 6),
        Text(
          'No puede entrar a la plataforma.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: _esAccesible ? 15 : 12,
          ),
        ),
      ];
    }

    if (vencido) {
      return [
        _chip('LA PENALIZACIÓN YA VENCIÓ', AppTheme.acentoNaranja),
        const SizedBox(height: 6),
        Text(
          'El plazo terminó. Se levanta sola la próxima vez que esa persona '
          'entra, o podés darla de alta ahora.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: _esAccesible ? 15 : 12,
          ),
        ),
      ];
    }

    return [
      _chip('PENALIZADA', AppTheme.acentoNaranja),
      const SizedBox(height: 6),
      Text(
        dias != null && dias > 0
            ? 'Puede entrar y mirar, pero no puede publicar. Le quedan $dias '
                'día${dias == 1 ? '' : 's'}.'
            : 'Puede entrar y mirar, pero no puede publicar.',
        style: TextStyle(
          color: Colors.white70,
          fontSize: _esAccesible ? 15 : 12,
        ),
      ),
    ];
  }

  Widget _tarjeta(Map<String, dynamic> usuario) {
    final nombre = '${usuario['nombre'] ?? ''} ${usuario['apellido'] ?? ''}'
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
    final motivo = (usuario['motivo_suspension'] ?? '').toString().trim();
    final id = int.tryParse((usuario['id'] ?? '').toString()) ?? -1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.superficieTarjeta,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  nombre.isEmpty ? 'Cuenta sin nombre' : nombre,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _esAccesible ? 18 : 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (usuario['rol'] == 'ADMIN')
                _chip('ADMIN', AppTheme.acentoAzulTurquesa),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'DNI ${usuario['dni'] ?? 'sin dato'}   ·   Alta: ${usuario['creado_legible'] ?? 'sin fecha'}',
            style: TextStyle(
              color: Colors.white38,
              fontSize: _esAccesible ? 13 : 10,
            ),
          ),
          const SizedBox(height: 10),
          ..._situacion(usuario),
          if (usuario['suspendido_hasta_legible'] != null) ...[
            const SizedBox(height: 6),
            Text(
              'Hasta el ${usuario['suspendido_hasta_legible']}',
              style: TextStyle(
                color: Colors.white38,
                fontSize: _esAccesible ? 13 : 10,
              ),
            ),
          ],
          if (motivo.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Motivo: $motivo',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: _esAccesible ? 14 : 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.lock_open, size: 18),
              label: Text(
                'DAR DE ALTA NUEVAMENTE',
                style: TextStyle(
                  fontSize: _esAccesible ? 14 : 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.acentoVerdeEco,
              ),
              onPressed: (_procesando || id < 0) ? null : () => _reactivar(usuario),
            ),
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
          'Cuentas bloqueadas',
          style: TextStyle(fontSize: _esAccesible ? 20 : 17),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                '${_usuarios.length}',
                style: TextStyle(
                  color: AppTheme.acentoNaranja,
                  fontWeight: FontWeight.bold,
                  fontSize: _esAccesible ? 20 : 16,
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
                    Container(
                      width: double.infinity,
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
                        'Acá ves a quién se le bloqueó la cuenta y a quién se '
                        'le puso una penalización, y podés levantar las dos. '
                        'Dar de alta no borra lo que esa persona había '
                        'publicado: eso sigue pasando por la cola de revisión.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _esAccesible ? 15 : 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_usuarios.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(30),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.verified_user_outlined,
                              color: AppTheme.acentoVerdeEco,
                              size: 44,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No hay ninguna cuenta bloqueada ni penalizada.',
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
                      ..._usuarios
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
