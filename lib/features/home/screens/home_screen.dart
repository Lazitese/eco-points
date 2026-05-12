import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/action_card.dart';
import '../widgets/points_banner.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.currentUser;
    final displayName =
        user?.userMetadata?['display_name'] as String? ?? 'Eco Hero';

    return Scaffold(
      appBar: AppBar(
        // Fixed height AppBar — no overflow from two-line title
        toolbarHeight: 64,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hello, ${displayName.split(' ').first} 👋',
              style: Theme.of(context).textTheme.titleLarge,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Keep up the great work!',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard_rounded),
            tooltip: 'Leaderboard',
            onPressed: () => context.push('/leaderboard'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: () async => SupabaseService.signOut(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Points banner ──────────────────────────────────────────────
              const PointsBanner()
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: -0.15),

              const SizedBox(height: 28),

              Text(
                'What would you like to do?',
                style: Theme.of(context).textTheme.headlineMedium,
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 16),

              // ── Walk button ────────────────────────────────────────────────
              ActionCard(
                icon: Icons.directions_walk_rounded,
                title: 'Walk',
                subtitle: 'Earn 10 pts per km',
                color: AppTheme.walkBlue,
                onTap: () => context.push('/walk'),
              )
                  .animate()
                  .fadeIn(delay: 300.ms)
                  .slideX(begin: -0.1),

              const SizedBox(height: 14),

              // ── Verify Meal button ─────────────────────────────────────────
              ActionCard(
                icon: Icons.restaurant_rounded,
                title: 'Verify Meal',
                subtitle: 'Snap a photo to earn points',
                color: AppTheme.mealOrange,
                onTap: () => context.push('/meal'),
              )
                  .animate()
                  .fadeIn(delay: 400.ms)
                  .slideX(begin: 0.1),

              const SizedBox(height: 28),

              // ── Recent activity ────────────────────────────────────────────
              const _RecentActivitySection()
                  .animate()
                  .fadeIn(delay: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Recent activity ────────────────────────────────────────────────────────────

class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService.client
          .from('activities')
          .stream(primaryKey: ['id'])
          .eq('user_id', SupabaseService.currentUser!.id)
          .order('created_at', ascending: false)
          .limit(5),
      builder: (context, snapshot) {
        final activities = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            if (activities.isEmpty)
              _EmptyActivity()
            else
              ...activities.map((a) => _ActivityTile(activity: a)),
          ],
        );
      },
    );
  }
}

class _EmptyActivity extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.eco_rounded, size: 48, color: AppTheme.accentGreen),
          const SizedBox(height: 12),
          Text(
            'No activities yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Start walking or verify a meal!',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity});
  final Map<String, dynamic> activity;

  @override
  Widget build(BuildContext context) {
    final type   = activity['type']   as String? ?? 'unknown';
    final points = activity['points'] as int?    ?? 0;
    final status = activity['status'] as String? ?? 'pending';
    final isWalk = type == 'walk';
    final color  = isWalk ? AppTheme.walkBlue : AppTheme.mealOrange;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isWalk
                  ? Icons.directions_walk_rounded
                  : Icons.restaurant_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          // Title + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isWalk ? 'Walk' : 'Meal Verification',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  status == 'approved' ? 'Approved ✓' : 'Pending review',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: status == 'approved'
                            ? AppTheme.primaryGreen
                            : AppTheme.textMuted,
                        fontSize: 12,
                      ),
                ),
              ],
            ),
          ),
          // Points — won't overflow because Expanded takes remaining space
          Text(
            '+$points pts',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.primaryGreen,
                  fontSize: 15,
                ),
          ),
        ],
      ),
    );
  }
}
