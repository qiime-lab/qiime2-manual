# 11. IS（内部標準）を抜く

> 参考: [Filtering sequences](https://docs.qiime2.org/2026.1/tutorials/filtering/)

## ISの除去

```bash
mkdir -p filterIS/taxonomy

# table ファイルからISを抜く
qiime taxa filter-table \
  --i-table table_cn.qza \
  --i-taxonomy taxonomy/rep-seqs_classified.qza \
  --p-exclude rhizobium,Salinibacterium \
  --o-filtered-table filterIS/table_filterIS.qza

# 代表配列ファイルからISを抜く
qiime taxa filter-seqs \
  --i-sequences rep-seqs.qza \
  --i-taxonomy taxonomy/rep-seqs_classified.qza \
  --p-exclude rhizobium,Salinibacterium \
  --o-filtered-sequences filterIS/rep-seqs_filterIS.qza
```

## 結果の確認

```bash
# table ファイルの可視化
qiime feature-table summarize \
  --i-table filterIS/table_filterIS.qza \
  --o-visualization filterIS/table_filterIS.qzv \
  --m-sample-metadata-file sample-metadata_cn.txt

# 代表配列ファイルの可視化
qiime feature-table tabulate-seqs \
  --i-data filterIS/rep-seqs_filterIS.qza \
  --o-visualization filterIS/rep-seqs_filterIS.qzv

# Feature table の作成
qiime tools export \
  --input-path filterIS/table_filterIS.qza \
  --output-path filterIS/
mv filterIS/feature-table.biom filterIS/feature-table_filterIS.biom
biom convert -i filterIS/feature-table_filterIS.biom -o filterIS/feature-table_filterIS.txt --to-tsv
```

> **確認ポイント**: table ファイルでは OTU（feature）数とリード数、代表配列ファイルでは Sequence count が減少していることを確認する。

> **⚠️ 注意**: `--p-exclude` は菌種名の部分一致で除外する。科レベルで終わっている場合（`f__Rhizobiaceae;` など）は除外できない。IS除去後の taxonomy ファイルに Rhizobiaceae や Microbacteriaceae が含まれていないか確認すること。

---

**次のセクション**: [12. IS除去後の多様性解析](13_is_diversity.md)
