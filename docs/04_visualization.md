# 3. QC・マージ結果の可視化

## QIIME 2 の可視化システム

QIIME 2 の可視化は、解析結果を `.qzv`（QIIME 2 Visualization）形式で出力し、[QIIME 2 View](https://view.qiime2.org/) でインタラクティブに確認する仕組みを基本とする。`.qzv` はアーティファクト（`.qza`）と同様にZIPアーカイブであり、内部にHTMLとデータを格納している。

### 可視化のメリット・デメリット

QIIME 2 の組み込み可視化は便利だが、R や Python による可視化との使い分けを理解しておくことが重要である。

| 観点 | QIIME 2 組み込み可視化 | R / Python |
|------|----------------------|------------|
| **手軽さ** | コマンド一発で可視化できる。コーディング不要 | ggplot2、matplotlib 等のコードが必要 |
| **インタラクティブ性** | ブラウザ上でインタラクティブに操作可能 | 静的な図が基本（plotly等でインタラクティブも可能） |
| **Provenance リンク** | 可視化ファイルに解析履歴が埋め込まれている | 別途管理が必要 |
| **カスタマイズ性** | 限定的。フォントや配色の細かい変更は難しい | 高い柔軟性。論文掲載用の図を作成できる |
| **出版用図の作成** | そのままでは難しい場合が多い | 論文・報告書向けの高品質な図を作成できる |

> **実践的な推奨**: 解析中の確認・探索的解析には QIIME 2 View を活用し、論文や報告書向けの最終図は R（ggplot2）または Python（matplotlib/seaborn）で作成するハイブリッドアプローチが現実的である（[18. R への出力](18_export_to_r.md) 参照）。

## 3.1 table ファイルの可視化

Feature table の要約を可視化する。各サンプルのリード数（フィーチャーカウント）の分布、サンプルごとのフィーチャー数を確認できる。この情報は後の rarefaction depth の決定に使用する。

```bash
qiime feature-table summarize \
  --i-table table.qza \
  --o-visualization table.qzv \
  --m-sample-metadata-file sample-metadata.txt
```

## 3.2 代表配列ファイルの可視化・FASTA出力

各 ASV の代表配列の長さ分布と配列一覧を可視化する。FASTA としてエクスポートすることで、BLAST などの外部ツールでの配列検索にも利用できる。

```bash
# 可視化
qiime feature-table tabulate-seqs \
  --i-data rep-seqs.qza \
  --o-visualization rep-seqs.qzv

# FASTA形式でエクスポート
qiime tools export \
  --input-path rep-seqs.qza \
  --output-path ./
mv dna-sequences.fasta rep-seqs.fasta
```

## 3.3 QC結果の可視化

DADA2 の各ステップ（フィルタリング、デノイジング、マージ、キメラ除去）でどれだけのリードが残ったかを表形式で確認できる。リードの歩留まりが著しく低いサンプルがある場合は、DADA2 のパラメータ（特に `--p-trunc-len-f` / `--p-trunc-len-r`）を見直すことを検討する。

```bash
qiime metadata tabulate \
  --m-input-file denoising-stats.qza \
  --o-visualization denoising-stats.qzv
```

## 3.4 q2-vizard による高度な可視化（2024.10+）

2024.10 リリースより、**q2-vizard** プラグインが利用可能になった。これはメタデータに基づいたインタラクティブなチャートを手軽に作成するためのプラグインであり、散布図、ヒートマップ、折れ線グラフ、箱ひげ図などを生成できる。コードを書かずに探索的なデータ可視化が可能になる点が特徴である。

```bash
# メタデータに基づく散布図
qiime vizard scatterplot \
  --m-metadata-file sample-metadata_cn.txt \
  --o-visualization scatter.qzv

# 箱ひげ図
qiime vizard boxplot \
  --m-metadata-file sample-metadata_cn.txt \
  --o-visualization boxplot.qzv

# ヒートマップ
qiime vizard heatmap \
  --m-metadata-file sample-metadata_cn.txt \
  --o-visualization heatmap.qzv

# 折れ線グラフ（時系列データ等）
qiime vizard lineplot \
  --m-metadata-file sample-metadata_cn.txt \
  --o-visualization lineplot.qzv
```

> q2-vizard は標準の amplicon distribution に含まれているが、バージョンによって利用可能なサブコマンドが異なる場合がある。`qiime vizard --help` で利用可能なコマンドを確認すること。

## 3.5 レポート統合可視化（2025.10+）

2025.10 リリースより、`qiime tools make-report` コマンドで複数の `.qzv` ファイルを1つの統合レポートにまとめることができるようになった。複数の可視化結果をまとめてレビューしたい場合や、共同研究者・クライアントに結果を共有する際に便利である。

```bash
qiime tools make-report \
  --i-results table.qzv denoising-stats.qzv rep-seqs.qzv \
  --o-report combined-report.qzv
```

> **活用例**: 解析の各ステップで生成した `.qzv` ファイルをまとめた combined-report を共同研究者に共有することで、個別のファイルを送り合う手間が省ける。

## 3.6 QIIME 2 View の改善点（2025.x〜）

[QIIME 2 View](https://view.qiime2.org/) にはここ数バージョンで以下の改善が加えられている。

- **`.qza` のプレビュー**: 従来は `.qzv` のみ対応していたが、`.qza` ファイルもドロップすることで内部メタデータや型情報を確認できるようになった
- **Provenance ベースのエラー報告**: Provenance タブで、解析の各ステップでどのエラーが発生したかを追跡しやすくなった。エラーの原因を過去の解析に遡って調査するのに役立つ
- **モバイル対応の改善**: スマートフォンやタブレットからの表示が最適化された

---

**次のセクション**: [04. サンプル名の変更](05_sample_rename.md)
