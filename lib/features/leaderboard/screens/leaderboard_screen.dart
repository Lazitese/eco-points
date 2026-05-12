import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pulsing green dot
                _LiveDot(),
                const SizedBox(width: 5),
                Text(
                  'Live',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: SupabaseService.leaderboardStream(),
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            );
          }

          // Error
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load leaderboard.\n${snapshot.error}',
                  style: const TextStyle(color: AppTheme.errorRed),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final users = snapshot.data ?? [];
          final currentUserId = SupabaseService.currentUser?.id;

          // Empty state
          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.leaderboard_rounded,
                      size: 64, color: AppTheme.accentGreen),
                  const SizedBox(height: 16),
                  Text('No users yet',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text('Be the first to earn points!',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // ── Podium (only when ≥ 3 users) ──────────────────────────────
              if (users.length >= 3)
                SliverToBoxAdapter(
                  child: _Podium(users: users.take(3).toList())
                      .animate()
                      .fadeIn(duration: 500.ms),
                ),

              // ── Full ranked list ───────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverList.builder(
                  itemCount: users.length,
                  itemBuilder: (context, i) {
                    return _LeaderboardTile(
                      rank: i + 1,
                      user: users[i],
                      isCurrentUser: users[i]['id'] == currentUserId,
                    )
                        .animate(delay: Duration(milliseconds: 40 * i))
                        .fadeIn()
                        .slideX(begin: 0.08);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Live dot ───────────────────────────────────────────────────────────────────

class _LiveDot extends StatefulWidget {
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppTheme.accentGreen,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ── Podium ─────────────────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  const _Podium({required this.users});
  final List<Map<String, dynamic>> users;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreen, Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      // IntrinsicHeight so all slots align at the bottom
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _PodiumSlot(user: users[1], rank: 2, barHeight: 72),
          _PodiumSlot(user: users[0], rank: 1, barHeight: 100),
          _PodiumSlot(user: users[2], rank: 3, barHeight: 52),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  const _PodiumSlot({
    required this.user,
    required this.rank,
    required this.barHeight,
  });

  final Map<String, dynamic> user;
  final int rank;
  final double barHeight;

  static const _medals = ['🥇', '🥈', '🥉'];
  static const _barColors = [
    Color(0xFFFFD700),
    Color(0xFFC0C0C0),
    Color(0xFFCD7F32),
  ];

  @override
  Widget build(BuildContext context) {
    final name = user['display_name'] as String? ?? 'User';
    final pts  = user['total_points'] as int? ?? 0;
    final color = _barColors[rank - 1];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_medals[rank - 1], style: const TextStyle(fontSize: 26)),
        const SizedBox(height: 4),
        // Name — constrained width so it never overflows
        SizedBox(
          width: 80,
          child: Text(
            name.split(' ').first,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        Text(
          '$pts pts',
          style: TextStyle(
              color: color, fontWeight: FontWeight.w800, fontSize: 11),
        ),
        const SizedBox(height: 6),
        Container(
          width: 72,
          height: barHeight,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.22),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          alignment: Alignment.center,
          child: Text(
            '#$rank',
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 20),
          ),
        ),
      ],
    );
  }
}

// ── List tile ──────────────────────────────────────────────────────────────────

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({
    required this.rank,
    required this.user,
    required this.isCurrentUser,
  });

  final int rank;
  final Map<String, dynamic> user;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final name   = user['display_name'] as String? ?? 'User';
    final points = user['total_points'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppTheme.primaryGreen.withValues(alpha: 0.07)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCurrentUser
            ? Border.all(color: AppTheme.primaryGreen, width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          // Rank — fixed width
          SizedBox(
            width: 34,
            child: Text(
              '#$rank',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: rank <= 3
                        ? AppTheme.primaryGreen
                        : AppTheme.textMuted,
                    fontWeight:
                        rank <= 3 ? FontWeight.w800 : FontWeight.w500,
                    fontSize: 14,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          // Avatar
          CircleAvatar(
            radius: 19,
            backgroundColor:
                AppTheme.primaryGreen.withValues(alpha: 0.13),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w700,
                  fontSize: 15),
            ),
          ),
          const SizedBox(width: 12),
          // Name — Expanded prevents overflow
          Expanded(
            child: Text(
              isCurrentUser ? '$name (You)' : name,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isCurrentUser
                        ? AppTheme.primaryGreen
                        : AppTheme.textDark,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Points — fixed, never pushed off
          Text(
            '$points pts',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
          ),
        ],
      ),
    );
  }
}
