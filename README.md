# QIIME 2 解析マニュアル

[![QIIME 2](https://img.shields.io/badge/QIIME%202-2026.5-blue)](https://qiime2.org)
[![SILVA](https://img.shields.io/badge/SILVA-138.2-green)](https://www.arb-silva.de/)
[![License: CC BY-NC-SA 4.0](https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-sa/4.0/)

初学者が QIIME 2 による 16S rRNA アンプリコンシーケンス解析を学ぶための包括的日本語マニュアル

## 概要

本マニュアルは、QIIME 2 を使ったマイクロバイオーム解析をこれから学ぶ人のためのガイドです。各解析ステップが **何をしているのか**・**なぜ必要なのか**・**どのような選択肢があるのか** を、メリット・デメリットとともに解説します。内部標準（IS）を用いた絶対定量ワークフローを含む、ラボで実際に使用されている解析パイプラインも詳細に記載しています。

> **Original manual by:** 佐藤翼（based on work by 月見友哉）
> **Updated & published by:** [Rhizobium-gits](https://github.com/Rhizobium-gits)

## 対応環境

| 項目 | バージョン |
|------|-----------|
| QIIME 2 | 2026.5 (qiime2 distribution) |
| リファレンスDB | SILVA 138.2 (SSURef NR99) |
| Python | 3.10 |
| OS | macOS (Intel/Apple Silicon), Linux, Windows (WSL2) |

## マニュアル構成

```
docs/
├── 00_introduction.md          # はじめに・メタ16S解析の概要
├── 01_installation.md          # インストール方法
├── 02_data_import.md           # データの読み込み
├── 03_quality_control.md       # クオリティーコントロール（DADA2）
├── 04_visualization.md         # QC結果の可視化
├── 05_sample_rename.md         # サンプル名の変更
├── 06_feature_table.md         # Feature tableの作成
├── 07_phylogenetic_tree.md     # 系統樹作成
├── 08_diversity.md             # 多様性解析（α/β）
├── 09_rarefaction.md           # Rarefaction curve
├── 10_classifier.md            # 分類器作成（SILVA 138.2）
├── 11_taxonomy.md              # 細菌種同定
├── 12_is_removal.md            # 内部標準（IS）の除去
├── 13_is_diversity.md          # IS除去後の多様性解析
├── 14_is_quantification.md     # IS検量線・絶対定量
├── 15_negative_control.md      # ネガティブコントロール除去
├── 16_statistical_testing.md   # 統計検定・可視化
├── 17_multi_run.md             # マルチラン処理・サンプル結合
├── 18_export_to_r.md           # R/phyloseqへのエクスポート
├── 19_utilities.md             # ユーティリティ（q2-fondue、便利コマンド）
├── 20_provenance.md            # 解析のトレース・再現性
├── 21_troubleshooting.md       # トラブルシューティング
├── 22_differential_abundance.md # 差次的存在量解析（ANCOM-BC2）（NEW）
├── 23_bootstrapped_diversity.md # ブートストラップ多様性解析（q2-boots）（NEW）
├── 24_automation.md            # 解析の自動化 — AI エージェントと seq2pipe（NEW）
├── appendix_metadata.md        # Appendix: メタデータ仕様
├── appendix_changelog.md       # 変更履歴
└── figures/                    # 図・ダイアグラム
    ├── workflow_overview.mmd
    ├── workflow_is.mmd
    ├── dada2_concept.mmd
    └── r_export_workflow.mmd
```

## クイックスタート

```bash
# QIIME 2 2026.5 のインストール（macOS/Linux）
wget https://data.qiime2.org/distro/qiime2/qiime2-2026.5-py310-linux-conda.yml
conda env create -n qiime2-2026.5 --file qiime2-2026.5-py310-linux-conda.yml
conda activate qiime2-2026.5
```

## 解析フローチャート

```mermaid
flowchart TD
    A[FASTQ データ] --> B[データ読み込み]
    B --> C[DADA2 デノイジング]
    C --> D[ASV テーブル作成]
    D --> E{IS あり?}
    E -->|No| F[系統樹作成]
    E -->|Yes| G[分類器で種同定]
    G --> H[IS 除去]
    H --> I[IS 定量<br/>検量線作成]
    H --> F
    F --> J[多様性解析<br/>α/β diversity]
    J --> K[統計検定]
    D --> L[R/phyloseq<br/>エクスポート]
    L --> M[R で下流解析]
    K --> N[結果の可視化]

    style L fill:#e1f5fe
    style M fill:#e1f5fe
    style A fill:#fff3e0
    style N fill:#e8f5e9
```

## 旧マニュアルからの主な変更点

| 項目 | 旧マニュアル (2019.7) | v2.0.0 (2026.1) | v2.1.0 (2026.5) |
|------|----------------------|-----------------|-----------------|
| QIIME 2 バージョン | 2019.7 | 2026.1 | 2026.5 |
| リファレンスDB | SILVA 132 | SILVA 138.2 | SILVA 138.2（SILVA 144 準備中） |
| DB 取得方法 | 手動ダウンロード | RESCRIPt プラグイン | RESCRIPt（新アクション追加） |
| Windows 環境 | VirtualBox | WSL2 | WSL2 |
| macOS | Intel のみ | Intel + Apple Silicon | Apple Silicon ネイティブ (2026.4+) |
| 下流解析 | QIIME 2 完結 | R/phyloseq 連携を追加 | R 連携 + ANCOM-BC2 完結も記載 |
| 差次的存在量解析 | なし | ANCOM-BC（R 経由） | ANCOM-BC2（QIIME 2 完結） |
| ブートストラップ多様性 | なし | なし | q2-boots（新章） |
| Provenance | 基本説明 | View 改善・エラー検出 | Annotation、暗号署名、replay |
| ディストリビューション名 | — | amplicon | qiime2（2026.4 リブランド） |
| マニュアル方針 | コマンド集 | コマンド集 + 解説 | 手法紹介 + メリット・デメリット解説 |

## 引用

QIIME 2 を使用した研究を発表する際は、以下を引用してください：

- Bolyen, E., et al. (2019). Reproducible, interactive, scalable and extensible microbiome data science using QIIME 2. *Nature Biotechnology*, 37, 852–857.
- SILVA: Quast, C., et al. (2013). The SILVA ribosomal RNA gene database project. *Nucleic Acids Research*, 41(D1), D590–D596.
- DADA2: Callahan, B.J., et al. (2016). DADA2: High-resolution sample inference from Illumina amplicon data. *Nature Methods*, 13, 581–583.
- q2-boots（ブートストラップ多様性を使用した場合）: Keefe, C.R., et al. (2025). Bootstrapped rarefaction outperforms single rarefaction for alpha and beta diversity estimation. *F1000Research*.

## ライセンス

本マニュアルは [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) ライセンスの下で公開されています。

## コントリビューション

Issue や Pull Request は歓迎します。改善提案やエラー報告は [Issues](../../issues) からお願いします。
