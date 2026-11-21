import 'dart:math' as math;

/// Lặp lại ngắt quãng theo FSRS-5 (Free Spaced Repetition Scheduler) — thuật toán
/// được huấn luyện trên hàng trăm triệu lượt ôn thật, chính xác hơn các lịch cố định.
///
/// Mỗi từ có hai số:
///  • độ bền S (stability): số ngày để khả năng nhớ lại tụt từ 100% xuống 90%;
///  • độ khó D (difficulty) từ 1 đến 10.
/// Khả năng nhớ lại sau t ngày: R = (1 + 19/81 · t / S)^-0.5.
/// Mỗi lần ôn, app hẹn lần tới đúng lúc R sắp còn 90% — lúc nhớ lại "vừa đủ khó",
/// giúp S tăng mạnh nhất. Nhớ càng chắc thì khoảng cách giãn càng xa (vài tháng,
/// vài năm), quên thì S giảm và từ quay lại ôn ngay trong ngày.
class Fsrs {
  static const w = [
    0.40255, 1.18385, 3.173, 15.69105, 7.1949, 0.5345, 1.4604, 0.0046, 1.54575, 0.1192, //
    1.01925, 1.9395, 0.11, 0.29605, 2.2698, 0.2315, 2.9898, 0.51655, 0.6621,
  ];
  static const decay = -0.5;
  static const factor = 19 / 81;

  /// Tỉ lệ nhớ mong muốn ở mỗi lần ôn.
  static const retention = 0.9;
  static const maxInterval = 36500;

  /// Mức chấm: 1 Quên · 2 Khó · 3 Nhớ · 4 Dễ.
  static const again = 1, hard = 2, good = 3, easy = 4;

  static double retrievability(double elapsedDays, double s) =>
      s <= 0 ? 0 : math.pow(1 + factor * elapsedDays / s, decay).toDouble();

  static int interval(double s) {
    final i = s / factor * (math.pow(retention, 1 / decay) - 1);
    return i.round().clamp(1, maxInterval);
  }

  static double initStability(int g) => w[g - 1];
  static double initDifficulty(int g) => (w[4] - math.exp(w[5] * (g - 1)) + 1).clamp(1.0, 10.0);

  static double nextDifficulty(double d, int g) {
    final dp = d + -w[6] * (g - 3) * (10 - d) / 9;
    return (w[7] * initDifficulty(easy) + (1 - w[7]) * dp).clamp(1.0, 10.0);
  }

  static double recallStability(double d, double s, double r, int g) {
    final hardPenalty = g == hard ? w[15] : 1.0;
    final easyBonus = g == easy ? w[16] : 1.0;
    return s *
        (1 + math.exp(w[8]) * (11 - d) * math.pow(s, -w[9]) * (math.exp(w[10] * (1 - r)) - 1) * hardPenalty * easyBonus);
  }

  static double forgetStability(double d, double s, double r) {
    final f = w[11] * math.pow(d, -w[12]) * (math.pow(s + 1, w[13]) - 1) * math.exp(w[14] * (1 - r));
    return math.min(f, s / math.exp(w[17] * w[18]));
  }

  /// Trạng thái mới sau một lần ôn. [elapsedDays] = số ngày từ lần ôn trước
  /// (null nếu từ chưa ôn bao giờ). Trả về (S, D, số ngày tới lần ôn sau; 0 = ôn lại hôm nay).
  static ({double s, double d, int days}) next(double s, double d, int? elapsedDays, int g) {
    double ns, nd;
    if (elapsedDays == null || s <= 0) {
      ns = initStability(g);
      nd = initDifficulty(g);
    } else if (elapsedDays <= 0) {
      // Ôn lại trong cùng ngày: nhớ đúng không làm từ "bền" thêm (tránh ảo tưởng
      // đã thuộc vì vừa xem xong), quên thì độ bền giảm.
      ns = g == again ? math.max(0.1, s * math.exp(w[17] * (g - 3 + w[18]))) : s;
      nd = nextDifficulty(d, g);
    } else {
      final r = retrievability(elapsedDays.toDouble(), s);
      ns = g == again ? forgetStability(d, s, r) : recallStability(d, s, r, g);
      nd = nextDifficulty(d, g);
    }
    ns = ns.clamp(0.1, maxInterval.toDouble());
    return (s: ns, d: nd, days: g == again ? 0 : interval(ns));
  }
}
