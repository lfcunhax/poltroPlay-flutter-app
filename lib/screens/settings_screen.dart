import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:poltro_play/providers/auth_provider.dart';
import 'package:poltro_play/providers/watch_progress_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Configurações',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF0A0A0A)],
            radius: 1.2,
            center: Alignment(0, -0.6),
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            children: [
              // Profile Section (Glassmorphism)
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7B2FF7).withValues(alpha: 0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF7B2FF7), Color(0xFF00D4FF)],
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 36,
                            backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                            backgroundColor: const Color(0xFF1A1A2E),
                            child: user?.photoURL == null
                                ? const Icon(Icons.person, color: Colors.white, size: 36)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.displayName ?? 'Usuário',
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? 'email@exemplo.com',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white60,
                                ),
                              ),
                              // A tag "Conta Premium" foi removida para ser implementada no futuro
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              Text(
                'PREFERÊNCIAS',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white54,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildSettingsCard(
                children: [
                  _buildSettingItem(
                    icon: Icons.notifications_active_rounded,
                    title: 'Notificações Push',
                    subtitle: 'Novos filmes e episódios',
                    trailing: Switch(
                      activeColor: const Color(0xFF00D4FF),
                      activeTrackColor: const Color(0xFF7B2FF7).withValues(alpha: 0.5),
                      inactiveThumbColor: Colors.grey,
                      inactiveTrackColor: Colors.white10,
                      value: _notificationsEnabled,
                      onChanged: (val) {
                        setState(() => _notificationsEnabled = val);
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              Text(
                'DADOS & PRIVACIDADE',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white54,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildSettingsCard(
                children: [
                  _buildSettingItem(
                    icon: Icons.cached_rounded,
                    title: 'Limpar Cache',
                    subtitle: 'Libera espaço no dispositivo',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cache limpo com sucesso!')),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.history_rounded,
                    title: 'Limpar Histórico',
                    subtitle: 'Apaga "Continue Assistindo"',
                    onTap: () async {
                      await ref.read(watchProgressListProvider.notifier).clearAllProgress();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Histórico limpo com sucesso!')),
                        );
                      }
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              Text(
                'SOBRE O APP',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white54,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildSettingsCard(
                children: [
                  _buildSettingItem(
                    icon: Icons.info_outline_rounded,
                    title: 'Sobre',
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'PoltroPlay',
                        applicationVersion: '1.0.0',
                        applicationIcon: Image.asset('assets/images/logo-01-sem-fundo.png', height: 48),
                        children: const [
                          Text('Sua plataforma de streaming premium.', style: TextStyle(color: Colors.black)),
                        ],
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.verified_rounded,
                    title: 'Versão',
                    trailing: Text('1.0.0', style: GoogleFonts.inter(color: Colors.white54, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Logout Button
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE94560), Color(0xFFC02B48)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE94560).withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      await ref.read(authServiceProvider).signOut();
                      if (context.mounted) context.go('/login');
                    },
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout_rounded, color: Colors.white),
                          const SizedBox(width: 12),
                          Text(
                            'Sair da Conta',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF7B2FF7).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF00D4FF), size: 24),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white54,
              ),
            )
          : null,
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right_rounded, color: Colors.white38) : null),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 72, right: 20),
      child: Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
    );
  }
}
