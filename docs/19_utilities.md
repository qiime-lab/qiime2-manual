# 19. ユーティリティ

## 18. タグ付きサンプルの処理（研究員・技術員向け）

Python スクリプトでスプリットした fastq ファイルを下記コマンドで gz に圧縮する。以降は本マニュアルに沿って解析を進めれば良い。

```bash
# 「splited」というフォルダに圧縮したい fastq ファイルがある場合
gzip splited/*
```

## 20. ファイル名の一括変更

`rename.R` スクリプトを利用する。

### 準備

A 列に変更前のファイル名、B 列に変更後のファイル名を入力した CSV ファイルを作成する。

### 実行

```bash
Rscript rename.R rename_test.csv fastq/
```

> **注意点**:
> - CSV と `rename.R` は別の場所にあっても大丈夫
> - `"incomplete final line found by readTableHeader"` という警告が出ることがあるが問題なく実行できる
> - エラーが起きても表示されない場合があるため、実行後は目視で確認すること

---

## q2-fondue — SRA からのデータ取得（2025.10+）

### 概要

公共データベース（NCBI SRA、ENA）からシーケンスデータを再現可能な形で取得できるプラグイン。アクセッション番号を `.qza` アーティファクトとして管理するため、データ取得ステップも Provenance に記録される。

**メリット**:
- 公共データの取得が QIIME 2 ワークフローに統合できる
- アクセッション番号が Provenance に記録され、再現性が担保される
- メタデータ（SRA ランテーブル）も同時に取得可能

**デメリット**:
- ネットワーク速度・SRA サーバーの状況に依存する
- 大規模データセットでは時間がかかる

### インストール

```bash
pip install q2-fondue
qiime dev refresh-cache
```

### アクセッション ID の準備

取得したいランの SRA アクセッション番号（例: `SRR12345678`）を 1 行 1 ID で記述したテキストファイルを作成し、インポートする：

```bash
# アクセッション ID リストを QIIME 2 アーティファクトに変換
qiime tools import \
  --type NCBIAccessionIDs \
  --input-path accession-ids.txt \
  --output-path accession-ids.qza
```

### SRA からシーケンスデータを取得

```bash
# NCBI SRA からデータ取得
qiime fondue get-sequences \
  --i-accession-ids accession-ids.qza \
  --p-email your@email.com \
  --o-single-end-sequences single-seqs.qza \
  --o-paired-end-sequences paired-seqs.qza \
  --o-failed-runs failed.qza
```

取得後は通常の QIIME 2 ワークフロー（[02. データ読み込み](02_data_import.md) 以降）に進む。

---

## よく使うコマンド集

日常的な QIIME 2 操作で役立つコマンドをまとめる。

### アーティファクトの確認

```bash
# .qza の中身を確認（メタデータを表示）
qiime tools peek table.qza
```

出力例：
```
UUID:        3b1a2c3d-...
Type:        FeatureTable[Frequency]
Data format: BIOMV210DirFmt
```

### バリデーション

```bash
# .qza/.qzv のバリデーション（ファイルの整合性チェック）
qiime tools validate table.qza
```

### ブラウザで直接表示

```bash
# .qzv を直接ブラウザで開く（QIIME 2 View にアップロード不要）
qiime tools view table.qzv
```

### エクスポート

```bash
# .qza の生データを取り出す
qiime tools export \
  --input-path table.qza \
  --output-path exported/
```

### プラグイン情報の確認

```bash
# インストール済みプラグインとバージョン一覧
qiime info

# 特定プラグインのアクション一覧
qiime dada2 --help
```

---

**次のセクション**: [20. 解析のトレース](20_provenance.md)
