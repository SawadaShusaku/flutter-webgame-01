# Git設定ガイド

## 概要
このドキュメントでは、PRoot Ubuntu環境でGitHubにpushするための設定方法を説明します。

## 環境
- OS: Ubuntu (PRoot-Distro on Termux/Android)
- Git repository: https://github.com/SawadaShusaku/flutter-webgame-01.git

## 問題と解決方法

### 問題: 認証エラー
PRoot環境では対話的な認証入力ができないため、以下のエラーが発生します：
```
fatal: could not read Username for 'https://github.com': No such device or address
```

### 解決方法: Credential Helperの設定

#### 1. Credential Helperを有効化
```bash
git config --global credential.helper store
```

これにより、認証情報が `~/.git-credentials` に保存されます。

#### 2. Personal Access Token (PAT) の使用

GitHubのPersonal Access Tokenを使って認証します。

**一時的な方法（初回のみ）:**
```bash
git remote set-url origin https://ユーザー名:PAT@github.com/ユーザー名/リポジトリ名.git
git push -u origin main
git remote set-url origin https://github.com/ユーザー名/リポジトリ名.git
```

**永続的な方法:**
1. Credential helperを設定（上記参照）
2. 一度PATを含むURLでpushすると、自動的に保存されます
3. その後はPATなしのURLに戻しても、保存された認証情報が使われます

#### 3. 保存された認証情報の確認
```bash
ls -la ~/.git-credentials
```

ファイルが存在すれば、認証情報が保存されています。

## 次回以降の使い方

設定が完了すれば、通常通りのコマンドでpushできます：

```bash
git add .
git commit -m "コミットメッセージ"
git push
```

## セキュリティ注意事項

- Personal Access Tokenは機密情報です。他人と共有しないでください
- `~/.git-credentials` は平文で保存されるため、ファイルの権限に注意してください
- 定期的にPATを更新することを推奨します

## トラブルシューティング

### 認証エラーが再発する場合
```bash
# 保存された認証情報を確認
cat ~/.git-credentials

# 認証情報を削除して再設定
rm ~/.git-credentials
# 上記の手順でPATを再設定
```

### リモートURLの確認
```bash
git remote -v
```

正しいリポジトリURLが設定されているか確認してください。

## 参考情報
- GitHubでのPersonal Access Token作成: Settings → Developer settings → Personal access tokens
- 必要な権限: `repo` (フルアクセス)
