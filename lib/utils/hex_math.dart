import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 六角形の座標を表すクラス（アキシャル座標系）
class HexCoordinate {
  final int q; // 列座標
  final int r; // 行座標

  const HexCoordinate(this.q, this.r);

  /// キューブ座標のs成分を取得
  int get s => -q - r;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HexCoordinate &&
          runtimeType == other.runtimeType &&
          q == other.q &&
          r == other.r;

  @override
  int get hashCode => q.hashCode ^ r.hashCode;

  @override
  String toString() => 'HexCoordinate($q, $r)';

  /// 隣接する六角形の座標を取得
  static const List<HexCoordinate> directions = [
    HexCoordinate(1, 0),
    HexCoordinate(1, -1),
    HexCoordinate(0, -1),
    HexCoordinate(-1, 0),
    HexCoordinate(-1, 1),
    HexCoordinate(0, 1),
  ];

  /// 指定された方向の隣接する六角形を取得
  HexCoordinate neighbor(int direction) {
    final dir = directions[direction % 6];
    return HexCoordinate(q + dir.q, r + dir.r);
  }

  /// 全ての隣接する六角形を取得
  List<HexCoordinate> get neighbors {
    return directions.map((dir) => HexCoordinate(q + dir.q, r + dir.r)).toList();
  }

  /// 2つの六角形間の距離を計算
  int distanceTo(HexCoordinate other) {
    return ((q - other.q).abs() + (r - other.r).abs() + (s - other.s).abs()) ~/ 2;
  }
}

/// 六角形の向き
enum HexOrientation {
  /// フラットトップ（上下が平らな六角形）
  flatTop,
  /// ポイントトップ（上下が尖った六角形）
  pointyTop,
}

/// 六角形のレイアウト情報
class HexLayout {
  final HexOrientation orientation;
  final double size; // 六角形のサイズ（中心から頂点までの距離）
  final Offset origin; // 原点の画面座標

  const HexLayout({
    required this.orientation,
    required this.size,
    this.origin = Offset.zero,
  });

  /// 六角形の幅を取得
  double get width {
    return orientation == HexOrientation.flatTop
        ? size * 2
        : size * math.sqrt(3);
  }

  /// 六角形の高さを取得
  double get height {
    return orientation == HexOrientation.flatTop
        ? size * math.sqrt(3)
        : size * 2;
  }

  /// 六角形の座標からピクセル座標への変換
  Offset hexToPixel(HexCoordinate hex) {
    final double x;
    final double y;

    if (orientation == HexOrientation.flatTop) {
      x = size * (3.0 / 2.0 * hex.q);
      y = size * (math.sqrt(3) / 2.0 * hex.q + math.sqrt(3) * hex.r);
    } else {
      // PointyTop
      x = size * (math.sqrt(3) * hex.q + math.sqrt(3) / 2.0 * hex.r);
      y = size * (3.0 / 2.0 * hex.r);
    }

    return Offset(x + origin.dx, y + origin.dy);
  }

  /// ピクセル座標から六角形の座標への変換
  HexCoordinate pixelToHex(Offset point) {
    final pt = Offset(point.dx - origin.dx, point.dy - origin.dy);
    final double q;
    final double r;

    if (orientation == HexOrientation.flatTop) {
      q = (2.0 / 3.0 * pt.dx) / size;
      r = (-1.0 / 3.0 * pt.dx + math.sqrt(3) / 3.0 * pt.dy) / size;
    } else {
      // PointyTop
      q = (math.sqrt(3) / 3.0 * pt.dx - 1.0 / 3.0 * pt.dy) / size;
      r = (2.0 / 3.0 * pt.dy) / size;
    }

    return _roundHex(q, r);
  }

  /// 六角形の角の位置を取得（0-5、時計回り）
  Offset hexCorner(HexCoordinate hex, int corner) {
    final center = hexToPixel(hex);
    final angleDeg = orientation == HexOrientation.flatTop
        ? 60.0 * corner
        : 60.0 * corner - 30.0;
    final angleRad = math.pi / 180.0 * angleDeg;

    return Offset(
      center.dx + size * math.cos(angleRad),
      center.dy + size * math.sin(angleRad),
    );
  }

  /// 六角形の全ての角の位置を取得
  List<Offset> hexCorners(HexCoordinate hex) {
    return List.generate(6, (i) => hexCorner(hex, i));
  }

  /// 六角形の頂点ID（3つの六角形が交わる点）
  /// 頂点は六角形の角（0-5）で識別される
  static String getVertexId(HexCoordinate hex, int corner) {
    // 頂点は複数の六角形で共有されるため、正規化した座標で識別
    // corner 0: 右上
    // corner 1: 右
    // corner 2: 右下
    // corner 3: 左下
    // corner 4: 左
    // corner 5: 左上
    final normalized = _normalizeVertex(hex, corner);
    return 'v_${normalized.$1.q}_${normalized.$1.r}_${normalized.$2}';
  }

  /// 六角形の辺ID（2つの六角形が共有する辺）
  /// 辺は六角形の辺（0-5）で識別される
  static String getEdgeId(HexCoordinate hex, int edge) {
    // 辺は2つの六角形で共有されるため、正規化した座標で識別
    final normalized = _normalizeEdge(hex, edge);
    return 'e_${normalized.$1.q}_${normalized.$1.r}_${normalized.$2}';
  }

  /// 頂点座標を正規化（同じ頂点を同じIDで識別するため）
  static (HexCoordinate, int) _normalizeVertex(HexCoordinate hex, int corner) {
    // 最も小さいq座標、次にr座標を持つ六角形のコーナーとして表現
    final coords = [
      (hex, corner),
      (hex.neighbor(corner), (corner + 4) % 6),
      (hex.neighbor((corner + 5) % 6), (corner + 2) % 6),
    ];

    coords.sort((a, b) {
      if (a.$1.q != b.$1.q) return a.$1.q.compareTo(b.$1.q);
      if (a.$1.r != b.$1.r) return a.$1.r.compareTo(b.$1.r);
      return a.$2.compareTo(b.$2);
    });

    return coords.first;
  }

  /// 辺座標を正規化
  static (HexCoordinate, int) _normalizeEdge(HexCoordinate hex, int edge) {
    // 隣接する六角形との辺を、小さい座標を持つ方で表現
    final neighbor = hex.neighbor(edge);
    final oppositeEdge = (edge + 3) % 6;

    if (hex.q < neighbor.q || (hex.q == neighbor.q && hex.r < neighbor.r)) {
      return (hex, edge);
    } else {
      return (neighbor, oppositeEdge);
    }
  }

  /// 六角形の浮動小数点座標を整数座標に丸める
  static HexCoordinate _roundHex(double q, double r) {
    final s = -q - r;

    int rq = q.round();
    int rr = r.round();
    int rs = s.round();

    final qDiff = (rq - q).abs();
    final rDiff = (rr - r).abs();
    final sDiff = (rs - s).abs();

    if (qDiff > rDiff && qDiff > sDiff) {
      rq = -rr - rs;
    } else if (rDiff > sDiff) {
      rr = -rq - rs;
    }

    return HexCoordinate(rq, rr);
  }
}

/// カタンの標準ボードレイアウトを生成
class CatanBoardLayout {
  /// 標準的な19タイルのカタンボードの六角形座標を取得
  static List<HexCoordinate> getStandardBoard() {
    final List<HexCoordinate> tiles = [];

    // カタンの標準ボードは中心からの距離が2以内の六角形
    for (int q = -2; q <= 2; q++) {
      final r1 = math.max(-2, -q - 2);
      final r2 = math.min(2, -q + 2);
      for (int r = r1; r <= r2; r++) {
        tiles.add(HexCoordinate(q, r));
      }
    }

    return tiles;
  }

  /// 拡張ボード（5-6人用）の六角形座標を取得
  static List<HexCoordinate> getExpandedBoard() {
    final List<HexCoordinate> tiles = [];

    // 5-6人用の拡張ボードは距離が3以内
    for (int q = -3; q <= 3; q++) {
      final r1 = math.max(-3, -q - 3);
      final r2 = math.min(3, -q + 3);
      for (int r = r1; r <= r2; r++) {
        tiles.add(HexCoordinate(q, r));
      }
    }

    return tiles;
  }
}
