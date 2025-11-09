# 緊急修正: ui/widgets/内の全importを絶対パスに変更

## タスク
lib/ui/widgets/ 配下の全サブディレクトリのDartファイルのimportを絶対パスに変更してください。

## 変更ルール

### 相対パスから絶対パスへ
```dart
❌ import '../../../models/game_state.dart';
❌ import '../../../services/game_controller.dart';
❌ import '../player/player_info_widget.dart';
✅ import 'package:test_web_app/models/game_state.dart';
✅ import 'package:test_web_app/services/game_controller.dart';
✅ import 'package:test_web_app/ui/widgets/player/player_info_widget.dart';
```

## 全てのパターン
```dart
// models
✅ import 'package:test_web_app/models/xxx.dart';

// services
✅ import 'package:test_web_app/services/xxx.dart';

// utils
✅ import 'package:test_web_app/utils/xxx.dart';

// 他のwidgets（別のサブディレクトリ）
✅ import 'package:test_web_app/ui/widgets/xxx/xxx.dart';

// screens
✅ import 'package:test_web_app/ui/screens/xxx.dart';

// painters
✅ import 'package:test_web_app/ui/painters/xxx.dart';
```

## 対象ディレクトリ
- actions/
- board/
- cards/
- log/
- player/
- robber/
- trade/
- game_info/

## 実行方法
1. 各サブディレクトリの.dartファイルを開く
2. 全てのimport文を絶対パスに変更
3. **全てのファイルを修正したらコミット**

```bash
git add -A
git commit -m "refactor(ui-widgets): 全importを絶対パスに変更"
```

完了したら報告してください。
