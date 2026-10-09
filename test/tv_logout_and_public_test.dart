import 'package:flutter_test/flutter_test.dart';
import 'package:amia_fest/services/auth_service.dart';
import 'package:amia_fest/core/constants/app_constants.dart';
import 'package:amia_fest/data/models/user_model.dart';
import 'package:amia_fest/data/models/audit_log_model.dart';
import 'package:amia_fest/data/repositories/app_repositories.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockUserRepository implements UserRepository {
  final List<User> _users = [];

  @override
  Future<List<User>> getUsers() async => _users;

  @override
  Future<User?> getByUsername(String username) async {
    return _users.where((u) => u.username == username).firstOrNull;
  }

  @override
  Future<void> saveUser(User user) async {
    _users.add(user);
  }

  @override
  Future<void> deleteUser(String id) async {}
}

class MockAuditLogRepository implements AuditLogRepository {
  @override
  Future<List<AuditLog>> getLogs() async => [];

  @override
  Future<void> addLog(AuditLog log) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TV Logout & Public/Login Route Tests', () {
    late AuthService authService;
    late MockUserRepository mockUserRepo;
    late MockAuditLogRepository mockAuditRepo;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockUserRepo = MockUserRepository();
      mockAuditRepo = MockAuditLogRepository();
      authService = AuthService(
        userRepository: mockUserRepo,
        auditRepository: mockAuditRepo,
      );
    });

    test('canAccessRoute allows public and login for unauthenticated users', () {
      expect(authService.canAccessRoute('/public', null), isTrue);
      expect(authService.canAccessRoute('/login', null), isTrue);
      expect(authService.canAccessRoute('/tv', null), isFalse);
    });

    test('canAccessRoute allows TV route only for TV operator and Controller', () {
      expect(authService.canAccessRoute('/tv', UserRole.tvOperator), isTrue);
      expect(authService.canAccessRoute('/tv', UserRole.festController), isTrue);
      expect(authService.canAccessRoute('/tv', UserRole.teamLeader), isFalse);
      expect(authService.canAccessRoute('/tv', UserRole.jury), isFalse);
    });

    test('logout clears currentUser and isAuthenticated', () async {
      await authService.logout();
      expect(authService.currentUser, isNull);
      expect(authService.isAuthenticated, isFalse);
    });
  });
}
