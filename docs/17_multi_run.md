# 17. マルチラン処理・同一サンプルの結合

## 背景

DNA量が少なくリードが十分に得られないとき、同一サンプルを複数回Runすることがある。DADA2 はRun間で生じるシーケンスバイアスも補正するため、同一Run内のサンプルに対しての使用が前提になっている。

> *"The DADA2 denoising process is only applicable to a single sequencing run at a time, so we need to run this on a per sequencing run basis and then merge the results."*

## 手順

DADA2のデノイジングまでは別々のデータとして処理し、その後マージする。

```bash
# table ファイルの結合
# ⚠️ --p-overlap-method 'sum' を忘れずに指定する
qiime feature-table merge \
  --i-tables table1.qza \
  --i-tables table2.qza \
  --p-overlap-method 'sum' \
  --o-merged-table merged_table.qza

# 代表配列ファイルの結合
qiime feature-table merge-seqs \
  --i-data rep-seqs1.qza \
  --i-data rep-seqs2.qza \
  --o-merged-data merged_rep-seqs.qza
```

> **⚠️ 注意**: `--p-overlap-method 'sum'` がないと「同じ名前のファイルがある」としてエラーになる。

結合の前後で各サンプルのリード数の値が合致しているか、table ファイルや txt ファイルで必ず確認すること。結合する fastq.gz のファイル名が異なる場合は、誤った結合を防ぐために事前にファイル名を同一にすること。

---

**次のセクション**: [18. R/phyloseqへのエクスポート](18_export_to_r.md)
