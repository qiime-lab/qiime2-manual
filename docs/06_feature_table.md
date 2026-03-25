# 5. Feature table の作成

---

## 概要

**Feature table**（QIIME 1 でいう OTU テーブル）は、マイクロバイオーム解析の中心的なデータ構造です。QIIME 2 では BIOM 形式（`.biom`）で保存されており、**行がASV（Amplicon Sequence Variant）、列がサンプル**の行列として、各サンプルにおける各ASVのリード数（カウント）を保持します。

```
          Sample_01  Sample_02  Sample_03  ...
ASV_0001      1234        892       2100  ...
ASV_0002       456          0        311  ...
ASV_0003         0        103         78  ...
...
```

DADA2 によるデノイジング後の feature table は、シーケンスエラー由来のノイズが除去された正確なカウントデータです。この table をもとに、多様性解析・分類・統計検定などあらゆる下流解析が行われます。

---

## 5.1 テキスト形式でのエクスポート

```bash
qiime tools export \
  --input-path table_cn.qza \
  --output-path ./
mv feature-table.biom feature-table_cn.biom
biom convert -i feature-table_cn.biom -o feature-table_cn.txt --to-tsv
```

出力される `feature-table_cn.txt` はタブ区切りのテキストファイルで、各サンプルの各ASVのリード数が記載されている。

---

## 5.2 Feature table の要約（summarize）

QIIME 2 **2026.1** では `summarize` コマンドが大幅にリファクタリングされ、旧バージョンで別プラグインとして存在していた `summarize_plus` の機能が標準の `summarize` に統合されました。これにより、サンプルあたりのリード数分布・ヒストグラム・ASV数の統計が単一コマンドで取得できます。

```bash
qiime feature-table summarize \
  --i-table table_cn.qza \
  --o-visualization table_cn.qzv \
  --m-sample-metadata-file sample-metadata_cn.txt
```

> **2026.1 の変更点**: タクソノミー情報と feature table をマージする際に、分類階層の深さが一致しない場合（例：一部のASVがGenusまで、他がSpeciesまで分類されている場合）に **taxonomy merge depth mismatch** の警告が表示されるようになりました。この警告はエラーではありませんが、マージ結果の解釈に影響する場合があるため、タクソノミーファイルの確認を推奨します。

---

## 5.3 正規化（Normalization）

**2025.4** から `qiime feature-table normalize` コマンドが追加され、ラレファクション（rarefaction）以外の正規化手法を QIIME 2 のワークフロー内で直接適用できるようになりました。

### 正規化コマンド（CSS の例）

```bash
qiime feature-table normalize \
  --i-table table_cn.qza \
  --p-method css \
  --o-normalized-table table_normalized.qza
```

### 正規化手法の比較

| 手法 | メリット | デメリット |
|------|---------|-----------|
| **Rarefaction**（ランダムサブサンプリング） | シンプル、広く使われている、シーケンス深度の不均一性を直接制御できる | データを破棄する、乱数シードによる再現性の問題、プラトーに達しない場合がある |
| **CSS**（Cumulative Sum Scaling） | 全データを保持する、metagenomeSeq で実績あり | 特定の分布を前提としている、全解析での性能が一定でない |
| **DESeq2 スタイル**（モデルベース正規化） | モデルベースで統計的な根拠が明確 | カウントデータ向けに設計されており、全デザインに適用できない場合がある |
| **CLR**（Centered Log-Ratio） | 組成データの特性（compositional data）を正しく扱える | ゼロ値の処理が必要（擬似カウントや imputation が必要） |

> **推奨**: 多様性の可視化・統計検定には rarefaction または q2-boots（[09. Rarefaction curve](09_rarefaction.md) 参照）が一般的です。差異的存在量解析（differential abundance analysis）を行う場合は CSS、CLR、DESeq2 スタイルの正規化が適しています。

---

**次のセクション**: [06. 系統樹作成](07_phylogenetic_tree.md)
