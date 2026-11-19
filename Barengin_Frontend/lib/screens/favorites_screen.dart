import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../models/barengin_models.dart';
import '../state/session_controller.dart';
import '../widgets/common_widgets.dart';
import 'activity_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<Activity>> _future;
  late final bool _signedIn;

  @override
  void initState() {
    super.initState();
    _signedIn = context.read<SessionController>().user != null;
    _future = _signedIn
        ? context.read<SessionController>().getMyFavorites()
        : Future.value(const <Activity>[]);
  }

  Future<void> _refresh() async {
    if (!_signedIn || !mounted) return;

    final future = context.read<SessionController>().getMyFavorites();

    setState(() => _future = future);

    try {
      await future;
    } catch (_) {
      // Error tetap ditangani oleh FutureBuilder.
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Aktivitas tersimpan',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
      ),
    ),
    body: FutureBuilder<List<Activity>>(
      future: _future,
      builder: (context, snapshot) {
        if (!_signedIn) {
          return const EmptyState(
            title: 'Masuk untuk melihat simpanan',
            message:
                'Login ke akun Barengin untuk menyimpan dan melihat aktivitas favoritmu.',
            icon: Icons.lock_outline_rounded,
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: EmptyState(
              title: 'Belum bisa memuat simpanan',
              message: snapshot.error is ApiException
                  ? (snapshot.error as ApiException).message
                  : snapshot.error.toString(),
              actionLabel: 'Coba lagi',
              onAction: _refresh,
            ),
          );
        }
        final activities = snapshot.data ?? const <Activity>[];
        if (activities.isEmpty) {
          return const EmptyState(
            title: 'Belum ada yang disimpan',
            message:
                'Tekan ikon bookmark di aktivitas yang menarik supaya gampang ditemukan lagi.',
            icon: Icons.bookmark_border_rounded,
          );
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: activities
                .map(
                  (activity) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ActivityCard(
                      activity: activity,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ActivityDetailScreen(activity: activity),
                        ),
                      ).then((_) => _refresh()),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    ),
  );
}
