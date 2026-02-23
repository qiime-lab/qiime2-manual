# 3. QC・マージ結果の可視化

## 3.1 table ファイルの可視化

```bash
qiime feature-table summarize \
  --i-table table.qza \
  --o-visualization table.qzv \
  --m-sample-metadata-file sample-metadata.txt
```

## 3.2 代表配列ファイルの可視化・FASTA出力

```bash
# 可視化
qiime feature-table tabulate-seqs \
  --i-data rep-seqs.qza \
  --o-visualization rep-seqs.qzv

# FASTA形式でエクスポート
qiime tools export \
  --input-path rep-seqs.qza \
  --output-path ./
mv dna-sequences.fasta rep-seqs.fasta
```

## 3.3 QC結果の可視化

```bash
qiime metadata tabulate \
  --m-input-file denoising-stats.qza \
  --o-visualization denoising-stats.qzv
```

---

**次のセクション**: [04. サンプル名の変更](05_sample_rename.md)
