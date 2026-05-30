# Codex Automated Paper Reader (CAPR)

> 中文 | [English](README.en.md)

CAPR 是一个用 Codex 自动化完成每日论文/技术文章候选检索、语义筛选、日报生成和 GitHub 推送的轻量级工作流。

当前仓库主要面向 `General Agent`、`Search Agent`、`Code Agent` 三类方向，重点追踪 Agent 架构、工具调用、搜索检索、代码生成/编辑、软件工程自动化、评测、安全约束和工程化部署。Agent 方向描述参考了 DeepSeek-V3.2 技术报告中的高效长上下文、可扩展强化学习、agentic task synthesis 和 reasoning-in-tool-use 思路。

核心原则：脚本只负责准备候选池和可解释的检索线索；最终阅读、语义评分、排序、总结和日报写作由 Codex 完成。

## 功能特性

- 从 arXiv 和 OpenReview 抓取近期候选，并提供默认关闭的 OpenAlex 可选抓取源。
- 将不同来源统一为一致的 JSON schema。
- 基于 source ID 和标准化标题去重。
- 用透明规则分数提供候选粗排线索。
- 在抓取前做网络预检，避免网络/代理错误被误写为空候选池。
- 当 arXiv export API 限流时，自动 fallback 到 arXiv HTML recent-list 页面。
- 支持面向 Agent 方向的每日中文 Markdown 日报。
- 支持每天 7:00 自动生成日报、提交并推送到 GitHub。
- 自动提交信息要求使用中文。

## 项目结构

```text
Codex_Automated_Paper_Reader/
├── README.md
├── README.en.md
├── Paper_Reader.template.txt
├── Paper_Reader.template.en.txt
├── Agent_Article_Publisher.template.zh.txt
├── publish-agent-article-report.ps1
├── docs/
│   └── agent-article-reports/
│       └── README.md
├── LICENSE
└── paper-daily/
    ├── config.yaml
    ├── requirements.txt
    ├── tutorial/
    │   ├── daily report.png
    │   └── codex automation.png
    ├── scripts/
    │   ├── daily_papers.py
    │   ├── fetch_arxiv.py
    │   ├── fetch_openalex.py
    │   ├── fetch_openreview.py
    │   ├── rank_papers.py
    │   └── utils.py
    └── tests/
```

以下运行产物默认不会提交到 Git：

```text
paper-daily/data/
paper-daily/logs/
paper-daily/reports/
```

每日 Agent 日报会写入并提交：

```text
docs/agent-article-reports/YYYY-MM-DD.md
```

## 快速开始

### 1. 克隆项目

```bash
git clone https://github.com/<your-user>/Codex_Automated_Paper_Reader.git
cd Codex_Automated_Paper_Reader/paper-daily
```

### 2. 创建 Python 环境

推荐 Python 3.10+。

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Windows PowerShell 示例：

```powershell
python -m venv .venv-win
.\.venv-win\Scripts\python.exe -m pip install -r requirements.txt
```

### 3. 抓取候选

```bash
python scripts/daily_papers.py --config config.yaml --date today --stage fetch --force
```

输出文件：

```text
data/raw/YYYY-MM-DD.json
data/processed/YYYY-MM-DD_candidates.json
logs/YYYY-MM-DD.log
```

这一步只生成候选池，不生成最终日报。`data/raw/YYYY-MM-DD.json` 会包含 `duplicate_check` 和 `recommended_action`。如果状态提示没有新批次或候选池重复，Codex 应写一段“今日无新候选批次”说明，而不是重复生成旧 Top 10。

## Agent 日报自动化

仓库提供中文模板：

```text
Agent_Article_Publisher.template.zh.txt
```

这个模板以 `Paper_Reader.template.txt` 为基底，并填充了 General Agent、Search Agent、Code Agent 的研究方向。它要求自动化：

- 每天 7:00 运行。
- 抓取当天候选。
- 读取候选并进行语义评分。
- 对 Top 候选尽量打开论文页或 PDF 深读。
- 写中文日报到 `docs/agent-article-reports/YYYY-MM-DD.md`。
- 只提交 `docs/agent-article-reports` 中的日报相关文件。
- 使用中文提交信息，例如：`文档：新增 YYYY-MM-DD Agent 文章日报`。
- 推送到 GitHub。

手动发布已有日报时，可使用：

```powershell
.\publish-agent-article-report.ps1 -Date YYYY-MM-DD
```

## 候选文件格式

`data/processed/YYYY-MM-DD_candidates.json` 中每篇候选大致包含：

```json
{
  "id": "2605.12345",
  "source": "arxiv",
  "title": "Paper title",
  "authors": ["Author One", "Author Two"],
  "abstract": "Paper abstract...",
  "url": "https://arxiv.org/abs/2605.12345",
  "pdf_url": "https://arxiv.org/pdf/2605.12345",
  "published_at": "2026-05-15T00:00:00+00:00",
  "updated_at": "2026-05-15T00:00:00+00:00",
  "venue": "cs.LG",
  "categories": ["cs.LG", "cs.AI"],
  "keyword_score": 7.0,
  "retrieval_reason": "matched method-transfer terms...",
  "matched_keywords": ["tool use"],
  "negative_matches": [],
  "coarse_retrieval_score": 8.0
}
```

`keyword_score` 和 `coarse_retrieval_score` 只是粗筛线索，不是最终推荐依据。

## 推荐阅读流程

抓取完成后，Codex 应该：

1. 读取 `data/processed/YYYY-MM-DD_candidates.json`。
2. 围绕 Agent 相关性、方法启发、可迁移性、论文质量、新颖性和可操作性逐篇评分。
3. 保存评分到 `data/processed/YYYY-MM-DD_scored.json`。
4. 对高分候选进一步打开网页或 PDF 阅读。
5. 写入最终报告 `docs/agent-article-reports/YYYY-MM-DD.md`。
6. 明确说明每篇总结是基于 `abstract-only`、`paper page` 还是 `PDF` 阅读。

## 配置

编辑 `paper-daily/config.yaml` 可调整：

- 研究画像
- 正向/负向关键词
- arXiv 分类
- OpenReview venue
- 候选数量上限
- arXiv retry 和 HTML fallback 行为
- 输出目录

## 代理说明

有些自动化环境会注入不可用的代理变量。CAPR 默认会在论文源请求中忽略环境代理，避免误判网络失败。如果你确实需要使用系统代理，可以设置：

```bash
PAPER_DAILY_USE_ENV_PROXY=1
```

## 测试

在 `paper-daily` 目录运行：

```bash
python -m pytest tests
```

## 项目状态

CAPR 目前是一个早期科研自动化工具。当前重点是提升候选检索可靠性、保持推荐过程透明，并让最终日报由 Codex 阅读候选后生成，而不是由固定关键词模板生成。

## License

本项目采用 MIT License，详见 [LICENSE](LICENSE)。
