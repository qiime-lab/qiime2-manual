# 4. サンプル名の変更

> 参考: [the metadata tutorial](https://docs.qiime2.org/2026.1/tutorials/metadata/)

metadata ファイルを用いてサンプル名を変更する。

```bash
qiime feature-table group \
  --i-table table.qza \
  --p-axis sample \
  --m-metadata-file sample-metadata.txt \
  --m-metadata-column newID \
  --p-mode sum \
  --o-grouped-table table_cn.qza
```

可視化してきちんと名前が変更されていることを確認する：

```bash
qiime feature-table summarize \
  --i-table table_cn.qza \
  --o-visualization table_cn.qzv \
  --m-sample-metadata-file sample-metadata_cn.txt
```

---

**次のセクション**: [05. Feature table の作成](06_feature_table.md)
