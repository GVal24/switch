import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';

class _NecesidadForm {
  final TextEditingController titulo = TextEditingController();
  final TextEditingController descripcion = TextEditingController();
  int cupoMaximo = 1;
  String prioridad = 'GENERAL';

  void dispose() {
    titulo.dispose();
    descripcion.dispose();
  }
}

class RegistroInstitucionScreen extends StatefulWidget {
  const RegistroInstitucionScreen({Key? key}) : super(key: key);

  @override
  State<RegistroInstitucionScreen> createState() => _RegistroInstitucionScreenState();
}

class _RegistroInstitucionScreenState extends State<RegistroInstitucionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _descripcionController = TextEditingController();
  String _tipoSeleccionado = 'COMEDOR';
  bool _enviando = false;

  final List<_NecesidadForm> _necesidades = [_NecesidadForm()];

  static const List<Map<String, String>> _tipos = [
    {'valor': 'COMEDOR', 'etiqueta': 'Comedor'},
    {'valor': 'HOGAR', 'etiqueta': 'Hogar'},
    {'valor': 'BIBLIOTECA', 'etiqueta': 'Biblioteca'},
    {'valor': 'CENTRO_DIA', 'etiqueta': 'Centro de día'},
    {'valor': 'OTRO', 'etiqueta': 'Otro'},
  ];

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _descripcionController.dispose();
    for (final n in _necesidades) {
      n.dispose();
    }
    super.dispose();
  }

  Widget _chipPrioridad(BuildContext context, _NecesidadForm n, String valor, String etiqueta, Color color) {
    final seleccionada = n.prioridad == valor;
    return ChoiceChip(
      label: Text(etiqueta),
      selected: seleccionada,
      selectedColor: color.withOpacity(0.25),
      labelStyle: TextStyle(
        color: seleccionada ? color : null,
        fontWeight: seleccionada ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => setState(() => n.prioridad = valor),
    );
  }

  Future<void> _enviarRegistro() async {
    if (!_formKey.currentState!.validate()) return;

    // Filtra necesidades sin título
    final necesidades = _necesidades
        .where((n) => n.titulo.text.trim().isNotEmpty)
        .map((n) => {
              'titulo': n.titulo.text.trim(),
              'descripcion': n.descripcion.text.trim(),
              'cupoMaximo': n.cupoMaximo,
              'prioridad': n.prioridad,
            })
        .toList();

    if (necesidades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cargá al menos una necesidad con su título.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _enviando = true);
    final res = await ApiService.registrarInstitucion(
      nombre: _nombreController.text.trim(),
      tipo: _tipoSeleccionado,
      direccion: _direccionController.text.trim(),
      telefono: _telefonoController.text.trim(),
      descripcion: _descripcionController.text.trim(),
      necesidades: necesidades,
    );
    if (!mounted) return;
    setState(() => _enviando = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res['mensaje'] ?? ''),
        backgroundColor: res['exito'] == true ? AppTheme.acentoVerdeEco : Colors.redAccent,
      ),
    );
    if (res['exito'] == true) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Registro de Institución')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.add_business_rounded, size: 36, color: AppTheme.acentoVerdeEco),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Sumá tu institución a Switch', style: theme.textTheme.headlineLarge),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Completá los datos y publicá qué necesita tu organización: los vecinos van a poder ofrecerse para ayudar.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),

                Text('Datos de la institución', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nombreController,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresá el nombre de la institución.' : null,
                  decoration: const InputDecoration(labelText: 'Nombre *'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _tipoSeleccionado,
                  decoration: const InputDecoration(labelText: 'Tipo de institución'),
                  items: _tipos
                      .map((t) => DropdownMenuItem(value: t['valor'], child: Text(t['etiqueta']!)))
                      .toList(),
                  onChanged: (v) => setState(() => _tipoSeleccionado = v ?? 'COMEDOR'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _direccionController,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresá la dirección.' : null,
                  decoration: const InputDecoration(labelText: 'Dirección *'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _telefonoController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Teléfono de contacto'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descripcionController,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Contanos brevemente qué hacen',
                    hintText: 'Ej: Comedor comunitario que asiste a 40 familias del barrio...',
                  ),
                ),
                const SizedBox(height: 28),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Necesidades de voluntariado', style: theme.textTheme.titleMedium),
                    IconButton(
                      onPressed: () => setState(() => _necesidades.add(_NecesidadForm())),
                      icon: const Icon(Icons.add_circle_rounded, color: AppTheme.acentoVerdeEco),
                      tooltip: 'Agregar otra necesidad',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('¿En qué necesitan ayuda los vecinos y cuántos voluntarios hacen falta?',
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: 12),

                ..._necesidades.asMap().entries.map((entry) {
                  final index = entry.key;
                  final n = entry.value;
                  return Card(
                    color: theme.colorScheme.surface,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text('Necesidad ${index + 1}', style: theme.textTheme.titleMedium?.copyWith(fontSize: 15)),
                              ),
                              if (_necesidades.length > 1)
                                IconButton(
                                  onPressed: () => setState(() {
                                    _necesidades.removeAt(index).dispose();
                                  }),
                                  icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.redAccent, size: 22),
                                ),
                            ],
                          ),
                          TextFormField(
                            controller: n.titulo,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: '¿Qué necesitan? *',
                              hintText: 'Ej: Cocineros para turnos de sábado',
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: n.descripcion,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Detalles (opcional)',
                              hintText: 'Días, horarios, materiales...',
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text('Voluntarios necesarios:', style: theme.textTheme.bodyLarge),
                              const Spacer(),
                              IconButton(
                                onPressed: () => setState(() {
                                  if (n.cupoMaximo > 1) n.cupoMaximo--;
                                }),
                                icon: const Icon(Icons.remove_circle_outline_rounded),
                              ),
                              Text('${n.cupoMaximo}',
                                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 17)),
                              IconButton(
                                onPressed: () => setState(() {
                                  if (n.cupoMaximo < 99) n.cupoMaximo++;
                                }),
                                icon: const Icon(Icons.add_circle_outline_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('¿Qué tan urgente es?',
                                style: theme.textTheme.bodyLarge),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            children: [
                              _chipPrioridad(context, n, 'GENERAL', 'General', Colors.grey),
                              _chipPrioridad(context, n, 'PRIORITARIA', 'Prioritaria', Colors.orange),
                              _chipPrioridad(context, n, 'URGENTE', 'Urgente', Colors.redAccent),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Las necesidades urgentes otorgan más días de Nexo Social a quien las cubre.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _enviando ? null : _enviarRegistro,
                    icon: _enviando
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.publish_rounded),
                    label: Text(_enviando ? 'PUBLICANDO...' : 'PUBLICAR EN VOLUNTARIADO'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
