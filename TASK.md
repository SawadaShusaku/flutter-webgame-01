# 緊急修正: ui/widgets/ 内の全importパスを修正

## タスク
lib/ui/widgets/ 配下の全サブディレクトリのDartファイルのimportパスを修正してください。

## 修正ルール

### 1. modelsのimport
```dart
❌ import '../../../../models/xxx.dart';
✅ import '../../../models/xxx.dart';
```

### 2. servicesのimport
```dart
❌ import '../../../../services/xxx.dart';
✅ import '../../../services/xxx.dart';
```

### 3. utilsのimport
```dart
❌ import '../../../../utils/xxx.dart';
✅ import '../../../utils/xxx.dart';
```

### 4. 同じwidgets内のimport
```dart
# widgets/board/ から widgets/player/ を参照する場合
✅ import '../player/player_info_widget.dart';

# widgets/actions/ から widgets/board/ を参照する場合
✅ import '../board/game_board_widget.dart';
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
2. import文を確認
3. 上記ルールに従って修正
4. **全てのファイルを修正したらコミット**

```bash
git add -A
git commit -m "fix(ui-widgets): 全importパスを修正"
```

完了したら報告してください。
