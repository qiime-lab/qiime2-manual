# コントリビューションガイド

## バグ報告・改善提案

[Issues](../../issues) から報告してください。以下の情報を含めると対応がスムーズです：

- 使用している QIIME 2 のバージョン
- OS（macOS / Linux / Windows WSL2）
- エラーメッセージ（あれば）
- 再現手順

## Pull Request

1. このリポジトリを Fork する
2. Feature branch を作成する (`git checkout -b feature/improve-xyz`)
3. 変更をコミットする (`git commit -m 'Add: XYZの改善'`)
4. Push する (`git push origin feature/improve-xyz`)
5. Pull Request を作成する

## 文書の記法

- Markdown で記述する
- フローチャートは [Mermaid](https://mermaid.js.org/) 記法を使用する
- コマンドはコードブロック（```bash）で囲む
- パラメータ説明はテーブルで記述する
- 日本語で記述する（コマンド・パラメータ名は英語のまま）

## QIIME 2 バージョン更新時の対応

QIIME 2 の新バージョンがリリースされた際は、以下を確認・更新してください：

1. `README.md` のバージョン情報
2. `docs/01_installation.md` のインストールコマンド
3. 各セクションのコマンド構文の変更有無
4. `docs/appendix_changelog.md` に変更を追記
