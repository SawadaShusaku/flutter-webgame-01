# 緊急修正: その他ファイルの全importパスを修正

## タスク
以下のファイルのimportパスを修正してください。

## 対象ファイル
1. lib/main.dart
2. lib/widgetbook.dart
3. lib/ui/painters/ 内のファイル
4. その他エラーが出ているファイル

## 修正ルール

### main.dartの場合
```dart
✅ import 'services/game_controller.dart';
✅ import 'ui/screens/title_screen.dart';
```

### paintersの場合
```dart
✅ import '../../models/xxx.dart';
✅ import '../../utils/xxx.dart';
```

## 実行方法
1. 各ファイルを開く
2. import文を確認
3. 正しいパスに修正
4. **全てのファイルを修正したらコミット**

```bash
git add -A
git commit -m "fix(misc): その他ファイルのimportパスを修正"
```

完了したら報告してください。
