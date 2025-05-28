import 'package:flutter/material.dart';
import 'alertdialog_skier.dart';
import 'teamProvider.dart';
import 'package:provider/provider.dart';

class HoverButton extends StatefulWidget {
  final String? text;
  final Widget? child;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final OutlinedBorder? shape;
  final Size? size;

  const HoverButton({
    Key? key,
    this.text,
    this.child,
    required this.onPressed,
    this.backgroundColor = Colors.lightBlue,
    this.shape,
    this.size,
  }) : super(key: key);

  @override
  State<HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<HoverButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isCircular = widget.shape is CircleBorder;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: _isHovered && !isCircular
            ? (Matrix4.identity()
              ..translate(0.0, -4.0)
              ..scale(1.05))
            : Matrix4.identity(),
        child: Container(
          decoration: BoxDecoration(
            gradient: isCircular
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue[900]!.withOpacity(0.9),
                      Colors.blue[800]!.withOpacity(0.8),
                    ],
                  ),
            borderRadius: isCircular
                ? BorderRadius.circular(50)
                : BorderRadius.circular(12),
            border: isCircular
                ? null
                : Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
            boxShadow: isCircular
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: isCircular
                ? BorderRadius.circular(50)
                : BorderRadius.circular(12),
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: isCircular
                  ? BorderRadius.circular(50)
                  : BorderRadius.circular(12),
              child: Container(
                constraints: BoxConstraints(
                  minWidth: widget.size?.width ?? 70,
                  minHeight: widget.size?.height ?? 50,
                ),
                padding: isCircular
                    ? EdgeInsets.zero
                    : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Center(
                  child: widget.child ??
                      Text(
                        widget.text ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HoverContainer extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double containerSize;

  const HoverContainer({
    Key? key,
    required this.child,
    this.onTap,
    required this.containerSize,
  }) : super(key: key);

  @override
  State<HoverContainer> createState() => _HoverContainerState();
}

class _HoverContainerState extends State<HoverContainer> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          transform: _isHovered
              ? (Matrix4.identity()
                ..translate(0.0, -4.0)
                ..scale(1.05))
              : Matrix4.identity(),
          child: widget.child,
        ),
      ),
    );
  }
}

// Variabler för att justera knapparnas positioner baserat på containerstorlek
double getButtonOffsetX(double containerSize) {
  if (containerSize >= 120) {
    // Desktop
    return 40.0;
  } else if (containerSize >= 110) {
    // Tablet
    return 35.0;
  } else {
    // Mobile
    return 30.0;
  }
}

double getButtonOffsetY(double containerSize) {
  if (containerSize >= 120) {
    // Desktop
    return 40.0;
  } else if (containerSize >= 110) {
    // Tablet
    return 30.0;
  } else {
    // Mobile
    return 30.0;
  }
}

// Variabler för att justera startpositioner
class ButtonStartPosition {
  final double x;
  final double y;

  const ButtonStartPosition(this.x, this.y);
}

ButtonStartPosition getInfoStartPosition(double containerSize) {
  if (containerSize >= 120) {
    // Desktop
    return const ButtonStartPosition(-15, -10);
  } else if (containerSize >= 110) {
    // Tablet
    return const ButtonStartPosition(-18, -18);
  } else {
    // Mobile
    return const ButtonStartPosition(-10, -6);
  }
}

ButtonStartPosition getDeleteStartPosition(double containerSize) {
  if (containerSize >= 120) {
    // Desktop
    return const ButtonStartPosition(-17, -10);
  } else if (containerSize >= 110) {
    // Tablet
    return const ButtonStartPosition(-15, -18);
  } else {
    // Mobile
    return const ButtonStartPosition(-12, -6);
  }
}

ButtonStartPosition getCaptainStartPosition(double containerSize) {
  if (containerSize >= 120) {
    // Desktop
    return const ButtonStartPosition(-17, -20);
  } else if (containerSize >= 110) {
    // Tablet
    return const ButtonStartPosition(-15, -16);
  } else {
    // Mobile
    return const ButtonStartPosition(-12, -12);
  }
}

void showQuickActionOverlay(
  BuildContext outerContext,
  String skierId,
  Offset position,
  double containerSize,
) {
  final overlay = Overlay.of(outerContext);
  late OverlayEntry entry;

  // Hämta offset baserat på containerstorlek
  final offsetX = getButtonOffsetX(containerSize);
  final offsetY = getButtonOffsetY(containerSize);

  // Hämta startpositioner
  final infoStart = getInfoStartPosition(containerSize);
  final deleteStart = getDeleteStartPosition(containerSize);
  final captainStart = getCaptainStartPosition(containerSize);

  entry = OverlayEntry(
    builder: (_) {
      final centerX = position.dx;
      final centerY = position.dy;

      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => entry.remove(),
              behavior: HitTestBehavior.translucent,
              child: Container(),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 200),
            builder: (ctx, value, child) {
              // Info-knapp (övre vänster)
              final infoX = centerX + infoStart.x + (-offsetX * value);
              final infoY = centerY + infoStart.y + (-offsetY * value);

              // Ta bort-knapp (övre höger)
              final deleteX = centerX + deleteStart.x + (offsetX * value);
              final deleteY = centerY + deleteStart.y + (-offsetY * value);

              // Kapten-knapp (nedre höger)
              final captainX = centerX + captainStart.x + (offsetX * value);
              final captainY = centerY + captainStart.y + (offsetY * value);

              return Stack(
                children: [
                  // Info-knapp (övre vänster)
                  Positioned(
                    left: infoX,
                    top: infoY,
                    child: Transform.scale(
                      scale: value,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.blue[600]!,
                              Colors.blue[800]!,
                            ],
                          ),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.2), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: HoverButton(
                          onPressed: () {
                            entry.remove();
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              showSkierInfo(outerContext, skierId);
                            });
                          },
                          shape: const CircleBorder(),
                          size: const Size(30, 30),
                          child: const Icon(Icons.info,
                              size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ),

                  // Ta bort-knapp (övre höger)
                  Positioned(
                    left: deleteX,
                    top: deleteY,
                    child: Transform.scale(
                      scale: value,
                      child: Builder(
                        builder: (context) {
                          DateTime? deadline =
                              context.watch<TeamProvider>().weekDeadline;
                          bool hasDeadlinePassed = false;
                          if (deadline != null) {
                            hasDeadlinePassed =
                                deadline.isBefore(DateTime.now());
                          }

                          return hasDeadlinePassed
                              ? const SizedBox() // Return empty widget if deadline passed
                              : Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.red[600]!,
                                        Colors.red[900]!,
                                      ],
                                    ),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: HoverButton(
                                    onPressed: () {
                                      entry.remove();
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        outerContext
                                            .read<TeamProvider>()
                                            .removeSkierFromTeam(
                                                skierId, outerContext);
                                      });
                                    },
                                    shape: const CircleBorder(),
                                    size: const Size(30, 30),
                                    child: const Icon(Icons.delete,
                                        size: 18, color: Colors.white),
                                  ),
                                );
                        },
                      ),
                    ),
                  ),

                  // Kapten-knapp (nedre höger)
                  Positioned(
                    left: captainX,
                    top: captainY,
                    child: Transform.scale(
                      scale: value,
                      child: Builder(
                        builder: (context) {
                          DateTime? deadline =
                              context.watch<TeamProvider>().weekDeadline;
                          bool hasDeadlinePassed = false;
                          if (deadline != null) {
                            hasDeadlinePassed =
                                deadline.isBefore(DateTime.now());
                          }

                          return hasDeadlinePassed
                              ? const SizedBox() // Return empty widget if deadline passed
                              : Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFFFD700), // Ljusare guld
                                        Color(
                                            0xFFFFA000), // Mörkare orange/guld
                                      ],
                                    ),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: HoverButton(
                                    onPressed: () {
                                      entry.remove();
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        final isCaptain = outerContext
                                                .read<TeamProvider>()
                                                .captain ==
                                            skierId;
                                        outerContext
                                            .read<TeamProvider>()
                                            .setLocalCaptain(
                                                isCaptain ? "" : skierId);
                                      });
                                    },
                                    shape: const CircleBorder(),
                                    size: const Size(30, 30),
                                    child: Center(
                                      child: Text(
                                        outerContext
                                                    .read<TeamProvider>()
                                                    .captain ==
                                                skierId
                                            ? "X"
                                            : "C",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      );
    },
  );

  overlay.insert(entry);
}
