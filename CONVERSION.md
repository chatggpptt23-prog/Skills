# 改造说明：Codex 技能仓库 → 可复用的 DSH Skill

本文件记录把 `chatggpptt23-prog/Skills` 改造成 DeepSeek Harness（DSH）可直接发现的 skill 时，逐项做了什么、依据是什么、以及验证结果。

## 结论先行

原仓库**本就接近 DSH 规范**：它是标准的 `<name>/SKILL.md` 目录 bundle，frontmatter 已有合法的 `name`（kebab-case）与 `description`，`references/*.md` 也用相对路径引用。因此改造不是重写，而是补齐 DSH 侧的能力并去掉宿主耦合。

| 项 | 原仓库 | 改造后 |
| --- | --- | --- |
| 目录结构 | `skills/wq-workflow/SKILL.md` | 不变（根指向 `skills/` 即符合 DSH 深度 1 发现） |
| `name` | `wq-workflow` | 不变（符合 `^[a-z0-9]+(?:-[a-z0-9]+)*$`） |
| `description` | 111 字符 | 不变（DSH 上限 500，不截断） |
| `whenToUse` | 无 | **新增** — DSH 用于判断加载时机 |
| `metadata` | 无 | **新增** — 承载显示名、简述、标签、引用清单 |
| 规则正文 | 1914 字符 | **逐字未改**（已 diff 验证） |
| `agents/openai.yaml` | Codex 专属 | 保留（DSH 忽略，不影响发现） |
| README | 仅 Codex | 改写为双宿主 |
| 安装方式 | 手动复制 / Codex 安装器 | 新增 `install.ps1` / `install.sh` |

## DSH 的 Skill 规范（从 app.asar 提取后确认）

依据 `@deepseek-ai/dsh-skill` 与 `@deepseek-ai/dsh-skill-filesystem` 的实现：

**发现规则**

- 只识别 `<root>/<name>/SKILL.md` 与 `<root>/<name>.md`，**深度为一层**，不递归。
- 名称语法：`SKILL_NAME = /^[a-z0-9]+(?:-[a-z0-9]+)*$/`。
- 必填 `name` 与 `description`；缺任一则整个 skill 被丢弃且只留一条 warn 日志。
- 格式错误会让 skill **静默消失**（模型目录拿不到逐 skill 诊断）。

**扫描根与优先级**

| Rank | 来源 | 路径 |
| --- | --- | --- |
| 100 | project-dsh | `<项目根>/.dsh/skills` |
| 200 | project-agents | `<项目根>/.agents/skills` |
| 300 | custom | `customSkillDirs` |
| 400 | user-dsh | `<dshHome>/skills`（默认 `~/.dsh/skills`） |
| 500 | user-agents | `<agentsHome>/skills` |
| 600 | bundled | `bundledSkillDir` |

项目根 = 最近含 `.git` 的祖先目录，不存在则用 cwd。

**frontmatter 字段**

| 字段 | 必填 | 说明 |
| --- | --- | --- |
| `name` | 是 | kebab-case |
| `description` | 是 | 会话目录中超过 `catalogDescriptionMaxLength`（默认 500）截断 |
| `whenToUse` | 否 | 字符串，辅助判断加载时机 |
| `metadata` | 否 | 任意映射，原样保留 |
| `disable-model-invocation` | 否 | `true` 时不进模型目录，只能显式调用 |
| `user-invocable` | 否 | `false` 时不进 `/` 菜单 |

布尔字段接受 YAML 布尔与不区分大小写的 `true/false`、`yes/no`、`on/off`、`1/0`；**拼写非法会让整个 skill 被丢弃**，而不是静默放行。

**资源解析**

加载时返回 `<skill_resources>` 块，给出 base directory，并要求相对路径按该目录解析。因此 `references/planning.md` 这类引用无需改动。

## 逐项改动

### 1. SKILL.md frontmatter（唯一的内容改动）

新增 `whenToUse` 与 `metadata`，其余原样：

```yaml
---
name: wq-workflow
description: 跨项目的个人开发工作流：……（原文未改）
whenToUse: 用户提到「个人开发流程」「按我的流程来」「wq-workflow」，或要求澄清需求、
  写或审查 PLAN.md、按计划分阶段实现、审查代码改动、修复审查问题、做最终验收收尾时加载。
  纯知识问答、单次事实查询、与项目交付无关的闲聊不要加载。
metadata:
  displayName: WQ-workflow
  shortDescription: 按需完成需求澄清、计划审查、分阶段实现、代码审查与交付验收
  tags: [workflow, planning, code-review, delivery]
  references:
    - references/planning.md
    - references/review.md
    - references/delivery.md
---
```

`whenToUse` 的写法刻意包含**排除项**（纯知识问答不加载），因为原 `description` 已经声明“普通知识问答无需启动此流程”，把它落到可判定的触发条件上，避免技能被过度匹配。

**规则正文一字未改**，已用脚本比对确认两侧均为 1914 字符且完全一致。

### 2. agents/openai.yaml —— 保留

```yaml
interface:
  display_name: "WQ-workflow"
  short_description: "按需完成需求澄清、计划审查、分阶段实现、代码审查与交付验收"
```

该文件只被 Codex 读取。DSH 只读 `SKILL.md`，`agents/` 是 bundle 内部子目录，不参与根目录扫描，因此保留它既不干扰 DSH，又保住了 Codex 的界面信息。其中的显示名与简述已同步进 `metadata`，DSH 侧不丢信息。

### 3. 新增安装脚本

`install.ps1` / `install.sh` 做三件原仓库没有的事：

1. **按 DSH 的根目录优先级选默认目标**，而不是硬编码一个路径。
2. **检测其他可发现根里的同名副本**——DSH 会跨根合并并去重，同名的多份容易让人误判生效的是哪一份。
3. **安装后自检** `SKILL.md` 是否落在正确层级。

Windows 侧注意：脚本必须存为 **UTF-8 with BOM**。Windows PowerShell 5.1 在无 BOM 时按 ANSI(GBK) 读取 `.ps1`，中文注释会导致解析器报 `The string is missing the terminator` 之类的错误而完全无法运行——这是改造过程中实际踩到并已修正的问题。

若执行策略阻止运行，用：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

### 4. README 改写

原 README 面向 Codex，改造后：

- 补充 DSH 的 5 个扫描根与 rank 表；
- 说明 `~/.agents/skills` **同时**是 Codex 个人目录与 DSH 的 rank 500 根，因此装一次两边都能用；
- 增加 frontmatter 字段对照表（哪个字段哪个宿主认）；
- 保留原有的调用示例、工作流程图、减少重复工作等章节；
- 调用示例中标注 DSH 用 `/wq-workflow`、Codex 用 `$wq-workflow`。

## 验证结果

改造后对**已安装副本**跑了 18 项检查，全部通过：

- bundle 目录与 `SKILL.md` 存在；
- frontmatter 可被 YAML 解析；
- `name` 合法 kebab-case 且与目录名一致；
- `description` 111 字符，低于 500 截断阈值；
- `whenToUse` 为字符串、`metadata` 为映射；
- 正文引用的 3 个 `references/*.md` 全部可解析且非空；
- `agents/openai.yaml` 保留；
- 无多余文件；
- 其他可发现根中无同名副本。

**运行时验证**：安装到 `~/.dsh/skills/wq-workflow` 后，当前会话的 `<available_skills>` 目录**立即出现** `wq-workflow` 条目，无需重启——说明 DSH 的文件监视器已捕获变更并刷新目录。随后用 `skill` 工具加载，`<skill_resources>` 正确给出 base directory，`references/` 的相对路径可解析。

## 复用到其他技能

仓库新增技能时按同样三步即可：

1. 建目录 `skills/<kebab-case-name>/SKILL.md`；
2. frontmatter 至少写 `name` + `description`，DSH 侧建议补 `whenToUse`；
3. 资源放 `references/`、`scripts/`、`assets/` 等子目录，正文用**相对路径**引用。

注意：

- 目录名与 `name` 保持一致；
- 不要嵌套多层（`a/b/SKILL.md` 不会被发现）；
- `description` 控制在 500 字符内，否则会话目录中被截断；
- 布尔字段只写合法值，否则整个技能会被丢弃且不报错给模型。
