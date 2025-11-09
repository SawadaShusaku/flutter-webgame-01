import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// セーブデータのメタ情報
class SaveGameMetadata {
  /// セーブID（ファイル名）
  final String id;

  /// セーブ日時
  final DateTime savedAt;

  /// ゲームのターン数
  final int turnNumber;

  /// 現在のプレイヤーID
  final String currentPlayerId;

  /// プレイヤー数
  final int playerCount;

  /// 説明（オプション）
  final String? description;

  SaveGameMetadata({
    required this.id,
    required this.savedAt,
    required this.turnNumber,
    required this.currentPlayerId,
    required this.playerCount,
    this.description,
  });

  /// JSONから作成
  factory SaveGameMetadata.fromJson(Map<String, dynamic> json) {
    return SaveGameMetadata(
      id: json['id'] as String,
      savedAt: DateTime.parse(json['savedAt'] as String),
      turnNumber: json['turnNumber'] as int,
      currentPlayerId: json['currentPlayerId'] as String,
      playerCount: json['playerCount'] as int,
      description: json['description'] as String?,
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'savedAt': savedAt.toIso8601String(),
      'turnNumber': turnNumber,
      'currentPlayerId': currentPlayerId,
      'playerCount': playerCount,
      'description': description,
    };
  }

  @override
  String toString() {
    return 'SaveGameMetadata(id: $id, turn: $turnNumber, player: $currentPlayerId, saved: $savedAt)';
  }
}

/// セーブデータ
class SaveGameData {
  /// メタ情報
  final SaveGameMetadata metadata;

  /// ゲーム状態（JSON形式）
  final Map<String, dynamic> gameState;

  SaveGameData({
    required this.metadata,
    required this.gameState,
  });

  /// JSONから作成
  factory SaveGameData.fromJson(Map<String, dynamic> json) {
    return SaveGameData(
      metadata: SaveGameMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      gameState: json['gameState'] as Map<String, dynamic>,
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'metadata': metadata.toJson(),
      'gameState': gameState,
    };
  }
}

/// ゲーム状態管理サービス
///
/// 機能:
/// - ゲーム状態の保存（JSON）
/// - ゲーム状態の読み込み
/// - セーブデータ一覧管理
/// - オートセーブ機能
class GameStateManager extends ChangeNotifier {
  /// セーブディレクトリ名
  static const String saveDirectoryName = 'catan_saves';

  /// オートセーブのID
  static const String autoSaveId = 'autosave';

  /// オートセーブが有効か
  bool _autoSaveEnabled = true;

  /// オートセーブ間隔（ターン数）
  int _autoSaveInterval = 1;

  /// 最後にオートセーブしたターン
  int _lastAutoSaveTurn = -1;

  /// オートセーブが有効か
  bool get autoSaveEnabled => _autoSaveEnabled;

  /// オートセーブ間隔
  int get autoSaveInterval => _autoSaveInterval;

  /// オートセーブを有効/無効化
  void setAutoSaveEnabled(bool enabled) {
    _autoSaveEnabled = enabled;
    notifyListeners();
  }

  /// オートセーブ間隔を設定
  void setAutoSaveInterval(int interval) {
    assert(interval > 0, 'オートセーブ間隔は1以上である必要があります');
    _autoSaveInterval = interval;
    notifyListeners();
  }

  /// セーブディレクトリのパスを取得
  Future<Directory> _getSaveDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final saveDir = Directory('${appDir.path}/$saveDirectoryName');

    // ディレクトリが存在しない場合は作成
    if (!await saveDir.exists()) {
      await saveDir.create(recursive: true);
    }

    return saveDir;
  }

  /// ゲーム状態を保存
  ///
  /// [gameState] ゲーム状態（JSON形式）
  /// [saveId] セーブID（省略時は現在時刻から自動生成）
  /// [description] 説明（オプション）
  ///
  /// 戻り値: 保存されたセーブデータのメタ情報
  Future<SaveGameMetadata> saveGame({
    required Map<String, dynamic> gameState,
    String? saveId,
    String? description,
  }) async {
    try {
      // セーブIDを生成（未指定の場合）
      final id = saveId ?? _generateSaveId();

      // メタ情報を作成
      final metadata = SaveGameMetadata(
        id: id,
        savedAt: DateTime.now(),
        turnNumber: gameState['turnNumber'] as int? ?? 0,
        currentPlayerId: gameState['currentPlayerId'] as String? ?? 'unknown',
        playerCount: (gameState['players'] as List?)?.length ?? 0,
        description: description,
      );

      // セーブデータを作成
      final saveData = SaveGameData(
        metadata: metadata,
        gameState: gameState,
      );

      // ファイルに保存
      await _writeSaveFile(id, saveData);

      debugPrint('Game saved: $id');
      notifyListeners();

      return metadata;
    } catch (e) {
      debugPrint('Error saving game: $e');
      rethrow;
    }
  }

  /// オートセーブを実行
  ///
  /// [gameState] ゲーム状態（JSON形式）
  ///
  /// 戻り値: 保存された場合はtrue、スキップされた場合はfalse
  Future<bool> autoSave(Map<String, dynamic> gameState) async {
    if (!_autoSaveEnabled) return false;

    final currentTurn = gameState['turnNumber'] as int? ?? 0;

    // インターバルチェック
    if (currentTurn - _lastAutoSaveTurn < _autoSaveInterval) {
      return false;
    }

    try {
      await saveGame(
        gameState: gameState,
        saveId: autoSaveId,
        description: 'Auto-saved at turn $currentTurn',
      );

      _lastAutoSaveTurn = currentTurn;
      debugPrint('Auto-saved at turn $currentTurn');
      return true;
    } catch (e) {
      debugPrint('Error during auto-save: $e');
      return false;
    }
  }

  /// ゲーム状態を読み込み
  ///
  /// [saveId] セーブID
  ///
  /// 戻り値: セーブデータ（存在しない場合はnull）
  Future<SaveGameData?> loadGame(String saveId) async {
    try {
      final file = await _getSaveFile(saveId);

      if (!await file.exists()) {
        debugPrint('Save file not found: $saveId');
        return null;
      }

      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      final saveData = SaveGameData.fromJson(json);
      debugPrint('Game loaded: $saveId');

      return saveData;
    } catch (e) {
      debugPrint('Error loading game: $e');
      return null;
    }
  }

  /// セーブデータ一覧を取得
  ///
  /// 戻り値: セーブデータのメタ情報リスト（新しい順）
  Future<List<SaveGameMetadata>> listSaves() async {
    try {
      final saveDir = await _getSaveDirectory();
      final files = await saveDir.list().toList();

      final metadataList = <SaveGameMetadata>[];

      for (final file in files) {
        if (file is File && file.path.endsWith('.json')) {
          try {
            final jsonString = await file.readAsString();
            final json = jsonDecode(jsonString) as Map<String, dynamic>;
            final saveData = SaveGameData.fromJson(json);
            metadataList.add(saveData.metadata);
          } catch (e) {
            debugPrint('Error reading save file ${file.path}: $e');
          }
        }
      }

      // 保存日時の新しい順にソート
      metadataList.sort((a, b) => b.savedAt.compareTo(a.savedAt));

      return metadataList;
    } catch (e) {
      debugPrint('Error listing saves: $e');
      return [];
    }
  }

  /// セーブデータを削除
  ///
  /// [saveId] セーブID
  ///
  /// 戻り値: 削除に成功した場合はtrue
  Future<bool> deleteSave(String saveId) async {
    try {
      final file = await _getSaveFile(saveId);

      if (!await file.exists()) {
        debugPrint('Save file not found: $saveId');
        return false;
      }

      await file.delete();
      debugPrint('Save deleted: $saveId');
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error deleting save: $e');
      return false;
    }
  }

  /// すべてのセーブデータを削除
  ///
  /// 戻り値: 削除したセーブ数
  Future<int> deleteAllSaves() async {
    try {
      final saves = await listSaves();
      int deletedCount = 0;

      for (final save in saves) {
        final success = await deleteSave(save.id);
        if (success) deletedCount++;
      }

      debugPrint('Deleted $deletedCount saves');
      notifyListeners();

      return deletedCount;
    } catch (e) {
      debugPrint('Error deleting all saves: $e');
      return 0;
    }
  }

  /// セーブデータが存在するか確認
  ///
  /// [saveId] セーブID
  ///
  /// 戻り値: 存在する場合はtrue
  Future<bool> saveExists(String saveId) async {
    try {
      final file = await _getSaveFile(saveId);
      return await file.exists();
    } catch (e) {
      debugPrint('Error checking save existence: $e');
      return false;
    }
  }

  /// セーブファイルを取得
  Future<File> _getSaveFile(String saveId) async {
    final saveDir = await _getSaveDirectory();
    return File('${saveDir.path}/$saveId.json');
  }

  /// セーブファイルに書き込み
  Future<void> _writeSaveFile(String saveId, SaveGameData saveData) async {
    final file = await _getSaveFile(saveId);
    final jsonString = jsonEncode(saveData.toJson());
    await file.writeAsString(jsonString);
  }

  /// セーブIDを生成（現在時刻ベース）
  String _generateSaveId() {
    final now = DateTime.now();
    return 'save_${now.year}${_pad(now.month)}${_pad(now.day)}_'
        '${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';
  }

  /// 2桁のゼロパディング
  String _pad(int value) {
    return value.toString().padLeft(2, '0');
  }

  /// ゲーム状態をJSONに変換するヘルパー
  ///
  /// 実際のゲーム状態オブジェクトからJSONを生成する際に使用
  /// （実装例として提供、実際はGameStateクラスのtoJsonメソッドを使用）
  static Map<String, dynamic> gameStateToJson(dynamic gameState) {
    // TODO: 実際のGameStateクラスに応じて実装
    // 例: return gameState.toJson();

    // 仮実装（動的にプロパティを取得）
    try {
      if (gameState is Map) {
        return Map<String, dynamic>.from(gameState);
      }

      // toJsonメソッドがある場合
      return gameState.toJson() as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error converting game state to JSON: $e');
      return {};
    }
  }

  /// JSONからゲーム状態を復元するヘルパー
  ///
  /// JSONから実際のゲーム状態オブジェクトを生成する際に使用
  /// （実装例として提供、実際はGameStateクラスのfromJsonメソッドを使用）
  static dynamic gameStateFromJson(Map<String, dynamic> json) {
    // TODO: 実際のGameStateクラスに応じて実装
    // 例: return GameState.fromJson(json);

    // 仮実装（JSONをそのまま返す）
    return json;
  }
}
