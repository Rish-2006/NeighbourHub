// lib/screens/neighbours/neighbours_screen.dart
//
// Premium Neighbours screen — displays all community members with
// animated cards, search, gradient avatars, and member stats.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

// Stable gradient palette for avatars — cycles through beautiful combos
const List<List<Color>> _avatarGradients = [
  [Color(0xFFFFCC00), Color(0xFFFF8C00)], // yellow-orange
  [Color(0xFF6C63FF), Color(0xFF3B82F6)], // purple-blue
  [Color(0xFF22C55E), Color(0xFF06B6D4)], // green-cyan
  [Color(0xFFEC4899), Color(0xFFEF4444)], // pink-red
  [Color(0xFF8B5CF6), Color(0xFFEC4899)], // violet-pink
  [Color(0xFFF59E0B), Color(0xFF22C55E)], // amber-green
];

List<Color> _gradientForName(String name) {
  if (name.isEmpty) return _avatarGradients[0];
  final idx = name.codeUnits.fold(0, (sum, c) => sum + c) % _avatarGradients.length;
  return _avatarGradients[idx];
}

class NeighboursScreen extends StatefulWidget {
  const NeighboursScreen({super.key});

  @override
  State<NeighboursScreen> createState() => _NeighboursScreenState();
}

class _NeighboursScreenState extends State<NeighboursScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthService>().currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: StreamBuilder<List<UserModel>>(
        stream: context.read<FirestoreService>().getAllUsersStream(),
        builder: (context, snapshot) {
          // ── Loading ─────────────────────────────────────────────────────────
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          // ── Error ────────────────────────────────────────────────────────────
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_rounded, color: AppTheme.errorColor, size: 48),
                  const SizedBox(height: 12),
                  Text('Could not load members',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            );
          }

          final allUsers = snapshot.data ?? [];

          // Separate "me" from others
          final others = allUsers.where((u) => u.id != currentUserId).toList();
          final me = allUsers.where((u) => u.id == currentUserId).firstOrNull;

          // Search filter
          final filtered = _query.isEmpty
              ? others
              : others
                  .where((u) =>
                      u.name.toLowerCase().contains(_query.toLowerCase()) ||
                      u.neighbourhood.toLowerCase().contains(_query.toLowerCase()))
                  .toList();

          return CustomScrollView(
            slivers: [
              // ── Hero AppBar ─────────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 160,
                floating: false,
                pinned: true,
                backgroundColor: AppTheme.darkBg,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: _HeroHeader(
                    totalMembers: allUsers.length,
                    currentUser: me,
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(64),
                  child: _SearchBar(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
              ),

              // ── Stats row ───────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _StatsRow(total: allUsers.length)
                    .animate()
                    .fadeIn(delay: 100.ms),
              ),

              // ── Section header ──────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Text(
                        _query.isEmpty ? 'ALL MEMBERS' : 'RESULTS',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: AppTheme.darkSubtext,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${filtered.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Empty state ─────────────────────────────────────────────────
              if (filtered.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 64,
                            color: AppTheme.darkSubtext.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text(
                          _query.isEmpty
                              ? 'No members yet.'
                              : 'No results for "$_query"',
                          style: const TextStyle(color: AppTheme.darkSubtext),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Member cards ────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final user = filtered[index];
                      final isMe = user.id == currentUserId;
                      return _MemberCard(
                        key: ValueKey(user.id),
                        user: user,
                        isMe: isMe,
                        index: index,
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Hero Header ──────────────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final int totalMembers;
  final UserModel? currentUser;

  const _HeroHeader({required this.totalMembers, this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1600), Color(0xFF0A0A0A)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Neighbours',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalMembers members in your community',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.darkSubtext,
                    ),
                  ),
                ],
              ),
            ),
            // Stacked avatar preview
            _StackedAvatars(count: min(totalMembers, 4)),
          ],
        ),
      ),
    );
  }
}

class _StackedAvatars extends StatelessWidget {
  final int count;
  const _StackedAvatars({required this.count});

  static const List<String> _initials = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    final items = min(count, _initials.length);
    return SizedBox(
      width: items * 28.0 + 14,
      height: 44,
      child: Stack(
        children: List.generate(items, (i) {
          final gradient = _avatarGradients[i % _avatarGradients.length];
          return Positioned(
            left: i * 24.0,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: gradient),
                border: Border.all(color: AppTheme.darkBg, width: 2.5),
              ),
              child: Center(
                child: Text(
                  _initials[i],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.darkBg,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search by name or neighbourhood…',
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryColor),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.darkSubtext),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: AppTheme.darkCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppTheme.darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final int total;
  const _StatsRow({required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _StatChip(
            icon: Icons.people_outline_rounded,
            label: '$total',
            sublabel: 'Members',
            color: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: color,
                    )),
                Text(sublabel,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.darkSubtext,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Member Card ──────────────────────────────────────────────────────────────
class _MemberCard extends StatelessWidget {
  final UserModel user;
  final bool isMe;
  final int index;

  const _MemberCard({
    super.key,
    required this.user,
    required this.isMe,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = _gradientForName(user.name);
    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';
    final hasPhoto = user.photoUrl.isNotEmpty;
    final hasApartment = user.apartment.isNotEmpty;
    final hasBio = user.bio.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isMe
              ? AppTheme.primaryColor.withValues(alpha: 0.5)
              : AppTheme.darkBorder,
          width: isMe ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showMemberSheet(context, gradient, initial, hasPhoto),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // ── Gradient avatar ─────────────────────────────────────────
                _GradientAvatar(
                  user: user,
                  gradient: gradient,
                  initial: initial,
                  hasPhoto: hasPhoto,
                  size: 52,
                  isMe: isMe,
                ),
                const SizedBox(width: 14),

                // ── Name / details ──────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'YOU',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      if (hasApartment) ...[
                        Row(
                          children: [
                            const Icon(Icons.home_outlined,
                                size: 12, color: AppTheme.darkSubtext),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                user.apartment,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.darkSubtext,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                      ],
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 12, color: AppTheme.darkSubtext),
                          const SizedBox(width: 4),
                          Text(
                            'Joined ${timeago.format(user.createdAt)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.darkSubtext,
                            ),
                          ),
                        ],
                      ),
                      if (hasBio) ...[
                        const SizedBox(height: 4),
                        Text(
                          user.bio,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.darkSubtext.withValues(alpha: 0.7),
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Chevron ─────────────────────────────────────────────────
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.darkSubtext,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (index * 50).ms, duration: 300.ms)
        .slideX(begin: 0.04, end: 0);
  }

  void _showMemberSheet(
    BuildContext context,
    List<Color> gradient,
    String initial,
    bool hasPhoto,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _MemberDetailSheet(
        user: user,
        gradient: gradient,
        initial: initial,
        hasPhoto: hasPhoto,
      ),
    );
  }
}

// ─── Gradient Avatar ──────────────────────────────────────────────────────────
class _GradientAvatar extends StatelessWidget {
  final UserModel user;
  final List<Color> gradient;
  final String initial;
  final bool hasPhoto;
  final double size;
  final bool isMe;

  const _GradientAvatar({
    required this.user,
    required this.gradient,
    required this.initial,
    required this.hasPhoto,
    required this.size,
    this.isMe = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: hasPhoto
          ? ClipOval(
              child: Image.network(
                user.photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(initial,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size * 0.4,
                        fontWeight: FontWeight.w800,
                      )),
                ),
              ),
            )
          : Center(
              child: Text(
                initial,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.38,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
    );
  }
}

// ─── Member Detail Bottom Sheet ───────────────────────────────────────────────
class _MemberDetailSheet extends StatelessWidget {
  final UserModel user;
  final List<Color> gradient;
  final String initial;
  final bool hasPhoto;

  const _MemberDetailSheet({
    required this.user,
    required this.gradient,
    required this.initial,
    required this.hasPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.darkBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Large avatar
            _GradientAvatar(
              user: user,
              gradient: gradient,
              initial: initial,
              hasPhoto: hasPhoto,
              size: 80,
            ),
            const SizedBox(height: 14),

            // Name
            Text(
              user.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),

            // Neighbourhood pill
            if (user.neighbourhood.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 13, color: AppTheme.primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      user.neighbourhood,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            const Divider(color: AppTheme.darkBorder),
            const SizedBox(height: 16),

            // Details list
            Expanded(
              child: ListView(
                controller: controller,
                children: [
                  if (user.apartment.isNotEmpty)
                    _DetailTile(
                      icon: Icons.home_outlined,
                      label: 'Apartment',
                      value: user.apartment,
                    ),
                  if (user.bio.isNotEmpty)
                    _DetailTile(
                      icon: Icons.info_outline_rounded,
                      label: 'About',
                      value: user.bio,
                    ),
                  _DetailTile(
                    icon: Icons.calendar_today_outlined,
                    label: 'Member since',
                    value: 'Joined ${timeago.format(user.createdAt)}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkSubtext,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
