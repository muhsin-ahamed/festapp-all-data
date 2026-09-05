import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
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

  Future<void> clearDatabase() async {
    try {
      final client = Supabase.instance.client;
      await client.from('announcements').delete().neq('id', '___none___');
      await client.from('results').delete().neq('id', '___none___');
      await client.from('registrations').delete().neq('id', '___none___');
      await client.from('students').delete().neq('id', '___none___');
      await client.from('schedules').delete().neq('id', '___none___');
      await client.from('programs').delete().neq('id', '___none___');
      await client.from('venues').delete().neq('id', '___none___');
      await client.from('teams').delete().neq('id', '___none___');
      await client.from('team_leaders').delete().neq('id', '___none___');
      await client.from('juries').delete().neq('id', '___none___');
    } catch (e) {
      // Fallback if table names vary
    }
  }

  Future<void> clearAllData() async {
    await clearDatabase();
  }

  Future<void> generateDemoData() async {
    await clearDatabase();

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

    // 2. Seed Only 2 Teams: Apex & Telos
    final teamData = [
      {
        'id': 'team_01',
        'code': 'T-APEX',
        'name': 'Apex',
        'leader': 'SHAHIL K',
        'assistant': 'HASHIM FARHAN',
        'mentor': 'USTHAD SHAHEER HUDAWI',
        'username': 'lsmht',
        'password': 'Lthlsm@9947',
      },
      {
        'id': 'team_02',
        'code': 'T-TELOS',
        'name': 'Telos',
        'leader': 'ALTHAF HUSSAIN',
        'assistant': 'IHSAN',
        'mentor': 'USTHAD NIZAM FAIZY',
        'username': 'halans',
        'password': 'fshlt@4792',
      },
    ];

    List<Team> teams = [];
    for (int i = 0; i < teamData.length; i++) {
      final tMap = teamData[i];
      final teamId = tMap['id']!;
      final leaderId = 'leader_${i + 1}';
      final leaderName = tMap['leader']!;
      final assistantName = tMap['assistant']!;
      final mentorName = tMap['mentor']!;
      final username = tMap['username']!;
      final password = tMap['password']!;

      final leader = TeamLeader(
        id: leaderId,
        name: leaderName,
        phone: '+91 987654321${i + 1}',
        email: '$username@amiafest.com',
        username: username,
        password: password,
        teamId: teamId,
      );
      await leaderRepository.addLeader(leader);

      final userLeader = User(
        id: 'usr_$leaderId',
        username: username,
        password: password,
        name: leaderName,
        role: UserRole.teamLeader,
        teamId: teamId,
      );
      await userRepository.saveUser(userLeader);

      final team = Team(
        id: teamId,
        teamName: tMap['name']!,
        teamCode: tMap['code']!,
        leaderId: leaderId,
        leaderName: leaderName,
        assistantLeaderName: assistantName,
        mentorName: mentorName,
        totalStudents: 12,
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
      {'code': 'P-101', 'name': 'Arabic Song Solo', 'sec': FestSection.senior, 'stage': true, 'ven': 'ven_main'},
      {'code': 'P-102', 'name': 'English Elocution', 'sec': FestSection.senior, 'stage': true, 'ven': 'ven_hall2'},
      {'code': 'P-103', 'name': 'Pencil Drawing', 'sec': FestSection.senior, 'stage': false, 'ven': 'ven_lab1'},
      {'code': 'P-104', 'name': 'Quiz Masters', 'sec': FestSection.senior, 'stage': false, 'ven': 'ven_hall2'},
      {'code': 'P-105', 'name': 'Poetry Writing', 'sec': FestSection.senior, 'stage': false, 'ven': 'ven_lab1'},

      {'code': 'P-201', 'name': 'Folk Dance Group', 'sec': FestSection.subJunior, 'stage': true, 'ven': 'ven_main'},
      {'code': 'P-202', 'name': 'Classical Music', 'sec': FestSection.subJunior, 'stage': true, 'ven': 'ven_hall3'},
      {'code': 'P-203', 'name': 'Calligraphy', 'sec': FestSection.subJunior, 'stage': false, 'ven': 'ven_lab1'},
      {'code': 'P-204', 'name': 'Spelling Bee', 'sec': FestSection.subJunior, 'stage': false, 'ven': 'ven_hall2'},
      {'code': 'P-205', 'name': 'Story Telling', 'sec': FestSection.subJunior, 'stage': true, 'ven': 'ven_hall2'},

      {'code': 'P-301', 'name': 'Classical Dance', 'sec': FestSection.superSenior, 'stage': true, 'ven': 'ven_main'},
      {'code': 'P-302', 'name': 'Light Music Solo', 'sec': FestSection.superSenior, 'stage': true, 'ven': 'ven_hall3'},
      {'code': 'P-303', 'name': 'Digital Art', 'sec': FestSection.superSenior, 'stage': false, 'ven': 'ven_lab1'},
      {'code': 'P-304', 'name': 'Mime & Drama', 'sec': FestSection.superSenior, 'stage': true, 'ven': 'ven_main'},
      {'code': 'P-305', 'name': 'Debate Competition', 'sec': FestSection.superSenior, 'stage': false, 'ven': 'ven_hall2'},

      {'code': 'P-401', 'name': 'Group Anthem General', 'sec': FestSection.general, 'stage': true, 'ven': 'ven_main'},
      {'code': 'P-402', 'name': 'Patriotic Song General', 'sec': FestSection.general, 'stage': true, 'ven': 'ven_hall3'},
      {'code': 'P-403', 'name': 'Collage Making General', 'sec': FestSection.general, 'stage': false, 'ven': 'ven_lab1'},
      {'code': 'P-404', 'name': 'Skit General', 'sec': FestSection.general, 'stage': true, 'ven': 'ven_main'},
      {'code': 'P-405', 'name': 'Photography General', 'sec': FestSection.general, 'stage': false, 'ven': 'ven_lab1'},
    ];

    final random = Random(42);
    List<Program> allPrograms = [];
    for (int i = 0; i < programTemplates.length; i++) {
      final t = programTemplates[i];
      final sec = t['sec'] as FestSection;
      final isGen = sec == FestSection.general;
      final prog = Program(
        id: 'prog_${i + 1}',
        programCode: t['code'] as String,
        programName: t['name'] as String,
        section: sec,
        category: (t['stage'] as bool) ? ProgramCategory.stage : ProgramCategory.nonStage,
        isStageProgram: t['stage'] as bool,
        isGeneral: isGen,
        maxParticipants: isGen ? 10 : (random.nextInt(3) + 1),
        duration: '${(random.nextInt(4) + 1) * 15} mins',
        venueId: t['ven'] as String,
        rules: 'Standard Fest rules apply for ${t['name']}.',
        status: i < 8 ? 'COMPLETED' : (i < 14 ? 'IN_PROGRESS' : 'UPCOMING'),
      );
      await programRepository.addProgram(prog);
      allPrograms.add(prog);

      // Create a schedule for each program
      final dateStr = i % 2 == 0 ? '2026-09-05' : '2026-09-06';
      final startHour = 9 + (i % 6);
      final startStr = '${startHour.toString().padLeft(2, '0')}:00';
      final endStr = '${(startHour + 1).toString().padLeft(2, '0')}:30';
      final sch = Schedule(
        id: 'sch_${i + 1}',
        programId: prog.id,
        venueId: t['ven'] as String,
        date: dateStr,
        startTime: startStr,
        endTime: endStr,
        status: prog.status == 'COMPLETED' ? 'COMPLETED' : (prog.status == 'IN_PROGRESS' ? 'IN_PROGRESS' : 'SCHEDULED'),
      );
      await scheduleRepository.addSchedule(sch);
    }

    // 6. Seed Students (3 students per section per team)
    final firstNames = ['Aarav', 'Ananya', 'Rohan', 'Diya', 'Vihaan', 'Isha', 'Aditya', 'Meera', 'Kabeer', 'Zara', 'Dev', 'Sanya', 'Arjun', 'Priya', 'Bilal', 'Fatima', 'Omar', 'Aisha', 'Zayan', 'Mariam'];
    final lastNames = ['Ahmed', 'Khan', 'Sharma', 'Nair', 'Verma', 'Patel', 'Siddiqui', 'Menon', 'Gupta', 'Hassan'];

    List<Student> allStudents = [];
    int chaseCounter = 1001;

    for (final team in teams) {
      final sections = [FestSection.subJunior, FestSection.senior, FestSection.superSenior, FestSection.general];
      for (final sec in sections) {
        String prefix = 'SB';
        if (sec == FestSection.subJunior) prefix = 'SB';
        if (sec == FestSection.senior) prefix = 'SR';
        if (sec == FestSection.superSenior) prefix = 'SS';
        if (sec == FestSection.general) prefix = 'GN';

        for (int k = 1; k <= 3; k++) {
          final fName = firstNames[random.nextInt(firstNames.length)];
          final lName = lastNames[random.nextInt(lastNames.length)];
          final chaseNum = '$prefix-$chaseCounter';

          final student = Student(
            id: 'stud_$chaseCounter',
            chaseNumber: chaseNum,
            name: '$fName $lName',
            gender: k % 2 == 0 ? 'Female' : 'Male',
            dateOfBirth: '200${8 + random.nextInt(6)}-0${1 + random.nextInt(8)}-15',
            section: sec,
            teamId: team.id,
            phone: '+91 98765$chaseCounter',
            className: sec == FestSection.subJunior ? 'Class 5' : (sec == FestSection.senior ? 'Class 9' : (sec == FestSection.superSenior ? 'Class 12' : 'General')),
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

    for (int pIdx = 0; pIdx < allPrograms.length; pIdx++) {
      final prog = allPrograms[pIdx];
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
      message: 'Sub Junior Arabic Song Solo results have been officially verified and published!',
      status: 'ANNOUNCED',
      announcedAt: DateTime.now(),
    );
    await announcementRepository.addAnnouncement(announcement);

    // 9. Recalculate team scores and ranks
    await scoringService.recalculateTeamScoresAndRanks();
  }
}
