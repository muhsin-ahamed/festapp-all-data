import 'dart:math';
import '../core/constants/app_constants.dart';
import '../data/models/student_model.dart';
import '../data/models/team_model.dart';
import '../data/models/team_leader_model.dart';
import '../data/models/program_model.dart';
import '../data/models/registration_model.dart';
import '../data/models/result_model.dart';
import '../data/models/venue_model.dart';
import '../data/models/schedule_model.dart';
import '../data/models/jury_model.dart';
import '../data/models/announcement_model.dart';
import '../data/models/user_model.dart';
import '../data/hive/hive_service.dart';
import '../data/repositories/app_repositories.dart';
import 'scoring_service.dart';

class DemoDataService {
  final StudentRepository studentRepository;
  final TeamRepository teamRepository;
  final TeamLeaderRepository leaderRepository;
  final ProgramRepository programRepository;
  final RegistrationRepository registrationRepository;
  final ResultRepository resultRepository;
  final VenueRepository venueRepository;
  final ScheduleRepository scheduleRepository;
  final JuryRepository juryRepository;
  final AnnouncementRepository announcementRepository;
  final UserRepository userRepository;
  final ScoringService scoringService;

  DemoDataService({
    required this.studentRepository,
    required this.teamRepository,
    required this.leaderRepository,
    required this.programRepository,
    required this.registrationRepository,
    required this.resultRepository,
    required this.venueRepository,
    required this.scheduleRepository,
    required this.juryRepository,
    required this.announcementRepository,
    required this.userRepository,
    required this.scoringService,
  });

  Future<void> clearAllData() async {
    await HiveService.clearAllBoxes();
  }

  Future<void> generateDemoData() async {
    await clearAllData();

    // 1. Seed Users & Leaders
    final controllerUser = User(
      id: 'usr_controller',
      username: 'controller',
      password: 'controller123',
      name: 'Fest Controller Admin',
      role: UserRole.festController,
    );
    await userRepository.saveUser(controllerUser);

    final tvUser = User(
      id: 'usr_tv',
      username: 'tv',
      password: 'tv123',
      name: 'Main Stage TV Display',
      role: UserRole.tvOperator,
    );
    await userRepository.saveUser(tvUser);

    // 2. Seed 6 Teams
    final teamData = [
      {'id': 'team_alpha', 'code': 'T-ALPHA', 'name': 'Alpha Tigers'},
      {'id': 'team_beta', 'code': 'T-BETA', 'name': 'Beta Eagles'},
      {'id': 'team_gamma', 'code': 'T-GAMMA', 'name': 'Gamma Lions'},
      {'id': 'team_delta', 'code': 'T-DELTA', 'name': 'Delta Falcons'},
      {'id': 'team_omega', 'code': 'T-OMEGA', 'name': 'Omega Warriors'},
      {'id': 'team_phoenix', 'code': 'T-PHOENIX', 'name': 'Phoenix Rises'},
    ];

    List<Team> teams = [];
    for (int i = 0; i < teamData.length; i++) {
      final tMap = teamData[i];
      final teamId = tMap['id']!;
      final leaderId = 'leader_${i + 1}';
      final username = i == 0 ? 'leader1' : 'leader${i + 1}';

      final leader = TeamLeader(
        id: leaderId,
        name: '${tMap['name']} Leader',
        phone: '+1 555-010${i + 1}',
        email: 'leader${i + 1}@fest.com',
        username: username,
        password: 'leader${i + 1}3' == 'leader13' ? 'leader123' : 'leader${i + 1}123',
        teamId: teamId,
      );
      await leaderRepository.addLeader(leader);

      final userLeader = User(
        id: 'usr_$leaderId',
        username: username,
        password: leader.password,
        name: leader.name,
        role: UserRole.teamLeader,
        teamId: teamId,
      );
      await userRepository.saveUser(userLeader);

      final team = Team(
        id: teamId,
        teamName: tMap['name']!,
        teamCode: tMap['code']!,
        leaderId: leaderId,
        totalStudents: 10,
      );
      await teamRepository.addTeam(team);
      teams.add(team);
    }

    // 3. Seed Venues
    final venues = [
      Venue(id: 'ven_main', name: 'Main Auditorium', location: 'Block A Ground Floor', capacity: 500, description: 'Stage 1'),
      Venue(id: 'ven_hall2', name: 'Seminar Hall 2', location: 'Block B First Floor', capacity: 200, description: 'Stage 2'),
      Venue(id: 'ven_hall3', name: 'Open Air Theatre', location: 'Central Campus', capacity: 800, description: 'Stage 3'),
      Venue(id: 'ven_lab1', name: 'Media Computer Lab', location: 'IT Wing', capacity: 60, description: 'Non-Stage Lab'),
    ];
    for (final v in venues) {
      await venueRepository.addVenue(v);
    }

    // 4. Seed Juries
    final jury1 = Jury(
      id: 'jury_1',
      name: 'Prof. Sarah Jenkins',
      username: 'jury1',
      password: 'jury123',
      juryCode: 'JURY-101',
      assignedPrograms: ['prog_101', 'prog_102', 'prog_103', 'prog_104'],
    );
    final jury2 = Jury(
      id: 'jury_2',
      name: 'Dr. Robert Lang',
      username: 'jury2',
      password: 'jury2123',
      juryCode: 'JURY-102',
      assignedPrograms: ['prog_201', 'prog_202', 'prog_301'],
    );
    await juryRepository.addJury(jury1);
    await juryRepository.addJury(jury2);

    final userJury1 = User(
      id: 'usr_jury1',
      username: 'jury1',
      password: 'jury123',
      name: jury1.name,
      role: UserRole.jury,
      juryId: jury1.id,
    );
    final userJury2 = User(
      id: 'usr_jury2',
      username: 'jury2',
      password: 'jury2123',
      name: jury2.name,
      role: UserRole.jury,
      juryId: jury2.id,
    );
    await userRepository.saveUser(userJury1);
    await userRepository.saveUser(userJury2);

    // 5. Seed 20 Programs
    final programTemplates = [
      {'code': 'P-101', 'name': 'Arabic Song Solo', 'sec': FestSection.junior, 'stage': true, 'ven': 'ven_main'},
      {'code': 'P-102', 'name': 'English Elocution', 'sec': FestSection.junior, 'stage': true, 'ven': 'ven_hall2'},
      {'code': 'P-103', 'name': 'Pencil Drawing', 'sec': FestSection.junior, 'stage': false, 'ven': 'ven_lab1'},
      {'code': 'P-104', 'name': 'Quiz Masters', 'sec': FestSection.junior, 'stage': false, 'ven': 'ven_hall2'},
      {'code': 'P-105', 'name': 'Poetry Writing', 'sec': FestSection.junior, 'stage': false, 'ven': 'ven_lab1'},

      {'code': 'P-201', 'name': 'Folk Dance Group', 'sec': FestSection.subJunior, 'stage': true, 'ven': 'ven_main'},
      {'code': 'P-202', 'name': 'Classical Music', 'sec': FestSection.subJunior, 'stage': true, 'ven': 'ven_hall3'},
      {'code': 'P-203', 'name': 'Calligraphy', 'sec': FestSection.subJunior, 'stage': false, 'ven': 'ven_lab1'},
      {'code': 'P-204', 'name': 'Spelling Bee', 'sec': FestSection.subJunior, 'stage': false, 'ven': 'ven_hall2'},
      {'code': 'P-205', 'name': 'Story Telling', 'sec': FestSection.subJunior, 'stage': true, 'ven': 'ven_hall2'},

      {'code': 'P-301', 'name': 'Classical Dance', 'sec': FestSection.superSenior, 'stage': true, 'ven': 'ven_main'},
      {'code': 'P-302', 'name': 'Light Music Solo', 'sec': FestSection.superSenior, 'stage': true, 'ven': 'ven_hall3'},
      {'code': 'P-303', 'name': 'Digital Art', 'sec': FestSection.superSenior, 'stage': false, 'ven': 'ven_lab1'},
      {'code': 'P-304', 'name': 'Debate Championship', 'sec': FestSection.superSenior, 'stage': true, 'ven': 'ven_hall2'},
      {'code': 'P-305', 'name': 'Essay Writing', 'sec': FestSection.superSenior, 'stage': false, 'ven': 'ven_lab1'},

      {'code': 'P-901', 'name': 'General Knowledge Quiz', 'sec': FestSection.general, 'stage': true, 'ven': 'ven_main'},
      {'code': 'P-902', 'name': 'Fest Theme Song', 'sec': FestSection.general, 'stage': true, 'ven': 'ven_main'},
      {'code': 'P-903', 'name': 'Group Photography', 'sec': FestSection.general, 'stage': false, 'ven': 'ven_lab1'},
      {'code': 'P-904', 'name': 'Short Film Contest', 'sec': FestSection.general, 'stage': false, 'ven': 'ven_lab1'},
      {'code': 'P-905', 'name': 'Mime & Skit', 'sec': FestSection.general, 'stage': true, 'ven': 'ven_hall3'},
    ];

    List<Program> programs = [];
    for (int i = 0; i < programTemplates.length; i++) {
      final pt = programTemplates[i];
      final progId = 'prog_${100 + i + 1}';
      final sec = pt['sec'] as FestSection;
      final isStage = pt['stage'] as bool;
      final venId = pt['ven'] as String;

      final prog = Program(
        id: progId,
        programCode: pt['code'] as String,
        programName: pt['name'] as String,
        section: sec,
        category: isStage ? ProgramCategory.stage : ProgramCategory.nonStage,
        isStageProgram: isStage,
        isGeneral: sec == FestSection.general,
        duration: '30 mins',
        venueId: venId,
        status: i < 5 ? 'COMPLETED' : (i < 10 ? 'IN_PROGRESS' : 'UPCOMING'),
      );
      await programRepository.addProgram(prog);
      programs.add(prog);

      // Create Schedule
      final sched = Schedule(
        id: 'sched_${progId}',
        programId: progId,
        venueId: venId,
        date: '2026-08-25',
        startTime: '${9 + (i % 8)}:00 AM',
        endTime: '${9 + (i % 8)}:45 AM',
        status: prog.status == 'COMPLETED' ? 'COMPLETED' : 'SCHEDULED',
      );
      await scheduleRepository.addSchedule(sched);
    }

    // 6. Seed 54 Students (9 per team across Junior, Sub Junior, Super Senior)
    final random = Random(42);
    final firstNames = ['Aarav', 'Ananya', 'Zayan', 'Mariam', 'Bilal', 'Fatima', 'Rohan', 'Diya', 'Kavya', 'Omar', 'Sarah', 'Aryan'];
    final lastNames = ['Ahmed', 'Khan', 'Sharma', 'Nair', 'Verma', 'Patel', 'Siddiqui', 'Menon', 'Gupta', 'Hassan'];

    List<Student> allStudents = [];
    int chaseCounter = 1001;

    for (final team in teams) {
      final sections = [FestSection.junior, FestSection.subJunior, FestSection.superSenior];
      for (final sec in sections) {
        for (int k = 1; k <= 3; k++) {
          final fName = firstNames[random.nextInt(firstNames.length)];
          final lName = lastNames[random.nextInt(lastNames.length)];
          final chaseNum = 'CHASE-$chaseCounter';

          final student = Student(
            id: 'stud_$chaseCounter',
            chaseNumber: chaseNum,
            name: '$fName $lName',
            gender: k % 2 == 0 ? 'Female' : 'Male',
            dateOfBirth: '200${8 + random.nextInt(6)}-0${1 + random.nextInt(8)}-15',
            section: sec,
            teamId: team.id,
            phone: '+91 98765${chaseCounter}',
            className: sec == FestSection.junior ? 'Class 7' : (sec == FestSection.subJunior ? 'Class 9' : 'Class 12'),
            schoolName: 'St. Fest International Academy',
            qrCode: chaseNum,
          );
          await studentRepository.addStudent(student);
          allStudents.add(student);
          chaseCounter++;
        }
      }
    }

    // 7. Seed Registrations & Results (Published & Drafts)
    int regCounter = 1;
    int resultCounter = 1;

    for (int pIdx = 0; pIdx < programs.length; pIdx++) {
      final prog = programs[pIdx];
      // Select 6 eligible students
      final eligibleStudents = allStudents.where((s) => prog.isGeneral || s.section == prog.section).take(6).toList();

      for (int sIdx = 0; sIdx < eligibleStudents.length; sIdx++) {
        final stud = eligibleStudents[sIdx];
        final reg = Registration(
          id: 'reg_$regCounter',
          studentId: stud.id,
          programId: prog.id,
          teamId: stud.teamId,
          registrationNumber: 'REG-${10000 + regCounter}',
          status: RegistrationStatus.approved,
        );
        await registrationRepository.addRegistration(reg);
        regCounter++;

        // Generate results for first 4 completed programs
        if (pIdx < 4) {
          final pos = (sIdx == 0) ? 1 : ((sIdx == 1) ? 2 : ((sIdx == 2) ? 3 : null));
          final grade = (sIdx <= 1) ? 'A' : ((sIdx <= 3) ? 'B' : 'C');
          final pts = scoringService.calculateResultPoints(position: pos, grade: grade);

          final result = Result(
            id: 'res_$resultCounter',
            programId: prog.id,
            studentId: stud.id,
            teamId: stud.teamId,
            juryId: 'jury_1',
            marks: 85.0 - (sIdx * 5),
            grade: grade,
            position: pos,
            points: pts,
            remarks: pos != null ? 'Outstanding performance in $pos place' : 'Good effort',
            status: ResultStatus.published,
            publishedAt: DateTime.now().subtract(Duration(hours: 4 - pIdx)),
          );
          await resultRepository.saveResult(result);
          resultCounter++;
        } else if (pIdx == 4) {
          // Draft results submitted by Jury
          final pos = (sIdx == 0) ? 1 : ((sIdx == 1) ? 2 : ((sIdx == 2) ? 3 : null));
          final grade = 'A';
          final pts = scoringService.calculateResultPoints(position: pos, grade: grade);

          final result = Result(
            id: 'res_$resultCounter',
            programId: prog.id,
            studentId: stud.id,
            teamId: stud.teamId,
            juryId: 'jury_1',
            marks: 90.0 - (sIdx * 4),
            grade: grade,
            position: pos,
            points: pts,
            remarks: 'Submitted by Jury - Pending Controller Review',
            status: ResultStatus.submitted,
          );
          await resultRepository.saveResult(result);
          resultCounter++;
        }
      }
    }

    // 8. Seed Announcements
    final announcement = Announcement(
      id: 'ann_1',
      programId: 'prog_101',
      resultId: 'res_1',
      title: '🎉 RESULT ANNOUNCEMENT 🎉',
      message: 'Junior Arabic Song Solo results have been officially verified and published!',
      status: 'ANNOUNCED',
      announcedAt: DateTime.now(),
    );
    await announcementRepository.addAnnouncement(announcement);

    // 9. Recalculate team scores and ranks
    await scoringService.recalculateTeamScoresAndRanks();
  }
}
