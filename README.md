# vim-draft-inbox

**Version 1.0.0 — 初版**

Vimをファイル名なしで起動したときの無名バッファを、そのまま失われる可能性のある一時領域として扱うのではなく、**複数のDraft（メモ・下書き）として保存・一覧・復元できるようにするVimプラグイン**です。

書き始めた内容はDraftとして保持し、後から既存Draftを選択して再開できます。残すことを決めたDraftは `:w filename` で通常ファイルへ昇格でき、不要なDraftは `:rm` で削除できます。

## 主な機能

- `vim` のようにファイル名なしで起動した場合にDraft Inboxを表示
- 複数のDraftを一覧管理
- 既存Draftの復元
- 空Enterで新しいDraftを作成
- `q` でDraft化せず通常の無名バッファのまま開始
- Draftを自動保存
- `:w filename` で通常ファイルとして保存し、元Draftを削除
- `:rm` で確認後にDraftを削除
- Draft削除後はDraft Inboxへ戻る
- 最後のDraftを削除した場合は新しいDraftを自動生成
- `vim-auto-save` など外部AutoSaveプラグインとの任意連携
- Windows / macOS / Linux向けインストール・アンインストールスクリプト
- Vimの `:help vim-draft-inbox` から参照できるヘルプファイル

## ファイル構成

```text
vim-draft-inbox/
├── plugin/
│   └── vim_draft_inbox.vim
├── doc/
│   └── vim-draft-inbox.txt
├── scripts/
│   ├── install-windows.cmd
│   ├── uninstall-windows.cmd
│   ├── install.sh
│   └── uninstall.sh
└── README.md
```

プラグイン本体は `plugin/vim_draft_inbox.vim` の1ファイルです。`autoload/` は使用しません。

## 基本動作

Vimをファイル名なしで起動します。

```text
vim
```

保存済みDraftがある場合、次のようなDraft Inboxが表示されます。

```text
Draft Inbox

[Enter] New Draft
q       Unnamed buffer / Cancel
1. 20261010-202154-14096.txt  [2026-10-10 20:34:59]
2. 20260926-132305-23340.txt  [2026-09-26 13:23:33]

Select:
```

操作は次のとおりです。

- **空Enter**: 新しいDraftを作成
- **`q`**: 起動時は通常の無名バッファのまま開始
- **数字**: 対応する既存Draftを開く

Draft Inboxは表示直後からそのまま入力できます。一覧表示のためだけに追加のEnterを押す必要はありません。

保存済みDraftが1件もない場合は、新しいDraftを自動生成します。

通常の、

```text
vim filename
```

による編集はDraftモードにはなりません。

## Draftの保存

現在のDraftをそのまま保存する場合:

```vim
:w
```

Draftを通常ファイルとして保存する場合:

```vim
:w memo.txt
```

Draft上での `:w filename` は、実質的に `:saveas filename` と同様に動作します。

保存に成功すると、

1. 指定したファイルが現在の編集対象になります。
2. 元のDraftファイルを削除します。
3. 以後、そのバッファは通常ファイルとして扱われます。

## Draftの削除

Draft上で、

```vim
:rm
```

を実行すると、削除確認が表示されます。

```text
Delete this Draft file?

C:/Users/USER/.vimdrafts/20261017-103000-12345.txt
```

`Yes` を選択した場合のみDraftを削除します。

削除後はDraft Inboxへ戻ります。最後のDraftを削除して残りが0件になった場合は、新しいDraftを自動生成します。

通常ファイルに対して `:rm` でファイルを削除することはありません。

## コマンド

| コマンド | 動作 |
|---|---|
| `:DraftInbox` | Draft Inboxを表示 |
| `:DraftNew` | 新しいDraftを新しいタブで作成 |
| `:DraftRemove` | 現在のDraftを確認付きで削除 |
| `:DraftWrite [filename]` | Draftを保存、または指定した名前で通常ファイル化 |

通常は短縮操作として次を利用できます。

```vim
:w
:w filename
:rm
```

`:w filename` と `:rm` の拡張にはコマンドラインの `<CR>` マッピングを使用します。既にコマンドラインの `<CR>` に別のマッピングが存在する場合、このプラグインは上書きしません。その場合でも `:DraftWrite` と `:DraftRemove` は利用できます。

## 設定

すべてデフォルト値を持つため、設定変更が不要であれば `.vimrc` への追加は必要ありません。

### Draft保存先

デフォルト:

```vim
let g:draft_inbox_dir = '~/.vimdrafts'
```

変更例:

```vim
let g:draft_inbox_dir = '~/Documents/vim-drafts'
```

### Draft Inboxの最大表示件数

```vim
let g:draft_inbox_restore_limit = 20
```

`0` 以下を指定した場合は件数制限を行いません。

### Draftファイルの拡張子

```vim
let g:draft_inbox_extension = 'txt'
```

## AutoSave

AutoSaveには3つのモードがあります。

### 内蔵AutoSave

デフォルトです。

```vim
let g:draft_inbox_autosave = 'builtin'
```

このプラグイン自身がDraftだけを自動保存します。

デフォルトイベント:

```vim
let g:draft_inbox_autosave_events = [
      \ 'InsertLeave',
      \ 'TextChanged',
      \ 'FocusLost',
      \ 'BufLeave',
      \ 'VimLeavePre',
      \ ]
```

### 外部AutoSaveプラグインを使用

既に `vim-auto-save` などを利用している場合:

```vim
let g:draft_inbox_autosave = 'external'
```

このモードでは本プラグインはAutoSave用autocommandを登録しません。

例:

```vim
let g:auto_save = 1
let g:auto_save_in_insert_mode = 0

let g:draft_inbox_autosave = 'external'
```

本プラグインから外部AutoSaveプラグインの設定値を変更することはありません。

### AutoSaveを使用しない

```vim
let g:draft_inbox_autosave = 'none'
```

## インストール

### Windows

CMDで実行します。

```cmd
scripts\install-windows.cmd
```

デフォルトのインストール先:

```text
%USERPROFILE%\vimfiles\plugin\vim_draft_inbox.vim
%USERPROFILE%\vimfiles\doc\vim-draft-inbox.txt
```

既存ファイルがある場合は `.bak` を作成してから上書きします。

バックアップなしで上書き:

```cmd
scripts\install-windows.cmd --force
```

インストール先を変更:

```cmd
scripts\install-windows.cmd "D:\vimfiles"
```

アンインストール:

```cmd
scripts\uninstall-windows.cmd
```

### macOS / Linux

```sh
chmod +x ./scripts/install.sh
./scripts/install.sh
```

デフォルトのインストール先:

```text
~/.vim/plugin/vim_draft_inbox.vim
~/.vim/doc/vim-draft-inbox.txt
```

既存ファイルがある場合は `.bak` を作成してから上書きします。

バックアップなしで上書き:

```sh
./scripts/install.sh --force
```

インストール先を変更:

```sh
./scripts/install.sh --vim-root /path/to/.vim
```

アンインストール:

```sh
./scripts/uninstall.sh
```

## Vim help

インストールスクリプトは、`vim` がPATH上にある場合、help tagsを自動生成します。

手動で生成する場合:

Windows:

```vim
:helptags ~/vimfiles/doc
```

macOS / Linux:

```vim
:helptags ~/.vim/doc
```

ヘルプ:

```vim
:help vim-draft-inbox
```

配布物には `tags` ファイルを同梱していません。同一 `doc` ディレクトリに複数のプラグインのヘルプが存在する場合でも、`helptags` によってそのディレクトリ全体の索引を生成できます。

## 初版について

Version 1.0.0 を初版とします。

この初版には、設計・試作段階で実施した改善内容をすべて統合しています。主な内容は、複数Draftの復元・管理、名前付き保存時の元Draft削除、確認付き削除、削除後のInbox復帰、通常の無名バッファへの離脱、新規Draftの空Enter操作、メニュー表示時の不要なhit-enter抑制、外部AutoSaveとの任意連携、Vim help、およびOS別配布スクリプトです。

過去の試作名や試作版の互換性を維持するためのエイリアスは含めていません。

## ChatGPTによる生成について

このプラグインおよびドキュメントは、OpenAIのChatGPTを利用して生成・整理したものです。

Vim本体、`vim-auto-save`、またはそれらの開発者が公式に提供・保証しているものではありません。

### 注意事項

- 利用前にコードの内容を確認し、自身のVim環境で十分にテストしてください。
- Vimのバージョン、OS、既存の `.vimrc`、他のプラグインやキーマッピングなどによって動作が異なる場合があります。
- ファイルの保存、名前変更、削除を行う機能を含むため、重要なファイルを扱う環境では事前にバックアップを取得することを推奨します。
- 外部AutoSaveプラグインとの併用時は、外部プラグイン側の仕様や設定によって動作が異なる可能性があります。
- Vimや関連プラグインの将来の仕様変更に対する互換性を保証するものではありません。
- 業務環境や重要なデータを扱う環境で使用する場合は、利用者自身の責任で内容を確認・検証したうえで導入してください。
