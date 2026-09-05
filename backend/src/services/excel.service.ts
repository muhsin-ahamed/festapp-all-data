import * as XLSX from 'xlsx';
import { StudentRepository } from '../repositories/student.repository';
import { TeamRepository } from '../repositories/team.repository';
import { AuditService } from './audit.service';
import { StudentEntity } from '../types';

export class ExcelService {
  private studentRepo = new StudentRepository();
  private teamRepo = new TeamRepository();
  private auditService = new AuditService();

  async importStudentsFromBuffer(
    buffer: Buffer,
    performedBy?: string
  ): Promise<{ totalRows: number; inserted: number; updated: number; failed: number; errors: string[] }> {
    const workbook = XLSX.read(buffer, { type: 'buffer' });
    const sheetName = workbook.SheetNames[0];
    const sheet = workbook.Sheets[sheetName];
    const rows: any[] = XLSX.utils.sheet_to_json(sheet);

    let inserted = 0;
    let updated = 0;
    let failed = 0;
    const errors: string[] = [];

    const teams = await this.teamRepo.findAll();
    const teamMap: Record<string, string> = {};
    for (const t of teams) {
      teamMap[t.id.toLowerCase()] = t.id;
      teamMap[t.teamCode.toLowerCase()] = t.id;
      teamMap[t.teamName.toLowerCase()] = t.id;
    }

    for (let i = 0; i < rows.length; i++) {
      const row = rows[i];
      const rowNum = i + 2; // Row index in Excel (1-indexed + header)

      const chaseNumber = String(row.chaseNumber || row.chase_number || row['Chase Number'] || '').trim();
      const name = String(row.name || row['Name'] || '').trim();
      const gender = String(row.gender || row['Gender'] || 'Male').trim();
      let section = String(row.section || row['Section'] || 'SUB_JUNIOR').trim();
      if (section.toUpperCase() === 'JUNIOR') {
        section = 'SUB_JUNIOR';
      }
      const rawTeam = String(row.teamId || row.team || row['Team'] || row['Team Code'] || '').trim().toLowerCase();

      if (!chaseNumber || !name) {
        failed++;
        errors.push(`Row ${rowNum}: Missing required fields (chaseNumber or name)`);
        continue;
      }

      const teamId = teamMap[rawTeam] || teams[0]?.id;
      if (!teamId) {
        failed++;
        errors.push(`Row ${rowNum}: Invalid team '${rawTeam}'`);
        continue;
      }

      try {
        const existing = await this.studentRepo.findByChaseNumber(chaseNumber);
        if (existing) {
          await this.studentRepo.update(existing.id, {
            name,
            gender,
            section,
            teamId,
            phone: String(row.phone || row['Phone'] || existing.phone || ''),
            className: String(row.className || row['Class'] || existing.className || ''),
            schoolName: String(row.schoolName || row['School'] || existing.schoolName || ''),
            updatedAt: new Date().toISOString(),
          });
          updated++;
        } else {
          const id = `std_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
          const newStudent: StudentEntity = {
            id,
            chaseNumber,
            name,
            gender,
            section,
            teamId,
            phone: String(row.phone || row['Phone'] || ''),
            className: String(row.className || row['Class'] || ''),
            schoolName: String(row.schoolName || row['School'] || ''),
            qrCode: chaseNumber,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
          };
          await this.studentRepo.create(newStudent);
          inserted++;
        }
      } catch (err: any) {
        failed++;
        errors.push(`Row ${rowNum}: ${err.message || 'Error processing row'}`);
      }
    }

    await this.auditService.logAction(
      'IMPORT_STUDENTS',
      performedBy,
      `Imported Excel: ${inserted} inserted, ${updated} updated, ${failed} failed out of ${rows.length} rows`
    );

    return {
      totalRows: rows.length,
      inserted,
      updated,
      failed,
      errors,
    };
  }

  async exportStudentsToBuffer(): Promise<Buffer> {
    const students = await this.studentRepo.findAll();
    const teams = await this.teamRepo.findAll();
    const teamNameMap: Record<string, string> = {};
    for (const t of teams) {
      teamNameMap[t.id] = t.teamName;
    }

    const dataRows = students.map((s) => ({
      ID: s.id,
      'Chase Number': s.chaseNumber,
      Name: s.name,
      Gender: s.gender,
      Section: s.section,
      Team: teamNameMap[s.teamId] || s.teamId,
      Phone: s.phone || '',
      Class: s.className || '',
      School: s.schoolName || '',
    }));

    const worksheet = XLSX.utils.json_to_sheet(dataRows);
    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Students');

    const buffer = XLSX.write(workbook, { type: 'buffer', bookType: 'xlsx' });
    return buffer;
  }
}
