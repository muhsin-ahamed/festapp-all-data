import { supabase } from '../config/supabase';
import { UserEntity } from '../types';

function normalizeUser(u: any): UserEntity {
  if (!u) return u;
  return {
    ...u,
    teamId: u.teamId || u.team_id,
    team_id: u.team_id || u.teamId,
    juryId: u.juryId || u.jury_id,
    jury_id: u.jury_id || u.juryId,
    is_active: u.is_active !== undefined ? u.is_active : true,
    auth_user_id: u.auth_user_id,
  };
}

export class UserRepository {
  private table = 'users';
  private inMemoryUsers: Map<string, UserEntity> = new Map();

  async findAll(): Promise<UserEntity[]> {
    try {
      const { data, error } = await supabase.from(this.table).select('*');
      if (!error && data) {
        for (const u of data) {
          const norm = normalizeUser(u);
          this.inMemoryUsers.set(norm.username.toLowerCase(), norm);
        }
        return data.map(normalizeUser);
      }
    } catch (_) {}
    return Array.from(this.inMemoryUsers.values());
  }

  async findById(id: string): Promise<UserEntity | null> {
    try {
      const { data, error } = await supabase.from(this.table).select('*').eq('id', id).maybeSingle();
      if (!error && data) return normalizeUser(data);
    } catch (_) {}
    for (const u of this.inMemoryUsers.values()) {
      if (u.id === id) return u;
    }
    return null;
  }

  async findByUsername(username: string): Promise<UserEntity | null> {
    const cleanUser = username.trim().toLowerCase();
    try {
      const { data, error } = await supabase.from(this.table).select('*').ilike('username', cleanUser).maybeSingle();
      if (!error && data) {
        const norm = normalizeUser(data);
        this.inMemoryUsers.set(cleanUser, norm);
        return norm;
      }
    } catch (_) {}
    return this.inMemoryUsers.get(cleanUser) || null;
  }

  async create(user: UserEntity): Promise<UserEntity> {
    const norm = normalizeUser(user);
    this.inMemoryUsers.set(norm.username.toLowerCase(), norm);
    try {
      const { data, error } = await supabase.from(this.table).upsert([norm]).select().single();
      if (!error && data) return normalizeUser(data);
    } catch (_) {}
    return norm;
  }

  async update(id: string, user: Partial<UserEntity>): Promise<UserEntity> {
    let existing = await this.findById(id);
    const updated = normalizeUser({ ...existing, ...user });
    if (updated.username) {
      this.inMemoryUsers.set(updated.username.toLowerCase(), updated);
    }
    try {
      const { data, error } = await supabase.from(this.table).update(user).eq('id', id).select().single();
      if (!error && data) return normalizeUser(data);
    } catch (_) {}
    return updated;
  }

  async delete(id: string): Promise<void> {
    const existing = await this.findById(id);
    if (existing) {
      this.inMemoryUsers.delete(existing.username.toLowerCase());
    }
    try {
      await supabase.from(this.table).delete().eq('id', id);
    } catch (_) {}
  }
}
