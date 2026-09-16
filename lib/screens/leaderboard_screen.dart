import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/controller.dart';
import '../core/leaderboard.dart';
import '../models/profile.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/morphing_background.dart';

/// Papan peringkat penghabis token Groq — data live, bukan dummy.
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
        final top = rows.isEmpty
            ? 0
            : (_weekly ? rows.first.weekTokens : rows.first.tokens);

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
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 36),
                  children: <Widget>[
                    _Header(weekly: _weekly, week: board.week),
                    const SizedBox(height: 14),
                    _StatsStrip(
                      writers: board.total,
                      week: board.week,
                      myTokens: logged
                          ? (mine == null
                                ? controller.stats.totalTokens
                                : (_weekly ? mine.weekTokens : mine.tokens))
                          : controller.stats.totalTokens,
                    ),
                    const SizedBox(height: 14),
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
                      rows: rows,
                      weekly: _weekly,
                      tokens: controller.stats.totalTokens,
                      onToggleMode: () =>
                          setState(() => _register = !_register),
                      onToggleObscure: () =>
                          setState(() => _obscure = !_obscure),
                      onSubmit: _submitAuth,
                      onSignOut: _signOut,
                    ),
                    const SizedBox(height: 18),
                    _PeriodToggle(
                      weekly: _weekly,
                      onChanged: (value) => setState(() => _weekly = value),
                    ),
                    const SizedBox(height: 16),
                    if (_loading)
                      const _Skeleton()
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
                      _Podium(rows: rows, weekly: _weekly),
                      const SizedBox(height: 16),
                      if (rows.isEmpty)
                        const _EmptyArena()
                      else
                        GlassCard(
                          padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
                          child: Column(
                            children: <Widget>[
                              for (var i = 0; i < rows.length; i++)
                                _RankTile(
                                  entry: rows[i],
                                  weekly: _weekly,
                                  highlight: mine?.id == rows[i].id,
                                  top: top,
                                ),
                            ],
                          ),
                        ),
                      if (mine != null && mine.rank > 10) ...<Widget>[
                        const SizedBox(height: 12),
                        _RankTile(
                          entry: mine,
                          weekly: _weekly,
                          highlight: true,
                          top: top,
                        ),
                      ],
                      const SizedBox(height: 14),
                      Text(
                        board.total == 0
                            ? 'Data live. Belum ada yang generate.'
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

class _Header extends StatelessWidget {
  const _Header({required this.weekly, required this.week});

  final bool weekly;
  final String week;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Papan token',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: AppColors.mint.withValues(alpha: 0.14),
                border: Border.all(
                  color: AppColors.mint.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.mint,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Live',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.mint,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          weekly
              ? 'Peringkat minggu ini$weekLabel. Skor dari generate sungguhan.'
              : 'Siapa paling rakus token Groq. Skor dari generate sungguhan, bukan dummy.',
          style: theme.textTheme.bodySmall?.copyWith(
            height: 1.5,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
          ),
        ),
      ],
    );
  }

  String get weekLabel => week.isEmpty ? '' : ' ($week)';
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({
    required this.writers,
    required this.week,
    required this.myTokens,
  });

  final int writers;
  final String week;
  final int myTokens;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _StatCell(
            label: 'Penulis',
            value: writers == 0 ? '—' : '$writers',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCell(
            label: 'Minggu',
            value: week.isEmpty ? '—' : week.replaceFirst('20', ''),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCell(
            label: 'Token kamu',
            value: myTokens == 0 ? '0' : formatTokens(myTokens),
          ),
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 9.5,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodToggle extends StatelessWidget {
  const _PeriodToggle({required this.weekly, required this.onChanged});

  final bool weekly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _PeriodChip(
            label: 'Sepanjang masa',
            selected: !weekly,
            onTap: () => onChanged(false),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PeriodChip(
            label: 'Minggu ini',
            selected: weekly,
            onTap: () => onChanged(true),
          ),
        ),
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: selected ? AppTheme.brand : null,
          color: selected ? null : theme.colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: selected
                ? Colors.transparent
                : theme.colorScheme.outline.withValues(alpha: 0.7),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: selected ? Colors.white : theme.colorScheme.onSurface,
          ),
        ),
      ),
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
    required this.rows,
    required this.weekly,
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
  final List<LeaderboardEntry> rows;
  final bool weekly;
  final int tokens;
  final VoidCallback onToggleMode;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (logged && profile != null) {
      return _YouCard(
        profile: profile!,
        mine: mine,
        rows: rows,
        weekly: weekly,
        tokens: tokens,
        onSignOut: onSignOut,
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            register ? 'Ambil tempat di papan' : 'Masuk ke papan',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Email + PIN 4-6 digit. Nama tampil publik, email di-hash.',
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
            label: busy ? 'Menyimpan…' : (register ? 'Daftar' : 'Masuk'),
            icon: register
                ? Icons.person_add_alt_1_rounded
                : Icons.login_rounded,
            loading: busy,
            onPressed: busy ? null : onSubmit,
          ),
          TextButton(
            onPressed: busy ? null : onToggleMode,
            child: Text(
              register ? 'Sudah punya akun? Masuk' : 'Belum punya akun? Daftar',
            ),
          ),
        ],
      ),
    );
  }
}

class _YouCard extends StatelessWidget {
  const _YouCard({
    required this.profile,
    required this.mine,
    required this.rows,
    required this.weekly,
    required this.tokens,
    required this.onSignOut,
  });

  final UserProfile profile;
  final LeaderboardEntry? mine;
  final List<LeaderboardEntry> rows;
  final bool weekly;
  final int tokens;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = mine == null
        ? tokens
        : (weekly ? mine!.weekTokens : mine!.tokens);
    final next = _gapToNext();
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderColor: AppColors.violet.withValues(alpha: 0.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _Avatar(name: profile.name, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      profile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      mine == null
                          ? 'Belum ada peringkat. Generate dulu.'
                          : 'Peringkat #${mine!.rank}',
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
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Text(
                formatTokens(score),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'token',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          if (next != null) ...<Widget>[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: next.$1,
                minHeight: 7,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: AppColors.violet,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              next.$2,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ],
      ),
    );
  }

  (double, String)? _gapToNext() {
    if (mine == null) return null;
    if (mine!.rank <= 1) {
      return (1, 'Kamu di puncak papan ini.');
    }
    LeaderboardEntry? above;
    for (final row in rows) {
      if (row.rank == mine!.rank - 1) {
        above = row;
        break;
      }
    }
    if (above == null) return null;
    final mineScore = weekly ? mine!.weekTokens : mine!.tokens;
    final aboveScore = weekly ? above.weekTokens : above.tokens;
    final gap = (aboveScore - mineScore + 1).clamp(1, 1000000000);
    final denom = aboveScore == 0 ? 1 : aboveScore;
    final value = (mineScore / denom).clamp(0.04, 0.96).toDouble();
    return (value, '${formatTokens(gap)} token lagi untuk #${above.rank}');
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.size = 36, this.color});

  final String name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: color == null ? AppTheme.brand : null,
        color: color,
        borderRadius: BorderRadius.circular(size * 0.34),
      ),
      child: Text(
        initials(name),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.36,
        ),
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
            height: 148,
            color: const Color(0xFF94A3B8),
            weekly: weekly,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 11,
          child: _PodiumCard(
            entry: first,
            place: 1,
            height: 186,
            color: AppColors.amber,
            weekly: weekly,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PodiumCard(
            entry: third,
            place: 3,
            height: 132,
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
    return AnimatedContainer(
      duration: AppMotion.normal,
      height: height,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            color.withValues(alpha: place == 1 ? 0.46 : 0.24),
            color.withValues(alpha: 0.07),
          ],
        ),
        border: Border.all(color: color.withValues(alpha: 0.55)),
        boxShadow: place == 1
            ? <BoxShadow>[
                BoxShadow(
                  color: color.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        children: <Widget>[
          _Avatar(name: name, size: place == 1 ? 44 : 36, color: color),
          const SizedBox(height: 6),
          Text(
            '#$place',
            style: theme.textTheme.titleSmall?.copyWith(
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
    required this.top,
  });

  final LeaderboardEntry entry;
  final bool weekly;
  final bool highlight;
  final int top;

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
    final bar = top <= 0 ? 0.0 : (score / top).clamp(0.04, 1.0);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
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
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              SizedBox(
                width: 36,
                child: Text(
                  '#${entry.rank}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: entry.rank <= 3
                        ? accent
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              _Avatar(
                name: entry.name,
                size: 32,
                color: entry.rank <= 3 ? accent : null,
              ),
              const SizedBox(width: 10),
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
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
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
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: bar,
              minHeight: 4,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: accent.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyArena extends StatelessWidget {
  const _EmptyArena();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: Column(
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: AppTheme.brand,
            ),
            child: const Icon(
              Icons.leaderboard_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Papan masih sepi',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bukan dummy: belum ada yang generate. Daftar, lalu buat sesuatu — '
            'posisi #1 masih kosong.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.55,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
            ),
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget bar(double h, [double w = double.infinity]) => Container(
      height: h,
      width: w,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
    );
    return Column(
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(child: bar(120)),
            const SizedBox(width: 8),
            Expanded(child: bar(160)),
            const SizedBox(width: 8),
            Expanded(child: bar(100)),
          ],
        ),
        const SizedBox(height: 8),
        bar(56),
        bar(56),
        bar(56),
      ],
    );
  }
}
