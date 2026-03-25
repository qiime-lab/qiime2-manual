# 21. トラブルシューティング

## よくあるエラーと対処法

### scikit-learn バージョン不一致

異なるバージョンの QIIME 2 で作成した分類器を使用するとエラーになることがある。

**対処法**: 使用する QIIME 2 バージョンで分類器を再作成する。

> **Note**: 旧マニュアルでは `conda install scikit-learn=0.22.1` による回避策を記載していたが、現行バージョンでは不要。

### メモリ不足

大規模データセットで DADA2 がメモリ不足になる場合：

```bash
# スレッド数を制限
qiime dada2 denoise-paired \
  ... \
  --p-n-threads 4  # 0（最大）ではなく制限する
```

### metadata のフォーマットエラー

- ファイルがタブ区切りになっているか確認（カンマ区切りは NG）
- 空白文字や特殊文字が含まれていないか確認
- Excel で保存する際は「タブ区切りテキスト (.txt)」を選択

### QIIME 2 View で qzv が開けない

- ブラウザのキャッシュをクリアする
- 別のブラウザで試す
- ファイルサイズが大きすぎる場合は `qiime tools export` でエクスポートして個別に確認

---

## 追加のよくあるエラー

### "Plugin error from dada2: An error was encountered while running DADA2"

DADA2 実行時の汎用エラー。原因は複数考えられる：

**原因と対処法**:
1. **メモリ不足** — `--p-n-threads` を減らす（`--p-n-threads 4` など）
2. **スレッド競合** — `--p-n-threads 1` で単スレッド実行してエラー内容を確認する
3. **トランケーション長が短すぎる** — `--p-trunc-len-f` / `--p-trunc-len-r` を大きくする
4. **入力データの問題** — manifest ファイルのパスと実ファイルが一致しているか確認

```bash
# デバッグ用：単スレッドで実行してエラーを特定
qiime dada2 denoise-paired \
  --i-demultiplexed-seqs demux.qza \
  --p-trunc-len-f 250 \
  --p-trunc-len-r 200 \
  --p-n-threads 1 \
  --o-table table.qza \
  --o-representative-sequences rep-seqs.qza \
  --o-denoising-stats stats.qza \
  --verbose
```

### metadata バリデーションエラー

よくあるフォーマット上の問題：

| エラー内容 | 原因 | 対処法 |
|-----------|------|--------|
| `Missing samples in metadata` | メタデータにないサンプル ID がある | sample-metadata の `#SampleID` 列を確認 |
| `Duplicate sample IDs` | 同じ ID が 2 行以上ある | 重複行を削除 |
| `Expected TSV` | ファイルがカンマ区切り | Excel でタブ区切りとして保存し直す |
| `ID contains invalid characters` | スペースや記号が含まれている | サンプル ID を英数字と `.` `-` のみにする |

```bash
# metadata をバリデーションして問題を可視化
qiime metadata tabulate \
  --m-input-file sample-metadata.txt \
  --o-visualization metadata-check.qzv
```

### "No sequences passed the filter"

フィルタリング後にシーケンスが 0 になるエラー。

**原因と対処法**:
- `--p-trunc-len-f` / `--p-trunc-len-r` が厳しすぎる → 値を小さくする（例: 250→220）
- `--p-trunc-q` が高すぎる → デフォルト（2）に戻す
- `--p-max-ee-f` / `--p-max-ee-r` が厳しすぎる → 値を大きくする（例: 2→5）
- DADA2Stats（`stats.qza`）の内容を確認して、どのステップでリードが落ちているかを特定する

```bash
# DADA2 統計を可視化
qiime metadata tabulate \
  --m-input-file stats.qza \
  --o-visualization stats.qzv
```

### Import エラー（フォーマット不一致）

```
There was a problem importing ...: No plugin registered a transformer from 'X' to 'Y'
```

**原因**: インポート時に指定した `--type` や `--input-format` が実際のデータ形式と合っていない。

**対処法**:
- Paired-end か Single-end かを確認
- manifest ファイルのカラム名が仕様通りか確認（`sample-id`, `forward-absolute-filepath`, `reverse-absolute-filepath`）
- `--input-format` の指定を確認（`PairedEndFastqManifestPhred33V2` など）

```bash
# インポート可能な型とフォーマットの一覧
qiime tools import --show-importable-types
qiime tools import --show-importable-formats
```

---

## 2026.5 で注意すべき破壊的変更

QIIME 2 のバージョンアップに伴い、過去のコマンドがそのまま動かない場合がある。主な破壊的変更を以下にまとめる。

### DADA2Stats → Collection[DADA2Stats]（2025.4）

DADA2 の出力アーティファクト型が変更された。マルチラン環境では `Collection[DADA2Stats]` として扱われるようになったため、旧コマンドの出力を直接 `metadata tabulate` に渡すとエラーになる場合がある。

```bash
# 2025.4 以降：stats.qza が Collection 型の場合はまず展開
# （通常の単一ランでは影響なし）
```

### --p-n-reads-learn → --p-n-bases-learn（リネーム）

DADA2 のエラーモデル学習パラメータの名前が変更された：

```bash
# 旧（2025.4 以前）
--p-n-reads-learn 1000000

# 新（2025.4 以降）
--p-n-bases-learn 250000000
```

### メタデータパラメータ名の統一（2026.4）

複数のアクションにわたってメタデータ引数の名前が `metadata` に統一された。プラグインによっては `--m-sample-metadata-file` が `--m-metadata-file` に変更されている可能性がある。エラーが出た場合は `--help` で現在の引数名を確認する。

```bash
qiime diversity alpha-group-significance --help
```

### ディストリビューション名の変更（2026.4）

- 旧: `qiime2-amplicon-2026.1`
- 新: `qiime2-2026.4`（`amplicon` ディストリビューションは `qiime2` にリブランド）

インストール手順やドキュメントの URL が変更されているため注意。

---

## 参考リソース

| リソース | URL | 内容 |
|---------|-----|------|
| 公式ドキュメント（amplicon） | https://amplicon-docs.qiime2.org/ | amplicon 解析特化の新ドキュメントサイト |
| QIIME 2 Library | https://library.qiime2.org/ | プラグイン・チュートリアル集 |
| チュートリアル | https://use.qiime2.org/ | ステップバイステップチュートリアル |
| フォーラム | https://forum.qiime2.org/ | コミュニティサポート・Q&A |
| GitHub | https://github.com/qiime2/qiime2 | ソースコード・Issue トラッカー |

> **エラーが出たときの心構え**: 「まずエラーメッセージを読む → 公式ドキュメント・チュートリアルを確認 → フォーラムで検索」

**参考文献**:
- 月見友哉, 伊藤光平, 福田真嗣, QIIME2: Wet 研究者も使える細菌叢解析ツール, 羊土社 (38・1・103-114), 2020.

---

**Appendix**: [メタデータ仕様](appendix_metadata.md) | [変更履歴](appendix_changelog.md)
