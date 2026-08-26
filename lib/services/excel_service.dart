import 'dart:typed_data';
import 'package:excel/excel.dart';
import '../core/constants/app_constants.dart';
import '../data/models/student_model.dart';
import '../data/models/team_model.dart';
import '../data/models/program_model.dart';
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

  ExcelService({
    required this.studentRepository,
    required this.teamRepository,
    required this.programRepository,
    required this.venueRepository,
    required this.scheduleRepository,
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
    final existingChaseNumbers = existingStudents.map((s) => s.chaseNumber.trim().toLowerCase()).toSet();
    final teams = await teamRepository.getTeams();

    for (int i = 1; i < sheet.maxRows; i++) {
      final row = sheet.row(i);
      if (row.isEmpty || row.every((cell) => cell?.value == null)) continue;
      total++;

      try {
        final chaseNumber = row[0]?.value?.toString().trim() ?? '';
        final name = row[1]?.value?.toString().trim() ?? '';
        final gender = row[2]?.value?.toString().trim() ?? 'Male';
        final dob = row[3]?.value?.toString().trim() ?? '2010-01-01';
        final sectionStr = row[4]?.value?.toString().trim() ?? 'Junior';
        final teamStr = row[5]?.value?.toString().trim() ?? '';
        final phone = row[6]?.value?.toString().trim() ?? '';
        final className = row[7]?.value?.toString().trim() ?? '10';
        final schoolName = row[8]?.value?.toString().trim() ?? 'Central School';

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
            if (t.teamCode.toLowerCase() == teamStr.toLowerCase() || t.teamName.toLowerCase() == teamStr.toLowerCase()) {
              matched = t;
              break;
            }
          }
          if (matched == null) {
            matched = Team(id: 'team_${const Uuid().v4()}', teamName: teamStr, teamCode: teamStr.toUpperCase());
            teams.add(matched);
            await teamRepository.addTeam(matched);
          }
          teamId = matched.id;
        }

        final student = Student(
          id: const Uuid().v4(),
          chaseNumber: chaseNumber,
          name: name,
          gender: gender,
          dateOfBirth: dob,
          section: FestSection.fromString(sectionStr),
          teamId: teamId.isNotEmpty ? teamId : 'default_team',
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

    // Save valid students to repository
    for (final s in validStudents) {
      await studentRepository.addStudent(s);
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
    final existingCodes = existingTeams.map((t) => t.teamCode.trim().toLowerCase()).toSet();

    for (int i = 1; i < sheet.maxRows; i++) {
      final row = sheet.row(i);
      if (row.isEmpty || row.every((cell) => cell?.value == null)) continue;
      total++;

      try {
        final code = row[0]?.value?.toString().trim() ?? '';
        final name = row[1]?.value?.toString().trim() ?? '';
        final leaderName = row.length > 2 ? row[2]?.value?.toString().trim() : null;

        if (code.isEmpty || name.isEmpty) {
          invalid++;
          errors.add('Row ${i + 1}: Missing team code or name.');
          continue;
        }

        if (existingCodes.contains(code.toLowerCase())) {
          duplicate++;
          errors.add('Row ${i + 1}: Duplicate team code "$code".');
          continue;
        }

        final team = Team(
          id: 'team_${const Uuid().v4()}',
          teamCode: code.toUpperCase(),
          teamName: name,
          leaderName: (leaderName != null && leaderName.isNotEmpty) ? leaderName : null,
        );

        validTeams.add(team);
        existingCodes.add(code.toLowerCase());
        valid++;
      } catch (e) {
        invalid++;
        errors.add('Row ${i + 1}: Error parsing team row ($e).');
      }
    }

    for (final t in validTeams) {
      await teamRepository.addTeam(t);
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
    final existingCodes = existingPrograms.map((p) => p.programCode.trim().toLowerCase()).toSet();

    for (int i = 1; i < sheet.maxRows; i++) {
      final row = sheet.row(i);
      if (row.isEmpty || row.every((cell) => cell?.value == null)) continue;
      total++;

      try {
        final code = row[0]?.value?.toString().trim() ?? '';
        final name = row[1]?.value?.toString().trim() ?? '';
        final sectionStr = row[2]?.value?.toString().trim() ?? 'Junior';
        final isStageStr = row[3]?.value?.toString().trim().toLowerCase() ?? 'true';
        final maxPartsStr = row[4]?.value?.toString().trim() ?? '1';
        final duration = row[5]?.value?.toString().trim() ?? '30 mins';

        if (code.isEmpty || name.isEmpty) {
          invalid++;
          errors.add('Row ${i + 1}: Missing program code or name.');
          continue;
        }

        if (existingCodes.contains(code.toLowerCase())) {
          duplicate++;
          errors.add('Row ${i + 1}: Duplicate program code "$code".');
          continue;
        }

        final sec = FestSection.fromString(sectionStr);
        final isStage = isStageStr == 'true' || isStageStr == 'yes' || isStageStr == '1';
        final cat = isStage ? ProgramCategory.stage : ProgramCategory.nonStage;

        final program = Program(
          id: 'prog_${const Uuid().v4()}',
          programCode: code.toUpperCase(),
          programName: name,
          section: sec,
          category: cat,
          isStageProgram: isStage,
          isGeneral: sec == FestSection.general,
          maxParticipants: int.tryParse(maxPartsStr) ?? 1,
          duration: duration,
        );

        validPrograms.add(program);
        existingCodes.add(code.toLowerCase());
        valid++;
      } catch (e) {
        invalid++;
        errors.add('Row ${i + 1}: Error parsing program ($e).');
      }
    }

    for (final p in validPrograms) {
      await programRepository.addProgram(p);
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

  Uint8List exportStudentsToExcel(List<Student> students, Map<String, String> teamNameMap) {
    final excel = Excel.createExcel();
    final sheet = excel['Students'];

    sheet.appendRow([
      TextCellValue('Chase Number'),
      TextCellValue('Name'),
      TextCellValue('Gender'),
      TextCellValue('Date of Birth'),
      TextCellValue('Section'),
      TextCellValue('Team'),
      TextCellValue('Phone'),
      TextCellValue('Class'),
      TextCellValue('School'),
    ]);

    for (final s in students) {
      sheet.appendRow([
        TextCellValue(s.chaseNumber),
        TextCellValue(s.name),
        TextCellValue(s.gender),
        TextCellValue(s.dateOfBirth),
        TextCellValue(s.section.label),
        TextCellValue(teamNameMap[s.teamId] ?? s.teamId),
        TextCellValue(s.phone),
        TextCellValue(s.className),
        TextCellValue(s.schoolName),
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
      TextCellValue('Gender'),
      TextCellValue('Date of Birth'),
      TextCellValue('Section'),
      TextCellValue('Team Code/Name'),
      TextCellValue('Phone'),
      TextCellValue('Class'),
      TextCellValue('School'),
    ]);

    sheet.appendRow([
      TextCellValue('101'),
      TextCellValue('John Doe'),
      TextCellValue('Male'),
      TextCellValue('2010-05-15'),
      TextCellValue('Junior'),
      TextCellValue('T-ALPHA'),
      TextCellValue('+1 555-0199'),
      TextCellValue('10'),
      TextCellValue('Central School'),
    ]);

    return Uint8List.fromList(excel.save() ?? []);
  }
}
