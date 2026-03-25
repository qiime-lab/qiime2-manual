# Appendix A: メタデータファイル仕様

## ファイル形式

- タブ区切りテキスト（`.txt` or `.tsv`）
- 文字コード: UTF-8

## 基本ルール

| ルール | 詳細 |
|--------|------|
| 区切り文字 | タブ（`\t`） |
| 1 列目 | `#SampleID`（identifier column） |
| コメント行 | 行頭が `#` の行は無視される |
| ID 制限 | 36 文字以内、ASCII (A-Z, a-z, 0-9, `.`, `-`) 推奨 |
| 空セル | "missing data" とみなされる（`"NA"` とは異なる） |
| 型推定 | 数字のみ → numeric、文字含む → categorical |
| 型明示 | 2 行 1 列目に `#q2:types` と記載 |

## numeric でサポートされる値

```
123, 123.45, 0123.40, -0.000123, +1.23, 1e9, 1.23E-4, -1.2e-08, +4.5E+6
```

> **⚠️ 非サポート**: `NaN`, `nan`, `inf`, `-Infinity`

## テンプレート

### sample-metadata.txt（名前変更前）

```tsv
#SampleID	BarcodeSequence	LinkerPrimerSequence	newID	IS	Group	Description
SP01_S1	ACGTACGT	AGRGTTTGATYMTGGCTCAG	SampleA_IS	yes	treatment	Sample A with IS
SP02_S2	TGCATGCA	AGRGTTTGATYMTGGCTCAG	SampleB_IS	yes	control	Sample B with IS
SP03_S3	GCTAGCTA	AGRGTTTGATYMTGGCTCAG	SampleC	no	treatment	Sample C without IS
```

### sample-metadata_cn.txt（名前変更後）

```tsv
#SampleID	IS	Group	Description
SampleA_IS	yes	treatment	Sample A with IS
SampleB_IS	yes	control	Sample B with IS
SampleC	no	treatment	Sample C without IS
```

## バリデーション

QIIME 2 の metadata バリデーションツールで確認できる：

```bash
qiime metadata tabulate \
  --m-input-file sample-metadata.txt \
  --o-visualization metadata-check.qzv
```

また、[Keemei](https://keemei.qiime2.org/) という Google Sheets アドオンでも検証が可能。列のデータ型や値の範囲、ID の重複などを GUI 上で確認できる。

---

## 2026.4 のメタデータパラメータ名統一について

QIIME 2 2026.4 のアップデートにより、複数のプラグインにわたってメタデータを指定する引数名が `--m-metadata-file` に統一された。

**影響を受ける可能性のある場面**:
- `--m-sample-metadata-file` などのプラグイン固有の引数名を使っていた場合
- 旧バージョンのスクリプトを 2026.4 以降の環境で実行する場合

**対処法**: エラーが出た場合は `--help` フラグで現在の引数名を確認する。

```bash
# 例：alpha-group-significance の最新の引数を確認
qiime diversity alpha-group-significance --help
```

> **Note**: CLI のコマンド構造自体は変わっておらず、引数名のみの変更のため、`--help` で確認すれば容易に対応できる。
