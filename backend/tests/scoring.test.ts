import { ScoringService } from '../src/services/scoring.service';

describe('ScoringService Unit Tests', () => {
  let scoringService: ScoringService;

  beforeEach(() => {
    scoringService = new ScoringService();
  });

  test('Calculates points correctly for 1st position with Grade A', () => {
    const points = scoringService.calculateResultPoints(1, 'A');
    expect(points).toBe(15); // 10 + 5
  });

  test('Calculates points correctly for 2nd position with Grade B', () => {
    const points = scoringService.calculateResultPoints(2, 'B');
    expect(points).toBe(10); // 7 + 3
  });

  test('Calculates points correctly for 3rd position with Grade C', () => {
    const points = scoringService.calculateResultPoints(3, 'C');
    expect(points).toBe(6); // 5 + 1
  });

  test('Calculates points correctly for grade only without position', () => {
    const points = scoringService.calculateResultPoints(undefined, 'A');
    expect(points).toBe(5);
  });
});
