import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:poltro_play/providers/auth_provider.dart';
import 'package:poltro_play/core/services/movie_request_service.dart';

void showMovieRequestModal(
  BuildContext context, {
  String? initialTitle,
  String initialType = 'movie',
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => MovieRequestModal(
      initialTitle: initialTitle,
      initialType: initialType,
    ),
  );
}

class MovieRequestModal extends ConsumerStatefulWidget {
  final String? initialTitle;
  final String initialType;

  const MovieRequestModal({
    super.key,
    this.initialTitle,
    this.initialType = 'movie',
  });

  @override
  ConsumerState<MovieRequestModal> createState() => _MovieRequestModalState();
}

class _MovieRequestModalState extends ConsumerState<MovieRequestModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _yearController;
  late TextEditingController _notesController;
  late TextEditingController _emailController;
  late String _selectedType;

  bool _isSubmitting = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _yearController = TextEditingController();
    _notesController = TextEditingController();
    _emailController = TextEditingController();
    _selectedType = widget.initialType;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _yearController.dispose();
    _notesController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);

    final user = ref.read(authStateProvider).value;
    final userEmail = user?.email ?? (_emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null);
    final userName = user?.displayName ?? (userEmail != null ? userEmail.split('@').first : 'Visitante');

    final success = await ref.read(movieRequestServiceProvider).submitRequest(
          title: _titleController.text,
          type: _selectedType,
          year: _yearController.text,
          notes: _notesController.text,
          userId: user?.uid,
          userName: userName,
          userEmail: userEmail,
        );

    if (!mounted) return;

    if (success) {
      HapticFeedback.heavyImpact();
      setState(() {
        _isSubmitting = false;
        _isSuccess = true;
      });
    } else {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFE94560),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            'Não foi possível enviar o pedido. Tente novamente!',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final user = ref.watch(authStateProvider).value;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.88,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF131024).withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: const Color(0xFF7B2FF7).withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7B2FF7).withValues(alpha: 0.25),
                  blurRadius: 32,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: _isSuccess ? _buildSuccessView() : _buildFormView(user),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView(dynamic user) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B2FF7), Color(0xFF00D4FF)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D4FF).withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(Icons.movie_filter_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fazer Pedido de Conteúdo',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Não achou no app? Peça e adicionamos para você!',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white54),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Segmented Type Selector (Filme / Série)
          Text(
            'O que você deseja solicitar?',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTypeButton(
                    label: 'Filme',
                    icon: Icons.movie_rounded,
                    value: 'movie',
                    isSelected: _selectedType == 'movie',
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildTypeButton(
                    label: 'Série',
                    icon: Icons.tv_rounded,
                    value: 'series',
                    isSelected: _selectedType == 'series',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Título do Filme / Série
          Text(
            'Nome do Filme ou Série *',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _titleController,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Informe o nome do título desejado';
              }
              return null;
            },
            decoration: _inputDecoration(
              hintText: 'Ex: Matrix Resurrections, Friends, Interestelar...',
              prefixIcon: Icons.title_rounded,
            ),
          ),

          const SizedBox(height: 16),

          // Ano de Lançamento (opcional)
          Text(
            'Ano de Lançamento (opcional)',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _yearController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
            decoration: _inputDecoration(
              hintText: 'Ex: 2024 (ajuda a achar a versão correta)',
              prefixIcon: Icons.calendar_today_rounded,
            ),
          ),

          const SizedBox(height: 16),

          // Observações / Detalhes
          Text(
            'Observações ou Detalhes (opcional)',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _notesController,
            maxLines: 2,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
            decoration: _inputDecoration(
              hintText: 'Ex: Dublado em PT-BR, ator principal, temporada específica...',
              prefixIcon: Icons.edit_note_rounded,
            ),
          ),

          const SizedBox(height: 18),

          // Informações do Solicitante
          if (user != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF7B2FF7).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF7B2FF7).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_circle_rounded, color: Color(0xFF00D4FF), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Enviando como: ${user.displayName ?? user.email ?? "Membro"}',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Text(
              'Seu E-mail para Aviso (opcional)',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              decoration: _inputDecoration(
                hintText: 'seuemail@exemplo.com',
                prefixIcon: Icons.alternate_email_rounded,
              ),
            ),
          ],

          const SizedBox(height: 26),

          // Botão Enviar
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B2FF7), Color(0xFF00D4FF)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7B2FF7).withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              'Enviar Pedido de ${_selectedType == 'movie' ? 'Filme' : 'Série'}',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton({
    required String label,
    required IconData icon,
    required String value,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedType = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7B2FF7) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF7B2FF7).withValues(alpha: 0.4),
                    blurRadius: 8,
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.white60,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF00D4FF), Color(0xFF7B2FF7)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00D4FF).withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Text('🍿', style: TextStyle(fontSize: 38)),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Pedido Enviado com Sucesso!',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Recebemos sua sugestão de "${_titleController.text}". Nossa equipe foi alertada e analisará para adicionar ao catálogo o mais rápido possível!',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white70,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B2FF7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              'Concluir',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.inter(color: Colors.white30, fontSize: 13),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF00D4FF), size: 18),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF00D4FF), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE94560), width: 1.2),
      ),
    );
  }
}
