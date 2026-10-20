# Skills

**DeepSeek Harness（DSH）技能集合**，同时兼容 Codex。沉淀可复用的开发工作流与协作实践。

每个技能是 `skills/<name>/SKILL.md` 形式的独立目录 bundle，带 YAML frontmatter——这正是 DSH `skill-filesystem` 提供方要求的格式，无需任何转换。

## 在 DeepSeek Harness 里怎么用它

装好之后（见下方[安装](#安装)），在任意 DSH 会话中：

| 操作 | 效果 |
| --- | --- |
| 输入 `/` | 弹出技能菜单，列表里会有 `wq-workflow` |
| 输入 `/wq` 或 `/workflow` 或 `/wq-workflow` | 直接选中该技能（`/` 菜单按技能名做不分大小写的模糊匹配） |
| 直接描述开发任务 | 由 `description` 与 `whenToUse` 自动匹配加载 |

`/` 菜单只匹配**技能名**（`wq-workflow`），不匹配描述文字。所以搜 `wq`、`workflow`、`wqw` 都能命中，搜「harness」这类描述性词不行。

安装后可在 `~/.dsh/skills/wq-workflow/` 确认落地，DSH 会监视该目录，新增技能通常无需重启。

## 技能目录

| 技能 | 宿主 | 用途 | 使用说明 |
| --- | --- | --- | --- |
| **WQ-workflow** · `wq-workflow` | DSH ✅ · Codex ✅ | 从需求澄清、计划审查到分阶段实现、代码审查、修复及最终验收；控制范围，减少重复检查，保留清楚的交接记录。 | [README](skills/wq-workflow/README.md) · [技能规则](skills/wq-workflow/SKILL.md) |

## 安装

技能根目录在两个宿主里位置不同，但**技能 bundle 本身完全一样**。选择一处安装即可，不要在多个可发现目录里放同名副本。

### DeepSeek Harness

DSH 按以下优先级扫描技能根（rank 小者优先）：

| Rank | 来源 | 路径 |
| --- | --- | --- |
| 100 | 项目 | `<项目根>/.dsh/skills` |
| 200 | 项目 | `<项目根>/.agents/skills` |
| 300 | 自定义 | 插件的 `customSkillDirs` 配置 |
| 400 | 用户 | `$DSH_HOME/skills`（默认 `~/.dsh/skills`） |
| 500 | 用户 | `~/.agents/skills` |
| 600 | 随包 | 插件 `bundledSkillDir` |

安装方式二选一。

**方式 A：脚本安装（推荐）**

```powershell
# Windows
.\install.ps1                 # -> $env:DSH_HOME\skills，默认 ~\.dsh\skills
.\install.ps1 -Project        # -> .\.dsh\skills（仅当前项目）
.\install.ps1 -Agents         # -> ~\.agents\skills（与 Codex 共用）
.\install.ps1 -Force          # 覆盖已有副本
```

```bash
# Linux / macOS
./install.sh
./install.sh --project
./install.sh --agents
./install.sh --force
```

**方式 B：手动复制**

把 `skills/wq-workflow/` 整个目录放到任一上述根目录下，最终必须是：

```text
<技能根>/wq-workflow/SKILL.md
```

不要多套一层同名目录，也不要只复制 `SKILL.md` 而漏掉 `references/`——正文用相对路径引用它们。

安装后：

- 会话中输入 `/wq-workflow` 显式调用；
- 或直接描述开发任务，由 `whenToUse` 与 `description` 触发自动匹配。

DSH 会监视技能根，新增或改名通常无需重启；若 `/` 菜单里没出现，重开一个会话。

### Codex

沿用 Codex 的既有约定，个人目录为：

```text
~/.agents/skills/wq-workflow/
```

项目目录为 `<项目>/.agents/skills/wq-workflow/`。该路径同时是 DSH 的 rank 200 / 500 根，因此**装一次两边都能用**。

若当前环境提供技能安装器，可直接发送：

```text
使用 $skill-installer，从以下地址安装 wq-workflow：
https://github.com/XiaoCuan030117/Skills/tree/main/skills/wq-workflow
```

用 `$wq-workflow` 显式调用。技能发现与调用方式以 [Codex 官方技能文档](https://learn.chatgpt.com/docs/build-skills) 为准。

## 快速开始

```text
使用 $wq-workflow。我想开发一个新项目，
先帮我澄清需求并制定可分阶段验收的计划，暂不写业务代码。
```

DSH 中把 `$wq-workflow` 换成 `/wq-workflow`。

已有计划时，直接指定当前环节：

```text
使用 $wq-workflow，按照 PLAN.md 完成第一阶段，
验证并汇报后停止，不提交、不推送、不创建 PR。
```

完整的计划审查、代码审查、修复、复审及收尾示例见 [使用说明](skills/wq-workflow/README.md#调用示例)。

## 仓库结构

```text
Skills/
├── README.md
├── install.ps1                  # Windows 安装脚本
├── install.sh                   # Linux / macOS 安装脚本
└── skills/
    └── wq-workflow/
        ├── SKILL.md             # 技能入口（frontmatter + 规则正文）
        ├── README.md            # 使用说明
        ├── agents/
        │   └── openai.yaml      # Codex 界面显示信息（DSH 忽略）
        └── references/
            ├── planning.md
            ├── review.md
            └── delivery.md
```

## 跨宿主兼容说明

`SKILL.md` 的 frontmatter 是两边共用的契约：

| 字段 | Codex | DSH | 说明 |
| --- | --- | --- | --- |
| `name` | 需要 | 需要 | 必须 kebab-case：`^[a-z0-9]+(?:-[a-z0-9]+)*$` |
| `description` | 需要 | 需要 | DSH 会话目录中超过 500 字符会截断 |
| `whenToUse` | 忽略 | 支持 | DSH 用于判断何时加载 |
| `metadata` | 忽略 | 支持 | 任意附加信息，DSH 原样保留 |
| `disable-model-invocation` | — | 支持 | 为 `true` 时不进模型目录，只能 `/name` 调用 |
| `user-invocable` | — | 支持 | 为 `false` 时不进 `/` 菜单 |

`agents/openai.yaml` 只被 Codex 读取，DSH 不做任何处理，保留它不影响 DSH 发现。

## 使用与维护

- 技能提供工作指引，项目自身约定和用户当前要求仍需遵守。
- 小任务可以简化流程，不强制生成整套文档或重复执行所有检查。
- 安装技能不会自动创建多个 agent、提交代码或部署项目；具体操作遵循用户授权范围。
- 技能是给 agent 的说明文本，不是自动运行的工作流引擎，也不是权限控制机制。
- 后续根据真实使用中的问题逐步调整；新技能使用独立目录，并在上方目录中登记。
