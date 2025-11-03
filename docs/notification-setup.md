# Claude Code 通知システム設定ガイド

## 概要
このドキュメントでは、PRoot Ubuntu環境からTermuxのtmuxペインに通知を送り、音声読み上げや通知音を鳴らす設定方法を説明します。

## 環境構成

```
Termux (Android)
  └─ tmux (分割されたペイン)
      ├─ ペイン0: Claude Code
      ├─ ペイン1: bash (Termux本体)
      └─ ペイン2: Claude Code (Ubuntu PRoot) ← このペインから通知を送る
```

## 前提条件

### 必要なもの
1. **Termux** (Android)
2. **tmux** (ターミナルマルチプレクサ)
3. **Termux:API** パッケージとアプリ

### Termux:APIのインストール

**1. Termux側でパッケージをインストール:**
```bash
pkg install termux-api
```

**2. Termux:APIアプリをインストール:**
- F-Droidから入手: https://f-droid.org/packages/com.termux.api/
- または GitHub Releases: https://github.com/termux/termux-api/releases

**3. 権限の設定:**
- Android設定 → アプリ → Termux:API → 権限
- 通知の表示を許可

## ファイル構成

```
.claude/
├── hooks.json              # フック設定
├── scripts/
│   └── notify.sh          # 通知スクリプト
├── settings.json          # 基本設定
└── settings.local.json    # 個人設定（gitignore対象）
```

## 通知スクリプトの設定

### `.claude/scripts/notify.sh`

```bash
#!/bin/bash
# Claude Code完了通知スクリプト

# ========== 通知設定 ==========
# 音声読み上げを使用する (true/false)
USE_TTS=true

# 通知音を使用する (true/false)
USE_NOTIFICATION_SOUND=true

# 視覚的な通知を他のペインに送る (true/false)
USE_VISUAL_NOTIFICATION=true
# ==============================

# 引数からメッセージを取得（デフォルト: "タスク完了"）
MESSAGE="${1:-タスク完了}"

# tmuxソケットのパス
# 注意: このパスは環境依存です。自分の環境に合わせて変更してください。
# 確認方法: ls /data/data/com.termux/files/usr/var/run/
TMUX_SOCKET="/data/data/com.termux/files/usr/var/run/tmux-10367/default"
```

### tmuxソケットパスの確認方法

```bash
ls /data/data/com.termux/files/usr/var/run/
```

表示されたディレクトリ（例: `tmux-10367`）内の`default`ファイルがソケットです。

## フック設定

### `.claude/hooks.json`

```json
{
  "hooks": [
    {
      "event": "SessionEnd",
      "script": ".claude/scripts/notify.sh 'セッション終了しました'",
      "description": "セッション終了時に音声で通知"
    },
    {
      "event": "PostToolUse",
      "matcher": {
        "tool": "Bash",
        "args": {
          "command": "flutter test*"
        }
      },
      "script": ".claude/scripts/notify.sh 'テストが完了しました'",
      "description": "Flutter テスト完了時に音声で通知"
    },
    {
      "event": "PostToolUse",
      "matcher": {
        "tool": "Bash",
        "args": {
          "command": "flutter build*"
        }
      },
      "script": ".claude/scripts/notify.sh 'ビルドが完了しました'",
      "description": "Flutter ビルド完了時に音声で通知"
    }
  ]
}
```

## 通知の種類と切り替え

### 1. 音声読み上げ (TTS)
```bash
USE_TTS=true
```
- メッセージを音声で読み上げます
- Termux:APIの`termux-tts-speak`を使用

### 2. 通知音
```bash
USE_NOTIFICATION_SOUND=true
```
- Android通知バーに通知を表示し、通知音を鳴らします
- Termux:APIの`termux-notification --sound`を使用

### 3. 視覚的な通知
```bash
USE_VISUAL_NOTIFICATION=true
```
- tmuxの他のペインにテキストメッセージを表示します

## 使用例

### 手動で通知を送る
```bash
.claude/scripts/notify.sh "カスタムメッセージ"
```

### 異なる通知タイプの設定例

**音声読み上げのみ:**
```bash
USE_TTS=true
USE_NOTIFICATION_SOUND=false
USE_VISUAL_NOTIFICATION=false
```

**通知音のみ:**
```bash
USE_TTS=false
USE_NOTIFICATION_SOUND=true
USE_VISUAL_NOTIFICATION=false
```

**静かにしたい（視覚通知のみ）:**
```bash
USE_TTS=false
USE_NOTIFICATION_SOUND=false
USE_VISUAL_NOTIFICATION=true
```

## 動作確認

### テスト実行
```bash
chmod +x .claude/scripts/notify.sh
.claude/scripts/notify.sh "テストメッセージ"
```

### 確認項目
- [ ] 音声読み上げが聞こえるか
- [ ] Android通知バーに通知が表示されるか
- [ ] 通知音が鳴るか
- [ ] 他のtmuxペインにメッセージが表示されるか

## トラブルシューティング

### 音声読み上げが動作しない
1. Termux:APIアプリがインストールされているか確認
2. 権限が付与されているか確認
3. 手動でTermux側から実行してみる:
   ```bash
   termux-tts-speak "テスト"
   ```

### 通知が表示されない
1. Android設定で通知が許可されているか確認
2. Termux:APIアプリの権限を確認
3. 手動でTermux側から実行してみる:
   ```bash
   termux-notification --title "テスト" --content "テスト" --sound
   ```

### tmuxペインにメッセージが表示されない
1. tmuxソケットのパスが正しいか確認:
   ```bash
   ls -la /data/data/com.termux/files/usr/var/run/tmux-*/default
   ```
2. ペイン番号が正しいか確認:
   ```bash
   tmux -S /path/to/socket list-panes
   ```

### send-keysが2回必要な問題
tmuxの`send-keys`コマンドでEnterキーが正しく送られない場合があります。
その場合は、以下のように2回送ります：

```bash
tmux send-keys -t 0 "コマンド"
tmux send-keys -t 0 C-m
```

## セキュリティとプライバシー

### gitignoreに追加済み
個人設定ファイルは除外されています：
```
.claude/settings.local.json
```

### 環境依存の設定
- tmuxソケットパスは環境ごとに異なります
- 新しい環境で使う場合は、`notify.sh`内のパスを更新してください

## 参考情報

### Termux:API公式ドキュメント
- https://wiki.termux.com/wiki/Termux:API

### 利用可能なコマンド
- `termux-notification`: 通知を表示
- `termux-tts-speak`: テキストを音声読み上げ
- `termux-vibrate`: 端末を振動させる
- `termux-media-player`: メディアファイルを再生

### Claude Code フック
- SessionEnd: セッション終了時
- PostToolUse: ツール使用後
- その他のイベントは公式ドキュメント参照
