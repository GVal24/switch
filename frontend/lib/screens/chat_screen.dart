import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final String usuarioActualId;
  final String receptorId;
  final String receptorNombre;

  const ChatScreen({
    Key? key,
    required this.usuarioActualId,
    required this.receptorId,
    required this.receptorNombre,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _mensajeController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _mensajes = [];
  bool _cargando = true;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _cargarMensajes();
  }

  @override
  void dispose() {
    _mensajeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 🟢 Carga los mensajes intercambiados con este receptor
  Future<void> _cargarMensajes() async {
    final msjs = await ApiService.obtenerMensajes(
      widget.usuarioActualId,
      widget.receptorId,
    );

    if (!mounted) return;

    setState(() {
      _mensajes = msjs;
      _cargando = false;
    });

    // Si el backend rechazó la carga (cuenta suspendida o dada de baja) lo
    // decimos en vez de mostrar un chat vacío sin explicación.
    final error = ApiService.ultimoErrorChat;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
    }

    _desplazarAlFinal();
  }

  void _desplazarAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // 🟢 Envía el mensaje y actualiza la lista al instante
  Future<void> _enviarMensaje() async {
    final texto = _mensajeController.text.trim();
    if (texto.isEmpty || _enviando) return;

    setState(() => _enviando = true);
    _mensajeController.clear();

    // 1. Agregamos el mensaje temporalmente en UI para respuesta instantánea
    final msjTemporal = {
      'emisor_id': widget.usuarioActualId,
      'receptor_id': widget.receptorId,
      'texto': texto,
      'creado_en': 'Ahora',
    };

    setState(() {
      _mensajes.add(msjTemporal);
    });
    _desplazarAlFinal();

    // 2. Enviamos al Backend
    final exito = await ApiService.enviarMensaje(
      emisorId: widget.usuarioActualId,
      receptorId: widget.receptorId,
      receptorNombre: widget.receptorNombre,
      texto: texto,
    );

    if (!mounted) return;

    setState(() => _enviando = false);

    if (exito) {
      // 3. Volvemos a sincronizar con la BD para confirmar el mensaje
      _cargarMensajes();
    } else {
      // Si falló, quitamos el mensaje de la UI y mostramos el motivo real
      // (por ejemplo: la cuenta está suspendida hasta tal fecha).
      setState(() {
        _mensajes.remove(msjTemporal);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiService.ultimoErrorChat ??
              'No se pudo enviar el mensaje. Intentalo de nuevo.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.acentoAzulTurquesa,
              child: Icon(Icons.person, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.receptorNombre,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar Mensajes',
            onPressed: _cargarMensajes,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Área de Mensajes
            Expanded(
              child: _cargando
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.acentoVerdeEco),
                    )
                  : _mensajes.isEmpty
                      ? Center(
                          child: Text(
                            'Aún no hay mensajes en esta conversación.\n¡Iniciá la charla sobre el intercambio!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: context.colorTextoSuave),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          itemCount: _mensajes.length,
                          itemBuilder: (ctx, idx) {
                            final msg = _mensajes[idx];
                            final emisorId =
                                (msg['emisor_id'] ?? msg['emisorId'] ?? '')
                                    .toString();
                            final esMio = emisorId == widget.usuarioActualId;
                            final texto = msg['texto'] ?? msg['mensaje'] ?? '';
                            final hora = msg['creado_en'] ?? msg['hora'] ?? '';

                            return Align(
                              alignment: esMio
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75,
                                ),
                                decoration: BoxDecoration(
                                  color: esMio
                                      ? AppTheme.acentoVerdeEco
                                          .withValues(alpha: 0.85)
                                      : context.colorTarjeta,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(14),
                                    topRight: const Radius.circular(14),
                                    bottomLeft: Radius.circular(esMio ? 14 : 0),
                                    bottomRight:
                                        Radius.circular(esMio ? 0 : 14),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: esMio
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      texto,
                                      style: TextStyle(
                                        color: esMio
                                            ? Colors.black
                                            : context.colorTexto,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (hora.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        hora,
                                        style: TextStyle(
                                          color: esMio
                                              ? Colors.black54
                                              : context.colorTextoSuave,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),

            // Barra de entrada de texto
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              color: context.colorTarjeta,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _mensajeController,
                      style: TextStyle(color: context.colorTexto),
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Escribí un mensaje...',
                        hintStyle: TextStyle(color: context.colorTextoSuave),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                      ),
                      onSubmitted: (_) => _enviarMensaje(),
                    ),
                  ),
                  IconButton(
                    icon: _enviando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.acentoVerdeEco,
                            ),
                          )
                        : const Icon(Icons.send_rounded,
                            color: AppTheme.acentoVerdeEco),
                    onPressed: _enviarMensaje,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
