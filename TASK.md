# 緊急修正: services/内の全importを絶対パスに変更

## タスク
lib/services/ 配下の全Dartファイルのimportを絶対パスに変更してください。

## 変更ルール

### 相対パスから絶対パスへ
```dart
❌ import '../models/game_state.dart';
❌ import '../../models/game_state.dart';
❌ import '../../../models/game_state.dart';
✅ import 'package:test_web_app/models/game_state.dart';

❌ import 'game_service.dart';
✅ import 'package:test_web_app/services/game_service.dart';

❌ import '../utils/constants.dart';
✅ import 'package:test_web_app/utils/constants.dart';
```

## 全てのパターン
```dart
// models
✅ import 'package:test_web_app/models/xxx.dart';

// services（同じディレクトリ内でも絶対パス）
✅ import 'package:test_web_app/services/xxx.dart';

// utils
✅ import 'package:test_web_app/utils/xxx.dart';

// ui
✅ import 'package:test_web_app/ui/xxx.dart';
```

## 対象ファイル
lib/services/ 内の全.dartファイル

## 実行方法
1. lib/services/内の各.dartファイルを開く
2. 全てのimport文を絶対パスに変更
3. **全てのファイルを修正したらコミット**

```bash
git add -A
git commit -m "refactor(services): 全importを絶対パスに変更"
```

完了したら報告してください。
