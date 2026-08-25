import '../core/constants/app_constants.dart';
import '../data/models/user_model.dart';
import '../data/repositories/app_repositories.dart';

class AuthService {
  final UserRepository userRepository;
  final AuditLogRepository auditRepository;
  User? _currentUser;

  AuthService({
    required this.userRepository,
    required this.auditRepository,
  });

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<void> seedDefaultUsers() async {
    final users = await userRepository.getUsers();
    if (users.isNotEmpty) return;

    final defaultUsers = [
      User(
        id: 'usr_controller',
        username: 'controller',
        password: 'controller123',
        name: 'Fest Controller',
        role: UserRole.festController,
      ),
      User(
        id: 'usr_tv',
        username: 'tv',
        password: 'tv123',
        name: 'TV Display Operator',
        role: UserRole.tvOperator,
      ),
    ];

    for (final u in defaultUsers) {
      await userRepository.saveUser(u);
    }
  }

  Future<User?> login(String username, String password) async {
    await seedDefaultUsers();
    final user = await userRepository.getByUsername(username);
    if (user != null && user.password == password) {
      _currentUser = user;
      return user;
    }
    return null;
  }

  void logout() {
    _currentUser = null;
  }

  bool canAccessRoute(String route, UserRole? role) {
    if (route == '/public' || route == '/login') return true;
    if (role == null) return false;

    switch (route) {
      case '/controller':
        return role == UserRole.festController;
      case '/leader':
        return role == UserRole.teamLeader || role == UserRole.festController;
      case '/jury':
        return role == UserRole.jury || role == UserRole.festController;
      case '/tv':
        return role == UserRole.tvOperator || role == UserRole.festController;
      default:
        return false;
    }
  }
}
