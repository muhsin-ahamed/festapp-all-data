import 'package:flutter_test/flutter_test.dart';
import 'package:amia_fest/data/models/team_model.dart';

void main() {
  group('Team Leader Name Unit Tests', () {
    test('Team model stores and serializes leaderName correctly', () {
      final team = Team(
        id: 'team_1',
        teamName: 'Thunder Tigers',
        teamCode: 'T-THUNDER',
        leaderId: 'leader_1',
        leaderName: 'John Doe',
      );

      expect(team.leaderName, equals('John Doe'));

      final map = team.toMap();
      expect(map['leaderName'], equals('John Doe'));

      final deserialized = Team.fromMap(map);
      expect(deserialized.id, equals('team_1'));
      expect(deserialized.teamName, equals('Thunder Tigers'));
      expect(deserialized.teamCode, equals('T-THUNDER'));
      expect(deserialized.leaderName, equals('John Doe'));
    });

    test('Team copyWith updates leaderName correctly', () {
      final team = Team(
        id: 'team_1',
        teamName: 'Thunder Tigers',
        teamCode: 'T-THUNDER',
        leaderName: 'John Doe',
      );

      final updatedTeam = team.copyWith(leaderName: 'Jane Smith');
      expect(updatedTeam.leaderName, equals('Jane Smith'));
      expect(updatedTeam.teamName, equals('Thunder Tigers'));
    });
  });
}
