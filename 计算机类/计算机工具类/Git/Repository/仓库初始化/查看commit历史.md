# 查看 commit 历史 —— git log 与历史回看

> [!abstract] 一句话
> ==`git log` 是 Git 的"行车记录仪"==：它从你所在的提交出发，**沿 `parent` 指针一路往回走**，把沿途每个提交的时间、作者、说明（以及可选的 diff）列出来。历史是**只读**的——查看它不会改动任何东西，看懂它却是"撤销、回退、找 bug"一切操作的前提。

---

## 一、它到底在走什么

[[提交]] 里说过，每个提交都有 `parent` 指向它的父提交。`git log` 做的事，就是**顺着这条父链遍历**：

```text
        HEAD
         ↓
   [ C3 ] ← 最新提交
     ↓ parent
   [ C2 ]
     ↓ parent
   [ C1 ] ← 首个提交，没有 parent，遍历到此结束
```

```bash
git log                 # 从 HEAD 开始，由新到旧，列出整条链
```

> [!info] 默认输出里每一段是什么
> ```text
> commit a1b2c3d4e5f6...            ← 完整的 SHA-1 哈希
> Author: 张三 <zs@example.com>     ← 作者
> Date:   Thu May 7 12:00:00 2026 +0800  ← 提交时间
>
>     fix: 修复登录态失效          ← 提交说明（缩进的正文）
> ```
>
> 这是**完整格式**，信息全但太占地方。日常几乎都用下面第二节的"瘦身版"。

> [!tip] 长输出会自动分页
> Git 把 `log` 输出交给 `less` 分页。**`空格`翻页、`b` 回翻、`/关键词`搜索、`q` 退出**。
> 如果被卡住，按 `q` 就回到命令行了。不想要分页加 `--no-pager`，或写进管道 `git log | cat`。

> [!warning] `git log` 默认只看"当前分支能到达的提交"
> 若另一个分支的提交还没合并进来，默认 `git log` **看不到它们**。
> 想看全仓所有分支的历史，加 `--all`（见第三节）。

---

## 二、最常用的几个参数（记住这行就够用）

```bash
git log --oneline --graph --decorate --all
```

这一行是**排查历史的标准姿势**，逐个拆开：

| 参数               | 作用                                |                           |
| ---------------- | --------------------------------- | ------------------------- |
| `--oneline`      | 每个提交压成**一行**：`缩写哈希 + 说明`          |                           |
| `--graph`        | 左侧画 `*                            | / \` 的**分支合并图**，一眼看出岔路与合并 |
| `--decorate`     | 显示分支名、标签、`HEAD` 等**引用标签**（新版默认已开） |                           |
| `--all`          | 不只当前分支，**列出所有分支/标签**能到达的提交        |                           |
| `-n` / `-5`      | 只看最新 **5** 条（`git log -5`）        |                           |
| `-p` / `--patch` | 顺带显示每次提交的**具体 diff**              |                           |
| `--stat`         | 每个提交**改了哪些文件、增删多少行**的汇总           |                           |
| `--name-only`    | 只列改动过的**文件名**，不显示 diff 内容         |                           |
| `--name-status`  | 文件名 + 状态字母（`M`改 `A`增 `D`删 `R`重命名） |                           |
| `--reverse`      | 把顺序**倒过来**，从最早往最新看                |                           |

输出长这样：

```text
* a1b2c3d (HEAD -> main, origin/main) fix: 修复登录态失效
* 9f8e7d6 feat: 新增 utils 工具
| * 3c2b1a0 (feature/login) wip: 登录页草稿
|/
* 1112223 chore: 初始提交
```

> [!tip] `--oneline` + `--graph` + `--all` 是黄金组合
> 只记一条命令的话就记它：**结构、标签、全部分支一个画面看全**。
> 想再看具体改了什么，追加 `-p` 或改看 `git show <哈希>`（第四节）。

> [!note] `--stat` 和 `-p` 的区别
> `--stat` 是"**改了哪些文件、几个加号几个减号**"的**概览表**；
> `-p` 是**逐行**的完整 diff。`git show --stat` 先扫一眼改了啥，再决定要不要 `-p` 细看，是常见节奏。

### 2.1 自定义输出格式

想要什么字段就拼什么，`--pretty=format:` 里的占位符：

| 占位符 | 含义 | 占位符 | 含义 |
| --- | --- | --- | --- |
| `%h` / `%H` | 缩写 / 完整哈希 | `%an` / `%ae` | 作者名 / 邮箱 |
| `%ad` / `%ar` | 作者日期 / **相对**日期 | `%s` | 说明的首行（标题） |
| `%d` | 引用装饰（分支/标签） | `%b` | 说明的正文 |
| `%cn` | 提交者名（rebuild 时≠作者） | `%cd` | 提交日期 |

```bash
# 只打"缩写哈希 + 日期 + 作者 + 标题"，紧凑一行
git log --pretty=format:"%h %ad %an %s" --date=short

# 存成别名，天天用
git config --global alias.lg "log --oneline --graph --decorate --all"
git lg
```

> [!tip] 内置的现成配方
> `--pretty=oneline`（哈希+标题，最简）、`--pretty=short`（加作者日期）、`--pretty=full`、`--pretty=fuller`（作者/提交者两套信息）。
> 日常 `--oneline` 足矣，需要精确复现就上 `format:`。

---

## 三、过滤与搜索：从海量历史里捞一条

历史一长，靠翻页找是灾难。**让 Git 只吐出你要的那几条**：

### 3.1 按时间 / 数量

```bash
git log -5                        # 最新 5 条
git log --since="2 weeks ago"     # 最近两周
git log --since="2026-05-01" --until="2026-05-07"
git log --before="yesterday"      # 也有 --after/--before 别名
```

### 3.2 按人

```bash
git log --author="张三"            # 作者名匹配（支持正则）
git log --committer="CI Bot"      # 按"提交者"过滤
```

### 3.3 按提交信息

```bash
git log --grep="fix"              # 说明里含 "fix" 的提交
git log --grep="登录" -i          # -i 忽略大小写
git log --grep="fix" -P           # 用 Perl 正则（默认基本正则）
```

### 3.4 按"改了哪一行代码"（pickaxe）

这是**找 bug 神器**——不记得哪天改的、只知道"某个字符串/函数名动了"：

```bash
git log -S "function login"       # 该字符串"出现次数发生变化"的提交（增或删）
git log -G "login\("              # diff 里"匹配到该正则"的提交
git log -S "TODO" --oneline       # 找出所有增删过 TODO 的提交
```

> [!note] `-S` 和 `-G` 的细微差别
> - `-S<string>`（pickaxe）：看的是**该字符串在提交前后出现的次数有没有变**——即"新增了它"或"删掉了它"。
> - `-G<regex>`：看的是 **diff 文本本身有没有匹配上正则**——移动一行、改个大小写也会命中。
> 找"某函数是何时被引入/删除的"用 `-S`；找"哪次改动碰过相关的行"用 `-G`。

### 3.5 按文件 / 目录

```bash
git log -- src/login.js           # 只看影响这个文件的提交
git log -p -- src/login.js        # 顺带看该文件的每次具体改动
git log --follow -- src/login.js  # ★即使文件被重命名过，也一路追下去
git log --grep="fix" -- src/      # 目录 + 消息过滤可叠加
```

> [!warning] `--` 双横线别漏
> `git log -- <路径>` 里的 `--` 用来**把"路径"和"分支/参数"隔开**，避免 Git 把路径当成引用名。
> 路径含空格或有歧义时，这个 `--` 是保命的。想追重命名史，务必加 `--follow`——**不加的话，重命名之前的历史会断掉**。

### 3.6 按分支范围与图形

```bash
git log main..feature             # 在 feature 里、但不在 main 里的提交
git log feature..main             # 反过来
git log --left-right main...feature  # 对称差集：两边各自独有的，标 < > 区分
git log --merges                  # 只看合并提交
git log --no-merges               # 不看合并提交（看"真实改动"更清爽）
git log --first-parent            # 只沿主线第一父，忽略被合并进来的分支内部
git log --all --source            # 每条提交标出"来自哪个引用"
```

> [!info] `A..B` 与 `A...B` 差一个点
> - `A..B` = **B 有而 A 没有**的提交（"feature 领先 main 的那些"）。
> - `A...B` = **两边各自独有**的提交（对称差集），常配 `--left-right` 看。
> 记住方向：`起点..终点`，含终点侧、排起点侧。

---

## 四、看单个提交：`git show`

`git log` 是"列表"，`git show` 是"放大看某一条"：

```bash
git show                          # 默认展示 HEAD（最近一次提交）的详情
git show a1b2c3d                  # 看指定提交：说明 + 完整 diff
git show a1b2c3d --stat           # 只要汇总，不要逐行 diff
git show HEAD~1                   # 倒数第二次
git show a1b2c3d:src/login.js     # ★看该提交"当时"某文件的内容
git show a1b2c3d -- src/login.js  # 只看该提交里这个文件的 diff
```

> [!tip] `git show <提交>:<路径>` 是"时间旅行查看文件"
> 它把该提交那一刻的文件内容**原样打印**出来，不动工作目录。
> 想知道"三天前这个配置长啥样"，比 `checkout` 再切回来安全得多。

> [!note] 提交里能引用到的"坐标"
> | 写法 | 含义 |
> | --- | --- |
> | `HEAD` | 当前所在提交 |
> | `HEAD~1` / `HEAD~` | 顺着**第一父**往前 1 步（`~2` 再往前一步） |
> | `HEAD^` | 同上，第一父；`HEAD^2` 是**合并提交的第二父** |
> | `HEAD@{2}` | **reflog** 里 HEAD 两次移动前的位置（见第六节） |
> | `main@{yesterday}` | 某分支昨天所在的位置 |
> | `v1.0.0` | 标签直接当坐标用 |

---

## 五、图形化与对比：肉眼更快

### 5.1 命令行里的图

```bash
git log --oneline --graph --all   # 终端里画出来，够用
git log --graph --pretty=format:"%h %d %s"
```

### 5.2 专门的工具

| 工具                          | 说明                                     |
| --------------------------- | -------------------------------------- |
| `gitk --all`                | Git 自带的 GUI 历史浏览器（多数安装包内置）             |
| `tig`                       | 终端里的交互式历史浏览（`tig log` / 直接 `tig`）      |
| `git log --oneline` + 编辑器插件 | VS Code Git Graph、JetBrains 内置 Log，点着看 |
| `git shortlog -sn`          | 按作者汇总提交数（"谁贡献了多少"）                     |

```bash
git shortlog -sn --all           # 各作者提交计数，降序
git shortlog -sn --since="1 month ago"
```

> [!tip] 什么时候用 GUI
> 历史分叉多、要看"到底从哪合进来的"时，GUI 的分支图比 ASCII 图直观得多。
> 但**能读懂 `--graph` 是基本功**——SSH 进服务器常常只有命令行。

### 5.3 两个提交之间比什么变了

```bash
git diff HEAD~3 HEAD              # 三个提交前 vs 现在，整体差异
git diff main..feature            # 两条分支的差异
git diff HEAD~1                   # 工作目录 vs 上一个提交（还没 commit 的改动）
git diff --stat HEAD~5 HEAD       # 只要概览
```

> [!note] `git log` vs `git diff`
> `git log A..B` 列出"**有哪些提交**"，`git diff A..B` 显示"**内容差在哪**"。
> 想知道"这段时间动了哪些提交"用 log；想知道"最终结果差什么"用 diff。

---

## 六、找回"丢失"的提交：`git reflog`

> [!danger] `git log` 只显示"还被引用到的"提交
> `reset`、`rebase`、删分支、`--amend` 之后，旧提交会从 `git log` 里**消失**——它们成了"没人指向的孤儿"。
> **但 Git 并不马上删除它们**，默认保留约 30~90 天（`gc.reflogExpire`）。这段时间内，`reflog` 能救回来。

```bash
git reflog                        # 记录 HEAD 每次移动："我在哪待过"
# 示例：
# a1b2c3d HEAD@{0}: commit: fix: 修复登录态
# 9f8e7d6 HEAD@{1}: reset: moving to HEAD~1
# 3c2b1a0 HEAD@{2}: commit: feat: 新增 utils   ← 被 reset 掉的那个
```

找回步骤：

```bash
git reflog                        # 1. 找到"消失前"的哈希，如 3c2b1a0
git branch rescue 3c2b1a0         # 2. 新开个分支钉住它（最安全）
git log rescue                    # 3. 确认内容无误
# 或直接 git switch -c rescue 3c2b1a0
```

> [!tip] reflog 是本地"后悔药"
> 它记录的是**你本机 HEAD 的移动历史**，不随仓库分发。
> 别的机器上、或远程仓库里，**没有你的 reflog**——所以"救回"操作得在当初操作的机器上做。
> [[提交]] 里提到的 detached HEAD 提交，也常常靠 reflog 找回。

---

## 七、完整示例：一次"查案"流程

```bash
# 场景：登录功能坏了，想查最近两周谁动了 auth 相关代码，并看看改了啥

# 1. 概览最近两周的分支全貌
git log --oneline --graph --decorate --all --since="2 weeks ago"

# 2. 只看影响 auth 目录、且消息含 fix 的提交
git log --oneline --since="2 weeks ago" --grep="fix" -- src/auth/

# 3. 不记得函数名了，只记得改过它 → pickaxe 找
git log -S "validateToken" --oneline -- src/auth/

# 4. 命中某个提交后，放大看它改了什么
git show 9f8e7d6 --stat
git show 9f8e7d6 -- src/auth/login.js

# 5. 看该文件"当时"的样子（不改工作目录）
git show 9f8e7d6:src/auth/login.js

# 6. 若发现是某次 reset 误删了提交 → reflog 找回
git reflog
git branch rescue <哈希>
```

> [!success] 成功标志
> 能一条命令画出带标签的分支图；能用 `--grep` / `-S` / `-- 路径` 把目标提交缩到几条；
> 能 `git show <哈希>:<路径>` 还原任意历史版本;**误操作后能靠 `git reflog` 把提交捞回来**。

---

## 八、常见困惑

> [!question] `git log` 里怎么突然少了几条提交？我是不是弄丢数据了？
> 多半是你**切了分支、或做过 `reset`/`rebase`**。`git log` 只显示"当前引用能到达"的提交。
> - 想看全部分支：`git log --all --oneline`。
> - 确认是真丢了：`git reflog` 里往往还找得到它们（见第六节）。
> 历史是**不可变的**，提交一旦生成就还在对象库里，"消失"通常只是"当前没有指针指向它"。

> [!question] 提交的哈希那么长，平时要写全吗？
> 不用。Git 允许**唯一前缀缩写**——通常 7 位就够（如 `a1b2c3d`）。
> 冲突时 Git 会提示"ambiguous"，多写几位即可。`git log --oneline` 打的就是缩写。

> [!question] `git log -p` 和 `git show` 有什么区别？
> - `git log -p`：**整条链**上每个提交都附带 diff（输出很长）。
> - `git show <提交>`：**单个**提交的详情（默认就是 HEAD）。
> 想连续看几个提交的改动：`git log -p -3`;想聚焦某一个：`git show <哈希>`。

> [!question] 怎么知道"这行代码是谁、哪次改的"？
> `git blame <文件>`（第八节的"认领"）会给**每一行**标出最后改动它的提交与作者。
> 嫌乱可以 `git blame -L 40,60 <文件>` 只看第 40–60 行。它是"读历史"的另一个入口。

> [!question] `--follow` 有必要吗？
> 文件**被重命名过**就有必要。不加 `--follow`，Git 把"改名"当成"旧文件删除 + 新文件新增"，改名前的历史就查不到了。
> 注意 `--follow` 目前**只支持单个文件**，且要放在 `--` 路径之前。

> [!question] 提交信息写错了，`git log` 里能看到，能改吗？
> 能，但会**换哈希**：`git commit --amend` 改最近一次；更早的用 `git rebase -i`。
> **口诀同 [[提交]]：公共历史不可改，私人历史随便改。** 已推送且被他人拉取过的提交别动。

---

> [!quote] 一句话记忆
> **`git log` 是"倒着读的日记"**：顺着 `parent` 往回翻，`--grep`/`-S` 是检索，`--graph` 是目录，`git show` 是放大镜；**万一哪天撕了页，`git reflog` 还能把碎纸捡回来**。

---

## 相关笔记

- [[提交]] —— 提交里装了什么、哈希为何不可变，是读懂 `log` 的前提
- [[暂存区]] —— `git log -p` 展示的 diff 由提交快照临时算出
- [[工作目录]] —— `git diff`（工作目录 vs 提交）的对照对象
- [[关于.gitignore]] —— 用 `git log` 回看历史里是否残留不该提交的文件
- [[git init]] —— `.git/refs`、`HEAD` 由 init 建立，log 顺着它们走
- [[git config]] —— 可配 `alias.lg` 等别名、`log.date` 日期格式、`gc.reflogExpire` 保留时长

---

参考：Pro Git 第 2 章 —— Git 基础（查看提交历史）；`man git-log` / `man git-show` / `man git-reflog`
