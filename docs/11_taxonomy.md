# 11. 細菌種の同定

> **バージョン**: 本章は QIIME 2 2026.5 に対応しています。

## 概要

**分類学的アサイン（Taxonomy Assignment）**とは、DADA2 等で得られた ASV（代表配列）に対して、前章で作成した分類器を用いて「どの生物かを表す名前（分類ラベル）」を付与するプロセスです。

この工程を経て初めて、「このサンプルには *Lactobacillus* が多い」「*Bacteroides* は群間で差がある」といった生物学的な解釈が可能になります。ASV の段階では単なる塩基配列の識別子に過ぎませんが、分類アサイン後は菌叢の組成、多様性、群間比較、疾患・環境との関連付けなど、あらゆる下流解析の基盤となります。

**ポイント:**
- Confidence スコアにより、各 ASV の分類信頼性が数値として得られる
- Confidence 閾値以下の場合は自動的に上位の分類レベルに引き上げられる（例: 種 → 属）
- 分類結果はメタデータとして各種可視化・統計解析に利用される

---

## 11.1 代表配列に細菌種名をアサインする

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

---

## 11.2 結果の可視化・テキスト出力

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

---

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

---

## 11.3 100%積み上げ棒グラフの作成

```bash
qiime taxa barplot \
  --i-table table_cn.qza \
  --i-taxonomy taxonomy/rep-seqs_classified.qza \
  --m-metadata-file sample-metadata_cn.txt \
  --o-visualization taxonomy/taxa-bar-plots.qzv
```

IS入りサンプルの場合：ISがスパイクしたサンプルからしか出ていないこと、組成が概ね同じことを確認する。

### barplot2 ビジュアライザー（2025.10+）

QIIME 2 2025.10 以降、**`taxa barplot2`** が利用可能になりました。従来の `barplot` に加え、インタラクティブなタクソン・サンプルフィルタリングと展開（ドリルダウン）機能が追加されており、将来的に `barplot` を置き換える予定です。

```bash
# 新しい barplot2（taxon/sample フィルタリング・展開機能付き）
qiime taxa barplot2 \
  --i-table table_cn.qza \
  --i-taxonomy taxonomy/rep-seqs_classified.qza \
  --m-sample-metadata-file sample-metadata_cn.txt \
  --o-visualization taxonomy/taxa-bar-plots2.qzv
```

**barplot2 の主な新機能:**
- 特定のタクソン（例: *Firmicutes* のみ）を絞り込んで表示できる
- サンプルをインタラクティブにフィルタリングできる
- 任意の分類レベルに「展開（drill down）」して下位の分類を確認できる
- QIIME 2 View 上でのインタラクティビティが向上

> 現時点では `barplot` と `barplot2` の両方が利用可能です。論文投稿など最終的な図の作成には `barplot2` または R/ggplot2 を推奨します。

---

### QIIME 2 分類可視化のメリット・デメリット

| 項目 | 内容 |
|------|------|
| **メリット** | QIIME 2 View 上でインタラクティブに操作できる（グループ並べ替え、レベル切り替え） |
| **メリット** | 複数の分類レベル（門〜種）を即座に切り替えて俯瞰できる |
| **メリット** | メタデータによるサンプルグループ化が簡単 |
| **デメリット** | 色のカスタマイズに制限がある（論文品質の図には不向き） |
| **デメリット** | 出版用のグラフ作成には限界がある |
| **推奨** | 探索的解析には QIIME 2 View を使い、最終的な論文図は **R（ggplot2/microbiome/phyloseq）** で作成することを推奨 |

---

## 11.4 分類レベルごとにテキストで出力

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

**次のセクション**: [12. ISを抜く](12_is_removal.md)
