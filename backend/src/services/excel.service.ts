import * as XLSX from 'xlsx';
import { StudentRepository } from '../repositories/student.repository';
import { TeamRepository } from '../repositories/team.repository';
import { ProgramRepository } from '../repositories/program.repository';
import { RegistrationRepository } from '../repositories/registration.repository';
import { AuditService } from './audit.service';
import { StudentEntity, RegistrationEntity, ProgramEntity } from '../types';

export class ExcelService {
  private studentRepo = new StudentRepository();
  private teamRepo = new TeamRepository();
  private programRepo = new ProgramRepository();
  private registrationRepo = new RegistrationRepository();
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

  async importRegistrationsFromBuffer(
    buffer: Buffer,
    performedBy?: string
  ): Promise<{ totalRows: number; inserted: number; skipped: number; failed: number; errors: string[] }> {
    const workbook = XLSX.read(buffer, { type: 'buffer' });
    const sheetName = workbook.SheetNames[0];
    const sheet = workbook.Sheets[sheetName];
    const rows: any[] = XLSX.utils.sheet_to_json(sheet);

    let inserted = 0;
    let skipped = 0;
    let failed = 0;
    const errors: string[] = [];

    const existingStudents = await this.studentRepo.findAll();
    const studentMap: Record<string, StudentEntity> = {};
    for (const s of existingStudents) {
      studentMap[s.chaseNumber.trim().toLowerCase()] = s;
    }

    const existingPrograms = await this.programRepo.findAll();
    const programMap: Record<string, ProgramEntity> = {};
    for (const p of existingPrograms) {
      programMap[p.programName.trim().toLowerCase()] = p;
    }

    const existingRegistrations = await this.registrationRepo.findAll();
    const regSet = new Set<string>();
    for (const r of existingRegistrations) {
      regSet.add(`${r.studentId}_${r.programId}`);
    }

    const teams = await this.teamRepo.findAll();
    const defaultTeamId = teams[0]?.id || 'team_01';

    for (let i = 0; i < rows.length; i++) {
      const row = rows[i];
      const rowNum = i + 2;

      let chaseNumber = '';
      let name = '';
      let progName = '';
      let sectionStr = '';

      for (const k of Object.keys(row)) {
        const cleanK = k.trim().toLowerCase();
        const val = String(row[k] || '').trim();
        if (cleanK.includes('chse') || cleanK.includes('chase') || cleanK.includes('chest') || cleanK.includes('ches')) {
          chaseNumber = val;
        } else if (cleanK.includes('name') || cleanK.includes('student')) {
          name = val;
        } else if (cleanK.includes('prog')) {
          progName = val;
        } else if (cleanK.includes('sec') || cleanK.includes('setion') || cleanK.includes('section') || cleanK.includes('category')) {
          sectionStr = val;
        }
      }

      if (!chaseNumber || !progName) {
        failed++;
        errors.push(`Row ${rowNum}: Missing chase number or program name`);
        continue;
      }

      let section = 'SUB_JUNIOR';
      const cleanSec = sectionStr.trim().toLowerCase().replace(/[\s\-_]/g, '');
      const cleanChase = chaseNumber.trim().toUpperCase();
      if (cleanChase.startsWith('SS') || cleanChase.startsWith('SUP') || cleanSec.includes('super')) {
        section = 'SUPER_SENIOR';
      } else if (cleanChase.startsWith('SR') || cleanChase.startsWith('SN') || cleanSec.includes('senior')) {
        section = 'SENIOR';
      } else if (cleanChase.startsWith('GRP') || cleanSec.includes('group')) {
        section = 'GROUP';
      } else if (cleanChase.startsWith('GEN') || cleanSec.includes('general')) {
        section = 'GENERAL';
      } else {
        section = 'SUB_JUNIOR';
      }

      try {
        let student = studentMap[chaseNumber.toLowerCase()];
        if (!student) {
          const sId = `std_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
          student = {
            id: sId,
            chaseNumber,
            name: name || `Student ${chaseNumber}`,
            gender: 'Male',
            section,
            teamId: defaultTeamId,
            phone: '',
            className: '',
            schoolName: '',
            qrCode: chaseNumber,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
          };
          await this.studentRepo.create(student);
          studentMap[chaseNumber.toLowerCase()] = student;
        } else if (name && (student.name.startsWith('Student ') || !student.name)) {
          student.name = name;
          await this.studentRepo.update(student.id, { name, updatedAt: new Date().toISOString() });
        }

        let program = programMap[progName.toLowerCase()];
        if (!program) {
          const pId = `prog_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
          const codeClean = progName.replace(/[^a-zA-Z0-9]/g, '').toUpperCase();
          const pCode = `P${codeClean.substring(0, 4) || 'PROG'}-${Date.now().toString().slice(-4)}`;
          program = {
            id: pId,
            programCode: pCode,
            programName: progName,
            section,
            category: 'STAGE',
            isStageProgram: true,
            isGeneral: false,
            maxParticipants: 1,
            duration: '10 min',
            status: 'UPCOMING',
          };
          await this.programRepo.create(program);
          programMap[progName.toLowerCase()] = program;
        }

        const comboKey = `${student.id}_${program.id}`;
        if (regSet.has(comboKey)) {
          skipped++;
          continue;
        }

        const regId = `reg_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
        const regNumber = `REG-${student.chaseNumber}-${program.programCode}`;
        const newReg: RegistrationEntity = {
          id: regId,
          studentId: student.id,
          programId: program.id,
          teamId: student.teamId || defaultTeamId,
          registrationNumber: regNumber,
          status: 'APPROVED',
          createdAt: new Date().toISOString(),
        };

        await this.registrationRepo.create(newReg);
        regSet.add(comboKey);
        inserted++;
      } catch (err: any) {
        failed++;
        errors.push(`Row ${rowNum}: ${err.message || 'Error processing registration'}`);
      }
    }

    await this.auditService.logAction(
      'IMPORT_REGISTRATIONS',
      performedBy,
      `Imported Registrations Excel: ${inserted} registered, ${skipped} skipped duplicates, ${failed} failed out of ${rows.length} rows`
    );

    return {
      totalRows: rows.length,
      inserted,
      skipped,
      failed,
      errors,
    };
  }

  generateRegistrationTemplateBuffer(): Buffer {
    const templateRows = [
      {
        'chse no': 'SB7882',
        name: 'JIYAN',
        program: 'QIRATH',
        setion: 'SUB JUNOR',
      },
      {
        'chse no': 'SB7165',
        name: 'SAEED ALI',
        program: 'QIRATH',
        setion: 'SUB JUNOR',
      },
    ];

    const worksheet = XLSX.utils.json_to_sheet(templateRows);
    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Registrations');

    return XLSX.write(workbook, { type: 'buffer', bookType: 'xlsx' });
  }
}
