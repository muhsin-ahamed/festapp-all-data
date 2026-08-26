import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/student_model.dart';
import '../../data/models/team_model.dart';
import '../../data/models/team_leader_model.dart';
import '../../data/models/jury_model.dart';
import '../../data/models/program_model.dart';
import '../../data/models/registration_model.dart';
import '../../data/models/result_model.dart';
import '../../data/models/venue_model.dart';
import '../../data/models/schedule_model.dart';
import '../../data/models/announcement_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/app_repositories.dart';
import '../../data/repositories/hive_repositories_impl.dart';
import '../../services/auth_service.dart';
import '../../services/scoring_service.dart';
import '../../services/excel_service.dart';
import '../../services/tv_service.dart';
import '../../services/demo_data_service.dart';

// --- Repositories ---
final studentRepositoryProvider = Provider<StudentRepository>((ref) => HiveStudentRepository());
final teamRepositoryProvider = Provider<TeamRepository>((ref) => HiveTeamRepository());
final leaderRepositoryProvider = Provider<TeamLeaderRepository>((ref) => HiveTeamLeaderRepository());
final programRepositoryProvider = Provider<ProgramRepository>((ref) => HiveProgramRepository());
final registrationRepositoryProvider = Provider<RegistrationRepository>((ref) => HiveRegistrationRepository());
final resultRepositoryProvider = Provider<ResultRepository>((ref) => HiveResultRepository());
final venueRepositoryProvider = Provider<VenueRepository>((ref) => HiveVenueRepository());
final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) => HiveScheduleRepository());
final juryRepositoryProvider = Provider<JuryRepository>((ref) => HiveJuryRepository());
final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) => HiveAnnouncementRepository());
final tvSettingsRepositoryProvider = Provider<TvSettingsRepository>((ref) => HiveTvSettingsRepository());
final userRepositoryProvider = Provider<UserRepository>((ref) => HiveUserRepository());
final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) => HiveAuditLogRepository());

// --- Services ---
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    userRepository: ref.watch(userRepositoryProvider),
    auditRepository: ref.watch(auditLogRepositoryProvider),
  );
});

final scoringServiceProvider = Provider<ScoringService>((ref) {
  return ScoringService(
    resultRepository: ref.watch(resultRepositoryProvider),
    teamRepository: ref.watch(teamRepositoryProvider),
  );
});

final excelServiceProvider = Provider<ExcelService>((ref) {
  return ExcelService(
    studentRepository: ref.watch(studentRepositoryProvider),
    teamRepository: ref.watch(teamRepositoryProvider),
    programRepository: ref.watch(programRepositoryProvider),
    venueRepository: ref.watch(venueRepositoryProvider),
    scheduleRepository: ref.watch(scheduleRepositoryProvider),
  );
});

final tvServiceProvider = ChangeNotifierProvider<TvService>((ref) {
  return TvService(tvSettingsRepository: ref.watch(tvSettingsRepositoryProvider));
});

final demoDataServiceProvider = Provider<DemoDataService>((ref) {
  return DemoDataService(
    studentRepository: ref.watch(studentRepositoryProvider),
    teamRepository: ref.watch(teamRepositoryProvider),
    leaderRepository: ref.watch(leaderRepositoryProvider),
    programRepository: ref.watch(programRepositoryProvider),
    registrationRepository: ref.watch(registrationRepositoryProvider),
    resultRepository: ref.watch(resultRepositoryProvider),
    venueRepository: ref.watch(venueRepositoryProvider),
    scheduleRepository: ref.watch(scheduleRepositoryProvider),
    juryRepository: ref.watch(juryRepositoryProvider),
    announcementRepository: ref.watch(announcementRepositoryProvider),
    userRepository: ref.watch(userRepositoryProvider),
    scoringService: ref.watch(scoringServiceProvider),
  );
});

// --- State Refresh Signal ---
final dataRefreshSignalProvider = StateProvider<int>((ref) => 0);

void triggerDataRefresh(WidgetRef ref) {
  ref.read(dataRefreshSignalProvider.notifier).state++;
}

// --- Dynamic Data Stream / Future Providers ---
final studentsProvider = FutureProvider<List<Student>>((ref) async {
  ref.watch(dataRefreshSignalProvider);
  return ref.watch(studentRepositoryProvider).getStudents();
});

final teamsProvider = FutureProvider<List<Team>>((ref) async {
  ref.watch(dataRefreshSignalProvider);
  final repo = ref.watch(teamRepositoryProvider);
  final teams = await repo.getTeams();
  teams.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
  return teams;
});

final programsProvider = FutureProvider<List<Program>>((ref) async {
  ref.watch(dataRefreshSignalProvider);
  return ref.watch(programRepositoryProvider).getPrograms();
});

final registrationsProvider = FutureProvider<List<Registration>>((ref) async {
  ref.watch(dataRefreshSignalProvider);
  return ref.watch(registrationRepositoryProvider).getRegistrations();
});

final resultsProvider = FutureProvider<List<Result>>((ref) async {
  ref.watch(dataRefreshSignalProvider);
  return ref.watch(resultRepositoryProvider).getResults();
});

final publishedResultsProvider = FutureProvider<List<Result>>((ref) async {
  ref.watch(dataRefreshSignalProvider);
  return ref.watch(resultRepositoryProvider).getPublishedResults();
});

final venuesProvider = FutureProvider<List<Venue>>((ref) async {
  ref.watch(dataRefreshSignalProvider);
  return ref.watch(venueRepositoryProvider).getVenues();
});

final schedulesProvider = FutureProvider<List<Schedule>>((ref) async {
  ref.watch(dataRefreshSignalProvider);
  return ref.watch(scheduleRepositoryProvider).getSchedules();
});

final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  ref.watch(dataRefreshSignalProvider);
  return ref.watch(announcementRepositoryProvider).getAnnouncements();
});

final usersProvider = FutureProvider<List<User>>((ref) async {
  ref.watch(dataRefreshSignalProvider);
  return ref.watch(userRepositoryProvider).getUsers();
});

final leadersProvider = FutureProvider<List<TeamLeader>>((ref) async {
  ref.watch(dataRefreshSignalProvider);
  return ref.watch(leaderRepositoryProvider).getLeaders();
});

final juriesProvider = FutureProvider<List<Jury>>((ref) async {
  ref.watch(dataRefreshSignalProvider);
  return ref.watch(juryRepositoryProvider).getJuries();
});

final currentUserProvider = StateProvider<User?>((ref) => null);
