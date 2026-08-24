import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'mis_trueques_screen.dart';

class PerfilScreen extends StatefulWidget {
  final Map<String, dynamic>? usuarioActual; // Usuario logueado
  final Map<String, dynamic>? usuarioVisitado; // Usuario del catálogo (opcional)
  final VoidCallback onToggleAccesibilidad;
  final bool modoAccesibleActivo;
  final Function(Map<String, dynamic>?)? onSesionCambiada;
  final VoidCallback? onMostrarLoginAdmin;

  const PerfilScreen({
    Key? key,
    this.usuarioActual,
    this.usuarioVisitado,
    required this.onToggleAccesibilidad,
    required this.modoAccesibleActivo,
    this.onSesionCambiada,
    this.onMostrarLoginAdmin,
  }) : super(key: key);

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  Future<Map<String, dynamic>?>? _futuroPerfil;

  @override
  void initState() {
    super.initState();
    final bool esMiPerfil = widget.usuarioVisitado == null;
    final bool estaLogueado = widget.usuarioActual != null &&
        widget.usuarioActual!['id'] != null &&
        widget.usuarioActual!['id'] != 'invitado';
    if (esMiPerfil && estaLogueado) {
      _futuroPerfil = ApiService.obtenerMiPerfil();
    }
  }

  IconData _iconoNivel(int numero) {
    switch (numero) {
      case 2:
        return Icons.spa_rounded;
      case 3:
        return Icons.workspace_premium_rounded;
      case 4:
        return Icons.star_rounded;
      case 5:
        return Icons.emoji_events_rounded;
      default:
        return Icons.eco_rounded;
    }
  }

  IconData _iconoInsignia(String codigo) {
    switch (codigo) {
      case 'PRIMER_TRUEQUE':
        return Icons.swap_horiz_rounded;
      case 'ALMA_TRUEQUE':
        return Icons.autorenew_rounded;
      case 'VOLUNTARIO':
        return Icons.volunteer_activism_rounded;
      case 'MANOS_SOLIDARIAS':
        return Icons.pan_tool_rounded;
      case 'CORAZON_ORO':
        return Icons.favorite_rounded;
      case 'VOZ_CONFIABLE':
        return Icons.record_voice_over_rounded;
      case 'PIONERO':
        return Icons.emoji_people_rounded;
      case 'MADRUGADOR':
        return Icons.wb_twilight_rounded;
      default:
        return Icons.military_tech_rounded;
    }
  }

  void _mostrarDialogoReporte() {
    final visitado = widget.usuarioVisitado;
    if (visitado == null || (visitado['id'] ?? '').toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se puede reportar a este usuario.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final motivoController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colorTarjeta,
        title: Text(
          'Reportar a ${visitado['nombre'] ?? 'usuario'}',
          style: TextStyle(color: context.colorTexto, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Describí el problema o irregularidad con esta cuenta:',
              style: TextStyle(color: context.colorTextoSuave, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: motivoController,
              style: TextStyle(color: context.colorTexto),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ej: Incumplimiento en intercambio, conducta inapropiada...',
                hintStyle: TextStyle(color: context.colorTextoSuave.withValues(alpha: 0.5), fontSize: 12),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.colorTextoSuave.withValues(alpha: 0.3))),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppTheme.acentoVerdeEco)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              final exito = await ApiService.reportarUsuario(
                reportanteId: (widget.usuarioActual?['id'] ?? '').toString(),
                reportanteNombre: widget.usuarioActual?['nombre'] ?? '',
                reportadoId: (visitado['id'] ?? '').toString(),
                reportadoNombre: visitado['nombre'] ?? '',
                motivo: motivoController.text.trim(),
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(exito
                      ? 'Reporte enviado. El equipo de moderación lo va a revisar.'
                      : 'No se pudo enviar el reporte. ¿Iniciaste sesión?'),
                  backgroundColor: exito ? AppTheme.acentoVerdeEco : Colors.redAccent,
                ),
              );
            },
            child: const Text('ENVIAR REPORTE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Definir si estoy viendo MI perfil o el de OTRO usuario
    final bool esMiPerfil = widget.usuarioVisitado == null;

    // Si es mi perfil pero no estoy logueado, mostrar Login
    final bool estaLogueado = widget.usuarioActual != null &&
        widget.usuarioActual!['id'] != null &&
        widget.usuarioActual!['id'] != 'invitado';

    if (esMiPerfil && !estaLogueado) {
      return LoginScreen(
        onToggleAccesibilidad: widget.onToggleAccesibilidad,
        modoAccesibleActivo: widget.modoAccesibleActivo,
        onAdminPressed: widget.onMostrarLoginAdmin,
        onSesionIniciada: (usuario) {
          if (widget.onSesionCambiada != null) {
            widget.onSesionCambiada!(usuario);
          }
        },
      );
    }

    // Factores de accesibilidad dinámicos
    final double factorTexto = widget.modoAccesibleActivo ? 1.25 : 1.0;
    final double factorIconos = widget.modoAccesibleActivo ? 1.2 : 1.0;
    final Color colorFondoTarjeta = context.colorTarjeta;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          esMiPerfil ? 'Mi Perfil' : 'Perfil de ${widget.usuarioVisitado?['nombre'] ?? ''}',
          style: TextStyle(fontSize: 18 * factorTexto),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (esMiPerfil && widget.onMostrarLoginAdmin != null)
            IconButton(
              icon: Icon(Icons.admin_panel_settings_outlined, color: context.colorTextoSuave, size: 24 * factorIconos),
              tooltip: 'Acceso Administración',
              onPressed: widget.onMostrarLoginAdmin,
            ),
          // Banderita para reportar (solo al ver a OTRO usuario)
          if (!esMiPerfil)
            IconButton(
              icon: Icon(Icons.flag_outlined, color: Colors.redAccent, size: 24 * factorIconos),
              tooltip: 'Reportar usuario',
              onPressed: _mostrarDialogoReporte,
            ),
        ],
      ),
      body: esMiPerfil
          ? FutureBuilder<Map<String, dynamic>?>(
              future: _futuroPerfil,
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.acentoVerdeEco));
                }
                final perfil = snapshot.data;
                if (perfil == null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('No pudimos cargar tu perfil.',
                            style: TextStyle(color: context.colorTextoSuave)),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => setState(() {
                            _futuroPerfil = ApiService.obtenerMiPerfil();
                          }),
                          child: const Text('REINTENTAR'),
                        ),
                      ],
                    ),
                  );
                }
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _cuerpoPerfil(
                    datos: perfil,
                    esMiPerfil: true,
                    factorTexto: factorTexto,
                    factorIconos: factorIconos,
                    colorFondoTarjeta: colorFondoTarjeta,
                  ),
                );
              },
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _cuerpoPerfil(
                datos: widget.usuarioVisitado!,
                esMiPerfil: false,
                factorTexto: factorTexto,
                factorIconos: factorIconos,
                colorFondoTarjeta: colorFondoTarjeta,
              ),
            ),
    );
  }

  Widget _cuerpoPerfil({
    required Map<String, dynamic> datos,
    required bool esMiPerfil,
    required double factorTexto,
    required double factorIconos,
    required Color colorFondoTarjeta,
  }) {
    final String nombre = datos['nombre'] ?? 'Usuario Switch';
    final String identificador =
        'DNI ${datos['dni'] ?? ''} · ${datos['rol'] ?? 'VECINO'}';
    final stats = datos['estadisticas'];
    final int trueques = (stats?['truequesCompletados'] ?? datos['trueques'] ?? 0) is int
        ? (stats?['truequesCompletados'] ?? datos['trueques'] ?? 0)
        : int.tryParse('${stats?['truequesCompletados'] ?? datos['trueques'] ?? 0}') ?? 0;
    final int voluntariados = (stats?['voluntariados'] ?? datos['voluntariados'] ?? 0) is int
        ? (stats?['voluntariados'] ?? datos['voluntariados'] ?? 0)
        : int.tryParse('${stats?['voluntariados'] ?? datos['voluntariados'] ?? 0}') ?? 0;
    final calificacion = double.tryParse('${stats?['calificacionPromedio'] ?? datos['calificacion'] ?? 0}') ?? 0.0;
    final int resenas = int.tryParse('${stats?['cantidadResenas'] ?? datos['resenas'] ?? 0}') ?? 0;
    final impacto = datos['impacto'];

    return Column(
      children: [
        CircleAvatar(
          radius: 42 * factorIconos,
          backgroundColor: AppTheme.acentoVerdeEco,
          child: Icon(Icons.person, size: 50 * factorIconos, color: Colors.black),
        ),
        const SizedBox(height: 12),
        Text(
          nombre,
          style: TextStyle(color: context.colorTexto, fontSize: 22 * factorTexto, fontWeight: FontWeight.bold),
        ),
        if (esMiPerfil)
          Text(
            identificador,
            style: TextStyle(color: context.colorTextoSuave, fontSize: 14 * factorTexto),
          )
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.workspace_premium_rounded,
                  size: 16 * factorIconos, color: AppTheme.acentoVerdeEco),
              const SizedBox(width: 4),
              Text(
                '${impacto?['nivel']?['nombre'] ?? 'Vecino de la comunidad'}',
                style: TextStyle(color: AppTheme.acentoVerdeEco, fontSize: 13 * factorTexto),
              ),
            ],
          ),
        const SizedBox(height: 20),

        // Tarjetas de estadísticas reales
        Row(
          children: [
            _buildTarjetaEstadistica(
              'Trueques',
              '$trueques',
              Icons.swap_horiz_rounded,
              AppTheme.acentoVerdeEco,
              factorTexto,
              factorIconos,
              colorFondoTarjeta,
            ),
            const SizedBox(width: 12),
            _buildTarjetaEstadistica(
              'Voluntariados',
              '$voluntariados',
              Icons.volunteer_activism_rounded,
              AppTheme.acentoAzulTurquesa,
              factorTexto,
              factorIconos,
              colorFondoTarjeta,
            ),
            const SizedBox(width: 12),
            _buildTarjetaEstadistica(
              'Reseñas',
              resenas > 0 ? '$calificacion ($resenas)' : '-',
              Icons.star_rounded,
              AppTheme.acentoNaranja,
              factorTexto,
              factorIconos,
              colorFondoTarjeta,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Card de Impacto Comunitario (gamificación real)
        _buildCardImpacto(
          impacto,
          esMiPerfil,
          factorTexto,
          factorIconos,
          colorFondoTarjeta,
        ),

        // Opciones PRIVADAS (Solo se muestran si es MI perfil)
        if (esMiPerfil) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12 * factorTexto),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MisTruequesScreen(
                      usuarioActualId: '${datos['id'] ?? ''}',
                      usuarioActualNombre: nombre,
                    ),
                  ),
                );
              },
              icon: Icon(Icons.swap_horiz_rounded, size: 20 * factorIconos),
              label: Text(
                'MIS TRUEQUES',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14 * factorTexto),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: colorFondoTarjeta,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.acentoVerdeEco, width: 2),
            ),
            child: SwitchListTile(
              activeColor: AppTheme.acentoVerdeEco,
              title: Text(
                'Modo Alta Accesibilidad',
                style: TextStyle(color: context.colorTexto, fontSize: 16 * factorTexto, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Aumenta el contraste y tamaño de iconos/textos',
                style: TextStyle(color: context.colorTextoSuave, fontSize: 12 * factorTexto),
              ),
              secondary: Icon(Icons.accessibility_new, color: AppTheme.acentoVerdeEco, size: 28 * factorIconos),
              value: widget.modoAccesibleActivo,
              onChanged: (_) => widget.onToggleAccesibilidad(),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent, width: 2),
                foregroundColor: Colors.redAccent,
                padding: EdgeInsets.symmetric(vertical: 12 * factorTexto),
              ),
              onPressed: () async {
                await ApiService.cerrarSesion();
                if (widget.onSesionCambiada != null) {
                  widget.onSesionCambiada!(null);
                }
              },
              icon: Icon(Icons.logout, size: 20 * factorIconos),
              label: Text(
                'CERRAR SESIÓN',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14 * factorTexto),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCardImpacto(
    Map<String, dynamic>? impacto,
    bool esMiPerfil,
    double factorTexto,
    double factorIconos,
    Color colorFondoTarjeta,
  ) {
    final nivel = impacto?['nivel'];
    final int numeroNivel = int.tryParse('${nivel?['numero'] ?? 1}') ?? 1;
    final String nombreNivel = nivel?['nombre'] ?? 'Semilla del Barrio';
    final int puntos = int.tryParse('${impacto?['puntos'] ?? 0}') ?? 0;
    final double progreso = double.tryParse('${impacto?['progreso'] ?? 0}') ?? 0;
    final siguiente = impacto?['nivelSiguiente'];
    final List insignias = (impacto?['insignias'] ?? []) as List;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorFondoTarjeta,
        borderRadius: BorderRadius.circular(16),
        border: widget.modoAccesibleActivo ? Border.all(color: context.colorTextoSuave.withValues(alpha: 0.3), width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Impacto Comunitario',
                style: TextStyle(color: context.colorTexto, fontSize: 16 * factorTexto, fontWeight: FontWeight.bold),
              ),
              Icon(Icons.emoji_events_outlined, color: AppTheme.acentoVerdeEco, size: 24 * factorIconos),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(_iconoNivel(numeroNivel), color: AppTheme.acentoVerdeEco, size: 26 * factorIconos),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Nivel $numeroNivel: $nombreNivel',
                  style: TextStyle(
                    color: AppTheme.acentoVerdeEco,
                    fontSize: 14 * factorTexto,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$puntos pts',
                style: TextStyle(
                  color: context.colorTexto,
                  fontSize: 15 * factorTexto,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progreso.clamp(0.0, 1.0),
            backgroundColor: context.colorTextoSuave.withValues(alpha: 0.15),
            color: AppTheme.acentoVerdeEco,
            minHeight: widget.modoAccesibleActivo ? 12 : 8,
          ),
          const SizedBox(height: 6),
          Text(
            siguiente != null
                ? 'Te faltan ${siguiente['puntos'] - puntos} pts para ser "${siguiente['nombre']}"'
                : '¡Alcanzaste el nivel máximo de la comunidad!',
            style: TextStyle(color: context.colorTextoSuave, fontSize: 12 * factorTexto),
          ),
          if (esMiPerfil) ...[
            const SizedBox(height: 14),
            Text(
              'Cómo sumar puntos',
              style: TextStyle(color: context.colorTextoSuave, fontSize: 12 * factorTexto, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Trueque completado +10 · Voluntariado en institución +15 · Buena reputación hasta +10',
              style: TextStyle(color: context.colorTextoSuave, fontSize: 11.5 * factorTexto),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            'Insignias',
            style: TextStyle(color: context.colorTextoSuave, fontSize: 13 * factorTexto, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: insignias.map((i) {
              final desbloqueada = i['desbloqueada'] == true;
              final secretaBloqueada = i['secreta'] == true && !desbloqueada;
              return Tooltip(
                message: i['descripcion'] ?? '',
                child: Chip(
                  avatar: Icon(
                    desbloqueada
                        ? _iconoInsignia(i['codigo'])
                        : secretaBloqueada
                            ? Icons.help_outline_rounded
                            : Icons.lock_outline_rounded,
                    size: 18,
                    color: desbloqueada ? AppTheme.acentoVerdeEco : context.colorTextoSuave.withValues(alpha: 0.35),
                  ),
                  label: Text(
                    i['nombre'] ?? '',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: desbloqueada ? context.colorTexto : context.colorTextoSuave.withValues(alpha: 0.5),
                      fontWeight: desbloqueada ? FontWeight.w600 : FontWeight.normal,
                      fontStyle: secretaBloqueada ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                  backgroundColor: desbloqueada
                      ? AppTheme.acentoVerdeEco.withValues(alpha: 0.15)
                      : context.colorTextoSuave.withValues(alpha: 0.08),
                  side: BorderSide(color: desbloqueada ? AppTheme.acentoVerdeEco : context.colorTextoSuave.withValues(alpha: 0.2)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaEstadistica(
    String titulo,
    String valor,
    IconData icono,
    Color color,
    double factorTexto,
    double factorIconos,
    Color colorFondo,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorFondo,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icono, color: color, size: 32 * factorIconos),
            const SizedBox(height: 8),
            Text(
              valor,
              style: TextStyle(color: context.colorTexto, fontSize: 22 * factorTexto, fontWeight: FontWeight.bold),
            ),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colorTextoSuave, fontSize: 12 * factorTexto),
            ),
          ],
        ),
      ),
    );
  }
}
