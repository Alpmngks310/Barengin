import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../state/session_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class SafetyCenterScreen extends StatefulWidget {
  const SafetyCenterScreen({super.key});
  @override
  State<SafetyCenterScreen> createState() => _SafetyCenterScreenState();
}

class _SafetyCenterScreenState extends State<SafetyCenterScreen> {
  late Future<List<dynamic>> _blocked;
  @override
  void initState() {
    super.initState();
    _blocked = context.read<SessionController>().getBlockedUsers();
  }

  Future<void> _refresh() async => setState(
    () => _blocked = context.read<SessionController>().getBlockedUsers(),
  );

  Future<void> _unblock(int id) async {
    try {
      await context.read<SessionController>().unblockUser(id);
      await _refresh();
      if (mounted) showAppMessage(context, 'Blokir berhasil dibatalkan.');
    } on ApiException catch (e) {
      if (mounted) showAppMessage(context, e.firstFieldError, error: true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Pusat keamanan',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
      ),
    ),
    body: FutureBuilder<List<dynamic>>(
      future: _blocked,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: EmptyState(
              title: 'Belum bisa memuat daftar blokir',
              message: snapshot.error.toString(),
              actionLabel: 'Coba lagi',
              onAction: _refresh,
            ),
          );
        }
        final users = snapshot.data ?? [];
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: AppColors.sageLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shield_moon_outlined,
                      color: AppColors.forest,
                      size: 25,
                    ),
                    SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        'Kamu punya kendali atas interaksi di Barengin. Pengguna yang diblokir tidak bisa berinteraksi denganmu melalui fitur aktivitas.',
                        style: TextStyle(
                          color: AppColors.forest,
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 21),
              const SectionTitle('Akun yang diblokir'),
              if (users.isEmpty)
                const EmptyState(
                  title: 'Belum ada akun yang diblokir',
                  message:
                      'Semoga kamu selalu bertemu orang-orang yang suportif di Barengin.',
                  icon: Icons.verified_user_outlined,
                )
              else
                ...users.map((raw) {
                  final item = Map<String, dynamic>.from(raw as Map);
                  final name = (item['name'] ?? 'Pengguna').toString();
                  final id = int.tryParse(item['id'].toString()) ?? 0;
                  return Card(
                    child: ListTile(
                      leading: AppAvatar(name: name),
                      title: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        '@${item['username'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.muted,
                        ),
                      ),
                      trailing: TextButton(
                        onPressed: () => _unblock(id),
                        child: const Text('Buka blokir'),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 20),
              const SectionTitle('Tips tetap aman'),
              const _SafetyTip(
                icon: Icons.location_on_outlined,
                text: 'Pilih titik pertemuan publik dan mudah ditemukan.',
              ),
              const _SafetyTip(
                icon: Icons.lock_outline_rounded,
                text:
                    'Jangan membagikan kata sandi, alamat rumah, atau data sensitif.',
              ),
              const _SafetyTip(
                icon: Icons.flag_outlined,
                text:
                    'Laporkan perilaku atau informasi aktivitas yang mencurigakan.',
              ),
            ],
          ),
        );
      },
    ),
  );
}

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, this.userId, this.activityId});
  final int? userId;
  final int? activityId;
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _details = TextEditingController();
  String _reason = 'inappropriate_behavior';
  bool _sending = false;
  final _reasons = const <String, String>{
    'inappropriate_behavior': 'Perilaku tidak pantas',
    'misleading_activity': 'Informasi aktivitas menyesatkan',
    'harassment_or_threat': 'Pelecehan atau ancaman',
    'spam_or_scam': 'Spam atau penipuan',
    'other': 'Lainnya',
  };

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (widget.userId == null && widget.activityId == null) {
      showAppMessage(context, 'Target laporan belum tersedia.', error: true);
      return;
    }
    setState(() => _sending = true);
    try {
      await context.read<SessionController>().report(
        userId: widget.userId,
        activityId: widget.activityId,
        reason: _reason,
        details: _details.text,
      );
      if (mounted) {
        showAppMessage(
          context,
          'Laporan terkirim dan akan ditinjau. Terima kasih sudah menjaga komunitas.',
        );
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (mounted) showAppMessage(context, e.firstFieldError, error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Laporkan',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
      children: [
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: AppColors.peach,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_outlined, color: AppColors.forest, size: 24),
              SizedBox(width: 11),
              Expanded(
                child: Text(
                  'Bantu jaga Barengin tetap aman dan nyaman. Laporanmu akan disimpan dan ditinjau secara rahasia.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: AppColors.forest,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Apa masalah yang ingin dilaporkan?',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 17,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 9),
        RadioGroup<String>(
          groupValue: _reason,
          onChanged: (value) => setState(() => _reason = value!),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _reasons.entries
                .map(
                  (entry) => RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: entry.key,
                    title: Text(
                      entry.value,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Keterangan tambahan (opsional)',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _details,
          minLines: 4,
          maxLines: 5,
          maxLength: 1000,
          decoration: const InputDecoration(
            hintText: 'Ceritakan apa yang terjadi...',
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _sending ? null : _send,
          child: _sending
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Kirim laporan'),
        ),
      ],
    ),
  );
}

class _SafetyTip extends StatelessWidget {
  const _SafetyTip({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.sageDark),
        title: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.ink,
            height: 1.35,
          ),
        ),
      ),
    ),
  );
}
