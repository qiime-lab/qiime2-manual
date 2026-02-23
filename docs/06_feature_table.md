# 5. Feature table の作成

Feature table（QIIME 1 の OTU テーブル）を作成する。

```bash
qiime tools export \
  --input-path table_cn.qza \
  --output-path ./
mv feature-table.biom feature-table_cn.biom
biom convert -i feature-table_cn.biom -o feature-table_cn.txt --to-tsv
```

出力される `feature-table_cn.txt` はタブ区切りのテキストファイルで、各サンプルの各ASVのリード数が記載されている。

---

**次のセクション**: [06. 系統樹作成](07_phylogenetic_tree.md)
