# git init —— 初始化仓库

> [!abstract] 一句话
> ==`git init` 把一个**普通目录**变成 **Git 仓库（Repository）**==：它在目录里创建一个 `.git` 隐藏子目录，把版本历史、配置、分支指针统统塞进去。执行完这一步，这个目录才真正"归 Git 管"。

---

## 一、基本用法

| 命令                                 | 作用                        |
| ---------------------------------- | ------------------------- |
| `git init`                         | ==把**当前目录**初始化为仓库==       |
| `git init <目录名>`                   | **新建**一个目录并初始化（目录已存在也可以）  |
| `git init -b main`                 | 初始化，并把初始分支命名为 `main`      |
| `git init --bare`                  | 创建**裸仓库**（没有工作区，用于服务器）    |
| `git init --separate-git-dir=<路径>` | 把 `.git` 放到别处，工作区只留一个链接文件 |

```bash
# 1. 在当前目录初始化
cd my-project
git init
# Initialized empty Git repository in D:/my-project/.git/

# 2. 新建目录并初始化（推荐用 -b 指定主分支名）
git init -b main my-project
# Initialized empty Git repository in D:/my-project/.git/

# 3. 旧版本 Git 没有 -b，只能先 init 再改名
git init
git branch -m main
```

> [!tip] init 之后，文件仍然"没被追踪"
> `git init` 只是**建了一个空账本**，它**不会**自动把任何文件纳入版本控制。
> 紧接着的标准动作是：写 `.gitignore` → `git add .` → `git commit -m "初始提交"`。
> 只 init 不 commit，`git status` 会显示一堆 `Untracked files`。

---

## 二、它到底做了什么

执行 `git init` 后，Git 会在目标目录里创建 `.git/`：

```text
my-project/
├── .git/              ← 仓库的"大脑"，全部历史与配置都在这里
│   ├── HEAD           ← 指向当前分支（内容形如 ref: refs/heads/main）
│   ├── config         ← 本仓库的配置（--local，见 [[git config]]）
│   ├── description    ← 仅供 GitWeb 使用，平时不用管
│   ├── hooks/         ← 客户端钩子示例脚本
│   ├── info/
│   │   └── exclude    ← 本仓库专用的忽略规则（类似私有 .gitignore）
│   ├── objects/       ← 所有内容（提交、目录树、文件）以对象形式存放
│   │   ├── info/
│   │   └── pack/
│   └── refs/          ← 引用（指针）
│       ├── heads/     ← 分支
│       └── tags/      ← 标签
└── （你的项目文件，此时还没被追踪）
```

> [!info] `index` 和 `logs/` 这时还没有
> `.git/index`（暂存区）要等到**第一次 `git add`** 才生成；
> `.git/logs/`（reflog）要等到**第一次提交或引用变动**才生成。
> 所以刚 init 完看到的 `.git` 比上面列的要"瘦"一点，这很正常。

> [!note] `.git` 就是整个仓库
> Git 认仓库靠的就是这个目录。**删掉 `.git`，这个目录立刻变回一个普通文件夹**——历史、分支、配置全没了，而且无法恢复。这也正是"取消初始化"的做法（见第六节）。

---

## 三、默认分支名：master 还是 main

Git 2.28 之前，`git init` 建出来的默认分支叫 `master`；之后 Git 会打印一段提示，建议你把默认名改掉。

```text
hint: Using 'master' as the name for the initial branch. This default branch name
hint: is subject to change. To configure the initial branch name to use in all
hint: of your new repositories, which will suppress this warning, call:
hint:
hint:   git config --global init.defaultBranch <name>
```

两种处理方式，==**推荐第一种：一劳永逸**==：

```bash
# 方式一：设成全局默认，以后 git init 都建 main
git config --global init.defaultBranch main

# 方式二：每次 init 时显式指定
git init -b main
```

> [!warning] 名字只是名字，但要全队统一
> `master` / `main` 在 Git 眼里**没有任何特殊含义**，纯粹是个普通分支名。
> 但如果你用 GitHub / GitLab，云端仓库的主分支名会和本地对不上 → 首次 `push` 要额外指定上游。
> **团队/新项目统一用 `main`**，省得来回解释。

---

## 四、裸仓库 `--bare`

```bash
git init --bare project.git
```

> [!info] 裸仓库没有工作区
> 普通仓库的 `.git` 里装着历史，工作区里是"当前能编辑的文件"；
> 裸仓库**直接把 `.git` 里的内容摊开放在目录根上**，没有工作区，因此**不能在里面 `git add` / `git commit`**。
>
> 它的定位是**中央仓库 / 服务器端**：只负责接收和分发，专门供大家 `clone` / `push` / `fetch`。
> 约定俗成的命名是加 `.git` 后缀：`project.git`。
>
> 在 GitHub 上建仓库、在服务器上用 `git init --bare` 建仓库，本质是一回事。

---

## 五、`git init` vs `git clone`

| 对比  | `git init`        | `git clone <url>`           |
| --- | ----------------- | --------------------------- |
| 起点  | ==**从零**新建一个空仓库== | ==从**已有的远程仓库**复制一份==        |
| 结果  | 空历史，等你提交          | 完整历史 + 已配好的 `remote.origin` |
| 场景  | 本地新项目，之后才推上去      | 参与/获取一个已存在的项目               |

> [!tip] clone 内部也会 init
> `git clone` 做的事相当于：新建目录 → `git init` → 添加远程 `origin` → `git fetch` 拉取全部历史 → 检出默认分支。
> 所以**克隆下来的仓库，不需要再手动 `git init`**，也不用手动 `git remote add origin`。

---

## 六、取消初始化

```bash
# 删掉 .git 目录 —— 目录立刻变回普通文件夹，Git 从此不再管它
rm -rf .git          # macOS / Linux
```

```powershell
# Windows PowerShell
Remove-Item -Recurse -Force .git
```

> [!danger] 这一刀是不可逆的
> 删掉 `.git` 会**永久丢失该仓库的全部历史、分支、标签、暂存内容、本地配置**。
> 只有两种情况可以放心删：
> 1. 你**确定**这是误操作，本来就不该初始化；
> 2. 历史已经推到了远程，随时能重新 `clone` 回来。
>
> **不要**用"删 `.git` 再 init"来解决冲突或历史混乱——那等于把病历烧了重开一本。

---

## 七、完整示例：把一个已有项目纳入版本控制

```bash
cd my-project                 # 进入项目目录

git init -b main              # 初始化，主分支叫 main

# 先写忽略规则，别把垃圾提交进去
printf 'node_modules/\n*.log\n.env\n' > .gitignore

git add .                     # 把当前所有文件放进暂存区（.gitignore 里的除外）
git status                    # 确认要提交的内容
git commit -m "chore: 初始提交"  # 生成第一个提交

git log --oneline             # 应该能看到唯一的一个提交
```

> [!success] 成功标志
> `git log` 能打出第一个 commit，`git status` 显示 `nothing to commit, working tree clean`。
> 如果 `git status` 显示 `No commits yet` + 一串 untracked，说明 `git add` / `git commit` 还没做。

---

## 八、常见提示与报错

> [!note] `Reinitialized existing Git repository in ...`
> 在**已经初始化过**的目录里再跑一次 `git init`。
> **不是错误，也不会清空任何东西**——它只是把缺失的模板文件补齐、把配置刷新一遍。
> 已有历史、分支、工作区**原封不动**，可以放心。

> [!failure] `fatal: not a git repository (or any of the parent directories): .git`
> 当前目录（及其所有父目录）都不是 Git 仓库。
> 要么你站错目录了，要么这个项目根本还没 `git init`。

> [!failure] `fatal: cannot mkdir ... Permission denied` / 路径含空格、中文异常
> 通常是权限不足或路径问题。用管理员权限重试，或把项目放到纯英文、无空格的路径下。

---

> [!quote] 一句话记忆
> **`git init` = 给目录装上一个"时间机器引擎"（`.git/`）**；引擎装好了，但还没开始记录——**第一次 `git add` + `git commit` 才是按下录制键**。

---

## 相关笔记

- [[git config]] —— 初始化后第一件事：告诉 Git 你是谁
- [[本地配置与全局配置（Local VS Global Config）]] —— 配置分三层，`init` 会创建本地配置
- [[什么是版本控制]] —— 仓库、提交、分支的概念
- [[为什么使用版本控制]] —— 为什么值得为项目装一个"时间机器"
- [[Git 跟其他VCS的比较]] —— 分布式仓库的意义

---
参考：Pro Git 第 2 章 —— Git 基础（获取 Git 仓库）
