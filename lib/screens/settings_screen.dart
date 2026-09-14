import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ce/hive.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart' as cache;
import 'package:poltro_play/providers/auth_provider.dart';
import 'package:poltro_play/providers/rewards_provider.dart';
import 'package:poltro_play/providers/watch_progress_provider.dart';
import 'package:poltro_play/widgets/rewards_modal.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _autoPlayNext = true;
  bool _cellularWarning = true;
  String _streamQuality = 'Automática';
  bool _isClearingCache = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() {
    try {
      if (Hive.isBoxOpen('user_prefs_box')) {
        final box = Hive.box('user_prefs_box');
        setState(() {
          _notificationsEnabled = box.get('pref_notifications', defaultValue: true);
          _autoPlayNext = box.get('pref_autoplay', defaultValue: true);
          _cellularWarning = box.get('pref_cellular_warning', defaultValue: true);
          _streamQuality = box.get('pref_quality', defaultValue: 'Automática');
        });
      }
    } catch (_) {}
  }

  Future<void> _savePreference(String key, dynamic value) async {
    try {
      if (Hive.isBoxOpen('user_prefs_box')) {
        await Hive.box('user_prefs_box').put(key, value);
      }
    } catch (_) {}
  }

  Future<void> _clearCache() async {
    setState(() => _isClearingCache = true);
    HapticFeedback.mediumImpact();

    try {
      // 1. Limpa cache de imagens customizado
      final customCache = cache.CacheManager(
        cache.Config(
          'moviePostersCache',
          stalePeriod: const Duration(days: 30),
          maxNrOfCacheObjects: 2000,
        ),
      );
      await customCache.emptyCache();

      // 2. Limpa cache de imagens padrão
      await cache.DefaultCacheManager().emptyCache();

      // 3. Limpa páginas em cache no Hive
      if (Hive.isBoxOpen('user_prefs_box')) {
        final box = Hive.box('user_prefs_box');
        final keysToRemove = box.keys
            .where((k) => k.toString().startsWith('movies_page_') ||
                          k.toString().startsWith('series_page_') ||
                          k.toString().startsWith('all_series_catalog_cache') ||
                          k.toString().startsWith('movie_catalog_cache'))
            .toList();
        for (final k in keysToRemove) {
          await box.delete(k);
        }
      }

      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1A1A2E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF00D4FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.black, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cache de imagens e catálogo liberado!',
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao limpar cache: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isClearingCache = false);
      }
    }
  }

  void _showQualitySelector() {
    final qualities = ['Automática', 'Alta (1080p)', 'Média (720p)', 'Econômica (480p)'];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161326),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Qualidade de Transmissão',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...qualities.map((q) {
                  final isSelected = _streamQuality == q;
                  return ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    tileColor: isSelected ? const Color(0xFF7B2FF7).withValues(alpha: 0.15) : null,
                    title: Text(
                      q,
                      style: GoogleFonts.inter(
                        color: isSelected ? const Color(0xFF00D4FF) : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: Color(0xFF00D4FF))
                        : null,
                    onTap: () {
                      setState(() => _streamQuality = q);
                      _savePreference('pref_quality', q);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161326),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Limpar Histórico',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Deseja remover todos os itens de "Continue Assistindo"? Essa ação não pode ser desfeita.',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE94560),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(watchProgressListProvider.notifier).clearAllProgress();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Histórico "Continue Assistindo" limpo com sucesso!'),
                  backgroundColor: Color(0xFF161326),
                ),
              );
            },
            child: Text('Limpar', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161326),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sair da Conta?',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Você precisará fazer login novamente para acessar suas recompensas e favoritos.',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE94560),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authServiceProvider).signOut();
              if (!mounted) return;
              context.go('/login');
            },
            child: Text('Sair', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAboutAppModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161326),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Image.asset('assets/images/logo-01-sem-fundo.png', height: 70),
              const SizedBox(height: 12),
              Text(
                'PoltroPlay',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Versão 1.0.0 (Build 5)',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  'O PoltroPlay é a sua plataforma definitiva de filmes, séries e animes. '
                  'Assista onde e quando quiser com a melhor experiência e ganhe Pipocas diárias assistindo aos seus conteúdos favoritos!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, height: 1.5),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B2FF7),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Entendido',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final rewards = ref.watch(rewardsProvider);

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
            colors: [Color(0xFF1A1733), Color(0xFF0A0A0A)],
            radius: 1.4,
            center: Alignment(0, -0.6),
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            children: [
              // 1. Profile Section (Glassmorphism + Neon Glow)
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7B2FF7).withValues(alpha: 0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
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
                                radius: 32,
                                backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                                backgroundColor: const Color(0xFF1A1A2E),
                                child: user?.photoURL == null
                                    ? const Icon(Icons.person, color: Colors.white, size: 32)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.displayName ?? 'Membro PoltroPlay',
                                    style: GoogleFonts.outfit(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user?.email ?? 'Conectado',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.white60,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7B2FF7).withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFF7B2FF7).withValues(alpha: 0.5), width: 0.8),
                                    ),
                                    child: Text(
                                      'Membro VIP',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF00D4FF),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Pipocas Banner inside Profile Card
                        GestureDetector(
                          onTap: () => showRewardsModal(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF7B2FF7).withValues(alpha: 0.25),
                                  const Color(0xFF00D4FF).withValues(alpha: 0.15),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF00D4FF).withValues(alpha: 0.3), width: 1),
                            ),
                            child: Row(
                              children: [
                                const Text('🍿', style: TextStyle(fontSize: 22)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Saldo de Pipocas',
                                        style: GoogleFonts.inter(fontSize: 11, color: Colors.white60),
                                      ),
                                      Text(
                                        '${rewards.balance} Pipocas',
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFFFD700),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7B2FF7),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Ganhar +',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.white),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // 2. Transmissão & Reprodução
              _buildSectionHeader('TRANSMISSÃO & VÍDEO'),
              const SizedBox(height: 12),
              _buildSettingsCard(
                children: [
                  _buildSettingItem(
                    icon: Icons.hd_rounded,
                    title: 'Qualidade do Vídeo',
                    subtitle: _streamQuality,
                    onTap: _showQualitySelector,
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.playlist_play_rounded,
                    title: 'Próximo Episódio Automático',
                    subtitle: 'Inicia automaticamente ao terminar',
                    trailing: Switch(
                      activeThumbColor: const Color(0xFF00D4FF),
                      activeTrackColor: const Color(0xFF7B2FF7).withValues(alpha: 0.5),
                      inactiveThumbColor: Colors.grey,
                      inactiveTrackColor: Colors.white10,
                      value: _autoPlayNext,
                      onChanged: (val) {
                        setState(() => _autoPlayNext = val);
                        _savePreference('pref_autoplay', val);
                      },
                    ),
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.network_check_rounded,
                    title: 'Economia em Dados Móveis',
                    subtitle: 'Alerta antes de reproduzir em 4G/5G',
                    trailing: Switch(
                      activeThumbColor: const Color(0xFF00D4FF),
                      activeTrackColor: const Color(0xFF7B2FF7).withValues(alpha: 0.5),
                      inactiveThumbColor: Colors.grey,
                      inactiveTrackColor: Colors.white10,
                      value: _cellularWarning,
                      onChanged: (val) {
                        setState(() => _cellularWarning = val);
                        _savePreference('pref_cellular_warning', val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. Notificações
              _buildSectionHeader('NOTIFICAÇÕES'),
              const SizedBox(height: 12),
              _buildSettingsCard(
                children: [
                  _buildSettingItem(
                    icon: Icons.notifications_active_rounded,
                    title: 'Lembretes e Lançamentos',
                    subtitle: 'Avisos de novos episódios e bônus diário',
                    trailing: Switch(
                      activeThumbColor: const Color(0xFF00D4FF),
                      activeTrackColor: const Color(0xFF7B2FF7).withValues(alpha: 0.5),
                      inactiveThumbColor: Colors.grey,
                      inactiveTrackColor: Colors.white10,
                      value: _notificationsEnabled,
                      onChanged: (val) {
                        setState(() => _notificationsEnabled = val);
                        _savePreference('pref_notifications', val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 4. Armazenamento & Dados
              _buildSectionHeader('ARMAZENAMENTO & DADOS'),
              const SizedBox(height: 12),
              _buildSettingsCard(
                children: [
                  _buildSettingItem(
                    icon: Icons.cleaning_services_rounded,
                    title: 'Limpar Cache de Imagens',
                    subtitle: 'Libera espaço e recarrega capas do zero',
                    trailing: _isClearingCache
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00D4FF)),
                          )
                        : null,
                    onTap: _isClearingCache ? null : _clearCache,
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.history_rounded,
                    title: 'Limpar Histórico',
                    subtitle: 'Apaga lista de "Continue Assistindo"',
                    onTap: _confirmClearHistory,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 5. Sobre o App
              _buildSectionHeader('SOBRE'),
              const SizedBox(height: 12),
              _buildSettingsCard(
                children: [
                  _buildSettingItem(
                    icon: Icons.info_outline_rounded,
                    title: 'Sobre o PoltroPlay',
                    subtitle: 'Saiba mais sobre o aplicativo',
                    onTap: _showAboutAppModal,
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.verified_rounded,
                    title: 'Versão',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '1.0.0 (5)',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF00D4FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // 6. Logout Button
              Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE94560), Color(0xFFBA1B38)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE94560).withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _confirmLogout,
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Sair da Conta',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white38,
          letterSpacing: 1.4,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161326).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF7B2FF7).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF7B2FF7).withValues(alpha: 0.25), width: 1),
        ),
        child: Icon(icon, color: const Color(0xFF00D4FF), size: 22),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
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
      padding: const EdgeInsets.only(left: 68, right: 16),
      child: Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
    );
  }
}
