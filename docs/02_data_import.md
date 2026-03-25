# 1. データの読み込み

> 参考: [QIIME 2 importing tutorial](https://docs.qiime2.org/2026.5/tutorials/importing/)
> 参考: [FASTQ format](https://en.wikipedia.org/wiki/FASTQ_format)

## データインポートの概要

QIIME 2 の解析は、生の FASTQ ファイルを QIIME 2 独自の **アーティファクト形式（`.qza`）** に変換することから始まる。このステップは単なるファイル形式の変換ではなく、以下の重要な役割を担っている。

- **データ型の明示**: 「これはペアエンドのシーケンスデータだ」という情報がアーティファクトに埋め込まれる。型が合わない操作を実行しようとするとエラーになるため、意図しない誤操作を防げる
- **Provenance の開始点**: 以降のすべての解析ステップはこのアーティファクトを起点として記録される。最終結果の `.qzv` ファイルを開くと、どのデータをどのコマンドで処理したかを完全に遡ることができる

### メリット・デメリット

**メリット**
- アーティファクトシステムにより、データの整合性と解析の追跡（Provenance）が保証される
- データ型の不一致がコマンド実行時に検出されるため、パイプラインの途中でのミスが減る

**デメリット**
- `.qza` ファイルはZIPアーカイブであり、中身のFASTQファイルを直接編集・確認することが直感的ではない（`unzip` を使えば展開は可能）
- `.qza` 形式を初めて扱う際には概念的な学習コストがかかる

## FASTQ ファイル形式について

FASTQ ファイルには複数のデータ形式があり、QIIME 2 ではデータ形式によって読み込み方法が異なる。Illumina の MiSeq は「**Casava 1.8 paired-end demultiplexed FASTQ**」という形式である。この形式ではシーケンサーから出力されるファイル名が `1_2_3_4_5.fastq.gz` となっている。

ファイル名の構造：
1. the sample identifier
2. the barcode sequence or a barcode identifier
3. the lane number
4. the direction of the read (i.e. R1 or R2)
5. the set number

例：`SP01_S317_L001_R1_001.fastq.gz`

QIIME 2 はこのファイル名パターンを自動認識して、サンプルとペアエンドリードの対応を決定する。ファイル名がこのパターンから外れている場合は、後述のマニフェストファイル形式を使用する。

## 1.1 データの読み込み

### Casava 1.8 形式（通常のMiSeqデータ）

```bash
qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path input \
  --input-format CasavaOneEightSingleLanePerSampleDirFmt \
  --output-path demux.qza
```

| パラメータ | 説明 |
|-----------|------|
| `--type` | インポート後のデータ形式 |
| `--input-path` | 解析したいファイルがある場所 |
| `--input-format` | 読み込むデータ形式 |
| `--output-path` | インポート後のファイル名 |

### マニフェストファイルを使ったインポート（ファイル名が非標準の場合）

ファイル名が Casava 1.8 形式に従っていない場合や、異なるディレクトリに散在している場合は、マニフェストファイルを作成してインポートする。

マニフェストファイル（`manifest.tsv`）の形式：

```
sample-id	forward-absolute-filepath	reverse-absolute-filepath
SP01	/path/to/SP01_R1.fastq.gz	/path/to/SP01_R2.fastq.gz
SP02	/path/to/SP02_R1.fastq.gz	/path/to/SP02_R2.fastq.gz
```

```bash
qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path manifest.tsv \
  --input-format PairedEndFastqManifestPhred33V2 \
  --output-path demux.qza
```

### SRA からのデータ取得（q2-fondue、2025.10+）

公開データの再解析を行う場合、**q2-fondue** プラグインを使用して NCBI SRA からデータとメタデータをプログラマティックに取得できる。論文で使われたデータを再解析する際や、他のコホートとの比較解析に特に有用である。

```bash
# SRA アクセッション番号のリストを用意
qiime fondue get-sequences \
  --p-accession-ids SRP123456 \
  --p-email your-email@example.com \
  --o-paired-reads sra-demux.qza \
  --o-failed-runs failed.qza \
  --o-metadata sra-metadata.qza
```

> q2-fondue は標準の amplicon distribution には含まれていない場合がある。`qiime info` でインストール済みのプラグインを確認し、未インストールの場合は [library.qiime2.org](https://library.qiime2.org) でインストール方法を確認すること。

## 1.2 読み込んだデータの可視化

インポートが成功したら、各サンプルのリード数とクオリティプロファイルを確認する。この可視化は後述のDADA2パラメータ設定の根拠となる重要なステップである。

```bash
qiime demux summarize \
  --i-data demux.qza \
  --o-visualization demux.qzv
```

| パラメータ | 説明 |
|-----------|------|
| `--i-data` | 可視化したい qza ファイル名 |
| `--o-visualization` | 出力する qzv ファイル名 |

`.qzv` ファイルは [QIIME 2 View](https://view.qiime2.org/) にアップロードすることで結果を確認できる。

各サンプルのリード数が確認できる。Interactive Quality Plot タブをクリックすると全体的なリードのクオリティを確認できる。通常はこのクオリティを参考にして次のクオリティーコントロールで入力する値を設定する（ただし、ルーチンなMiSeqの場合、クオリティは概ね安定しているので下記コマンドのパラメータで問題ない場合が多い）。

### .qza と .qzv ファイルについて

QIIME 2 では処理の結果得られるファイル（`.qza`）とその結果を可視化したファイル（`.qzv`）が厳密に分けられている。これらはバイナリファイル（実体はZIPアーカイブ）であり、中身を直接人間が理解することはできない。この仕組みによって、意図しないデータの変更が行いにくく、データ解析の流れを可視化（Provenance tracking）することが可能になっている。

> **Tip**: `.qza` / `.qzv` は実際にはZIPファイルなので、`unzip` コマンドで中身を直接展開することも可能。

---

**次のセクション**: [02. クオリティーコントロール](03_quality_control.md)
