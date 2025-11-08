/// 盗賊（Robber）
/// - 盗賊がいるタイルは資源を生産しない
/// - 7が出たら盗賊を移動し、対象プレイヤーから資源を1枚奪う
class Robber {
  /// 現在盗賊がいるタイルのID
  String currentHexId;

  Robber({
    required this.currentHexId,
  });

  /// 盗賊を移動
  void moveTo(String hexId) {
    currentHexId = hexId;
  }

  /// コピーを作成
  Robber copyWith({
    String? currentHexId,
  }) {
    return Robber(
      currentHexId: currentHexId ?? this.currentHexId,
    );
  }

  @override
  String toString() => 'Robber(currentHexId: $currentHexId)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Robber &&
          runtimeType == other.runtimeType &&
          currentHexId == other.currentHexId;

  @override
  int get hashCode => currentHexId.hashCode;
}
