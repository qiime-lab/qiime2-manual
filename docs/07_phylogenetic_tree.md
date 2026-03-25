# 6. 代表配列の系統樹作成

> **IS入りサンプルの場合はスキップ** → [12. IS除去後の系統樹作成](13_is_diversity.md)

---

## 概要

系統樹（phylogenetic tree）は、ASV間の進化的関係を表す樹形図です。**UniFrac 距離**や**Faith's PD（Phylogenetic Diversity）** をはじめとする系統発生的多様性指標の計算には、有根系統樹が必須です。これらの指標は「どれだけ多様か」だけでなく「進化的にどれだけ多様か」を定量化するため、単純なリード数ベースの指標と比べて生物学的な意義が大きいとされています。

---

## 処理の流れ

系統樹作成は以下の4ステップで構成されます：

1. **MAFFT によるマルチプルアラインメント**
   全 ASV の代表配列を整列させ、相同な塩基位置を揃えます。配列長が揃っていないと次のステップに進めません。

2. **mask（高変異領域のフィルタリング）**
   アラインメントの中で変異が激しすぎる位置（phylogenetic noise になりやすい領域）をマスクし、系統樹の精度を高めます。

3. **FastTree による系統樹構築（無根系統樹）**
   マスク済みアラインメントから近似最尤法で系統樹を作成します。QIIME 2 が内部で使用する FastTree は高速ですが、RAxML や IQ-TREE に比べると精度が劣ることがあります。

4. **midpoint rooting（中点根付け）**
   最も離れた2点の中間点を根として設定し、有根系統樹を作成します。外群（outgroup）を指定しない代わりに、中点を根と仮定します。

---

## メリット・デメリット

| 項目 | 内容 |
|------|------|
| **メリット: 系統発生的多様性指標が使える** | Faith PD・UniFrac など、進化的関係を考慮した指標を算出できる |
| **メリット: 進化的関係の可視化** | ASV 同士の類縁関係を視覚的に把握できる |
| **デメリット: アンプリコン領域の制約** | 16S rRNA の一部の領域（例: V3-V4 領域）から得られる系統樹は、必ずしも真の進化系統樹を反映しない |
| **デメリット: 短リードによる解像度の限界** | 300 bp 程度のリードでは長い系統樹の枝を正確に推定することが難しい |
| **デメリット: 大規模データでの計算コスト** | ASV 数が数万を超える場合、MAFFT と FastTree の実行に長時間を要する（後述の `--p-parttree` オプション参照） |

---

## 系統樹作成コマンド

```bash
# ディレクトリ作成
mkdir -p phylogeny

qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences rep-seqs.qza \
  --o-alignment phylogeny/aligned-rep-seqs.qza \
  --o-masked-alignment phylogeny/masked-aligned-rep-seqs.qza \
  --o-tree phylogeny/unrooted-tree.qza \
  --o-rooted-tree phylogeny/rooted-tree.qza
```

| パラメータ | 説明 |
|-----------|------|
| `--i-sequences` | 入力する代表配列ファイル名 |
| `--o-alignment` | 出力するアラインメントファイル名 |
| `--o-masked-alignment` | マスク処理後のアラインメントファイル名 |
| `--o-tree` | 出力する無根系統樹ファイル名 |
| `--o-rooted-tree` | 出力する有根系統樹ファイル名 |

---

## 大規模データセットへの対応（2025.7 / 2026.1）

### MAFFT `--parttree` フラグ（2025.7 で追加）

ASV 数が **50,000 を超える**大規模データセットでは、通常の MAFFT アラインメントは大量のメモリと時間を必要とします。QIIME 2 **2025.7** で `--p-parttree` オプションが追加され、MAFFT の `--large` フラグ相当の処理（部分木ガイドアラインメント）を有効にできるようになりました。

```bash
qiime alignment mafft \
  --i-sequences rep-seqs.qza \
  --p-parttree \
  --o-alignment aligned-rep-seqs.qza
```

`--p-parttree` を使うと、全配列を直接アラインメントする代わりに部分木を用いた近似アラインメントを行うため、**RAM 使用量と計算時間を大幅に削減**できます。精度はわずかに低下しますが、数万以上の ASV を扱う場合には現実的な選択肢です。

### アラインメント戦略の明示的指定（2026.1）

QIIME 2 **2026.1** では `qiime alignment mafft` コマンドにアラインメント戦略を明示的に指定するオプションが追加されました。これにより、データセット規模に応じて最適なアラインメント手法を選択できます。

> **Tip**: 通常の解析（〜数千 ASV）では `align-to-tree-mafft-fasttree` を使用してください。大規模データセット（50,000 ASV 以上）では `--p-parttree` オプション付きの個別 `mafft` コマンドを推奨します。

---

**次のセクション**: [07. 多様性解析](08_diversity.md)
