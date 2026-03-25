# 8. Rarefaction curve の算出

> **IS入りサンプルの場合はスキップ**

---

## 概要

**Rarefaction（ラレファクション）** とは、シーケンス深度の不均一性（サンプル間でリード数が大きく異なる状況）に対処するための手法です。具体的には、全サンプルを指定したリード数（sampling depth）まで**ランダムサブサンプリング**し、同じ深度で多様性を比較できるようにします。

Rarefaction curve は横軸にサンプリングするリード数、縦軸に多様性指標（ASV 数など）をプロットしたグラフです。曲線が**プラトー（頭打ち）** に達していれば、そのリード数では群集の多様性を十分に捉えられていることを示します。逆に、プラトーに達していない場合はシーケンス深度が不足している可能性があります。

---

## メリット・デメリット

| 観点 | 内容 |
|------|------|
| **メリット: シーケンス深度差の制御** | 深度が異なるサンプル間でも公平な比較が可能になる |
| **メリット: 広く受け入れられた手法** | 生態学・微生物学で長年使われており、解釈の共通認識がある |
| **メリット: シンプルで理解しやすい** | ランダムサブサンプリングという概念が直感的 |
| **デメリット: データを破棄する** | sampling depth を超えるリードは全て捨てられるため、情報の損失が生じる |
| **デメリット: 乱数依存の再現性問題** | 実行のたびに異なる乱数シードが使われ、完全に同一の結果を再現しにくい |
| **デメリット: プラトー未達サンプルの問題** | シーケンス深度が不十分なサンプルでは曲線がプラトーに達せず、深度不足を見逃す可能性がある |

---

## Rarefaction をめぐる論争

Rarefaction の是非については研究者の間で継続的な議論があります：

- **McMurdie & Holmes (2014)** は、rarefaction はデータを捨てる非効率な手法であり、モデルベースの正規化（DESeq2 など）の方が統計的に優れていると主張しました
- **Weiss et al. (2017)** は、rarefaction はサンプリング深度の偏りを制御する実用的な手法であり、特定の状況では依然として有効であることを示しました

現在のコンセンサスとしては、**探索的解析や多様性解析には rarefaction（または q2-boots）が広く使われる一方、差異的存在量解析（differential abundance analysis）には CSS・DESeq2・CLR などの正規化が推奨される**という方向性が定着しています。

---

## Rarefaction curve の算出コマンド

```bash
mkdir -p rarefaction/csv

# observed OTUs, Shannon, Faith PD
qiime diversity alpha-rarefaction \
  --i-table table_cn.qza \
  --i-phylogeny phylogeny/rooted-tree.qza \
  --p-max-depth 9899 \
  --m-metadata-file sample-metadata_cn.txt \
  --o-visualization rarefaction/alpha-rarefaction.qzv

# Chao1（別途算出）
qiime diversity alpha-rarefaction \
  --i-table table_cn.qza \
  --p-max-depth 9899 \
  --p-metrics chao1 \
  --m-metadata-file sample-metadata_cn.txt \
  --o-visualization rarefaction/alpha-rarefaction_chao1.qzv
```

> **Note**: `--p-max-depth` には最小リード数を指定する。

---

## 8.1 テキストで出力

```bash
qiime tools export \
  --input-path rarefaction/alpha-rarefaction.qzv \
  --output-path rarefaction/calculation

qiime tools export \
  --input-path rarefaction/alpha-rarefaction_chao1.qzv \
  --output-path rarefaction/calculation_chao1

cp rarefaction/calculation/*.csv rarefaction/csv/
cp rarefaction/calculation_chao1/*.csv rarefaction/csv/
```

> **Tip**: QIIME 2 の rarefaction curve は QIIME 1 よりも安定する（プラトーに達しやすい）。これはデノイジングによってシーケンスエラー由来のASVが減少するためと考えられる。

---

## 8.2 q2-boots によるブートストラップ Rarefaction（2025.10+）

従来の rarefaction は1回のランダムサブサンプリングに基づいているため、結果が乱数シードに依存するという問題があります。**q2-boots** はラレファクションを **n 回繰り返し**、その結果を統合することでより安定した多様性指標を算出します。

F1000Research 2025 の論文（Robeson et al.）で詳細が報告されており、QIIME 2 **2025.10** 以降で利用可能です。

```bash
# q2-boots: rarefaction を n 回繰り返し結果を統合
qiime boots core-metrics \
  --i-table table_cn.qza \
  --i-phylogeny phylogeny/rooted-tree.qza \
  --p-sampling-depth 11045 \
  --p-n 100 \
  --p-replacement \
  --m-metadata-file sample-metadata_cn.txt \
  --output-dir boots-core-metrics-results
```

| パラメータ | 説明 |
|-----------|------|
| `--p-sampling-depth` | 各反復でサブサンプリングするリード数 |
| `--p-n` | rarefaction の反復回数（多いほど安定、計算時間増加） |
| `--p-replacement` | 復元抽出を使用する（`--p-no-replacement` で非復元抽出） |
| `--output-dir` | 出力ディレクトリ |

> **2026.1 以降のデフォルト動作**: 距離行列の集約には **medoid 法**が使われます。n 回の rarefaction で得られた距離行列群の中から「最も代表的なもの（他全行列との距離の和が最小）」を選択する手法で、単純な平均よりも外れ値に対してロバストです。

---

## 8.3 手法の比較

| 手法 | 再現性 | データ活用 | 推奨場面 |
|------|--------|-----------|---------|
| **従来の Rarefaction**（1回） | 低い（乱数依存） | 低い（sampling depth 以上のデータを破棄） | 迅速な探索的解析 |
| **q2-boots**（n 回繰り返し） | 高い（統合により安定） | 中程度（繰り返しサンプリングで安定化） | 論文・プレゼンテーション用の最終解析 |
| **正規化（CSS / DESeq2 / CLR）** | 高い（決定的な変換） | 高い（全データを保持） | 差異的存在量解析（differential abundance） |

---

**次のセクション**: [09. 分類器作成](10_classifier.md)
