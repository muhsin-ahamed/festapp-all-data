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
import '../../data/repositories/supabase_repositories_impl.dart';
import '../../data/repositories/api_repositories_impl.dart';
import '../../services/auth_service.dart';
import '../../services/scoring_service.dart';
import '../../services/excel_service.dart';
import '../../services/tv_service.dart';
import '../../services/demo_data_service.dart';

// --- Database Configuration Flags ---
// Enforce Node.js REST API Backend Architecture (Flutter -> Node.js -> Supabase)
final useNodeBackendProvider = StateProvider<bool>((ref) => true);

// --- Repositories ---
final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  final useNodeBackend = ref.watch(useNodeBackendProvider);
  return useNodeBackend ? ApiStudentRepository() : SupabaseStudentRepository();
});

final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  final useNodeBackend = ref.watch(useNodeBackendProvider);
  return useNodeBackend ? ApiTeamRepository() : SupabaseTeamRepository();
});

final leaderRepositoryProvider = Provider<TeamLeaderRepository>((ref) {
  return SupabaseTeamLeaderRepository();
});

final programRepositoryProvider = Provider<ProgramRepository>((ref) {
  final useNodeBackend = ref.watch(useNodeBackendProvider);
  return useNodeBackend ? ApiProgramRepository() : SupabaseProgramRepository();
});

final registrationRepositoryProvider = Provider<RegistrationRepository>((ref) {
  final useNodeBackend = ref.watch(useNodeBackendProvider);
  return useNodeBackend
      ? ApiRegistrationRepository()
      : SupabaseRegistrationRepository();
});

final resultRepositoryProvider = Provider<ResultRepository>((ref) {
  final useNodeBackend = ref.watch(useNodeBackendProvider);
  return useNodeBackend ? ApiResultRepository() : SupabaseResultRepository();
});

final venueRepositoryProvider = Provider<VenueRepository>((ref) {
  return SupabaseVenueRepository();
});

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return SupabaseScheduleRepository();
});

final juryRepositoryProvider = Provider<JuryRepository>((ref) {
  return SupabaseJuryRepository();
});

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return SupabaseAnnouncementRepository();
});

final tvSettingsRepositoryProvider = Provider<TvSettingsRepository>((ref) {
  return SupabaseTvSettingsRepository();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return SupabaseUserRepository();
});

final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) {
  return SupabaseAuditLogRepository();
});

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
    registrationRepository: ref.watch(registrationRepositoryProvider),
  );
});

final tvServiceProvider = ChangeNotifierProvider<TvService>((ref) {
  return TvService(
    tvSettingsRepository: ref.watch(tvSettingsRepositoryProvider),
  );
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
  ref.invalidate(programsProvider);
  ref.invalidate(studentsProvider);
  ref.invalidate(teamsProvider);
  ref.invalidate(registrationsProvider);
  ref.invalidate(resultsProvider);
  ref.invalidate(publishedResultsProvider);
  ref.invalidate(venuesProvider);
  ref.invalidate(schedulesProvider);
  ref.invalidate(announcementsProvider);
  ref.invalidate(usersProvider);
  ref.invalidate(leadersProvider);
  ref.invalidate(juriesProvider);
}

// --- Dynamic Data Stream / Future Providers ---
final studentsProvider = FutureProvider<List<Student>>((ref) async {
  ref.watch(dataRefreshSignalProvider);
  try {
    return await ref.watch(studentRepositoryProvider).getStudents();
  } catch (_) {
    return [];
  }
});

final teamsProvider = FutureProvider<List<Team>>((ref) async {
  ref.watch(dataRefreshSignalProvider);
  try {
    final repo = ref.watch(teamRepositoryProvider);
    final teams = await repo.getTeams();
    teams.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
    return teams;
  } catch (_) {
    return [];
  }
});

final programsProvider = FutureProvider<List<Program>>((ref) async {
  ref.watch(dataRefreshSignalProvider);
  try {
    final repo = ref.watch(programRepositoryProvider);
    return await repo.getPrograms();
  } catch (_) {
    return [];
  }
});

final registrationsProvider = FutureProvider<List<Registration>>((ref) async {
  ref.watch(dataRefreshSignalProvider);
  try {
    return await ref.watch(registrationRepositoryProvider).getRegistrations();
  } catch (_) {
    return [];
  }
});

final resultsProvider = FutureProvider<List<Result>>((ref) async {
  ref.watch(dataRefreshSignalProvider);
  try {
    return await ref.watch(resultRepositoryProvider).getResults();
  } catch (_) {
    return [];
  }
});

final publishedResultsProvider = FutureProvider<List<Result>>((ref) async {
  ref.watch(dataRefreshSignalProvider);
  try {
    return await ref.watch(resultRepositoryProvider).getPublishedResults();
  } catch (_) {
    return [];
  }
});

final venuesProvider = FutureProvider<List<Venue>>((ref) async {
  ref.watch(dataRefreshSignalProvider);
  try {
    return await ref.watch(venueRepositoryProvider).getVenues();
  } catch (_) {
    return [];
  }
});

final schedulesProvider = FutureProvider<List<Schedule>>((ref) async {
  ref.watch(dataRefreshSignalProvider);
  try {
    return await ref.watch(scheduleRepositoryProvider).getSchedules();
  } catch (_) {
    return [];
  }
});

final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  ref.watch(dataRefreshSignalProvider);
  try {
    return await ref.watch(announcementRepositoryProvider).getAnnouncements();
  } catch (_) {
    return [];
  }
});

final usersProvider = FutureProvider<List<User>>((ref) async {
  ref.watch(dataRefreshSignalProvider);
  try {
    return await ref.watch(userRepositoryProvider).getUsers();
  } catch (_) {
    return [];
  }
});

final leadersProvider = FutureProvider<List<TeamLeader>>((ref) async {
  ref.watch(dataRefreshSignalProvider);
  try {
    return await ref.watch(leaderRepositoryProvider).getLeaders();
  } catch (_) {
    return [];
  }
});

final juriesProvider = FutureProvider<List<Jury>>((ref) async {
  ref.watch(dataRefreshSignalProvider);
  try {
    return await ref.watch(juryRepositoryProvider).getJuries();
  } catch (_) {
    return [];
  }
});

final currentUserProvider = StateProvider<User?>((ref) => null);
