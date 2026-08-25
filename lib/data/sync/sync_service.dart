import 'package:flutter/foundation.dart';

abstract class SyncService {
  Future<void> initializeSync();
  Future<void> syncUp();
  Future<void> syncDown();
  Stream<Map<String, dynamic>> listenToRealtimeChannel(String channel);
}

class FutureSupabaseSyncService implements SyncService {
  @override
  Future<void> initializeSync() async {
    if (kDebugMode) {
      print('SyncService: Local-only mode active (Hive). Ready for Supabase sync integration.');
    }
  }

  @override
  Future<void> syncUp() async {
    // Phase 2: Push local changes to Supabase PostgreSQL
  }

  @override
  Future<void> syncDown() async {
    // Phase 2: Pull latest data from Supabase
  }

  @override
  Stream<Map<String, dynamic>> listenToRealtimeChannel(String channel) async* {
    // Phase 2: Supabase Realtime broadcast stream
  }
}
