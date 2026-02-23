# 10. 細菌種の同定

## 10.1 代表配列に細菌種名をアサインする

```bash
mkdir -p taxonomy

# classifier フォルダの直下に使用する分類器を置く
qiime feature-classifier classify-sklearn \
  --i-classifier classifier/silva138_v12/classifier_silva138_v12.qza \
  --i-reads rep-seqs.qza \
  --o-classification taxonomy/rep-seqs_classified.qza
```

| パラメータ | 説明 |
|-----------|------|
| `--i-classifier` | 分類器ファイル名 |
| `--i-reads` | 種同定する代表配列ファイル名 |
| `--o-classification` | 出力ファイル名 |

## 10.2 結果の可視化・テキスト出力

```bash
# 可視化
qiime metadata tabulate \
  --m-input-file taxonomy/rep-seqs_classified.qza \
  --o-visualization taxonomy/rep-seqs_classified.qzv

# テキスト出力
qiime tools export \
  --input-path taxonomy/rep-seqs_classified.qza \
  --output-path taxonomy
mv taxonomy/taxonomy.tsv taxonomy/rep-seqs_classified.tsv
```

## Confidence フィルタリングについて

`qiime feature-classifier classify-sklearn` コマンドの `--p-confidence` オプションでアサインの確からしさによるフィルタリングを行える（デフォルト: 0.7）。

処理の流れ：
1. 分類器を用いて代表配列に細菌種をアサイン
2. そのアサインの confidence を計算
3. confidence 値と `--p-confidence` で指定した閾値を比較
4. 閾値を下回る場合、分類レベルを1つ引き上げてアサイン（例：`g__Enterococcus` → `f__Enterococcaceae`）
5. 閾値を満たすまで繰り返す

| `--p-confidence` | 意味 |
|:---:|------|
| 0.7（デフォルト） | 標準的な閾値 |
| 0.8 | より厳密（特定の菌種に着目する場合） |
| 0 | confidence計算はするが閾値比較なし |
| disable | confidence計算自体をしない（全て -1.0） |

## 10.3 100%積み上げ棒グラフの作成

```bash
qiime taxa barplot \
  --i-table table_cn.qza \
  --i-taxonomy taxonomy/rep-seqs_classified.qza \
  --m-metadata-file sample-metadata_cn.txt \
  --o-visualization taxonomy/taxa-bar-plots.qzv
```

IS入りサンプルの場合：ISがスパイクしたサンプルからしか出ていないこと、組成が概ね同じことを確認する。

## 10.4 分類レベルごとにテキストで出力

```bash
# 科レベル (level 5)
qiime taxa collapse \
  --i-table table_cn.qza \
  --i-taxonomy taxonomy/rep-seqs_classified.qza \
  --p-level 5 \
  --o-collapsed-table taxonomy/collapsed_table5.qza
qiime tools export \
  --input-path taxonomy/collapsed_table5.qza \
  --output-path taxonomy
mv taxonomy/feature-table.biom taxonomy/collapsed_table5.biom
biom convert -i taxonomy/collapsed_table5.biom -o taxonomy/collapsed_table5.txt --to-tsv

# 属レベル (level 6)
qiime taxa collapse \
  --i-table table_cn.qza \
  --i-taxonomy taxonomy/rep-seqs_classified.qza \
  --p-level 6 \
  --o-collapsed-table taxonomy/collapsed_table6.qza
qiime tools export \
  --input-path taxonomy/collapsed_table6.qza \
  --output-path taxonomy
mv taxonomy/feature-table.biom taxonomy/collapsed_table6.biom
biom convert -i taxonomy/collapsed_table6.biom -o taxonomy/collapsed_table6.txt --to-tsv

# 種レベル (level 7)
qiime taxa collapse \
  --i-table table_cn.qza \
  --i-taxonomy taxonomy/rep-seqs_classified.qza \
  --p-level 7 \
  --o-collapsed-table taxonomy/collapsed_table7.qza
qiime tools export \
  --input-path taxonomy/collapsed_table7.qza \
  --output-path taxonomy
mv taxonomy/feature-table.biom taxonomy/collapsed_table7.biom
biom convert -i taxonomy/collapsed_table7.biom -o taxonomy/collapsed_table7.txt --to-tsv
```

| レベル | 分類階層 |
|:-----:|---------|
| 1 | Kingdom |
| 2 | Phylum |
| 3 | Class |
| 4 | Order |
| 5 | Family |
| 6 | Genus |
| 7 | Species |

---

**次のセクション**: [11. ISを抜く](12_is_removal.md)
