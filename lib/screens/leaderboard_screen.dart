import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/controller.dart';
import '../core/leaderboard.dart';
import '../models/profile.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/morphing_background.dart';

/// Papan peringkat penghabis token Groq.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with AutomaticKeepAliveClientMixin {
  bool _weekly = false;
  bool _register = true;
  bool _busy = false;
  bool _loading = true;
  String? _error;
  bool _obscure = true;
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _pin = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  AppController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    final profile = controller.profile;
    if (profile != null) {
      _name.text = profile.name;
      _email.text = profile.email;
      _pin.text = profile.pin;
      _register = false;
    }
    _boot();
  }

  Future<void> _boot() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await controller.refreshLeaderboard();
    } catch (error) {
      _error = error.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submitAuth() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final pin = _pin.text.trim();
    if (_register && name.isEmpty) {
      _toast('Isi nama tampilan dulu.');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      _toast('Email-nya belum valid.');
      return;
    }
    if (!RegExp(r'^\d{4,6}$').hasMatch(pin)) {
      _toast('PIN harus 4 sampai 6 digit angka.');
      return;
    }
    setState(() => _busy = true);
    try {
      await controller.signIn(
        UserProfile(email: email, name: name, pin: pin),
        register: _register,
      );
      if (!mounted) return;
      _toast(_register ? 'Akun dibuat. Selamat datang.' : 'Masuk berhasil.');
    } catch (error) {
      if (!mounted) return;
      _toast(error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    await controller.signOut();
    if (!mounted) return;
    setState(() {
      _register = true;
      _pin.clear();
    });
  }

  void _toast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final board = controller.leaderboard;
        final rows = _weekly ? board.weekly : board.all;
        final mine = _weekly ? board.meWeek : board.me;
        final logged = controller.profile?.isLoggedIn ?? false;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: MorphingScaffoldBody(
            seed: 61,
            opacity: 0.46,
            child: SafeArea(
              bottom: false,
              child: RefreshIndicator(
                onRefresh: _boot,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
                  children: <Widget>[
                    Text(
                      'Papan token',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Siapa yang paling rakus token Groq minggu ini '
                      'dan sepanjang masa.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.5,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.58,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _AuthCard(
                      logged: logged,
                      register: _register,
                      busy: _busy,
                      obscure: _obscure,
                      name: _name,
                      email: _email,
                      pin: _pin,
                      profile: controller.profile,
                      mine: mine,
                      tokens: controller.stats.totalTokens,
                      onToggleMode: () =>
                          setState(() => _register = !_register),
                      onToggleObscure: () =>
                          setState(() => _obscure = !_obscure),
                      onSubmit: _submitAuth,
                      onSignOut: _signOut,
                    ),
                    const SizedBox(height: 18),
                    SegmentedButton<bool>(
                      segments: const <ButtonSegment<bool>>[
                        ButtonSegment<bool>(
                          value: false,
                          label: Text('Sepanjang masa'),
                          icon: Icon(Icons.public_rounded, size: 16),
                        ),
                        ButtonSegment<bool>(
                          value: true,
                          label: Text('Minggu ini'),
                          icon: Icon(Icons.bolt_rounded, size: 16),
                        ),
                      ],
                      selected: <bool>{_weekly},
                      onSelectionChanged: (selection) =>
                          setState(() => _weekly = selection.first),
                    ),
                    const SizedBox(height: 16),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_error != null && rows.isEmpty)
                      GlassCard(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          _error!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.5,
                          ),
                        ),
                      )
                    else ...<Widget>[
                      if (rows.isNotEmpty) _Podium(rows: rows, weekly: _weekly),
                      const SizedBox(height: 14),
                      if (rows.isEmpty)
                        GlassCard(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Papan masih sepi. Masuk, lalu generate — '
                            'token-mu akan muncul di sini.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.55,
                            ),
                          ),
                        )
                      else
                        GlassCard(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                          child: Column(
                            children: <Widget>[
                              for (var i = 0; i < rows.length; i++)
                                _RankTile(
                                  entry: rows[i],
                                  weekly: _weekly,
                                  highlight: mine?.id == rows[i].id,
                                  medal: i < 3,
                                ),
                            ],
                          ),
                        ),
                      if (mine != null && mine.rank > 3) ...<Widget>[
                        const SizedBox(height: 12),
                        _RankTile(
                          entry: mine,
                          weekly: _weekly,
                          highlight: true,
                          medal: false,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        board.total == 0
                            ? 'Belum ada yang masuk papan.'
                            : '${board.total} penulis terdaftar'
                              '${board.week.isEmpty ? '' : ' · ${board.week}'}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.logged,
    required this.register,
    required this.busy,
    required this.obscure,
    required this.name,
    required this.email,
    required this.pin,
    required this.profile,
    required this.mine,
    required this.tokens,
    required this.onToggleMode,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.onSignOut,
  });

  final bool logged;
  final bool register;
  final bool busy;
  final bool obscure;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController pin;
  final UserProfile? profile;
  final LeaderboardEntry? mine;
  final int tokens;
  final VoidCallback onToggleMode;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (logged && profile != null) {
      return GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppTheme.brand,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  profile!.name.isEmpty
                      ? '?'
                      : profile!.name.characters.first.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    profile!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    profile!.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.55,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mine == null
                        ? '${formatTokens(tokens)} token di perangkat ini'
                        : 'Peringkat #${mine!.rank} · '
                              '${formatTokens(mine!.tokens)} token',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onSignOut, child: const Text('Keluar')),
          ],
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            register ? 'Buat akun papan' : 'Masuk ke papan',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pakai email dan PIN 4-6 digit. Tidak ada kata sandi rumit.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          if (register) ...<Widget>[
            const SizedBox(height: 12),
            TextField(
              controller: name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama tampilan',
                hintText: 'Misal: Kal',
              ),
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'kamu@email.com',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: pin,
            obscureText: obscure,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              labelText: 'PIN 4-6 digit',
              counterText: '',
              suffixIcon: IconButton(
                onPressed: onToggleObscure,
                icon: Icon(
                  obscure
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GradientButton(
            label: busy
                ? 'Menyimpan…'
                : (register ? 'Daftar' : 'Masuk'),
            icon: register
                ? Icons.person_add_alt_1_rounded
                : Icons.login_rounded,
            onPressed: busy ? null : onSubmit,
          ),
          TextButton(
            onPressed: busy ? null : onToggleMode,
            child: Text(
              register
                  ? 'Sudah punya akun? Masuk'
                  : 'Belum punya akun? Daftar',
            ),
          ),
        ],
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.rows, required this.weekly});

  final List<LeaderboardEntry> rows;
  final bool weekly;

  @override
  Widget build(BuildContext context) {
    final first = rows.isNotEmpty ? rows[0] : null;
    final second = rows.length > 1 ? rows[1] : null;
    final third = rows.length > 2 ? rows[2] : null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: _PodiumCard(
            entry: second,
            place: 2,
            height: 132,
            color: const Color(0xFF94A3B8),
            weekly: weekly,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PodiumCard(
            entry: first,
            place: 1,
            height: 168,
            color: AppColors.amber,
            weekly: weekly,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PodiumCard(
            entry: third,
            place: 3,
            height: 116,
            color: const Color(0xFFD97706),
            weekly: weekly,
          ),
        ),
      ],
    );
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({
    required this.entry,
    required this.place,
    required this.height,
    required this.color,
    required this.weekly,
  });

  final LeaderboardEntry? entry;
  final int place;
  final double height;
  final Color color;
  final bool weekly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = entry?.name ?? 'Kosong';
    final score = entry == null
        ? '—'
        : formatTokens(weekly ? entry!.weekTokens : entry!.tokens);
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            color.withValues(alpha: place == 1 ? 0.42 : 0.22),
            color.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Column(
        children: <Widget>[
          Text(
            '#$place',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const Spacer(),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            score,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankTile extends StatelessWidget {
  const _RankTile({
    required this.entry,
    required this.weekly,
    required this.highlight,
    required this.medal,
  });

  final LeaderboardEntry entry;
  final bool weekly;
  final bool highlight;
  final bool medal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = weekly ? entry.weekTokens : entry.tokens;
    final colors = <int, Color>{
      1: AppColors.amber,
      2: const Color(0xFF94A3B8),
      3: const Color(0xFFD97706),
    };
    final accent = colors[entry.rank] ?? theme.colorScheme.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: highlight
            ? theme.colorScheme.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        border: highlight
            ? Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.35),
              )
            : null,
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 36,
            child: Text(
              medal ? '#${entry.rank}' : '${entry.rank}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: medal ? accent : theme.colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${entry.generates} generate',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatTokens(score),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}
