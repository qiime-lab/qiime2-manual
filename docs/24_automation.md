# 24. 解析の自動化 — AI エージェントによるマイクロバイオーム解析

## 概要

本章では、マイクロバイオーム解析を AI で自動化するアプローチについて解説する。具体的には、ローカル LLM エージェント **seq2pipe** を題材に、自動化の仕組み・利点・限界・セキュリティ上の考慮事項を紹介する。

QIIME 2 の解析パイプラインは多くのステップから構成され、それぞれにパラメータの選定が必要である。初学者にとってはどのコマンドをどの順番で実行すべきかが障壁となり、経験者にとっても定型的な作業の繰り返しは負担となる。AI エージェントはこの問題に対して、「データを読み取り、適切なコマンドを組み立て、実行し、結果を解釈する」という一連の作業を自動化する。

---

## AI による解析自動化のメリットとデメリット

| 観点 | メリット | デメリット |
|:--|:--|:--|
| **速度** | FASTQ から図・レポートまで数十分で完了 | LLM の推論速度に依存（GPU がないと遅い） |
| **再現性** | 同一パラメータなら同一結果（決定論的ステップ） | LLM 生成コードは実行ごとに異なりうる |
| **学習コスト** | コマンドを覚えなくても解析できる | ブラックボックスになりやすい（何をしているか理解せずに使う危険） |
| **パラメータ選定** | リード長から自動推定、プライマーも自動検出 | データ特性によっては最適でない場合がある |
| **柔軟性** | 自然言語で解析を指示できる | 複雑な実験デザインでは意図通りに動かないことがある |
| **品質** | 決定論的解析で 25 種以上の標準図を確実に生成 | LLM 生成コードは必ずしも正しくない — 結果の確認が必要 |

> **重要**: AI 自動化は便利なツールだが、結果の生物学的解釈は研究者自身が行う必要がある。AI が出した図や統計結果を鵜呑みにせず、マニュアルの各章で学んだ知識をもとに結果を評価すること。

---

## セキュリティとプライバシー

マイクロバイオームデータには患者情報や未発表の研究データが含まれる場合がある。AI ツールを使用する際のセキュリティは重要な考慮事項である。

### クラウド AI vs ローカル AI

| 観点 | クラウド AI (ChatGPT, Claude 等) | ローカル AI (Ollama + seq2pipe) |
|:--|:--|:--|
| **データ送信** | サーバーにデータが送信される | データはマシン外に出ない |
| **プライバシー** | 利用規約に依存 | 完全にユーザーの管理下 |
| **ネットワーク** | インターネット接続が必須 | オフラインで動作可能 |
| **モデル性能** | 高性能（数百 B パラメータ） | 中程度（7B〜32B パラメータ） |
| **コスト** | API 従量課金 | 無料（ハードウェアコストのみ） |
| **監査可能性** | サーバー側の処理は不透明 | 全処理がローカルで確認可能 |

### seq2pipe のセキュリティモデル

seq2pipe は **完全ローカル動作** を設計原則としている。

**通信先は localhost のみ:**
- LLM: `http://localhost:11434` (Ollama API)
- Web UI: `http://localhost:8501` (Streamlit、使用する場合)
- 外部サーバーへの自動的なデータ送信は一切ない

**コード実行のリスク:**

LLM が生成した Python コードは、QIIME 2 conda 環境内で **サンドボックスなし** で実行される。これは柔軟性のためのトレードオフであるが、以下の点に注意が必要：

- LLM が生成したコードがファイルシステムにアクセスできる
- `--auto` モードでは人間の確認なしにコードが実行される
- 対話モードでは、シェルコマンド実行前にユーザー確認を求める

**推奨される運用方法:**

1. 重要なデータがあるマシンでは `--auto` モードの使用に注意する
2. 生成されたコードは実行ログで確認できる — 定期的にレビューすること
3. 専用の解析環境（conda 環境や Docker コンテナ内）で実行すること
4. QIIME 2 のコアパイプライン（STEP 1）は決定論的であり、LLM は関与しない

### パッケージインストールの安全性

LLM が生成したコードが未インストールのパッケージを必要とする場合、seq2pipe はユーザーに確認を求める。`--auto` モードでも、インストール先は QIIME 2 conda 環境に限定される。

---

## seq2pipe の仕組み

### アーキテクチャ

seq2pipe は以下のコンポーネントで構成される：

```
launch.sh            環境検出・Ollama 起動・QIIME 2 環境検出
    ↓
cli.py               CLI エントリポイント・モード選択・パラメータ自動検出
    ↓
pipeline_runner.py   QIIME 2 パイプラインの実行制御
    ↓
qiime2_agent.py      QIIME 2 コマンド実行・Ollama API 通信・ツール関数群
    ↓
analysis.py          決定論的包括解析（STEP 1.5、LLM 非依存）
    ↓
code_agent.py        LLM によるコード生成・実行・エラー自動修正
    ↓
report_generator.py  HTML / LaTeX レポート自動生成
```

### 3 ステップ自動パイプライン

seq2pipe の `--auto` モードは、以下の 3 ステップで構成される：

#### STEP 1: QIIME 2 コアパイプライン（決定論的）

LLM は関与しない。QIIME 2 コマンドを順番に実行する。

```
データインポート → DADA2 デノイジング → 系統樹構築
→ α/β 多様性解析 → 分類学的解析 → 結果エクスポート
```

本マニュアルの Ch.01〜Ch.17 で解説している内容と同等の処理を自動で行う。

パラメータは FASTQ リードから自動検出される：
- **プライマー配列**: リード先頭の配列を 16S プライマー DB と照合し、`trim_left` を自動設定
- **リード長**: 実際の FASTQ を読み取り、`trunc_len` を推定（Forward: 87%, Reverse: 80%）
- **サンプリング深度**: 最小リード数の 80% を自動設定

#### STEP 1.5: 決定論的包括解析（LLM 非依存）

`analysis.py` モジュールが 25 種以上の標準的な統計図を **LLM を使わずに** 生成する。

生成される図の例：
- DADA2 デノイジング統計、サンプル別シーケンス深度
- α 多様性（Shannon, Simpson, Faith PD）箱ひげ図・ストリッププロット
- β 多様性 PCoA（Bray-Curtis, Jaccard, Weighted/Unweighted UniFrac）
- 分類組成積み上げ棒グラフ（門〜属レベル）、ヒートマップ
- ラレファクションカーブ、NMDS、共起ネットワーク、コアマイクロバイオーム

このステップは決定論的であるため、同一データに対して常に同一の図が出力される。LLM の揺らぎに依存しない再現性の高い結果が得られる。

#### STEP 2: LLM 適応型自律解析

ローカル LLM（デフォルト: `qwen2.5-coder:7b`）が STEP 1 のエクスポートデータを読み取り、データの特性に応じた応用解析を自律的に設計・実行する。

LLM の動作フロー：
1. `read_file` ツールでエクスポートされた TSV/BIOM データの構造を確認
2. メタデータの列名・グループ情報を把握
3. データに適した解析コード（Python）を生成
4. `execute_python` ツールでコードを実行
5. エラーが出た場合はエラーメッセージを読んで自動修正（NEVER GIVE UP 方式）
6. 3〜5 種の応用解析を順次実行

このステップで生成されるコードは実行ごとに異なりうるため、再現性は STEP 1/1.5 より低い。

#### STEP 3: レポート自動生成

全図を HTML レポートにまとめる。図は Base64 エンコードされて HTML に埋め込まれるため、単一ファイルで完結する。LaTeX/PDF レポートの生成にも対応（`pdflatex` が必要）。

### 操作モード

seq2pipe には 3 つの操作モードがある：

| モード | 起動方法 | 特徴 |
|:--|:--|:--|
| **自律モード** | `./launch.sh --fastq-dir ~/input --auto` | 完全無人実行。パラメータ自動検出、LLM 自律解析 |
| **対話モード** | `./launch.sh --fastq-dir ~/input` | 各ステップで確認・修正が可能。生成図に自然言語で修正指示 |
| **チャットモード** | `./launch.sh --fastq-dir ~/input --chat` | 実験デザインの相談から解析まで対話形式で進行 |

### ツール呼び出し型コード生成（vibe-local 方式）

seq2pipe の LLM は、いきなりコードを書くのではなく、まず **ツール呼び出し** でデータの中身を確認してからコードを生成する。

```
LLM: read_file("exported/taxonomy/taxonomy.tsv", max_lines=10)
      → TSV の列名とデータ形式を確認

LLM: read_file("exported/alpha-diversity/shannon.tsv", max_lines=20)
      → Shannon 指数の値とサンプル数を確認

LLM: execute_python("""
import pandas as pd
import seaborn as sns
# 確認したデータ構造に基づいてコードを生成
df = pd.read_csv("exported/alpha-diversity/shannon.tsv", sep="\\t")
sns.boxplot(data=df, x="group", y="shannon_entropy")
plt.savefig("figures/shannon_boxplot.png", dpi=200)
""")
```

この方式により、LLM がデータ構造を知らないまま推測でコードを書く失敗を大幅に減らしている。

### 環境要件

| 項目 | 要件 |
|:--|:--|
| OS | macOS (Intel / Apple Silicon), Linux, Windows (WSL2) |
| Python | 3.9 以上 |
| Ollama | `setup.sh` で自動インストール |
| QIIME 2 | conda 環境（推奨）または Docker |
| RAM | 8 GB 以上推奨（QIIME 2 + Ollama モデル） |
| ディスク | 約 10 GB（LLM モデル + QIIME 2 環境） |
| GPU | 不要（あれば LLM 推論が高速化） |

### インストールと実行

```bash
# クローンとセットアップ
git clone https://github.com/qiime-lab/seq2pipe.git
cd seq2pipe
./setup.sh      # Ollama・Python パッケージを自動インストール

# 全自動解析
./launch.sh --fastq-dir ~/your_fastq_data --auto

# 対話モード（各ステップを確認しながら進める）
./launch.sh --fastq-dir ~/your_fastq_data

# 既存の QIIME 2 エクスポートデータに対して追加解析のみ
./launch.sh --export-dir ~/existing_exported_data --prompt "PCoA を描いて"

# DADA2 パラメータを手動指定
./launch.sh --fastq-dir ~/input --auto \
  --trim-left-f 20 --trim-left-r 20 \
  --trunc-len-f 260 --trunc-len-r 230 \
  --sampling-depth 20000
```

### 設定のカスタマイズ

環境変数で動作を調整できる：

| 環境変数 | デフォルト | 説明 |
|:--|:--|:--|
| `QIIME2_AI_MODEL` | `qwen2.5-coder:7b` | 使用する Ollama モデル |
| `OLLAMA_TIMEOUT` | `600` | LLM 応答タイムアウト（秒） |
| `SEQ2PIPE_PYTHON_TIMEOUT` | `600` | コード実行タイムアウト（秒） |
| `SEQ2PIPE_MAX_STEPS` | `200` | エージェントの最大ステップ数 |

---

## 手動解析と自動解析の使い分け

| 場面 | 推奨 |
|:--|:--|
| QIIME 2 を初めて学ぶ | 本マニュアルで手動実行して理解を深める |
| パラメータの意味を理解したい | 手動で `demux.qzv` を確認しながら調整 |
| ルーチン解析を効率化したい | `seq2pipe --auto` で自動実行 |
| 探索的にデータを見たい | `seq2pipe --chat` で対話しながら解析 |
| 論文用の図を作成したい | STEP 1.5 の決定論的図 + R/ggplot2 で仕上げ |
| 実験デザインの相談をしたい | `qiime2-assistant` または `seq2pipe --chat` |
| 非標準的な解析が必要 | 手動で R/Python スクリプトを書く |

---

## 出力ディレクトリ構成

```
~/seq2pipe_results/{timestamp}/
├── exported/           QIIME 2 からエクスポートされた TSV/BIOM
│   ├── feature-table/
│   ├── taxonomy/
│   ├── alpha-diversity/
│   └── beta-diversity/
├── figures/            生成された全図（PNG）
│   ├── fig01_dada2_stats.png
│   ├── fig02_sequencing_depth.png
│   ├── ...
│   └── fig29_core_microbiome.png
├── analysis.py         STEP 1.5 で使用した解析スクリプト
├── report.html         HTML レポート（図を Base64 埋め込み）
└── report.pdf          LaTeX/PDF レポート（pdflatex がある場合）
```

---

## 関連リポジトリ

- [seq2pipe](https://github.com/qiime-lab/seq2pipe) — 本章で解説した自動解析パイプライン
- [qiime2-assistant](https://github.com/qiime-lab/qiime2-assistant) — マニュアルをナレッジベースとした AI チャットアシスタント

---

**Appendix**: [メタデータ仕様](appendix_metadata.md) | [変更履歴](appendix_changelog.md)
