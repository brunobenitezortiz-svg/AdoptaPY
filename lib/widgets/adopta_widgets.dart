import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/mascota.dart';
import '../theme/app_theme.dart';

// ==========================================
// LOGOTIPO DE ADOPTAPY
// ==========================================

class BrandLogo extends StatelessWidget {
  final bool compact;

  const BrandLogo({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final tamano = compact ? 39.0 : 52.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: tamano,
          height: tamano,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.celeste, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(compact ? 14 : 18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2856B8F2),
                blurRadius: 15,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            Icons.pets_rounded,
            color: Colors.white,
            size: compact ? 22 : 28,
          ),
        ),

        const SizedBox(width: 11),

        Text.rich(
          const TextSpan(
            children: [
              TextSpan(
                text: 'Adopta',
                style: TextStyle(color: AppColors.ink),
              ),
              TextSpan(
                text: 'PY',
                style: TextStyle(color: AppColors.primary),
              ),
            ],
          ),
          style: GoogleFonts.quicksand(
            fontSize: compact ? 22 : 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }
}

// ==========================================
// ENCABEZADO PRINCIPAL DE PANTALLAS
// ==========================================

class PageHeading extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;

  const PageHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.azulPastel,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.pets_rounded,
                    color: AppColors.primary,
                    size: 14,
                  ),

                  const SizedBox(width: 7),

                  Text(
                    eyebrow.toUpperCase(),
                    style: GoogleFonts.quicksand(
                      color: AppColors.primaryDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            Text(
              title,
              style: GoogleFonts.quicksand(
                color: AppColors.ink,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1.16,
                letterSpacing: -0.8,
              ),
            ),

            const SizedBox(height: 9),

            Text(
              subtitle,
              style: GoogleFonts.quicksand(
                color: AppColors.muted,
                fontSize: 14,
                height: 1.55,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        )
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(
          begin: 0.05,
          end: 0,
          duration: 350.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

// ==========================================
// ENCABEZADO DE SECCIONES
// ==========================================

class SectionHeading extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.quicksand(
                  color: AppColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),

              if (subtitle != null) ...[
                const SizedBox(height: 5),

                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),

        if (trailing != null) const SizedBox(width: 10),

        ?trailing,
      ],
    );
  }
}

// ==========================================
// FOTOGRAFIA DE MASCOTAS
// ==========================================

class PetPhoto extends StatelessWidget {
  final String imageUrl;
  final double? height;
  final double? width;
  final BorderRadius? radius;

  const PetPhoto({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE8F6FF), Color(0xFFCEE9FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: -45,
            right: -35,
            child: Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x55FFFFFF),
              ),
            ),
          ),

          Positioned(
            bottom: -60,
            left: -35,
            child: Container(
              width: 145,
              height: 145,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x40FFFFFF),
              ),
            ),
          ),

          const Icon(Icons.pets_rounded, size: 66, color: AppColors.celeste),
        ],
      ),
    );

    return ClipRRect(
      borderRadius: radius ?? BorderRadius.circular(22),
      child: SizedBox(
        width: width,
        height: height,
        child: imageUrl.trim().isEmpty
            ? placeholder
            : Image.network(
                imageUrl,
                width: width,
                height: height,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,

                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return placeholder
                      .animate(onPlay: (controller) => controller.repeat())
                      .shimmer(
                        duration: 1500.ms,
                        color: const Color(0x66FFFFFF),
                      );
                },

                errorBuilder: (context, error, stackTrace) {
                  return placeholder;
                },
              ),
      ),
    );
  }
}

// ==========================================
// TARJETA PREMIUM DE MASCOTAS
// ==========================================

class PetCard extends StatelessWidget {
  final Mascota mascota;
  final VoidCallback onTap;

  const PetCard({super.key, required this.mascota, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(27),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10164E86),
                blurRadius: 22,
                offset: Offset(0, 8),
              ),
            ],
          ),

          child: ClipRRect(
            borderRadius: BorderRadius.circular(27),

            child: Material(
              color: Colors.white,

              child: InkWell(
                onTap: onTap,

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // FOTOGRAFIA
                    Stack(
                      children: [
                        PetPhoto(
                          imageUrl: mascota.imagenUrl,
                          height: 195,
                          width: double.infinity,
                          radius: BorderRadius.zero,
                        ),

                        // DEGRADADO SOBRE LA FOTO
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withValues(alpha: 0.20),
                                    Colors.transparent,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.center,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // ETIQUETA DE ADOPCION
                        Positioned(
                          top: 15,
                          left: 15,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.96),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.favorite_rounded,
                                  color: AppColors.primary,
                                  size: 15,
                                ),

                                SizedBox(width: 6),

                                Text(
                                  'Busco hogar',
                                  style: TextStyle(
                                    color: AppColors.ink,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // INDICADOR DE DETALLES
                        Positioned(
                          top: 15,
                          right: 15,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_outward_rounded,
                              color: AppColors.primary,
                              size: 19,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // INFORMACION
                    Padding(
                      padding: const EdgeInsets.fromLTRB(19, 18, 19, 20),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // NOMBRE
                          Text(
                            mascota.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.quicksand(
                              color: AppColors.ink,
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),

                          const SizedBox(height: 5),

                          // ESPECIE Y RAZA
                          Row(
                            children: [
                              const Icon(
                                Icons.pets_outlined,
                                color: AppColors.celeste,
                                size: 15,
                              ),

                              const SizedBox(width: 7),

                              Expanded(
                                child: Text(
                                  '${mascota.especie} · ${mascota.raza}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 17),

                          // INFORMACION GENERAL
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _PetInfo(
                                icon: Icons.cake_outlined,
                                text: mascota.edad,
                              ),

                              _PetInfo(
                                icon: Icons.straighten_rounded,
                                text: mascota.tamano,
                              ),

                              _PetInfo(
                                icon: Icons.pets_outlined,
                                text: mascota.sexo,
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // LLAMADA A LA ACCION
                          Container(
                            padding: const EdgeInsets.only(top: 13),
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: AppColors.border),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.favorite_border_rounded,
                                  color: AppColors.primary,
                                  size: 18,
                                ),

                                SizedBox(width: 8),

                                Expanded(
                                  child: Text(
                                    'Conoceme mejor',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),

                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 280.ms)
        .slideY(
          begin: 0.035,
          end: 0,
          duration: 280.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

// ==========================================
// ETIQUETAS DE INFORMACION DE MASCOTAS
// ==========================================

class _PetInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PetInfo({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.azulSuave,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),

          const SizedBox(width: 6),

          Text(
            text,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// ESTADO VACIO DE PANTALLAS
// ==========================================

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),

        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 23, vertical: 38),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ILUSTRACION
              Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE6F6FF), Color(0xFFCDEBFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1556B8F2),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(icon, size: 47, color: AppColors.primary),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(
                    begin: const Offset(0.92, 0.92),
                    end: const Offset(1, 1),
                    duration: 400.ms,
                  ),

              const SizedBox(height: 23),

              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.quicksand(
                  color: AppColors.ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 14,
                  height: 1.55,
                ),
              ),

              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 25),

                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh_rounded, size: 19),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// ETIQUETAS DE ESTADO
// ==========================================

class StatusPill extends StatelessWidget {
  final String text;
  final Color color;

  const StatusPill({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),

          const SizedBox(width: 7),

          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// TARJETAS DE ACCIONES
// ==========================================

class ActionTile extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const ActionTile({
    super.key,
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0B164E86),
                blurRadius: 16,
                offset: Offset(0, 5),
              ),
            ],
          ),

          child: Material(
            color: Colors.transparent,

            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(23),

              child: Padding(
                padding: const EdgeInsets.all(17),

                child: Row(
                  children: [
                    // ICONO PRINCIPAL
                    Container(
                      width: 53,
                      height: 53,
                      decoration: BoxDecoration(
                        color: tint.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Icon(icon, color: tint, size: 26),
                    ),

                    const SizedBox(width: 15),

                    // TEXTO
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.quicksand(
                              color: AppColors.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // FLECHA
                    Container(
                      width: 31,
                      height: 31,
                      decoration: BoxDecoration(
                        color: AppColors.azulSuave,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: AppColors.primary,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(
          begin: 0.04,
          end: 0,
          duration: 300.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
