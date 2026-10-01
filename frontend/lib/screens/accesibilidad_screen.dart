import 'package:flutter/material.dart';

import '../services/accesibilidad_service.dart';
import '../theme/app_theme.dart';
import '../widgets/boton_accesibilidad.dart';
import '../widgets/logo_switch.dart';

class AccesibilidadScreen extends StatefulWidget {
  final VoidCallback onToggleAccesibilidad;
  final bool modoAccesibleActivo;

  const AccesibilidadScreen({
    Key? key,
    required this.onToggleAccesibilidad,
    required this.modoAccesibleActivo,
  }) : super(key: key);

  @override
  State<AccesibilidadScreen> createState() => _AccesibilidadScreenState();
}

class _AccesibilidadScreenState extends State<AccesibilidadScreen> {
  final AccesibilidadService _acc = AccesibilidadService.instancia;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            LogoSwitchIsotipo(size: 34),
            SizedBox(width: 12),
            Text('Accesibilidad',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        actions: [
          BotonAccesibilidad(
            modoAccesibleActivo: widget.modoAccesibleActivo,
            onPressed: widget.onToggleAccesibilidad,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.accessibility_new,
                      size: 40, color: AppTheme.acentoVerdeEco),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text('Adaptá Switch a tu forma de ver el mundo',
                          style: theme.textTheme.headlineLarge)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Todos los cambios se aplican al instante en toda la app y quedan guardados para tus próximas visitas.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // ==========================================
              // 1. TAMAÑO DE TEXTO
              // ==========================================
              _seccionTitulo(
                  context,
                  Icons.format_size_rounded,
                  'Tamaño del texto',
                  'Ideal si te cuesta leer los textos chicos.'),
              Card(
                color: theme.colorScheme.surface,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ValueListenableBuilder<double>(
                    valueListenable: _acc.escalaTexto,
                    builder: (context, escala, _) => Column(
                      children: [
                        Row(
                          children: [
                            const Text('A',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Slider(
                                value: escala,
                                min: 1.0,
                                max: 1.5,
                                divisions: 5,
                                label: '${(escala * 100).round()}%',
                                activeColor: AppTheme.acentoVerdeEco,
                                onChanged: (val) => _acc.setEscalaTexto(val),
                              ),
                            ),
                            const Text('A',
                                style: TextStyle(
                                    fontSize: 28, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Text(
                          escala == 1.0
                              ? 'Texto normal'
                              : 'Texto aumentado al ${(escala * 100).round()}%',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ==========================================
              // 2. PALETAS DE COLOR
              // ==========================================
              _seccionTitulo(
                  context,
                  Icons.palette_outlined,
                  'Colores de la app',
                  'Elegí cómo querés ver Switch. Podés volver a la paleta original cuando quieras.'),
              ValueListenableBuilder<bool>(
                valueListenable: _acc.paletaSuave,
                builder: (context, paletaSuave, _) =>
                    ValueListenableBuilder<bool>(
                  valueListenable: _acc.altoContraste,
                  builder: (context, altoContraste, _) => Column(
                    children: [
                      _tarjetaOpcion(
                        context,
                        titulo: 'Paleta suave y calma',
                        descripcion:
                            'Tonos pastel de baja saturación, sin colores vibrantes ni contrastes agresivos. Recomendada si sos sensible a la sobreestimulación visual.',
                        icono: Icons.spa_rounded,
                        valor: paletaSuave,
                        onChanged: (val) => _acc.setPaletaSuave(val),
                      ),
                      const SizedBox(height: 12),
                      _tarjetaOpcion(
                        context,
                        titulo: 'Alto contraste',
                        descripcion:
                            'Negro y blanco puros con acentos amarillos y bordes gruesos. Pensada para personas con baja visión.',
                        icono: Icons.contrast_rounded,
                        valor: altoContraste,
                        onChanged: (val) => _acc.setAltoContraste(val),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<bool>(
                valueListenable: _acc.blancoNegro,
                builder: (context, byn, _) => _tarjetaOpcion(
                  context,
                  titulo: 'Blanco y negro puro',
                  descripcion:
                      'Convierte toda la app a escala de grises eliminando por completo los tonos de color. Se puede combinar con cualquier paleta.',
                  icono: Icons.filter_b_and_w_rounded,
                  valor: byn,
                  onChanged: (val) => _acc.setBlancoNegro(val),
                ),
              ),
              const SizedBox(height: 24),

              // ==========================================
              // 3. LECTORES DE PANTALLA (informativo real)
              // ==========================================
              _seccionTitulo(
                  context,
                  Icons.record_voice_over_rounded,
                  'Lectores de pantalla',
                  'Switch es compatible con TalkBack (Android) y VoiceOver (iPhone).'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.acentoAzulTurquesa.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color:
                          AppTheme.acentoAzulTurquesa.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: AppTheme.acentoAzulTurquesa, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'No necesitás activar nada acá',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Activá el lector de pantalla desde las opciones de tu teléfono '
                      '(Configuración → Accesibilidad) y Switch lo detecta automáticamente: '
                      'los botones y textos se leen en voz alta mientras navegás.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ==========================================
              // VISTA PREVIA EN VIVO
              // ==========================================
              _seccionTitulo(
                  context, Icons.preview_rounded, 'Vista previa', null),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: AppTheme.acentoVerdeEco, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bicicleta Rodado 26',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                        'Así se ven los textos de las publicaciones e instituciones con tus ajustes actuales.',
                        style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.chat_bubble_outline_rounded,
                          size: 18),
                      label: const Text('ASÍ SE VEN LOS BOTONES'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ==========================================
              // RESTABLECER
              // ==========================================
              Center(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await _acc.restablecerTodo();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Preferencias restablecidas.'),
                          backgroundColor: AppTheme.acentoVerdeEco),
                    );
                  },
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('RESTABLECER TODO'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _seccionTitulo(BuildContext context, IconData icono, String titulo,
      String? descripcion) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, size: 22, color: AppTheme.acentoVerdeEco),
            const SizedBox(width: 10),
            Text(titulo, style: theme.textTheme.titleMedium),
          ],
        ),
        if (descripcion != null && descripcion.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 32, top: 4),
            child: Text(descripcion, style: theme.textTheme.bodyMedium),
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _tarjetaOpcion(
    BuildContext context, {
    required String titulo,
    required String descripcion,
    required IconData icono,
    required bool valor,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: valor ? AppTheme.acentoVerdeEco : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: SwitchListTile(
        value: valor,
        activeThumbColor: AppTheme.acentoVerdeEco,
        onChanged: onChanged,
        secondary: Icon(icono, size: 28, color: AppTheme.acentoVerdeEco),
        title: Text(titulo, style: theme.textTheme.titleMedium),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(descripcion, style: theme.textTheme.bodyMedium),
        ),
        isThreeLine: true,
      ),
    );
  }
}
