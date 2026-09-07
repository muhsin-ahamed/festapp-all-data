import 'dart:typed_data';
import 'package:excel/excel.dart';
import '../core/constants/app_constants.dart';
import '../data/models/student_model.dart';
import '../data/models/team_model.dart';
import '../data/models/program_model.dart';
import '../data/models/venue_model.dart';
import '../data/models/schedule_model.dart';
import '../data/models/registration_model.dart';
import '../data/repositories/app_repositories.dart';
import 'package:uuid/uuid.dart';

class ExcelImportResult<T> {
  final int totalRows;
  final int validRows;
  final int invalidRows;
  final int duplicateRows;
  final int importedRows;
  final List<String> errors;
  final List<T> validItems;

  ExcelImportResult({
    required this.totalRows,
    required this.validRows,
    required this.invalidRows,
    required this.duplicateRows,
    required this.importedRows,
    required this.errors,
    required this.validItems,
  });
}

class ExcelService {
  final StudentRepository studentRepository;
  final TeamRepository teamRepository;
  final ProgramRepository programRepository;
  final VenueRepository venueRepository;
  final ScheduleRepository scheduleRepository;
  final RegistrationRepository registrationRepository;

  ExcelService({
    required this.studentRepository,
    required this.teamRepository,
    required this.programRepository,
    required this.venueRepository,
    required this.scheduleRepository,
    required this.registrationRepository,
  });

  Future<ExcelImportResult<Student>> importStudents(Uint8List bytes) async {
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables.values.first;

    int total = 0;
    int valid = 0;
    int invalid = 0;
    int duplicate = 0;
    List<String> errors = [];
    List<Student> validStudents = [];

    final existingStudents = await studentRepository.getStudents();
    final existingChaseNumbers = existingStudents
        .map((s) => s.chaseNumber.trim().toLowerCase())
        .toSet();
    final teams = await teamRepository.getTeams();
    final List<Team> newTeamsToSave = [];

    for (int i = 1; i < sheet.maxRows; i++) {
      final row = sheet.row(i);
      if (row.isEmpty || row.every((cell) => cell?.value == null)) continue;
      total++;

      try {
        final chaseNumber = row[0]?.value?.toString().trim() ?? '';
        final name = row[1]?.value?.toString().trim() ?? '';
        final sectionStr = row.length > 2
            ? (row[2]?.value?.toString().trim() ?? 'Sub Junior')
            : 'Sub Junior';
        final teamStr = row.length > 3
            ? (row[3]?.value?.toString().trim() ?? '')
            : '';

        if (chaseNumber.isEmpty || name.isEmpty) {
          invalid++;
          errors.add('Row ${i + 1}: Missing chase number or student name.');
          continue;
        }

        if (existingChaseNumbers.contains(chaseNumber.toLowerCase())) {
          duplicate++;
          errors.add('Row ${i + 1}: Duplicate chase number "$chaseNumber".');
          continue;
        }

        // Resolve Team
        String teamId = '';
        if (teamStr.isNotEmpty) {
          Team? matched;
          for (final t in teams) {
            if (t.teamCode.toLowerCase() == teamStr.toLowerCase() ||
                t.teamName.toLowerCase() == teamStr.toLowerCase()) {
              matched = t;
              break;
            }
          }
          if (matched == null) {
            matched = Team(
              id: 'team_${const Uuid().v4()}',
              teamName: teamStr,
              teamCode:
                  'T-${teamStr.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '')}',
            );
            teams.add(matched);
            newTeamsToSave.add(matched);
          }
          teamId = matched.id;
        }

        final student = Student(
          id: const Uuid().v4(),
          chaseNumber: chaseNumber,
          name: name,
          gender: 'Male',
          dateOfBirth: '2010-01-01',
          section: FestSection.fromString(sectionStr, chaseNumber),
          teamId: teamId.isNotEmpty ? teamId : 'default_team',
          phone: '',
          className: '',
          schoolName: '',
          qrCode: chaseNumber,
        );

        validStudents.add(student);
        existingChaseNumbers.add(chaseNumber.toLowerCase());
        valid++;
      } catch (e) {
        invalid++;
        errors.add('Row ${i + 1}: Parsing error ($e).');
      }
    }

    // Save newly created teams & valid students in batch
    if (newTeamsToSave.isNotEmpty) {
      await teamRepository.addTeams(newTeamsToSave);
    }
    if (validStudents.isNotEmpty) {
      await studentRepository.addStudents(validStudents);
    }

    return ExcelImportResult<Student>(
      totalRows: total,
      validRows: valid,
      invalidRows: invalid,
      duplicateRows: duplicate,
      importedRows: validStudents.length,
      errors: errors,
      validItems: validStudents,
    );
  }

  Future<ExcelImportResult<Team>> importTeams(Uint8List bytes) async {
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables.values.first;

    int total = 0;
    int valid = 0;
    int invalid = 0;
    int duplicate = 0;
    List<String> errors = [];
    List<Team> validTeams = [];

    final existingTeams = await teamRepository.getTeams();
    final existingCodes = existingTeams
        .map((t) => t.teamCode.trim().toLowerCase())
        .toSet();

    for (int i = 1; i < sheet.maxRows; i++) {
      final row = sheet.row(i);
      if (row.isEmpty || row.every((cell) => cell?.value == null)) continue;
      total++;

      try {
        final name = row[0]?.value?.toString().trim() ?? '';
        final mentorName = row.length > 1
            ? (row[1]?.value?.toString().trim() ?? '')
            : '';
        final leaderName = row.length > 2
            ? (row[2]?.value?.toString().trim() ?? '')
            : '';
        final assistantLeaderName = row.length > 3
            ? (row[3]?.value?.toString().trim() ?? '')
            : '';

        if (name.isEmpty) {
          invalid++;
          errors.add('Row ${i + 1}: Missing team name.');
          continue;
        }

        final code =
            'T-${name.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '')}';

        if (existingCodes.contains(code.toLowerCase())) {
          duplicate++;
          errors.add('Row ${i + 1}: Duplicate team "$name".');
          continue;
        }

        final team = Team(
          id: 'team_${const Uuid().v4()}',
          teamCode: code,
          teamName: name,
          mentorName: mentorName.isNotEmpty ? mentorName : null,
          leaderName: leaderName.isNotEmpty ? leaderName : null,
          assistantLeaderName: assistantLeaderName.isNotEmpty
              ? assistantLeaderName
              : null,
        );

        validTeams.add(team);
        existingCodes.add(code.toLowerCase());
        valid++;
      } catch (e) {
        invalid++;
        errors.add('Row ${i + 1}: Error parsing team row ($e).');
      }
    }

    if (validTeams.isNotEmpty) {
      await teamRepository.addTeams(validTeams);
    }

    return ExcelImportResult<Team>(
      totalRows: total,
      validRows: valid,
      invalidRows: invalid,
      duplicateRows: duplicate,
      importedRows: validTeams.length,
      errors: errors,
      validItems: validTeams,
    );
  }

  Future<ExcelImportResult<Program>> importPrograms(Uint8List bytes) async {
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables.values.first;

    int total = 0;
    int valid = 0;
    int invalid = 0;
    int duplicate = 0;
    List<String> errors = [];
    List<Program> validPrograms = [];

    final existingPrograms = await programRepository.getPrograms();
    final existingCodes = existingPrograms
        .map((p) => p.programCode.trim().toLowerCase())
        .toSet();
    int codeCounter = 101;

    for (int i = 1; i < sheet.maxRows; i++) {
      final row = sheet.row(i);
      if (row.isEmpty || row.every((cell) => cell?.value == null)) continue;
      total++;

      try {
        final name = row[0]?.value?.toString().trim() ?? '';
        final sectionStr = row.length > 1
            ? (row[1]?.value?.toString().trim() ?? 'Sub Junior')
            : 'Sub Junior';
        final typeStr = row.length > 2
            ? (row[2]?.value?.toString().trim() ?? 'Stage')
            : 'Stage';

        if (name.isEmpty) {
          invalid++;
          errors.add('Row ${i + 1}: Missing program name.');
          continue;
        }

        // Auto-generate code
        String code = 'P-$codeCounter';
        while (existingCodes.contains(code.toLowerCase())) {
          codeCounter++;
          code = 'P-$codeCounter';
        }

        final typeLower = typeStr.toLowerCase();
        final bool isGenType = typeLower.contains('gen');
        final isStage = !typeLower.contains('non');
        final sec = FestSection.fromString(sectionStr);
        final cat = isGenType
            ? ProgramCategory.general
            : (isStage ? ProgramCategory.stage : ProgramCategory.nonStage);

        final program = Program(
          id: 'prog_${const Uuid().v4()}',
          programCode: code,
          programName: name,
          section: sec,
          category: cat,
          isStageProgram: isStage,
          isGeneral: isGenType || sec == FestSection.general,
          maxParticipants: 1,
          duration: '30 mins',
        );

        validPrograms.add(program);
        existingCodes.add(code.toLowerCase());
        codeCounter++;
        valid++;
      } catch (e) {
        invalid++;
        errors.add('Row ${i + 1}: Error parsing program ($e).');
      }
    }

    if (validPrograms.isNotEmpty) {
      await programRepository.addPrograms(validPrograms);
    }

    return ExcelImportResult<Program>(
      totalRows: total,
      validRows: valid,
      invalidRows: invalid,
      duplicateRows: duplicate,
      importedRows: validPrograms.length,
      errors: errors,
      validItems: validPrograms,
    );
  }

  Uint8List exportProgramsToExcel(List<Program> programs) {
    final excel = Excel.createExcel();
    final sheet = excel['Programs'];

    sheet.appendRow([
      TextCellValue('Program Name'),
      TextCellValue('Section'),
      TextCellValue('Program Type'),
    ]);

    for (final p in programs) {
      final typeLabel = p.isStageProgram ? 'Stage' : 'Non-Stage';

      sheet.appendRow([
        TextCellValue(p.programName),
        TextCellValue(p.section.label),
        TextCellValue(typeLabel),
      ]);
    }

    return Uint8List.fromList(excel.save() ?? []);
  }

  Uint8List generateProgramTemplate() {
    final excel = Excel.createExcel();
    final sheet = excel['Programs_Template'];

    sheet.appendRow([
      TextCellValue('Program Name'),
      TextCellValue('Section'),
      TextCellValue('Program Type'),
    ]);

    sheet.appendRow([
      TextCellValue('Elocution English'),
      TextCellValue('Sub Junior'),
      TextCellValue('Stage'),
    ]);
    sheet.appendRow([
      TextCellValue('Group Song'),
      TextCellValue('Senior'),
      TextCellValue('Stage'),
    ]);
    sheet.appendRow([
      TextCellValue('Pencil Drawing'),
      TextCellValue('General'),
      TextCellValue('Non-Stage'),
    ]);
    sheet.appendRow([
      TextCellValue('General Quiz'),
      TextCellValue('General'),
      TextCellValue('Stage'),
    ]);

    return Uint8List.fromList(excel.save() ?? []);
  }

  Uint8List exportStudentsToExcel(
    List<Student> students,
    Map<String, String> teamNameMap,
  ) {
    final excel = Excel.createExcel();
    final sheet = excel['Students'];

    sheet.appendRow([
      TextCellValue('Chase Number'),
      TextCellValue('Name'),
      TextCellValue('Section'),
      TextCellValue('Team Name'),
    ]);

    for (final s in students) {
      sheet.appendRow([
        TextCellValue(s.chaseNumber),
        TextCellValue(s.name),
        TextCellValue(s.section.label),
        TextCellValue(teamNameMap[s.teamId] ?? s.teamId),
      ]);
    }

    return Uint8List.fromList(excel.save() ?? []);
  }

  Uint8List generateStudentTemplate() {
    final excel = Excel.createExcel();
    final sheet = excel['Students_Template'];

    sheet.appendRow([
      TextCellValue('Chase Number'),
      TextCellValue('Name'),
      TextCellValue('Section'),
      TextCellValue('Team Name'),
    ]);

    sheet.appendRow([
      TextCellValue('101'),
      TextCellValue('John Doe'),
      TextCellValue('Sub Junior'),
      TextCellValue('Tigrees'),
    ]);

    return Uint8List.fromList(excel.save() ?? []);
  }

  Future<ExcelImportResult<Registration>> importRegistrations(
    Uint8List bytes,
  ) async {
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables.values.first;

    int total = 0;
    int valid = 0;
    int invalid = 0;
    int duplicate = 0;
    List<String> errors = [];
    List<Registration> validRegistrations = [];

    final existingRegistrations = await registrationRepository
        .getRegistrations();
    final Set<String> existingComboKeys = existingRegistrations
        .map((r) => '${r.studentId}_${r.programId}')
        .toSet();

    final students = await studentRepository.getStudents();
    final programs = await programRepository.getPrograms();

    for (int i = 1; i < sheet.maxRows; i++) {
      final row = sheet.row(i);
      if (row.isEmpty || row.every((cell) => cell?.value == null)) continue;
      total++;

      try {
        final chaseNumber = row[0]?.value?.toString().trim() ?? '';
        final studentName = row[1]?.value?.toString().trim() ?? '';
        final programName = row[2]?.value?.toString().trim() ?? '';
        final sectionStr = ''; // Section removed per user request

        if (chaseNumber.isEmpty || programName.isEmpty) {
          invalid++;
          errors.add('Row ${i + 1}: Missing ches.no or program name.');
          continue;
        }

        final student = students.firstWhere(
          (s) => s.chaseNumber.toLowerCase() == chaseNumber.toLowerCase(),
          orElse: () => throw Exception(
            'Student with chase number "$chaseNumber" not found.',
          ),
        );

        final program = programs.firstWhere(
          (p) =>
              p.programName.toLowerCase() == programName.toLowerCase() &&
              (sectionStr.isEmpty ||
                  p.section.label.toLowerCase() == sectionStr.toLowerCase()),
          orElse: () => throw Exception(
            'Program "$programName" (Section: $sectionStr) not found.',
          ),
        );

        final comboKey = '${student.id}_${program.id}';
        if (existingComboKeys.contains(comboKey)) {
          duplicate++;
          errors.add(
            'Row ${i + 1}: Registration already exists for Student: $chaseNumber and Program: $programName.',
          );
          continue;
        }

        final registration = Registration(
          id: const Uuid().v4(),
          studentId: student.id,
          programId: program.id,
          teamId: student.teamId,
          registrationNumber:
              'REG-${student.chaseNumber}-${program.programCode}',
        );

        validRegistrations.add(registration);
        existingComboKeys.add(comboKey);
        valid++;
      } catch (e) {
        invalid++;
        errors.add(
          'Row ${i + 1}: Parsing error (${e.toString().replaceAll('Exception: ', '')}).',
        );
      }
    }

    for (var reg in validRegistrations) {
      await registrationRepository.addRegistration(reg);
    }

    return ExcelImportResult<Registration>(
      totalRows: total,
      validRows: valid,
      invalidRows: invalid,
      duplicateRows: duplicate,
      importedRows: validRegistrations.length,
      errors: errors,
      validItems: validRegistrations,
    );
  }

  Uint8List generateRegistrationTemplate() {
    final excel = Excel.createExcel();
    final sheet = excel['Registrations_Template'];

    sheet.appendRow([
      TextCellValue('ches.no'),
      TextCellValue('name'),
      TextCellValue('program'),
    ]);

    sheet.appendRow([
      TextCellValue('101'),
      TextCellValue('John Doe'),
      TextCellValue('Solo Song'),
    ]);

    return Uint8List.fromList(excel.save() ?? []);
  }

  Uint8List exportTeamsToExcel(List<Team> teams) {
    final excel = Excel.createExcel();
    final sheet = excel['Teams'];

    sheet.appendRow([
      TextCellValue('Team Name'),
      TextCellValue('Mentor Name'),
      TextCellValue('Leader Name'),
      TextCellValue('Assistant Leader Name'),
    ]);

    for (final t in teams) {
      sheet.appendRow([
        TextCellValue(t.teamName),
        TextCellValue(t.mentorName ?? ''),
        TextCellValue(t.leaderName ?? ''),
        TextCellValue(t.assistantLeaderName ?? ''),
      ]);
    }

    return Uint8List.fromList(excel.save() ?? []);
  }

  Uint8List generateTeamTemplate() {
    final excel = Excel.createExcel();
    final sheet = excel['Teams_Template'];

    sheet.appendRow([
      TextCellValue('Team Name'),
      TextCellValue('Mentor Name'),
      TextCellValue('Leader Name'),
      TextCellValue('Assistant Leader Name'),
    ]);

    sheet.appendRow([
      TextCellValue('Tigrees'),
      TextCellValue('Dr. Smith'),
      TextCellValue('Alice Johnson'),
      TextCellValue('Bob Williams'),
    ]);

    return Uint8List.fromList(excel.save() ?? []);
  }

  Future<ExcelImportResult<Student>> importTeamStudents(
    Uint8List bytes,
    String teamId,
  ) async {
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables.values.first;

    int total = 0;
    int valid = 0;
    int invalid = 0;
    int duplicate = 0;
    List<String> errors = [];
    List<Student> validStudents = [];

    final existingStudents = await studentRepository.getStudents();
    final existingChaseNumbers = existingStudents
        .map((s) => s.chaseNumber.trim().toLowerCase())
        .toSet();

    for (int i = 1; i < sheet.maxRows; i++) {
      final row = sheet.row(i);
      if (row.isEmpty || row.every((cell) => cell?.value == null)) continue;
      total++;

      try {
        final chaseNumber = row[0]?.value?.toString().trim() ?? '';
        final name = row.length > 1
            ? (row[1]?.value?.toString().trim() ?? '')
            : '';
        final sectionStr = row.length > 2
            ? (row[2]?.value?.toString().trim() ?? 'Sub Junior')
            : 'Sub Junior';
        final genderStr = row.length > 3
            ? (row[3]?.value?.toString().trim() ?? 'Male')
            : 'Male';
        final phone = row.length > 4
            ? (row[4]?.value?.toString().trim() ?? '')
            : '';
        final className = row.length > 5
            ? (row[5]?.value?.toString().trim() ?? '')
            : '';
        final schoolName = row.length > 6
            ? (row[6]?.value?.toString().trim() ?? '')
            : '';

        if (chaseNumber.isEmpty || name.isEmpty) {
          invalid++;
          errors.add('Row ${i + 1}: Missing chase number or student name.');
          continue;
        }

        if (existingChaseNumbers.contains(chaseNumber.toLowerCase())) {
          duplicate++;
          errors.add('Row ${i + 1}: Duplicate chase number "$chaseNumber".');
          continue;
        }

        final student = Student(
          id: 'stud_${const Uuid().v4()}',
          chaseNumber: chaseNumber,
          name: name,
          gender: genderStr.isNotEmpty ? genderStr : 'Male',
          dateOfBirth: '2010-01-01',
          section: FestSection.fromString(sectionStr, chaseNumber),
          teamId: teamId,
          phone: phone,
          className: className,
          schoolName: schoolName,
          qrCode: chaseNumber,
        );

        validStudents.add(student);
        existingChaseNumbers.add(chaseNumber.toLowerCase());
        valid++;
      } catch (e) {
        invalid++;
        errors.add('Row ${i + 1}: Parsing error ($e).');
      }
    }

    if (validStudents.isNotEmpty) {
      await studentRepository.addStudents(validStudents);
    }

    return ExcelImportResult<Student>(
      totalRows: total,
      validRows: valid,
      invalidRows: invalid,
      duplicateRows: duplicate,
      importedRows: validStudents.length,
      errors: errors,
      validItems: validStudents,
    );
  }

  Uint8List generateTeamStudentTemplate() {
    final excel = Excel.createExcel();
    final sheet = excel['Team_Students_Template'];

    sheet.appendRow([
      TextCellValue('Chase Number'),
      TextCellValue('Name'),
      TextCellValue('Section'),
      TextCellValue('Gender'),
      TextCellValue('Phone'),
      TextCellValue('Class'),
      TextCellValue('School'),
    ]);

    sheet.appendRow([
      TextCellValue('CHASE-101'),
      TextCellValue('Muhammed Ali'),
      TextCellValue('Sub-Junior'),
      TextCellValue('Male'),
      TextCellValue('9876543210'),
      TextCellValue('Class 5'),
      TextCellValue('Al-Huda Academy'),
    ]);

    sheet.appendRow([
      TextCellValue('CHASE-102'),
      TextCellValue('Fatima Zahra'),
      TextCellValue('Sub Junior'),
      TextCellValue('Female'),
      TextCellValue('9876543211'),
      TextCellValue('Class 8'),
      TextCellValue('Al-Huda Academy'),
    ]);

    sheet.appendRow([
      TextCellValue('CHASE-103'),
      TextCellValue('Ahmad Hassan'),
      TextCellValue('Senior'),
      TextCellValue('Male'),
      TextCellValue('9876543212'),
      TextCellValue('Class 10'),
      TextCellValue('Al-Huda Academy'),
    ]);

    return Uint8List.fromList(excel.save() ?? []);
  }

  Uint8List exportTeamStudentsToExcel(List<Student> students, String teamName) {
    final excel = Excel.createExcel();
    final sheet =
        excel['${teamName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_Students'];

    sheet.appendRow([
      TextCellValue('Chase Number'),
      TextCellValue('Name'),
      TextCellValue('Section'),
      TextCellValue('Gender'),
      TextCellValue('Phone'),
      TextCellValue('Class'),
      TextCellValue('School'),
    ]);

    for (final s in students) {
      sheet.appendRow([
        TextCellValue(s.chaseNumber),
        TextCellValue(s.name),
        TextCellValue(s.section.label),
        TextCellValue(s.gender),
        TextCellValue(s.phone),
        TextCellValue(s.className),
        TextCellValue(s.schoolName),
      ]);
    }

    return Uint8List.fromList(excel.save() ?? []);
  }

  Future<ExcelImportResult<Schedule>> importSchedules(
    Uint8List bytes, [
    String? filename,
  ]) async {
    final List<List<String>> rows = [];
    final isPdf =
        (filename != null && filename.toLowerCase().endsWith('.pdf')) ||
        (bytes.length > 4 &&
            String.fromCharCodes(bytes.sublist(0, 4)) == '%PDF');

    if (isPdf) {
      final pdfContent = String.fromCharCodes(
        bytes.map(
          (b) => (b >= 32 && b <= 126 || b == 10 || b == 13 || b == 9) ? b : 32,
        ),
      );
      final matches = RegExp(r'\(([^()]{2,})\)').allMatches(pdfContent);
      final extractedStrings = matches
          .map((m) => m.group(1)?.trim() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();

      if (extractedStrings.length >= 5) {
        for (int i = 0; i + 4 < extractedStrings.length; i += 5) {
          rows.add([
            extractedStrings[i],
            extractedStrings[i + 1],
            extractedStrings[i + 2],
            extractedStrings[i + 3],
            extractedStrings[i + 4],
          ]);
        }
      } else {
        final lines = pdfContent.split(RegExp(r'[\r\n]+'));
        for (final line in lines) {
          final parts = line
              .split(RegExp(r'[,;\t]'))
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
          if (parts.isNotEmpty) {
            rows.add([
              parts[0],
              parts.length > 1 ? parts[1] : '',
              parts.length > 2 ? parts[2] : '09:00 - 10:30',
              parts.length > 3 ? parts[3] : '',
              parts.length > 4 ? parts[4] : 'General',
            ]);
          }
        }
      }
    } else {
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables.values.first;
      for (int i = 1; i < sheet.maxRows; i++) {
        final row = sheet.row(i);
        if (row.isEmpty || row.every((cell) => cell?.value == null)) continue;
        rows.add([
          row[0]?.value?.toString().trim() ?? '2026-09-05',
          row.length > 1 ? (row[1]?.value?.toString().trim() ?? '') : '',
          row.length > 2
              ? (row[2]?.value?.toString().trim() ?? '09:00 - 10:30')
              : '09:00 - 10:30',
          row.length > 3 ? (row[3]?.value?.toString().trim() ?? '') : '',
          row.length > 4
              ? (row[4]?.value?.toString().trim() ?? 'General')
              : 'General',
        ]);
      }
    }

    int total = 0;
    int valid = 0;
    int invalid = 0;
    int duplicate = 0;
    List<String> errors = [];
    List<Schedule> validSchedules = [];

    final existingSchedules = await scheduleRepository.getSchedules();
    final existingPrograms = await programRepository.getPrograms();
    final existingVenues = await venueRepository.getVenues();

    final List<Program> newProgramsToSave = [];
    final List<Venue> newVenuesToSave = [];

    final programMap = <String, Program>{};
    for (final p in existingPrograms) {
      programMap[p.programName.trim().toLowerCase()] = p;
      programMap[p.programCode.trim().toLowerCase()] = p;
    }

    final venueMap = <String, Venue>{};
    for (final v in existingVenues) {
      venueMap[v.name.trim().toLowerCase()] = v;
    }

    int generatedProgCode = 501;

    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      total++;

      try {
        // Expected columns: DATE, ITEM, TIME, VENUE, CATEGORY
        final dateStr = row[0].isEmpty ? '2026-09-05' : row[0];
        final progStr = row.length > 1 ? row[1] : '';
        final timeStr = row.length > 2 && row[2].isNotEmpty
            ? row[2]
            : '09:00 - 10:30';
        final venueStr = row.length > 3 ? row[3] : '';
        final sectionStr = row.length > 4 && row[4].isNotEmpty
            ? row[4]
            : 'General';

        // Skip header row if present
        if (dateStr.toUpperCase() == 'DATE' ||
            progStr.toUpperCase() == 'ITEM' ||
            progStr.toUpperCase() == 'PROGRAM') {
          continue;
        }

        if (progStr.isEmpty) {
          invalid++;
          errors.add('Row ${i + 1}: Missing Program/Item Name or Code.');
          continue;
        }

        // 1. Resolve or auto-create Program
        Program? matchedProg = programMap[progStr.toLowerCase()];
        if (matchedProg == null) {
          final sec = FestSection.fromString(sectionStr);
          final progCode = 'P-$generatedProgCode';
          generatedProgCode++;

          matchedProg = Program(
            id: 'prog_${const Uuid().v4()}',
            programCode: progCode,
            programName: progStr,
            section: sec,
            category: sec == FestSection.general
                ? ProgramCategory.general
                : ProgramCategory.stage,
            isStageProgram: true,
            isGeneral: sec == FestSection.general,
            maxParticipants: 1,
            duration: '30 mins',
          );
          existingPrograms.add(matchedProg);
          newProgramsToSave.add(matchedProg);
          programMap[matchedProg.programName.toLowerCase()] = matchedProg;
          programMap[matchedProg.programCode.toLowerCase()] = matchedProg;
        }

        // 2. Resolve or auto-create Venue
        String venueId = 'ven_main';
        if (venueStr.isNotEmpty) {
          Venue? matchedVenue = venueMap[venueStr.toLowerCase()];
          if (matchedVenue == null) {
            matchedVenue = Venue(
              id: 'ven_${const Uuid().v4()}',
              name: venueStr,
              location: 'Main Site',
              capacity: 100,
              description: 'Imported Venue',
            );
            existingVenues.add(matchedVenue);
            newVenuesToSave.add(matchedVenue);
            venueMap[matchedVenue.name.toLowerCase()] = matchedVenue;
          }
          venueId = matchedVenue.id;
        }

        // 3. Parse Start & End Time
        String startTime = '09:00';
        String endTime = '10:30';
        final timeUpper = timeStr.toUpperCase();
        if (timeUpper.contains('TO')) {
          final parts = timeUpper.split('TO');
          startTime = parts[0].trim();
          endTime = parts.length > 1 ? parts[1].trim() : '10:30';
        } else if (timeStr.contains('-')) {
          final parts = timeStr.split('-');
          startTime = parts[0].trim();
          endTime = parts.length > 1 ? parts[1].trim() : '10:30';
        } else if (timeStr.isNotEmpty) {
          startTime = timeStr;
          endTime = '10:30';
        }

        // Duplicate check (same program on same date at same start time)
        final isDuplicate = existingSchedules.any(
          (s) =>
              s.programId == matchedProg!.id &&
              s.date == dateStr &&
              s.startTime == startTime,
        );

        if (isDuplicate) {
          duplicate++;
          errors.add(
            'Row ${i + 1}: Duplicate schedule for "${matchedProg.programName}" on $dateStr at $startTime.',
          );
          continue;
        }

        final schedule = Schedule(
          id: 'sch_${const Uuid().v4()}',
          programId: matchedProg.id,
          venueId: venueId,
          date: dateStr.isEmpty ? '2026-09-05' : dateStr,
          startTime: startTime,
          endTime: endTime,
          status: 'SCHEDULED',
        );

        validSchedules.add(schedule);
        existingSchedules.add(schedule);
        valid++;
      } catch (e) {
        invalid++;
        errors.add('Row ${i + 1}: Error parsing schedule row ($e).');
      }
    }

    if (newProgramsToSave.isNotEmpty) {
      await programRepository.addPrograms(newProgramsToSave);
    }
    if (newVenuesToSave.isNotEmpty) {
      await venueRepository.addVenues(newVenuesToSave);
    }
    if (validSchedules.isNotEmpty) {
      await scheduleRepository.addSchedules(validSchedules);
    }

    return ExcelImportResult<Schedule>(
      totalRows: total,
      validRows: valid,
      invalidRows: invalid,
      duplicateRows: duplicate,
      importedRows: validSchedules.length,
      errors: errors,
      validItems: validSchedules,
    );
  }

  Uint8List exportSchedulesToExcel(
    List<Schedule> schedules,
    Map<String, Program> progMap,
    Map<String, Venue> venMap,
  ) {
    final excel = Excel.createExcel();
    final sheet = excel['Schedule'];

    sheet.appendRow([
      TextCellValue('DATE'),
      TextCellValue('ITEM'),
      TextCellValue('TIME'),
      TextCellValue('VENUE'),
      TextCellValue('CATEGORY'),
    ]);

    for (final sch in schedules) {
      final prog = progMap[sch.programId];
      final ven = venMap[sch.venueId];

      sheet.appendRow([
        TextCellValue(sch.date),
        TextCellValue(prog?.programName ?? 'Unknown Program'),
        TextCellValue('${sch.startTime} - ${sch.endTime}'),
        TextCellValue(ven?.name ?? 'TBA Venue'),
        TextCellValue(prog?.section.label ?? 'General'),
      ]);
    }

    return Uint8List.fromList(excel.save() ?? []);
  }

  Uint8List generateScheduleTemplate() {
    final excel = Excel.createExcel();
    final sheet = excel['Schedule_Template'];

    sheet.appendRow([
      TextCellValue('DATE'),
      TextCellValue('ITEM'),
      TextCellValue('TIME'),
      TextCellValue('VENUE'),
      TextCellValue('CATEGORY'),
    ]);

    sheet.appendRow([
      TextCellValue('2026-09-05'),
      TextCellValue('ESSAY ARB'),
      TextCellValue('6:00 TO 6:45 am'),
      TextCellValue('S1'),
      TextCellValue('SENIOR'),
    ]);

    sheet.appendRow([
      TextCellValue('2026-09-05'),
      TextCellValue('ARABIC SONG'),
      TextCellValue('9:00 TO 10:30 am'),
      TextCellValue('S2'),
      TextCellValue('SUB JUNIOR'),
    ]);

    sheet.appendRow([
      TextCellValue('2026-09-05'),
      TextCellValue('PENCIL DRAWING'),
      TextCellValue('11:30 TO 13:00 pm'),
      TextCellValue('S3'),
      TextCellValue('GENERAL'),
    ]);

    return Uint8List.fromList(excel.save() ?? []);
  }
}
