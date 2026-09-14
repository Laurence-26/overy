import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/models/cycle.dart';
import 'package:period_tracker/models/cycle_prediction.dart';
import 'package:period_tracker/models/daily_log.dart';
import 'package:period_tracker/services/prediction_engine.dart';

void main() {
  DateTime d(int y, int m, int day) => DateTime(y, m, day);

  test('returns null when there are no cycles', () {
    expect(
      PredictionEngine.predict(
        cyclesNewestFirst: const [],
        fallbackCycleLength: 28,
        fallbackPeriodLength: 5,
      ),
      isNull,
    );
  });

  test('regular 28-day history predicts next period and ovulation', () {
    final cycles = [
      Cycle(id: 'c3', startDate: d(2026, 3, 1), periodLength: 5, cycleLength: 28),
      Cycle(id: 'c2', startDate: d(2026, 2, 1), periodLength: 5, cycleLength: 28),
      Cycle(id: 'c1', startDate: d(2026, 1, 4), periodLength: 5, cycleLength: 28),
    ];
    final p = PredictionEngine.predict(
      cyclesNewestFirst: cycles,
      fallbackCycleLength: 28,
      fallbackPeriodLength: 5,
      now: d(2026, 3, 10),
    )!;
    expect(p.nextPeriodStart, d(2026, 3, 29));
    expect(p.ovulationDay, d(2026, 3, 15));
    expect(p.isIrregular, isFalse);
    expect(p.confidence, greaterThan(50));
    expect(p.averagePeriodLength, 5);
  });

  test('irregular cycles widen the window and lower confidence', () {
    final cycles = [
      Cycle(id: 'c4', startDate: d(2026, 4, 1), periodLength: 5, cycleLength: 35),
      Cycle(id: 'c3', startDate: d(2026, 3, 1), periodLength: 4, cycleLength: 22),
      Cycle(id: 'c2', startDate: d(2026, 2, 1), periodLength: 6, cycleLength: 40),
      Cycle(id: 'c1', startDate: d(2026, 1, 1), periodLength: 5, cycleLength: 24),
    ];
    final p = PredictionEngine.predict(
      cyclesNewestFirst: cycles,
      fallbackCycleLength: 28,
      fallbackPeriodLength: 5,
      userReportedIrregular: true,
      now: d(2026, 4, 5),
    )!;
    expect(p.isIrregular, isTrue);
    expect(p.latestPeriodStart.isAfter(p.earliestPeriodStart), isTrue);
  });

  test('learned luteal length from OPK logs', () {
    final cycles = [
      Cycle(id: 'c2', startDate: d(2026, 2, 1), periodLength: 5, cycleLength: 28),
      Cycle(id: 'c1', startDate: d(2026, 1, 4), periodLength: 5, cycleLength: 28),
    ];
    final logs = [
      DailyLog(date: d(2026, 1, 16), symptoms: const ['Positive OPK']),
    ];
    final p = PredictionEngine.predict(
      cyclesNewestFirst: cycles,
      fallbackCycleLength: 28,
      fallbackPeriodLength: 5,
      logs: logs,
      now: d(2026, 2, 10),
    )!;
    // Jan 4 + 28 = Feb 1, OPK Jan 16 → luteal = Feb 1 - Jan 16 = 16
    expect(p.lutealLength, 16);
  });

  test('logged period days win over predictions', () {
    final cycles = [
      Cycle(id: 'c1', startDate: d(2026, 3, 1), periodLength: 5),
    ];
    final p = PredictionEngine.predict(
      cyclesNewestFirst: cycles,
      fallbackCycleLength: 28,
      fallbackPeriodLength: 5,
      now: d(2026, 3, 10),
    );
    expect(
      PredictionEngine.phaseFor(
        day: d(2026, 3, 3),
        cyclesNewestFirst: cycles,
        prediction: p,
      ),
      CyclePhase.period,
    );
  });
}
