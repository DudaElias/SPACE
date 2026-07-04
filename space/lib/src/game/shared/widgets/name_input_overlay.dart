import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NameInputOverlay extends StatefulWidget {
  const NameInputOverlay({
    required this.title,
    required this.onConfirm,
    required this.onCancel,
    super.key,
  });

  final String title;
  final void Function(String name) onConfirm;
  final VoidCallback onCancel;

  @override
  State<NameInputOverlay> createState() => _NameInputOverlayState();
}

class _NameInputOverlayState extends State<NameInputOverlay> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _confirm() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) {
      widget.onConfirm(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontFamily: GoogleFonts.silkscreen().fontFamily,
      color: Colors.white,
    );

    return GestureDetector(
      onTap: widget.onCancel,
      child: Container(
        color: const Color(0xCC020617),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 420,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFF62D5FF).withAlpha(170), width: 2),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xEE111F39), Color(0xEE0A1429)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9EEAFF).withAlpha(70),
                    blurRadius: 6,
                    spreadRadius: 1.5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: textStyle.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onSubmitted: (_) => _confirm(),
                    style: textStyle.copyWith(fontSize: 18),
                    maxLength: 16,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'Digite o nome...',
                      hintStyle: textStyle.copyWith(fontSize: 16, color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withAlpha(15),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF62D5FF), width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: const Color(0xFF62D5FF).withAlpha(80), width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF62D5FF), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildButton(
                        label: 'Cancelar',
                        color: const Color(0xFF1F3A5F),
                        onTap: widget.onCancel,
                      ),
                      const SizedBox(width: 20),
                      _buildButton(
                        label: 'Confirmar',
                        color: const Color(0xffFF986A),
                        onTap: _confirm,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: GoogleFonts.silkscreen().fontFamily,
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
