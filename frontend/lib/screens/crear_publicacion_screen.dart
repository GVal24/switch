import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';

class CrearPublicacionScreen extends StatefulWidget {
  final String usuarioId;
  final String usuarioNombre;

  const CrearPublicacionScreen({
    Key? key,
    required this.usuarioId,
    required this.usuarioNombre,
  }) : super(key: key);

  @override
  State<CrearPublicacionScreen> createState() => _CrearPublicacionScreenState();
}

class _CrearPublicacionScreenState extends State<CrearPublicacionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final ImagePicker _selectorImagen = ImagePicker();

  String _tipoItem = 'OBJETO';
  String _esfuerzoEstimado = '';
  bool _clasificando = false;
  Timer? _debounceClasificador;

  File? _imagenElegida;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _tituloController.addListener(_programarClasificacion);
    _descripcionController.addListener(_programarClasificacion);
  }

  @override
  void dispose() {
    _debounceClasificador?.cancel();
    _tituloController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  // El servidor clasifica el esfuerzo según lo que escribís (vista previa en vivo)
  void _programarClasificacion() {
    _debounceClasificador?.cancel();
    if (_tituloController.text.trim().isEmpty) {
      setState(() => _esfuerzoEstimado = '');
      return;
    }
    _debounceClasificador =
        Timer(const Duration(milliseconds: 600), _clasificarAhora);
  }

  Future<void> _clasificarAhora() async {
    setState(() => _clasificando = true);
    final nivel = await ApiService.clasificarEsfuerzo(
      titulo: _tituloController.text,
      descripcion: _descripcionController.text,
      tipoItem: _tipoItem,
    );
    if (!mounted) return;
    setState(() {
      _esfuerzoEstimado = nivel;
      _clasificando = false;
    });
  }

  Future<void> _elegirImagen(ImageSource origen) async {
    try {
      final imagen = await _selectorImagen.pickImage(
        source: origen,
        maxWidth: 1200,
        imageQuality: 82,
      );
      if (imagen != null) {
        setState(() => _imagenElegida = File(imagen.path));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No se pudo abrir la galería/cámara.'),
            backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _guardarPublicacion() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);

    String? urlImagen;
    if (_imagenElegida != null) {
      final subida = await ApiService.subirImagen(_imagenElegida!);
      if (!subida['exito']) {
        if (!mounted) return;
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(subida['mensaje'] ?? 'No se pudo subir la foto.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      urlImagen = subida['url'] as String?;
    }

    final resultado = await ApiService.crearPublicacion(
      titulo: _tituloController.text.trim(),
      descripcion: _descripcionController.text.trim(),
      tipoItem: _tipoItem,
      imagenUrl: urlImagen,
    );

    if (!mounted) return;
    setState(() => _cargando = false);

    if (resultado['exito'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(resultado['mensaje'] ?? '¡Publicación creada con éxito!'),
          backgroundColor: AppTheme.acentoVerdeEco,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado['mensaje'].toString().isNotEmpty
              ? resultado['mensaje']
              : 'Error al crear la publicación. Verificá tener tu Nexo Social activo.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Color _colorEsfuerzo(String nivel) {
    switch (nivel) {
      case 'SIMPLE':
        return AppTheme.acentoVerdeEco;
      case 'MEDIO':
        return AppTheme.acentoAzulTurquesa;
      case 'ALTO':
        return AppTheme.acentoNaranja;
      default:
        return context.colorTextoSuave;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ofrecer en Switch')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _tituloController,
                  style: TextStyle(color: context.colorTexto),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: '¿Qué ofrecés?',
                    labelStyle: TextStyle(color: context.colorTextoSuave),
                    hintText:
                        'Ej: Bicicleta rodado 26 / Clases de apoyo de matemática',
                    hintStyle: TextStyle(
                        color: context.colorTextoSuave.withValues(alpha: 0.5)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Contanos qué ofrecés'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descripcionController,
                  maxLines: 3,
                  style: TextStyle(color: context.colorTexto),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    labelStyle: TextStyle(color: context.colorTextoSuave),
                    hintText:
                        'Detallá estado, días, horarios o lo que sea útil...',
                    hintStyle: TextStyle(
                        color: context.colorTextoSuave.withValues(alpha: 0.5)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Agregá una descripción'
                      : null,
                ),
                const SizedBox(height: 16),

                Text('Es un...',
                    style: TextStyle(
                        color: context.colorTextoSuave, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        avatar: Icon(Icons.inventory_2_outlined,
                            size: 18,
                            color: _tipoItem == 'OBJETO'
                                ? Colors.white
                                : context.colorTextoSuave),
                        label: const Text('Objeto'),
                        selected: _tipoItem == 'OBJETO',
                        selectedColor: AppTheme.acentoVerdeEco,
                        backgroundColor: context.colorTarjeta,
                        labelStyle: TextStyle(
                          color: _tipoItem == 'OBJETO'
                              ? Colors.white
                              : context.colorTextoSuave,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (_) {
                          setState(() => _tipoItem = 'OBJETO');
                          _programarClasificacion();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ChoiceChip(
                        avatar: Icon(Icons.handyman_rounded,
                            size: 18,
                            color: _tipoItem == 'SERVICIO'
                                ? Colors.white
                                : context.colorTextoSuave),
                        label: const Text('Servicio'),
                        selected: _tipoItem == 'SERVICIO',
                        selectedColor: AppTheme.acentoVerdeEco,
                        backgroundColor: context.colorTarjeta,
                        labelStyle: TextStyle(
                          color: _tipoItem == 'SERVICIO'
                              ? Colors.white
                              : context.colorTextoSuave,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (_) {
                          setState(() => _tipoItem = 'SERVICIO');
                          _programarClasificacion();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Nivel de esfuerzo calculado automáticamente por el servidor
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.colorTarjeta,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: context.colorTextoSuave.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          color: _esfuerzoEstimado.isEmpty
                              ? context.colorTextoSuave
                              : _colorEsfuerzo(_esfuerzoEstimado),
                          size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _esfuerzoEstimado.isEmpty
                            ? Text(
                                'El nivel de esfuerzo se calcula solo según lo que ofrezcas.',
                                style: TextStyle(
                                    color: context.colorTextoSuave,
                                    fontSize: 13),
                              )
                            : RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                      color: context.colorTextoSuave,
                                      fontSize: 13),
                                  children: [
                                    const TextSpan(text: 'Esfuerzo estimado: '),
                                    TextSpan(
                                      text: _clasificando
                                          ? '...'
                                          : _esfuerzoEstimado,
                                      style: TextStyle(
                                        color:
                                            _colorEsfuerzo(_esfuerzoEstimado),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      if (_clasificando)
                        const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Foto desde el dispositivo
                Text('Foto (opcional)',
                    style: TextStyle(
                        color: context.colorTextoSuave, fontSize: 13)),
                const SizedBox(height: 8),
                if (_imagenElegida != null)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          _imagenElegida!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.close_rounded,
                                size: 18, color: Colors.white),
                            onPressed: () =>
                                setState(() => _imagenElegida = null),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.photo_library_outlined,
                              size: 20),
                          label: const Text('GALERÍA'),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.acentoAzulTurquesa),
                          onPressed: () => _elegirImagen(ImageSource.gallery),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon:
                              const Icon(Icons.photo_camera_outlined, size: 20),
                          label: const Text('CÁMARA'),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.acentoAzulTurquesa),
                          onPressed: () => _elegirImagen(ImageSource.camera),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _cargando ? null : _guardarPublicacion,
                    icon: _cargando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.publish_rounded),
                    label: Text(_cargando ? 'PUBLICANDO...' : 'PUBLICAR AHORA'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
