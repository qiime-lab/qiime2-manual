# 22. 差次的存在量解析（Differential Abundance Analysis）

> **バージョン**: 本章は QIIME 2 2026.5 に対応しています。ANCOM-BC2 は QIIME 2 2025.4 以降で利用可能です。

## 概要

**差次的存在量解析（Differential Abundance Analysis）**とは、グループ間（例: 疾患群 vs. 健常群、投薬前 vs. 投薬後）で**存在量が統計的に異なる特定の菌種・ASV を同定**する解析です。

PERMANOVA（第19章）が「コミュニティ全体として差があるか」を検定するのに対し、差次的存在量解析は「どの菌種が具体的に違うのか」という問いに答えます。論文で「*Lactobacillus* が A 群で有意に多かった（p < 0.01、log fold change = 2.3）」と報告するためには、この解析が必要です。

---

## 組成データ問題（Compositionality Problem）

マイクロバイオームデータは**組成データ（compositional data）**です。各サンプルのリード数の総和が一定（ライブラリサイズ）であるため、ある菌が増えると他の菌の相対存在量は自動的に減少します。この「見かけの変化」を避けるために、ANCOM-BC2 や CLR 変換が推奨されます。

**具体例：**

```
サンプル A（健常）:  菌X = 500 reads, 菌Y = 500 reads  → 各50%
サンプル B（疾患）:  菌X = 900 reads, 菌Y = 100 reads  → 菌X 90%, 菌Y 10%
```

この場合、ライブラリサイズが同じなら菌X の増加は実際の増加かもしれません。しかし、もし菌Z が新たに 800 reads 検出されてライブラリが膨らんだだけであれば、菌X・菌Y の相対的な減少は「見かけ」に過ぎません。

**このため、単純な相対存在量での t 検定や Wilcoxon 検定は偽陽性を招く可能性があります。** ANCOM 系の手法や CLR（Centered Log-Ratio）変換を用いることで、この組成性の問題を回避できます。

---

## 22.1 ANCOM-BC2（推奨）

**ANCOM-BC2（Analysis of Compositions of Microbiomes with Bias Correction 2）**は現在最も推奨される差次的存在量解析手法です（Lin & Peddada, 2023）。

**特徴:**
- 組成データの偏りをバイアス補正（Bias Correction）により統計的に除去
- 共変量（年齢、性別、バッチなど）の調整が可能
- ログフォールドチェンジ（log fold change）として効果量が得られる
- 多重検定補正（BH 法など）に対応

### 前処理と実行

```bash
# 前処理：add-pseudocount（ゼロカウントの対数変換対策）
qiime composition add-pseudocount \
  --i-table table_cn.qza \
  --o-composition-table comp-table.qza

# ANCOM-BC2 の実行
qiime composition ancombc2 \
  --i-table table_cn.qza \
  --m-metadata-file sample-metadata_cn.txt \
  --p-formula "Group" \
  --p-p-adj-method "BH" \
  --o-differentials ancombc2-results.qza \
  --o-visualization ancombc2-results.qzv
```

| パラメータ | 説明 |
|-----------|------|
| `--i-table` | フィーチャーテーブル（フィルタリング済みのもの） |
| `--m-metadata-file` | サンプルメタデータ |
| `--p-formula` | 検定式（例: `"Group"`, `"Group + Age + Sex"`） |
| `--p-p-adj-method` | 多重検定補正法（`BH`=Benjamini-Hochberg 推奨） |
| `--o-differentials` | 差次的存在量の結果（.qza） |
| `--o-visualization` | インタラクティブ可視化（.qzv） |

**`--p-formula` の指定例:**

```bash
# グループのみ
--p-formula "Group"

# グループ + 共変量（年齢・性別）
--p-formula "Group + Age + Sex"

# 交互作用項
--p-formula "Group * TimePoint"
```

### 結果の読み方

ANCOM-BC2 の結果には各菌種について以下が含まれます：
- **lfc（log fold change）**: グループ間の対数フォールドチェンジ（効果量）
- **se**: 標準誤差
**p-val**: p 値
- **q-val（adjusted p-value）**: BH 補正済み p 値
- **diff（differentially abundant）**: 有意差ありかのフラグ（TRUE/FALSE）

q-val < 0.05 かつ |lfc| > 1（2倍以上の変化）を目安に、生物学的に意味のある差異を選別することが多いです。

---

## 22.2 クラシック ANCOM（参考）

ANCOM-BC2 が利用できない環境や、旧バージョンの QIIME 2 との互換性のために ANCOM クラシック版も利用できます。

```bash
qiime composition ancom \
  --i-table comp-table.qza \
  --m-metadata-file sample-metadata_cn.txt \
  --m-metadata-column Group \
  --o-visualization ancom-results.qzv
```

**注意:** クラシック ANCOM は W 統計量（その菌種が有意差を示した比較ペア数）を出力しますが、効果量や共変量調整機能がありません。新規解析では **ANCOM-BC2 を推奨**します。

---

## 手法の比較表

| 手法 | 組成データ対応 | 共変量調整 | 効果量 | QIIME 2 実装 |
|------|-------------|----------|--------|-------------|
| **ANCOM**（クラシック） | あり | なし | なし（W 統計量） | QIIME 2 内蔵 |
| **ANCOM-BC** | あり | あり | あり（log fold change） | QIIME 2 内蔵 |
| **ANCOM-BC2** | あり | あり | あり（改良版） | **QIIME 2 2025.4+**（推奨） |
| **ALDEx2** | あり（CLR変換） | 限定的 | あり | R パッケージ |
| **DESeq2** | なし（カウントベース） | あり | あり | R パッケージ（phyloseq 経由） |
| **LEfSe** | なし | なし | あり（LDA スコア） | スタンドアロンツール（レガシー） |

**選択の指針:**
- QIIME 2 内で完結させたい → **ANCOM-BC2**（2025.4+）
- R での詳細解析 → **ALDEx2**（組成対応）または **DESeq2**（豊富な可視化）
- LEfSe は現在レガシー扱いであり、組成性を考慮しないため注意が必要

---

## 解析の使い分け

| 目的 | 推奨手法 | 参照章 |
|------|---------|-------|
| グループ間の**全体的なコミュニティ差**を検定したい | PERMANOVA | 第19章 |
| グループ間の**α多様性の差**を検定したい | Kruskal-Wallis | 第19章 |
| **個別菌種レベルの差異**を同定したい | ANCOM-BC2 | 本章 |
| R での詳細な統計・可視化 | ALDEx2, DESeq2 | 第18章 |

---

## 注意事項

1. **サンプル数**: 差次的存在量解析はグループあたり最低 10 サンプル以上が推奨されます。サンプル数が少ない場合（n < 5/グループ）は統計的検出力が著しく低下します。

2. **希少な菌種のフィルタリング**: 解析前に、出現頻度が極めて低い特徴量（例: 全サンプルの 10% 未満、かつ総リードの 0.01% 未満）を除去することで、偽発見率（FDR）を改善できます。

3. **多重検定補正**: 数百〜数千の菌種を同時に検定するため、必ず多重検定補正（BH 法推奨）を適用してください（`--p-p-adj-method "BH"`）。

4. **分類レベルの選択**: ASV レベルよりも属レベル（level 6）や科レベル（level 5）に集約してから解析する方が、安定した結果が得られることが多いです（`qiime taxa collapse` で集約後に実行）。

---

**前のセクション**: [19. 統計検定](16_statistical_testing.md)
**次のセクション**: appendix など（各環境に応じて追加）
