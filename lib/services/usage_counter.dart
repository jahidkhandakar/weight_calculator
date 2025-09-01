import 'package:get_storage/get_storage.dart';

class UsageCounter {
  final GetStorage _box = GetStorage();
  final String userKey; // make this per-user if you can (e.g., user id / email)
  final int limit;

  UsageCounter({required this.userKey, this.limit = 10});

  String get _usedKey => 'free_hits_used:$userKey';
  String get _reservedKey => 'free_hits_reserved:$userKey'; // last reservation marker

  int getUsed() => (_box.read(_usedKey) as int?) ?? 0;
  int getRemaining() => (limit - getUsed()).clamp(0, limit);
  bool canConsume() => getUsed() < limit;

  /// Atomically "reserve" one hit. Returns false if limit reached.
  Future<bool> consume() async {
    final used = getUsed();
    if (used >= limit) return false;
    await _box.write(_usedKey, used + 1);
    await _box.write(_reservedKey, (used + 1)); // remember last state for rollback
    return true;
  }

  /// Roll back the most recent consume (if we just reserved and then failed).
  Future<void> rollback() async {
    final used = getUsed();
    final reservedAt = (_box.read(_reservedKey) as int?) ?? -1;
    if (reservedAt == used && used > 0) {
      await _box.write(_usedKey, used - 1);
    }
    await _box.remove(_reservedKey);
  }

  Future<void> reset() async {
    await _box.write(_usedKey, 0);
    await _box.remove(_reservedKey);
  }
}
