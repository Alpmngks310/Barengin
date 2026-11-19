import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../models/barengin_models.dart';
import '../state/session_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'edit_activity_screen.dart';

class HostManagementScreen extends StatefulWidget {
  const HostManagementScreen({super.key, required this.activity});
  final Activity activity;
  @override
  State<HostManagementScreen> createState() => _HostManagementScreenState();
}

class _HostManagementScreenState extends State<HostManagementScreen> {
  late Future<void> _loading;
  List<JoinRequest> _requests = [];
  List<dynamic> _participants = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loading = _load();
  }

  Future<void> _load() async {
    final api = context.read<SessionController>();

    final results = await Future.wait([
      api.getJoinRequests(widget.activity.id),
      api.getParticipants(widget.activity.id),
    ]);

    if (!mounted) return;

    _requests = results[0] as List<JoinRequest>;
    _participants = results[1];
  }

  Future<void> _refresh() async {
    if (!mounted) return;

    final future = _load();

    setState(() => _loading = future);

    await future;
  }

  Future<void> _decide(JoinRequest request, String status) async {
    setState(() => _busy = true);
    try {
      await context.read<SessionController>().decideJoinRequest(
        request.id,
        status,
      );
      await _refresh();
      if (mounted) {
        showAppMessage(
          context,
          status == 'accepted' ? 'Permintaan diterima.' : 'Permintaan ditolak.',
        );
      }
    } on ApiException catch (e) {
      if (mounted) showAppMessage(context, e.firstFieldError, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _lifecycleAction(String action) async {
    final labels = {
      'publish': 'Publikasikan aktivitas ini?',
      'start': 'Mulai aktivitas ini?',
      'complete': 'Tandai aktivitas selesai?',
      'cancel': 'Batalkan aktivitas ini?',
    };
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(labels[action] ?? 'Konfirmasi'),
        content: Text(
          action == 'cancel'
              ? 'Peserta akan diberi status pembatalan dan permintaan pending akan ditolak.'
              : action == 'publish'
              ? 'Aktivitas akan terlihat di Explore dan bisa menerima permintaan bergabung.'
              : 'Status aktivitas akan diperbarui.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, lanjut'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      final api = context.read<SessionController>();
      if (action == 'publish') await api.publishActivity(widget.activity.id);
      if (action == 'start') await api.startActivity(widget.activity.id);
      if (action == 'complete') await api.completeActivity(widget.activity.id);
      if (action == 'cancel') {
        await api.cancelActivity(
          widget.activity.id,
          reason: 'Dibatalkan oleh Host.',
        );
      }
      if (mounted) {
        showAppMessage(context, 'Status aktivitas berhasil diperbarui.');
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) showAppMessage(context, e.firstFieldError, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeParticipant(int userId, String name) async {
    if (_busy || userId <= 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluarkan peserta?'),
        content: Text(
          '$name tidak lagi terdaftar sebagai peserta aktivitas ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluarkan'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);

    try {
      await context.read<SessionController>().removeParticipant(
        widget.activity.id,
        userId,
      );

      await _refresh();

      if (mounted) {
        showAppMessage(context, 'Peserta berhasil dikeluarkan.');
      }
    } on ApiException catch (e) {
      if (mounted) {
        showAppMessage(context, e.firstFieldError, error: true);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Kelola aktivitas',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
      ),
      actions: [
        if (['draft', 'published'].contains(widget.activity.status) &&
            (widget.activity.startsAt?.isAfter(DateTime.now()) ?? false))
          IconButton(
            tooltip: 'Edit aktivitas',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _busy
                ? null
                : () async {
                    final updated = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            EditActivityScreen(activity: widget.activity),
                      ),
                    );
                    if (updated == true && mounted) {
                      await _refresh();
                      if (mounted) {
                        showAppMessage(
                          context,
                          'Aktivitas berhasil diperbarui.',
                        );
                        Navigator.pop(context, true);
                      }
                    }
                  },
          ),
      ],
    ),
    body: FutureBuilder<void>(
      future: _loading,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: EmptyState(
              title: 'Data belum bisa dimuat',
              message: snapshot.error.toString(),
              actionLabel: 'Coba lagi',
              onAction: _refresh,
            ),
          );
        }
        final pending = _requests.where((e) => e.status == 'pending').toList();
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            children: [
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: AppColors.sageLight,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.activity.categoryName.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.sageDark,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: .8,
                            ),
                          ),
                        ),
                        StatusPill(widget.activity.status),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Text(
                      widget.activity.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.forest,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.activity.city} · ${widget.activity.capacity} kapasitas',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        const Icon(
                          Icons.people_alt_outlined,
                          color: AppColors.forest,
                          size: 17,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_participants.length}/${widget.activity.capacity} peserta terdaftar',
                          style: const TextStyle(
                            color: AppColors.forest,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${pending.length} menunggu',
                          style: const TextStyle(
                            color: AppColors.forest,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SectionTitle(
                'Permintaan masuk',
                actionLabel: '${pending.length} pending',
              ),
              if (pending.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'Belum ada permintaan baru. Nanti request yang masuk akan muncul di sini.',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                )
              else
                ...pending.map(
                  (request) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(13),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              AppAvatar(name: request.userName, size: 40),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      request.userName,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      request.username.isEmpty
                                          ? request.city
                                          : '@${request.username}',
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const StatusPill('pending'),
                            ],
                          ),
                          if (request.message.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 11),
                              child: Text(
                                '“${request.message}”',
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _decide(request, 'rejected'),
                                  child: const Text('Tolak'),
                                ),
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _decide(request, 'accepted'),
                                  child: const Text('Terima'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              SectionTitle(
                'Peserta terdaftar',
                actionLabel: '${_participants.length} orang',
              ),
              if (_participants.isEmpty)
                const Text(
                  'Belum ada peserta.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                )
              else
                ..._participants.map((raw) {
                  final item = Map<String, dynamic>.from(raw as Map);
                  final user = item['user'] is Map
                      ? Map<String, dynamic>.from(item['user'])
                      : <String, dynamic>{};
                  final profile = user['profile'] is Map
                      ? Map<String, dynamic>.from(user['profile'])
                      : <String, dynamic>{};
                  final name =
                      (profile['display_name'] ?? user['name'] ?? 'Pengguna')
                          .toString();
                  final userId = int.tryParse(user['id'].toString()) ?? 0;
                  final isHost = item['role'] == 'host';
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 2),
                    leading: AppAvatar(name: name, size: 40),
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      isHost ? 'Host' : '@${user['username'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.muted,
                      ),
                    ),
                    trailing: isHost
                        ? const StatusPill('accepted')
                        : IconButton(
                            tooltip: 'Keluarkan peserta',
                            onPressed: _busy || userId <= 0
                                ? null
                                : () => _removeParticipant(userId, name),
                            icon: const Icon(
                              Icons.person_remove_alt_1_outlined,
                              color: AppColors.danger,
                            ),
                          ),
                  );
                }),
              const SizedBox(height: 22),
              const SectionTitle('Tindakan Host'),
              if (widget.activity.status == 'draft')
                _ActionTile(
                  icon: Icons.send_rounded,
                  title: 'Publikasikan aktivitas',
                  subtitle: 'Tampilkan aktivitas di Explore',
                  onTap: _busy ? null : () => _lifecycleAction('publish'),
                ),
              if (widget.activity.status == 'published')
                _ActionTile(
                  icon: Icons.play_arrow_rounded,
                  title: 'Mulai aktivitas',
                  subtitle: 'Tandai kegiatan sedang berlangsung',
                  onTap: _busy ? null : () => _lifecycleAction('start'),
                ),
              if (widget.activity.status == 'ongoing')
                _ActionTile(
                  icon: Icons.flag_rounded,
                  title: 'Tandai selesai',
                  subtitle: 'Selesaikan kegiatan yang berlangsung',
                  onTap: _busy ? null : () => _lifecycleAction('complete'),
                ),
              if ([
                'draft',
                'published',
                'ongoing',
              ].contains(widget.activity.status))
                _ActionTile(
                  icon: Icons.cancel_outlined,
                  title: 'Batalkan aktivitas',
                  subtitle: 'Peserta akan diberi informasi pembatalan',
                  danger: true,
                  onTap: _busy ? null : () => _lifecycleAction('cancel'),
                ),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.all(14),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        );
      },
    ),
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool danger;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 3),
    leading: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: danger ? const Color(0xFFFFE9E5) : AppColors.sageLight,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: danger ? AppColors.danger : AppColors.forest),
    ),
    title: Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: danger ? AppColors.danger : AppColors.ink,
      ),
    ),
    subtitle: Text(
      subtitle,
      style: const TextStyle(fontSize: 10, color: AppColors.muted),
    ),
    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
    onTap: onTap,
  );
}
