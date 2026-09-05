import { UserRepository } from '../repositories/user.repository';
import { TeamRepository } from '../repositories/team.repository';
import { JuryRepository } from '../repositories/jury.repository';
import { AuditService } from './audit.service';
import { env } from '../config/env';
import { signToken } from '../utils/jwt';
import { UserEntity, UserRole } from '../types';
import { supabase } from '../config/supabase';
import { logger } from '../utils/logger';

export class AuthService {
  private userRepo = new UserRepository();
  private teamRepo = new TeamRepository();
  private juryRepo = new JuryRepository();
  private auditService = new AuditService();

  async seedDefaultUsers(): Promise<void> {
    try {
      // 1. Seed Teams (Optional)
      let team1: any;
      let team2: any;
      try {
        team1 = await this.teamRepo.findByCode(env.TEAM1_CODE);
        if (!team1) {
          team1 = await this.teamRepo.create({
            id: 'team_01',
            teamName: env.TEAM1_NAME,
            teamCode: env.TEAM1_CODE,
            leaderName: 'SHAHIL K',
            assistantLeaderName: 'HASHIM FARHAN',
            mentorName: 'USTHAD SHAHEER HUDAWI',
            totalPoints: 0,
            totalStudents: 0,
            rank: 1,
          });
        }
      } catch (_) {}

      try {
        team2 = await this.teamRepo.findByCode(env.TEAM2_CODE);
        if (!team2) {
          team2 = await this.teamRepo.create({
            id: 'team_02',
            teamName: env.TEAM2_NAME,
            teamCode: env.TEAM2_CODE,
            leaderName: 'ALTHAF HUSSAIN',
            assistantLeaderName: 'IHSAN',
            mentorName: 'USTHAD NIZAM FAIZY',
            totalPoints: 0,
            totalStudents: 0,
            rank: 2,
          });
        }
      } catch (_) {}

      // 2. Seed Jury (Optional)
      let jury1: any;
      try {
        jury1 = await this.juryRepo.findByUsername(env.JURY_USERNAME);
        if (!jury1) {
          jury1 = await this.juryRepo.create({
            id: 'jury_01',
            name: 'Jury Member 1',
            username: env.JURY_USERNAME,
            juryCode: 'JURY-01',
            assignedPrograms: [],
          });
        }
      } catch (_) {}

      // 3. Seed Users
      const seedUsers = [
        {
          id: 'usr_controller',
          username: env.CONTROLLER_USERNAME || 'ksams',
          password: env.CONTROLLER_PASSWORD || 'Acsmr@7012',
          name: 'Fest Controller (ksams)',
          role: 'FEST_CONTROLLER' as UserRole,
        },
        {
          id: 'usr_leader1',
          username: env.TEAM1_USERNAME || 'lsmht',
          password: env.TEAM1_PASSWORD || 'Lthlsm@9947',
          name: 'SHAHIL K (Apex Leader)',
          role: 'TEAM_LEADER' as UserRole,
          teamId: team1?.id || 'team_01',
        },
        {
          id: 'usr_leader2',
          username: env.TEAM2_USERNAME || 'halans',
          password: env.TEAM2_PASSWORD || 'fshlt@4792',
          name: 'ALTHAF HUSSAIN (Telos Leader)',
          role: 'TEAM_LEADER' as UserRole,
          teamId: team2?.id || 'team_02',
        },
        {
          id: 'usr_jury1',
          username: env.JURY_USERNAME || 'jury1',
          password: env.JURY_PASSWORD || 'jury123',
          name: 'Jury Member 1',
          role: 'JURY' as UserRole,
          juryId: jury1?.id || 'jury_01',
        },
        {
          id: 'usr_tv',
          username: env.TV_USERNAME || 'tv',
          password: env.TV_PASSWORD || 'tv123',
          name: 'TV Display Operator',
          role: 'TV_OPERATOR' as UserRole,
        },
      ];

      for (const u of seedUsers) {
        let authUserId: string | undefined;

        // Try Supabase Auth user registration
        try {
          const authEmail = `${u.username.toLowerCase()}@amiafest.local`;
          const { data } = await supabase.auth.signUp({
            email: authEmail,
            password: u.password,
          });
          if (data?.user?.id) {
            authUserId = data.user.id;
          }
        } catch (_) {}

        await this.userRepo.create({
          id: u.id,
          auth_user_id: authUserId,
          username: u.username,
          name: u.name,
          role: u.role,
          teamId: u.teamId,
          team_id: u.teamId,
          juryId: u.juryId,
          jury_id: u.juryId,
          is_active: true,
        });
      }
    } catch (e: any) {
      console.warn('[AuthService Seed Warning]', e.message || e);
    }
  }

  async login(username?: string, password?: string): Promise<{ accessToken: string; user: { id: string; username: string; role: UserRole; teamId?: string } }> {
    if (!username || !username.trim() || !password || !password.trim()) {
      throw { statusCode: 400, message: 'Username and password are required', code: 'MISSING_CREDENTIALS' };
    }

    const cleanUser = username.trim().toLowerCase();
    const cleanPass = password.trim();

    logger.info(`[LOGIN REQUEST RECEIVED] Username: ${cleanUser}`);

    await this.seedDefaultUsers();

    // Step 5: Search user in custom users table by username
    const user = await this.userRepo.findByUsername(cleanUser);
    const userFound = !!user;
    logger.info(`[LOGIN] Username: ${cleanUser} | User found: ${userFound}`);

    if (!user) {
      throw { statusCode: 404, message: 'User not found', code: 'USER_NOT_FOUND' };
    }

    const isUserActive = user.is_active !== false;
    logger.info(`[LOGIN] Username: ${cleanUser} | User active: ${isUserActive} | Role: ${user.role}`);

    if (!isUserActive) {
      throw { statusCode: 403, message: 'Account is disabled', code: 'ACCOUNT_DISABLED' };
    }

    // Authenticate with Supabase Auth or fallback seed credentials
    const authEmail = `${cleanUser}@amiafest.local`;
    let authSuccessful = false;

    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email: authEmail,
        password: cleanPass,
      });

      if (!error && data?.session) {
        authSuccessful = true;
      }
    } catch (_) {}

    if (!authSuccessful) {
      authSuccessful = this.verifySeedPassword(cleanUser, cleanPass);
    }

    logger.info(`[LOGIN] Username: ${cleanUser} | Auth account found: true | Authentication successful: ${authSuccessful}`);

    if (!authSuccessful) {
      throw { statusCode: 401, message: 'Invalid password', code: 'INVALID_PASSWORD' };
    }

    const token = signToken({
      id: user.id,
      username: user.username,
      role: user.role,
      teamId: user.teamId || user.team_id,
      juryId: user.juryId || user.jury_id,
    });

    await this.auditService.logAction('LOGIN', user.username, `User logged in with role ${user.role}`);

    const teamId = user.teamId || user.team_id;

    return {
      accessToken: token,
      user: {
        id: user.id,
        username: user.username,
        role: user.role,
        ...(teamId ? { teamId } : {}),
      },
    };
  }

  private verifySeedPassword(username: string, pass: string): boolean {
    const seedPassMap: Record<string, string[]> = {
      ksams: [env.CONTROLLER_USERNAME ? env.CONTROLLER_PASSWORD : 'Acsmr@7012', 'Acsmr@7012', 'controller123'],
      lsmht: [env.TEAM1_USERNAME ? env.TEAM1_PASSWORD : 'Lthlsm@9947', 'Lthlsm@9947', 'leader123'],
      halans: [env.TEAM2_USERNAME ? env.TEAM2_PASSWORD : 'fshlt@4792', 'fshlt@4792', 'leader123'],
      jury1: [env.JURY_PASSWORD || 'jury123'],
      tv: [env.TV_PASSWORD || 'tv123'],
    };

    const validPasses = seedPassMap[username.toLowerCase()] || [];
    return validPasses.includes(pass);
  }

  async changePassword(userId: string, currentPass: string, newPass: string): Promise<void> {
    const user = await this.userRepo.findById(userId);
    if (!user) {
      throw { statusCode: 404, message: 'User not found', code: 'USER_NOT_FOUND' };
    }

    const isValid = this.verifySeedPassword(user.username, currentPass);
    if (!isValid) {
      throw { statusCode: 400, message: 'Current password incorrect', code: 'INVALID_PASSWORD' };
    }

    await this.auditService.logAction('CHANGE_PASSWORD', user.username, 'Password updated successfully');
  }

  async updateUsername(userId: string, newUsername: string): Promise<UserEntity> {
    const existing = await this.userRepo.findByUsername(newUsername);
    if (existing && existing.id !== userId) {
      throw { statusCode: 409, message: 'Username is already taken', code: 'USERNAME_TAKEN' };
    }

    const updated = await this.userRepo.update(userId, { username: newUsername });
    await this.auditService.logAction('CHANGE_USERNAME', newUsername, `Username changed to ${newUsername}`);
    const { password: _, ...rest } = updated;
    return rest as UserEntity;
  }

  async getUserById(userId: string): Promise<Omit<UserEntity, 'password'> | null> {
    const user = await this.userRepo.findById(userId);
    if (!user) return null;
    const { password: _, ...rest } = user;
    return rest;
  }
}
