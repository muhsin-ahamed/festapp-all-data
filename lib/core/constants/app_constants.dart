enum FestSection {
  subJunior('Sub Junior'),
  senior('Senior'),
  superSenior('Super Senior'),
  general('General'),
  group('Group');

  final String label;
  const FestSection(this.label);

  static FestSection fromString(String val, [String? chaseNumber]) {
    // 1. Check chase number prefix first if available
    if (chaseNumber != null && chaseNumber.trim().isNotEmpty) {
      final cleanChase = chaseNumber.trim().toUpperCase();
      if (cleanChase.startsWith('SB') || cleanChase.startsWith('SJ') || cleanChase.startsWith('SUB') || cleanChase.startsWith('JR') || cleanChase.startsWith('JUNIOR')) {
        return FestSection.subJunior;
      }
      if (cleanChase.startsWith('SS') || cleanChase.startsWith('SUP') || cleanChase.startsWith('SUPER')) {
        return FestSection.superSenior;
      }
      if (cleanChase.startsWith('SR') || cleanChase.startsWith('SN') || cleanChase.startsWith('SENIOR')) {
        return FestSection.senior;
      }
      if (cleanChase.startsWith('GRP') || cleanChase.startsWith('GROUP')) {
        return FestSection.group;
      }
    }

    // 2. Parse section string
    final cleanVal = val.trim().toLowerCase().replaceAll(RegExp(r'[\s\-_]'), '');

    if (cleanVal.contains('group') || cleanVal == 'grp') {
      return FestSection.group;
    }
    if (cleanVal.contains('super') || cleanVal == 'ss' || cleanVal == 'sup') {
      return FestSection.superSenior;
    }
    if (cleanVal.startsWith('sub') || cleanVal == 'sb' || cleanVal == 'subj' || cleanVal == 'sj' || cleanVal == 'subjunior' || cleanVal == 'junior' || cleanVal == 'jr' || cleanVal == 'juniors') {
      return FestSection.subJunior;
    }
    if (cleanVal == 'senior' || cleanVal == 'sr' || cleanVal == 'sn') {
      return FestSection.senior;
    }
    if (cleanVal == 'general' || cleanVal == 'gen') {
      return FestSection.general;
    }

    for (final e in FestSection.values) {
      final eNameClean = e.name.toLowerCase().replaceAll(RegExp(r'[\s\-_]'), '');
      final eLabelClean = e.label.toLowerCase().replaceAll(RegExp(r'[\s\-_]'), '');
      if (cleanVal == eNameClean || cleanVal == eLabelClean) {
        return e;
      }
    }

    // 3. Additional fallback based on single character prefix in chase number
    if (chaseNumber != null && chaseNumber.trim().isNotEmpty) {
      final cleanChase = chaseNumber.trim().toUpperCase();
      if (cleanChase.startsWith('S')) return FestSection.senior;
      if (cleanChase.startsWith('J')) return FestSection.subJunior;
    }

    return FestSection.subJunior;
  }
}

enum ProgramCategory {
  stage('Stage Program'),
  nonStage('Non-Stage Program'),
  general('General Program');

  final String label;
  const ProgramCategory(this.label);

  static ProgramCategory fromString(String val) {
    return ProgramCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase() || e.label.toLowerCase() == val.toLowerCase(),
      orElse: () => ProgramCategory.stage,
    );
  }
}

enum RegistrationStatus {
  pending('PENDING'),
  approved('APPROVED'),
  rejected('REJECTED'),
  cancelled('CANCELLED');

  final String label;
  const RegistrationStatus(this.label);

  static RegistrationStatus fromString(String val) {
    return RegistrationStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase() || e.label.toLowerCase() == val.toLowerCase(),
      orElse: () => RegistrationStatus.pending,
    );
  }
}

enum ResultStatus {
  draft('DRAFT'),
  submitted('SUBMITTED'),
  verified('VERIFIED'),
  published('PUBLISHED'),
  announced('ANNOUNCED');

  final String label;
  const ResultStatus(this.label);

  static ResultStatus fromString(String val) {
    return ResultStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase() || e.label.toLowerCase() == val.toLowerCase(),
      orElse: () => ResultStatus.draft,
    );
  }
}

enum UserRole {
  festController('FEST_CONTROLLER', 'Fest Controller'),
  teamLeader('TEAM_LEADER', 'Team Leader'),
  jury('JURY', 'Jury'),
  tvOperator('TV_OPERATOR', 'TV Operator');

  final String code;
  final String label;
  const UserRole(this.code, this.label);

  static UserRole? fromCode(String code) {
    try {
      return UserRole.values.firstWhere((e) => e.code == code || e.name == code);
    } catch (_) {
      return null;
    }
  }
}

class AppConstants {
  static const String appName = 'Askesis Fest Management System';
  
  // Registration limits
  static const int maxNonStagePerStudent = 4;
  static const int maxStagePerStudent = 3;
  
  // Scoring default points
  static const int pointsFirst = 10;
  static const int pointsSecond = 7;
  static const int pointsThird = 5;
  
  static const int pointsGradeA = 5;
  static const int pointsGradeB = 3;
  static const int pointsGradeC = 1;

  // TV Rotation default
  static const int defaultTvSlideDuration = 15; // seconds
}
