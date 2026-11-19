import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../models/barengin_models.dart';
import '../state/session_controller.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';
import 'host_management_screen.dart';
import 'safety_screens.dart';

class ActivityDetailScreen extends StatefulWidget {
  const ActivityDetailScreen({
    super.key,
    required this.activity,
    this.isMember = false,
  });
  final Activity activity;
  final bool isMember;
  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  late Future<Activity> _future;
  late bool _favorite;
  bool _sending = false;
  bool _loadingJoinState = false;
  bool _isMember = false;
  bool _favoriteBusy = false;
  String? _requestStatus;
  int? _requestId;

  @override
  void initState() {
    super.initState();
    _favorite = widget.activity.isFavorited;
    _isMember = widget.isMember;
    _future = widget.isMember
        ? Future<Activity>.value(widget.activity)
        : context.read<SessionController>().getActivity(widget.activity.id);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadJoinState());
  }

  Future<void> _loadJoinState() async {
    if (!mounted) return;
    final session = context.read<SessionController>();
    if (session.user == null) return;

    setState(() => _loadingJoinState = true);
    try {
      final results = await Future.wait([
        session.getLatestJoinRequestForActivity(widget.activity.id),
        session.getMyActivities(role: 'member'),
      ]);
      if (!mounted) return;
      final latestRequest = results[0] as JoinRequest?;
      final memberships = results[1] as List<Activity>;
      setState(() {
        _requestId = latestRequest?.id;
        _requestStatus = latestRequest?.status;
        _isMember =
            widget.isMember ||
            memberships.any((item) => item.id == widget.activity.id);
      });
    } on ApiException catch (e) {
      if (mounted) showAppMessage(context, e.firstFieldError, error: true);
    } finally {
      if (mounted) setState(() => _loadingJoinState = false);
    }
  }

  Future<void> _toggleFavorite() async {
    if (_favoriteBusy) return;

    final session = context.read<SessionController>();

    if (session.user == null) {
      showAppMessage(
        context,
        'Masuk terlebih dahulu untuk menyimpan aktivitas.',
        error: true,
      );
      return;
    }

    setState(() => _favoriteBusy = true);

    try {
      await session.toggleFavorite(widget.activity.id, _favorite);

      if (mounted) {
        setState(() => _favorite = !_favorite);
      }
    } on ApiException catch (e) {
      if (mounted) {
        showAppMessage(context, e.firstFieldError, error: true);
      }
    } finally {
      if (mounted) {
        setState(() => _favoriteBusy = false);
      }
    }
  }

  Future<void> _join() async {
    if (context.read<SessionController>().user == null) {
      showAppMessage(
        context,
        'Masuk terlebih dahulu untuk mengajukan bergabung.',
        error: true,
      );
      return;
    }

    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) => const _JoinRequestSheet(),
    );

    if (!mounted || message == null) return;

    setState(() => _sending = true);

    try {
      final request = await context.read<SessionController>().submitJoinRequest(
        widget.activity.id,
        message.trim(),
      );

      if (mounted) {
        setState(() {
          _requestStatus = request.status;
          _requestId = request.id;
        });

        showAppMessage(
          context,
          'Permintaan terkirim! Tunggu persetujuan Host, ya.',
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        showAppMessage(context, e.firstFieldError, error: true);
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _cancelJoinRequest() async {
    final requestId = _requestId;
    if (requestId == null) {
      await _loadJoinState();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan permintaan?'),
        content: const Text(
          'Permintaan bergabungmu akan dibatalkan. Sesuai aturan Barengin, kamu tidak dapat mengajukan permintaan kedua untuk aktivitas yang sama.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _sending = true);
    try {
      await context.read<SessionController>().cancelMyJoinRequest(requestId);
      if (mounted) {
        setState(() => _requestStatus = 'cancelled');
        showAppMessage(context, 'Permintaan berhasil dibatalkan.');
      }
    } on ApiException catch (e) {
      if (mounted) showAppMessage(context, e.firstFieldError, error: true);
      if (mounted) await _loadJoinState();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _leaveActivity() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari aktivitas?'),
        content: const Text(
          'Slot peserta akan tersedia kembali untuk orang lain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tetap ikut'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, keluar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _sending = true);
    try {
      await context.read<SessionController>().leaveActivity(widget.activity.id);
      if (mounted) {
        showAppMessage(context, 'Kamu sudah keluar dari aktivitas ini.');
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) showAppMessage(context, e.firstFieldError, error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _showSafetyMenu(Activity activity) async {
    final currentUserId = context.read<SessionController>().user?.id;
    final isOwnActivity = activity.hostId == currentUserId;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isOwnActivity)
                ListTile(
                  leading: const Icon(
                    Icons.flag_outlined,
                    color: AppColors.danger,
                  ),
                  title: const Text('Laporkan Host'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReportScreen(userId: activity.hostId),
                      ),
                    );
                  },
                ),
              ListTile(
                leading: const Icon(
                  Icons.report_problem_outlined,
                  color: AppColors.danger,
                ),
                title: const Text('Laporkan Aktivitas'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReportScreen(activityId: activity.id),
                    ),
                  );
                },
              ),
              if (!isOwnActivity)
                ListTile(
                  leading: const Icon(Icons.block_rounded),
                  title: const Text('Blokir Host'),
                  onTap: () async {
                    Navigator.pop(sheetContext);

                    if (activity.hostId == null) return;

                    try {
                      await context.read<SessionController>().blockUser(
                        activity.hostId!,
                      );

                      if (mounted) {
                        showAppMessage(context, 'Pengguna berhasil diblokir.');
                      }
                    } on ApiException catch (e) {
                      if (mounted) {
                        showAppMessage(context, e.firstFieldError, error: true);
                      }
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Detail aktivitas',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
      ),
      actions: [
        IconButton(
          onPressed: _favoriteBusy ? null : _toggleFavorite,
          icon: Icon(
            _favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: _favorite ? AppColors.danger : AppColors.ink,
          ),
        ),
        IconButton(
          onPressed: () => _future.then(_showSafetyMenu),
          icon: const Icon(Icons.more_horiz_rounded),
        ),
      ],
    ),

    body: FutureBuilder<Activity>(
      future: _future,
      builder: (context, snapshot) {
        final activity = snapshot.data ?? widget.activity;

        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError && snapshot.data == null) {
          return Center(
            child: EmptyState(
              title: 'Detail belum bisa dimuat',
              message: snapshot.error.toString(),
              actionLabel: 'Coba lagi',
              onAction: () => setState(
                () => _future = context.read<SessionController>().getActivity(
                  widget.activity.id,
                ),
              ),
            ),
          );
        }

        // Lanjutkan kode berikutnya seperti semula.

        final isHost =
            activity.hostId == context.read<SessionController>().user?.id;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Container(
              height: 190,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFDDE9D9), Color(0xFFF9E9DD)],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -8,
                    bottom: -22,
                    child: Icon(
                      Icons.diversity_3_rounded,
                      size: 170,
                      color: AppColors.forest.withValues(alpha: .10),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .85),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        activity.categoryName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          letterSpacing: .8,
                          color: AppColors.forest,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 19),
            Text(
              activity.title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -.8,
                height: 1.08,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                AppAvatar(name: activity.hostName),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.hostName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        activity.hostUsername.isEmpty
                            ? 'Host Barengin'
                            : '@${activity.hostUsername}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusPill(activity.status),
              ],
            ),
            const SizedBox(height: 23),
            const Text(
              'Jadwal & lokasi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            _InfoTile(
              icon: Icons.calendar_month_rounded,
              title: formatDate(activity.startsAt),
              subtitle:
                  '${formatTime(activity.startsAt)} – ${formatTime(activity.endsAt)}',
            ),
            _InfoTile(
              icon: Icons.location_on_outlined,
              title: activity.venueName.isEmpty
                  ? 'Lokasi belum tersedia'
                  : activity.venueName,
              subtitle: [
                activity.address,
                activity.area,
                activity.city,
              ].where((e) => e.isNotEmpty).join(', '),
            ),
            _InfoTile(
              icon: Icons.people_alt_outlined,
              title:
                  '${activity.joinedCount} dari ${activity.capacity} peserta',
              subtitle:
                  '${activity.availableSlots} slot tersisa · kapasitas termasuk Host',
            ),
            _InfoTile(
              icon: Icons.payments_outlined,
              title: formatRupiah(activity.budgetAmount),
              subtitle: 'Estimasi budget per orang',
            ),
            const SizedBox(height: 17),
            const Text(
              'Tentang kegiatan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              activity.description.isEmpty
                  ? 'Host belum menambahkan deskripsi.'
                  : activity.description,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.sageLight,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 20,
                    color: AppColors.forest,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Jaga komunikasi tetap nyaman. Pastikan jadwal dan titik pertemuan sesuai, lalu jangan membagikan data sensitif.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.45,
                        color: AppColors.forest,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (isHost)
              ElevatedButton.icon(
                onPressed: () async {
                  final changed = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HostManagementScreen(activity: activity),
                    ),
                  );
                  if (changed == true && mounted) {
                    setState(() {
                      _future = context.read<SessionController>().getActivity(
                        widget.activity.id,
                      );
                    });
                  }
                },
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Kelola aktivitas'),
              )
            else if (_isMember)
              OutlinedButton(
                onPressed: _sending ? null : _leaveActivity,
                child: _sending
                    ? const CircularProgressIndicator()
                    : const Text('Keluar dari aktivitas'),
              )
            else if (_loadingJoinState)
              const OutlinedButton(
                onPressed: null,
                child: Text('Memeriksa status permintaan...'),
              )
            else if (_requestStatus == 'pending')
              OutlinedButton(
                onPressed: _sending ? null : _cancelJoinRequest,
                child: _sending
                    ? const CircularProgressIndicator()
                    : const Text('Batalkan permintaan'),
              )
            else if (_requestStatus == 'rejected')
              const OutlinedButton(
                onPressed: null,
                child: Text('Permintaan sebelumnya ditolak'),
              )
            else if (_requestStatus == 'cancelled')
              const OutlinedButton(
                onPressed: null,
                child: Text('Permintaan sudah dibatalkan'),
              )
            else if (_requestStatus == 'accepted')
              const OutlinedButton(
                onPressed: null,
                child: Text('Kamu sudah pernah diterima'),
              )
            else if (activity.status == 'published' &&
                activity.availableSlots > 0)
              ElevatedButton(
                onPressed: _sending ? null : _join,
                child: _sending
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Ajukan untuk bergabung'),
              )
            else
              OutlinedButton(
                onPressed: null,
                child: Text(
                  activity.availableSlots == 0
                      ? 'Kapasitas sudah penuh'
                      : 'Aktivitas tidak menerima permintaan',
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.sageLight,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: AppColors.sageDark, size: 19),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _JoinRequestSheet extends StatefulWidget {
  const _JoinRequestSheet();

  @override
  State<_JoinRequestSheet> createState() => _JoinRequestSheetState();
}

class _JoinRequestSheetState extends State<_JoinRequestSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          16,
          22,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Kenalan dulu, yuk!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Kirim pesan singkat ke Host. Permintaanmu akan berstatus pending sampai ditinjau.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText: 'Hai! Aku tertarik ikut aktivitas ini...',
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, _controller.text);
                  },
                  child: const Text('Kirim permintaan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
