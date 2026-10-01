import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LogoSwitchIsotipo extends StatelessWidget {
  final double size;
  const LogoSwitchIsotipo({Key? key, this.size = 36.0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Flechas en bucle (Verde Esmeralda)
        Icon(
          Icons.autorenew_rounded,
          size: size * 1.25,
          color: AppTheme.acentoVerdeEco,
        ),
        // S Central (Blanca)
        Text(
          'S',
          style: TextStyle(
            fontSize: size * 0.55,
            fontWeight: FontWeight.w900,
            color: AppTheme.textoClaro,
          ),
        ),
      ],
    );
  }
}
