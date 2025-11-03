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

# ターミナルベルを鳴らす（環境によっては音が出る）
printf '\a'

# 視覚的な通知メッセージ（現在のペインに表示）
echo ""
echo "================================"
echo "✅ ${MESSAGE}"
echo "================================"
echo ""

# tmuxの他のペインに通知を送る
if [ -S "$TMUX_SOCKET" ]; then
    # 音声読み上げ
    if [ "$USE_TTS" = true ]; then
        tmux -S "$TMUX_SOCKET" send-keys -t 1 "termux-tts-speak '${MESSAGE}' > /dev/null 2>&1 &" Enter 2>/dev/null
    fi

    # 通知音付きの通知バー表示
    if [ "$USE_NOTIFICATION_SOUND" = true ]; then
        tmux -S "$TMUX_SOCKET" send-keys -t 1 "termux-notification --title '✅ 完了' --content '${MESSAGE}' --sound > /dev/null 2>&1 &" Enter 2>/dev/null
    else
        # 音なしの通知バー表示（通知音をオフにしても通知自体は表示）
        tmux -S "$TMUX_SOCKET" send-keys -t 1 "termux-notification --title '✅ 完了' --content '${MESSAGE}' > /dev/null 2>&1 &" Enter 2>/dev/null
    fi

    # 視覚的な通知
    if [ "$USE_VISUAL_NOTIFICATION" = true ]; then
        # ペイン1に視覚的な通知も送る
        tmux -S "$TMUX_SOCKET" send-keys -t 1 "echo -e '\n━━━━━━━━━━━━━━━━━━━━━━━━\n✅ ${MESSAGE}\n━━━━━━━━━━━━━━━━━━━━━━━━\n'" Enter 2>/dev/null

        # ペイン0にも視覚的な通知を送る
        tmux -S "$TMUX_SOCKET" send-keys -t 0 "echo -e '\n━━━━━━━━━━━━━━━━━━━━━━━━\n✅ ${MESSAGE}\n━━━━━━━━━━━━━━━━━━━━━━━━\n'" Enter 2>/dev/null
    fi
fi
