# 1. データの読み込み

> 参考: [QIIME 2 importing tutorial](https://docs.qiime2.org/2026.1/tutorials/importing/)  
> 参考: [FASTQ format](https://en.wikipedia.org/wiki/FASTQ_format)

FASTQ ファイルには複数のデータ形式があり、QIIME 2 ではデータ形式によって読み込み方法が異なる。Illumina の MiSeq は「Casava 1.8 paired-end demultiplexed FASTQ」という形式である。この形式ではシーケンサーから出力されるファイル名が `1_2_3_4_5.fastq.gz` となっている。

ファイル名の構造：
1. the sample identifier
2. the barcode sequence or a barcode identifier
3. the lane number
4. the direction of the read (i.e. R1 or R2)
5. the set number

例：`SP01_S317_L001_R1_001.fastq.gz`

## 1.1 データの読み込み

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

## 1.2 読み込んだデータの可視化

```bash
qiime demux summarize \
  --i-data demux.qza \
  --o-visualization demux.qzv
```

| パラメータ | 説明 |
|-----------|------|
| `--i-data` | 可視化したい qza ファイル名 |
| `--o-visualization` | 出力する qzv ファイル名 |

### .qza と .qzv ファイルについて

QIIME 2 では処理の結果得られるファイル（`.qza`）とその結果を可視化したファイル（`.qzv`）が厳密に分けられている。これらはバイナリファイル（実体はZIPアーカイブ）であり、中身を直接人間が理解することはできない。この仕組みによって、意図しないデータの変更が行いにくく、データ解析の流れを可視化（Provenance tracking）することが可能になっている。

`.qzv` ファイルは [QIIME 2 View](https://view.qiime2.org/) にアップロードすることで結果を確認できる。

> **Tip**: `.qza` / `.qzv` は実際にはZIPファイルなので、`unzip` コマンドで中身を直接展開することも可能。

各サンプルのリード数が確認できる。Interactive Quality Plot タブをクリックすると全体的なリードのクオリティを確認できる。通常はこのクオリティを参考にして次のクオリティーコントロールで入力する値を設定する（ただし、ルーチンなMiSeqの場合、クオリティは概ね安定しているので下記コマンドのパラメータで問題ない場合が多い）。

---

**次のセクション**: [02. クオリティーコントロール](03_quality_control.md)
