enum FestSection {
  junior('Junior'),
  subJunior('Sub Junior'),
  superSenior('Super Senior'),
  general('General');

  final String label;
  const FestSection(this.label);

  static FestSection fromString(String val) {
    return FestSection.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase() || e.label.toLowerCase() == val.toLowerCase(),
      orElse: () => FestSection.junior,
    );
  }
}

enum ProgramCategory {
  stage('Stage Program'),
  nonStage('Non-Stage Program');

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
  static const String appName = 'Fest Management System';
  
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
