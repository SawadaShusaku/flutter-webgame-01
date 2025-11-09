# 緊急修正: ui/screens/ 内の全importパスを修正

## タスク
lib/ui/screens/ 配下の全てのDartファイルのimportパスを修正してください。

## 修正ルール

### 1. modelsのimport
```dart
❌ import '../../../models/xxx.dart';
✅ import '../../models/xxx.dart';
```

### 2. servicesのimport
```dart
❌ import '../../../services/xxx.dart';
❌ import '../../controllers/xxx.dart';
✅ import '../../services/xxx.dart';
```

### 3. widgetsのimport
```dart
❌ import '../widgets/game_board_widget.dart';
✅ import '../widgets/board/game_board_widget.dart';

❌ import '../widgets/game_log_widget.dart';
✅ import '../widgets/log/game_log_widget.dart';
```

### 4. utilsのimport
```dart
✅ import '../../utils/constants.dart';
```

## 対象ファイル
- game_screen.dart
- setup_screen.dart
- normal_play_screen.dart
- trade_screen.dart
- game_over_screen.dart
- その他全て

## 実行方法
1. 各.dartファイルを開く
2. import文を確認
3. 上記ルールに従って修正
4. **全てのファイルを修正したらコミット**

```bash
git add -A
git commit -m "fix(ui-screens): 全importパスを修正"
```

完了したら報告してください。
