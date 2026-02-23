# 17. ネガティブコントロールのOTUを抜く

> ※QIIME 2 のチュートリアルには記載が見られなかった。`qiime feature-table --help` コマンドの出力結果を参考に作成。

## 17.1 ネガコンのOTU IDの確認

`feature-table_cn.txt` や `feature-table_filterIS.txt` からネガコンのOTU IDを確認する。ネガコンに含まれるOTUのID（例: `64a6d38e951ce89cfd685c6d033a700e`）をメモする。

## 17.2 metadata ファイルの作成

1行目1列目に `#OTUID` と入力し、2行目以降にメモしたOTU IDを入力する。ファイル名は `NC_OTU.txt` とする。

```
#OTUID
64a6d38e951ce89cfd685c6d033a700e
ec9211f2975b1612cd3ad75b7822ad4f
```

## 17.3 OTUの除去

```bash
mkdir -p filterNC

# table ファイルからネガコンを抜く
qiime feature-table filter-features \
  --i-table table_cn.qza \
  --m-metadata-file NC_OTU.txt \
  --p-exclude-ids True \
  --o-filtered-table filterNC/table_filterNC.qza

# 可視化
qiime feature-table summarize \
  --i-table filterNC/table_filterNC.qza \
  --o-visualization filterNC/table_filterNC.qzv \
  --m-sample-metadata-file sample-metadata_cn.txt

# テキスト出力
qiime tools export \
  --input-path filterNC/table_filterNC.qza \
  --output-path filterNC/
mv filterNC/feature-table.biom filterNC/feature-table_filterNC.biom
biom convert -i filterNC/feature-table_filterNC.biom \
  -o filterNC/feature-table_filterNC.txt --to-tsv

# 代表配列からもNC を抜く
qiime feature-table filter-seqs \
  --i-data rep-seqs.qza \
  --m-metadata-file NC_OTU.txt \
  --p-exclude-ids True \
  --o-filtered-data filterNC/rep-seqs_filterNC.qza

qiime feature-table tabulate-seqs \
  --i-data filterNC/rep-seqs_filterNC.qza \
  --o-visualization filterNC/rep-seqs_filterNC.qzv
```

## 17.4 確認

リード数の差分を計算し、除去したOTUのリード数と一致することを確認する。また、`rep-seqs_filterNC.qzv` で Sequence count が正しく減少していること、除去したOTU IDが検索でヒットしないことを確認する。

---

**次のセクション**: [16. 統計検定](16_statistical_testing.md)
