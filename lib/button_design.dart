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
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: _isHovered
            ? (Matrix4.identity()
              ..translate(0.0, -4.0)
              ..scale(1.05))
            : Matrix4.identity(),
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.backgroundColor,
            shape: widget.shape ??
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
            minimumSize: widget.size ?? const Size(70, 50),
          ),
          child: widget.child ??
              Text(
                widget.text ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.black,
                  decorationThickness: 2,
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

  const HoverContainer({
    Key? key,
    required this.child,
    this.onTap,
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

void showQuickActionOverlay(
  BuildContext outerContext,
  String skierId,
  Offset position,
) {
  final overlay = Overlay.of(outerContext);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) {
      final adjustedPosition = Offset(position.dx - 33, position.dy);

      return Stack(
        children: [
          // Klick utanför för att stänga
          Positioned.fill(
            child: GestureDetector(
              onTap: () => entry.remove(),
              behavior: HitTestBehavior.translucent,
              child: Container(),
            ),
          ),

          // Animation för knapparna
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 200),
            builder: (ctx, value, child) {
              final offsetCaptain = Offset(31 * value, 19);
              final offsetInfo = Offset(-31, -40 * value);
              final offsetRemove = Offset(31 * value, -40);

              return Stack(
                children: [
                  // 👑 Kapten-knapp
                  Positioned(
                    left: adjustedPosition.dx + offsetCaptain.dx,
                    top: adjustedPosition.dy + offsetCaptain.dy,
                    child: HoverButton(
                      onPressed: () {
                        entry.remove();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          final isCaptain =
                              outerContext.read<TeamProvider>().captain ==
                                  skierId;
                          outerContext
                              .read<TeamProvider>()
                              .setLocalCaptain(isCaptain ? "" : skierId);
                        });
                      },
                      backgroundColor: Colors.yellow,
                      shape: const CircleBorder(),
                      size: const Size(30, 30),
                      child: Center(
                        child: Text(
                          outerContext.read<TeamProvider>().captain == skierId
                              ? "X"
                              : "C",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14, // 🔹 Lägg till fontSize för balans
                            height:
                                1, // 🔹 Viktigt! Hjälper till att vertikalt centrera
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ℹ️ Info-knapp
                  Positioned(
                    left: adjustedPosition.dx + offsetInfo.dx,
                    top: adjustedPosition.dy + offsetInfo.dy,
                    child: HoverButton(
                      onPressed: () {
                        entry.remove();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          showSkierInfo(outerContext, skierId);
                        });
                      },
                      backgroundColor: Colors.green,
                      shape: const CircleBorder(),
                      size: const Size(30, 30),
                      child: Container(
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.black, width: 2)),
                          child: const Icon(Icons.info, size: 18)),
                    ),
                  ),

                  // 🗑 Ta bort-knapp
                  Positioned(
                    left: adjustedPosition.dx + offsetRemove.dx,
                    top: adjustedPosition.dy + offsetRemove.dy,
                    child: HoverButton(
                      onPressed: () {
                        entry.remove();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          outerContext
                              .read<TeamProvider>()
                              .removeSkierFromTeam(skierId, outerContext);
                        });
                      },
                      backgroundColor: Colors.red,
                      shape: const CircleBorder(),
                      size: const Size(30, 30),
                      child: Container(
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.black, width: 2)),
                          child: const Icon(
                            Icons.delete,
                            size: 18,
                          )),
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
