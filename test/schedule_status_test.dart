import 'package:flutter_test/flutter_test.dart';
import 'package:amia_fest/data/models/schedule_model.dart';
import 'package:amia_fest/features/public/scan_and_qr_screen.dart';

void main() {
  group('ScheduleStatusHelper Unit Tests', () {
    final fixedNow = DateTime(2026, 9, 9, 14, 30); // 2026-09-09 14:30

    test('Returns COMPLETED when schedule date is in the past', () {
      final sch = Schedule(
        id: 'sch_1',
        programId: 'prog_1',
        venueId: 'v_1',
        date: '2026-09-05',
        startTime: '09:00',
        endTime: '11:00',
      );

      final status = ScheduleStatusHelper.getStatus(
        schedule: sch,
        currentTime: fixedNow,
      );
      expect(status, equals(ScheduleDisplayStatus.completed));
    });

    test('Returns COMPLETED when schedule is today but end time has passed', () {
      final sch = Schedule(
        id: 'sch_2',
        programId: 'prog_2',
        venueId: 'v_1',
        date: '2026-09-09',
        startTime: '10:00',
        endTime: '12:00',
      );

      final status = ScheduleStatusHelper.getStatus(
        schedule: sch,
        currentTime: fixedNow,
      );
      expect(status, equals(ScheduleDisplayStatus.completed));
    });

    test('Returns ON TIME when schedule is today and current time is within slot', () {
      final sch = Schedule(
        id: 'sch_3',
        programId: 'prog_3',
        venueId: 'v_1',
        date: '2026-09-09',
        startTime: '14:00',
        endTime: '15:30',
      );

      final status = ScheduleStatusHelper.getStatus(
        schedule: sch,
        currentTime: fixedNow,
      );
      expect(status, equals(ScheduleDisplayStatus.onTime));
    });

    test('Returns UPCOMING when schedule is today but start time is in future', () {
      final sch = Schedule(
        id: 'sch_4',
        programId: 'prog_4',
        venueId: 'v_1',
        date: '2026-09-09',
        startTime: '16:00',
        endTime: '18:00',
      );

      final status = ScheduleStatusHelper.getStatus(
        schedule: sch,
        currentTime: fixedNow,
      );
      expect(status, equals(ScheduleDisplayStatus.upcoming));
    });

    test('Returns UPCOMING when schedule date is in the future', () {
      final sch = Schedule(
        id: 'sch_5',
        programId: 'prog_5',
        venueId: 'v_1',
        date: '2026-09-15',
        startTime: '09:00',
        endTime: '11:00',
      );

      final status = ScheduleStatusHelper.getStatus(
        schedule: sch,
        currentTime: fixedNow,
      );
      expect(status, equals(ScheduleDisplayStatus.upcoming));
    });

    test('Returns UPCOMING when schedule is null', () {
      final status = ScheduleStatusHelper.getStatus(
        schedule: null,
        currentTime: fixedNow,
      );
      expect(status, equals(ScheduleDisplayStatus.upcoming));
    });

    test('Returns COMPLETED when results are already published', () {
      final sch = Schedule(
        id: 'sch_6',
        programId: 'prog_6',
        venueId: 'v_1',
        date: '2026-09-15',
        startTime: '09:00',
        endTime: '11:00',
      );

      final status = ScheduleStatusHelper.getStatus(
        schedule: sch,
        hasPublishedResult: true,
        currentTime: fixedNow,
      );
      expect(status, equals(ScheduleDisplayStatus.completed));
    });

    test('Returns COMPLETED when schedule status is explicitly COMPLETED', () {
      final sch = Schedule(
        id: 'sch_7',
        programId: 'prog_7',
        venueId: 'v_1',
        date: '2026-09-15',
        startTime: '09:00',
        endTime: '11:00',
        status: 'COMPLETED',
      );

      final status = ScheduleStatusHelper.getStatus(
        schedule: sch,
        currentTime: fixedNow,
      );
      expect(status, equals(ScheduleDisplayStatus.completed));
    });

    test('Returns ON TIME when schedule status is explicitly IN_PROGRESS', () {
      final sch = Schedule(
        id: 'sch_8',
        programId: 'prog_8',
        venueId: 'v_1',
        date: '2026-09-15',
        startTime: '09:00',
        endTime: '11:00',
        status: 'IN_PROGRESS',
      );

      final status = ScheduleStatusHelper.getStatus(
        schedule: sch,
        currentTime: fixedNow,
      );
      expect(status, equals(ScheduleDisplayStatus.onTime));
    });

    test('Handles 12-hour AM/PM time strings correctly', () {
      final sch = Schedule(
        id: 'sch_9',
        programId: 'prog_9',
        venueId: 'v_1',
        date: '2026-09-09',
        startTime: '02:00 PM',
        endTime: '03:00 PM',
      );

      final status = ScheduleStatusHelper.getStatus(
        schedule: sch,
        currentTime: fixedNow,
      );
      expect(status, equals(ScheduleDisplayStatus.onTime));
    });

    test('Handles DD-MM-YYYY date format correctly', () {
      final sch = Schedule(
        id: 'sch_10',
        programId: 'prog_10',
        venueId: 'v_1',
        date: '05-09-2026',
        startTime: '09:00',
        endTime: '10:00',
      );

      final status = ScheduleStatusHelper.getStatus(
        schedule: sch,
        currentTime: fixedNow,
      );
      expect(status, equals(ScheduleDisplayStatus.completed));
    });
  });
}
