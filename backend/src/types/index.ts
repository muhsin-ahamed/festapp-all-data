export type UserRole = 'FEST_CONTROLLER' | 'TEAM_LEADER' | 'JURY' | 'TV_OPERATOR';

export type FestSection = 'SUB_JUNIOR' | 'SENIOR' | 'SUPER_SENIOR' | 'GENERAL' | 'GROUP';

export type ProgramCategory = 'stage' | 'nonStage' | 'Stage Program' | 'Non-Stage Program';

export type RegistrationStatus = 'PENDING' | 'APPROVED' | 'REJECTED' | 'CANCELLED';

export type ResultStatus = 'DRAFT' | 'SUBMITTED' | 'VERIFIED' | 'PUBLISHED' | 'ANNOUNCED';

export interface JwtPayload {
  id: string;
  username: string;
  role: UserRole;
  teamId?: string;
  juryId?: string;
  iat?: number;
  exp?: number;
}

export interface UserEntity {
  id: string;
  auth_user_id?: string;
  username: string;
  password?: string;
  name: string;
  role: UserRole;
  team_id?: string;
  teamId?: string;
  jury_id?: string;
  juryId?: string;
  is_active?: boolean;
  created_at?: string;
  createdAt?: string;
  updated_at?: string;
}

export interface StudentEntity {
  id: string;
  chaseNumber: string;
  name: string;
  gender: string;
  dateOfBirth?: string;
  section: string;
  teamId: string;
  phone?: string;
  className?: string;
  schoolName?: string;
  photo?: string;
  qrCode?: string;
  createdAt?: string;
  updatedAt?: string;
}

export interface TeamEntity {
  id: string;
  teamName: string;
  teamCode: string;
  leaderId?: string;
  leaderName?: string;
  mentorName?: string;
  assistantLeaderName?: string;
  section?: string;
  logo?: string;
  totalStudents?: number;
  totalPoints?: number;
  rank?: number;
  gradeA?: number;
  gradeB?: number;
  gradeC?: number;
  firstPlaces?: number;
  secondPlaces?: number;
  thirdPlaces?: number;
  status?: string;
  createdAt?: string;
  updatedAt?: string;
}

export interface TeamLeaderEntity {
  id: string;
  name: string;
  phone?: string;
  email?: string;
  username: string;
  password?: string;
  teamId?: string;
}

export interface ProgramEntity {
  id: string;
  programCode: string;
  programName: string;
  section: string;
  category: string;
  isStageProgram?: boolean;
  isGeneral?: boolean;
  maxParticipants?: number;
  duration?: string;
  venueId?: string;
  scheduleId?: string;
  rules?: string;
  status?: string;
}

export interface RegistrationEntity {
  id: string;
  studentId: string;
  programId: string;
  teamId: string;
  registrationNumber: string;
  status: string;
  createdAt?: string;
}

export interface ResultEntity {
  id: string;
  programId: string;
  studentId: string;
  teamId: string;
  juryId?: string;
  marks?: number;
  grade?: string;
  position?: number;
  points?: number;
  remarks?: string;
  status: string;
  createdAt?: string;
  updatedAt?: string;
  publishedAt?: string;
}

export interface VenueEntity {
  id: string;
  name: string;
  location?: string;
  capacity?: number;
  description?: string;
}

export interface ScheduleEntity {
  id: string;
  programId: string;
  venueId: string;
  date?: string;
  startTime?: string;
  endTime?: string;
  status?: string;
}

export interface JuryEntity {
  id: string;
  name: string;
  username: string;
  password?: string;
  juryCode: string;
  assignedPrograms?: string[];
  status?: string;
}

export interface AnnouncementEntity {
  id: string;
  programId?: string;
  resultId?: string;
  title: string;
  message: string;
  status?: string;
  createdAt?: string;
  announcedAt?: string;
}

export interface TvSettingsEntity {
  id: string;
  scrollSpeed?: number;
  autoRefreshSeconds?: number;
  theme?: string;
  showTopTeamsCount?: number;
  activeAnnouncementId?: string;
}

export interface AuditLogEntity {
  id: string;
  action: string;
  details?: string;
  timestamp?: string;
  performedBy?: string;
}
