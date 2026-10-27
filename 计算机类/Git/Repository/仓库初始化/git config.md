# git config —— 配置 Git

> [!abstract] 一句话
> `git config` ==是 Git 的**配置读写工具**==：它以"**键值对**"的形式管理配置项——小到你的名字和邮箱，大到编辑器、别名、换行符策略、代理。

---

## 一、三级作用域：配置写到哪里

`git config` 不带作用域选项时，会"就近写入"；加上选项才能精确控制写在哪一层。

| 选项 | 作用域 | 影响范围 | 配置文件 |
| --- | --- | --- | --- |
| `--system` | 系统级 | 本机**所有用户、所有仓库** | Windows：`C:\Program Files\Git\etc\gitconfig`<br>Linux：`/etc/gitconfig` |
| `--global` | 全局级 | 当前**用户的所有仓库** | `~/.gitconfig`（`%USERPROFILE%\.gitconfig`） |
| `--local` | 本地级（**默认**） | **仅当前仓库** | `<仓库>/.git/config` |
| `--worktree` | 工作树级 | 当前工作树（多工作树场景） | `<仓库>/.git/config.worktree` |

> [!info] 默认行为：读按优先级，写就近
> - **读**（不写作用域）：按 `local → global → system` 顺序查找，**就近的赢**。详见 [[本地配置与全局配置（Local VS Global Config）]]。
> - **写**（不写作用域）：默认写入 **`--local`**；**不在仓库内时**退回到 `--global`。
> - 想避免歧义，**写配置时永远显式带上作用域**。

---

## 二、读写语法

### 2.1 读

```bash
git config user.name                 # 读单个值（就近优先）
git config --get user.email          # 同上，显式写法
git config --global user.name        # 只读全局那一层
git config --get-all user.name       # 读该键的"所有值"（多值配置用）

git config --list                    # 列出所有生效配置
git config --list --show-origin      # ★列出并显示"每个值来自哪个文件"
git config --list --show-scope       # ★列出并显示作用域（system/global/local）
```

> [!tip] 排查配置问题，先看 `--show-origin`
> 为什么我设了邮箱却不生效？为什么这个值怪怪的？
> `git config --list --show-origin` 会打出**每个配置项的来源文件**，一眼定位是谁覆盖了谁。

### 2.2 写

```bash
git config --global user.name "张三"       # 设置
git config --global user.email "zs@x.com"

git config --global --unset core.editor   # 删除该键
git config --global --unset-all --get-regexp '^alias\.'  # 批量删（配合正则）

git config --global --add alias.co checkout  # 给同一个键"追加"一个值（多值）
git config --global --edit                 # 直接用编辑器打开配置文件手改
```

> [!note] `--add` 用于"一键多值"
> 大多数配置项只能有一个值，直接 `git config key value` 会**覆盖**旧值。
> 少数项天然支持多个值（如一个远程 `url` 配多条推送地址、多个 `insteadOf`），这时要用 `--add` 追加，用 `--get-all` 读取。

---

## 三、常用配置项速查

| 配置项 | 作用 | 推荐值 |
| --- | --- | --- |
| `user.name` | 提交作者名 | 你的名字 |
| `user.email` | 提交作者邮箱 | **必须与远端账号一致** |
| `core.editor` | 编辑提交信息用的编辑器 | `code --wait` / `vim` / `notepad++` |
| `init.defaultBranch` | 新建仓库的默认主分支名 | `main` |
| `core.autocrlf` | 换行符自动转换（见下） | Windows `true`，mac/Linux `input` |
| `core.quotepath` | 是否转义非 ASCII 文件名 | `false`（中文文件名才正常显示） |
| `color.ui` | 输出着色 | `auto` |
| `pull.rebase` | `git pull` 默认用 rebase 还是 merge | 团队统一（`false` 或 `true`） |
| `push.default` | 无参数 `push` 的行为 | `simple` |
| `credential.helper` | 记住账号密码的方式 | `manager`（Windows）/ `store` / `osxkeychain` |
| `merge.conflictstyle` | 冲突标记样式 | `zdiff3`（更易看懂） |
| `alias.*` | 命令别名 | 见第四节 |
| `http.proxy` / `https.proxy` | 走代理 | 按需 |

> [!warning] `user.email` 写错，提交"白做"
> Git 不校验邮箱真假，但 GitHub / GitLab 靠邮箱**把提交关联到你的账号**。
> 邮箱错了 → 提交悬空、不显示作者头像、不计入贡献图。**换机/换项目第一件事就是核对它。**

### `core.autocrlf` 该设什么

```bash
git config --global core.autocrlf true    # Windows：检出转 CRLF，提交转 LF
git config --global core.autocrlf input   # macOS/Linux：提交时转 LF，检出不动
git config --global core.autocrlf false   # 不转换（仓库有 .gitattributes 时用）
```

> [!danger] 换行符是所有团队的经典事故
> Windows 用 `CRLF`（`\r\n`），Linux/macOS 用 `LF`（`\n`）。
> 不统一的话，会出现"我只改了一行，`git diff` 却说整个文件都变了"。
> 现代做法：**仓库里放一个 `.gitattributes`**（`* text=auto eol=lf`）从源头统一，比依赖每个人各自的 `autocrlf` 更可靠。

---

## 四、别名 alias：给自己造命令

```bash
git config --global alias.st  status
git config --global alias.co  checkout
git config --global alias.br  branch
git config --global alias.ci  commit
git config --global alias.last "log -1 HEAD"
git config --global alias.unstage "reset HEAD --"
git config --global alias.lg "log --oneline --graph --all --decorate"
```

之后就能这样用：

```bash
git st            # = git status
git lg            # 漂亮的图形化日志
git unstage file  # = git reset HEAD -- file
```

> [!tip] 别名也能"造新命令"
> 别名值如果**不以 `git` 开头**，Git 会补上（`alias.lg = log ...`）。
> 想调用外部程序，就让别名以 `!` 开头：`git config --global alias.visual '!gitk'`。

---

## 五、优先级演示：同一个键三层都设了会怎样

```bash
git config --system user.email "sys@example.com"
git config --global user.email "global@example.com"
git config --local  user.email "local@example.com"

git config user.email                       # local@example.com  ← 就近的赢
git config --global user.email              # global@example.com
git config --list --show-origin             # 三层来源一目了然地列出来
```

> [!success] 结论：越靠近仓库，优先级越高
> **`local` > `global` > `system`**。
> 单值配置是"覆盖"，多值配置是"累加"（低优先级的先出现，高优先级的后出现）。

---

## 六、配置文件长什么样

`.gitconfig` 是普通的 INI 风格文本，可以直接编辑：

```ini
[user]
    name = 张三
    email = zhangsan@example.com
[init]
    defaultBranch = main
[core]
    editor = code --wait
    quotepath = false
[alias]
    st = status
    lg = log --oneline --graph --all --decorate
[pull]
    rebase = false
```

> [!tip] `[section.subsection]` 就是点号的来源
> 配置项 `core.editor` 对应文件里的 `[core]` 段下的 `editor`；
> `alias.lg` 对应 `[alias]` 段下的 `lg`。`git config` 只是给这个文本文件套了一层命令行外壳。

---

## 七、完整示例：新电脑 / 新仓库的"开机配置"

```bash
# 1. 你是谁（必做，否则 commit 直接被拒）
git config --global user.name  "张三"
git config --global user.email "zhangsan@example.com"

# 2. 主分支默认名
git config --global init.defaultBranch main

# 3. 中文文件名不乱码
git config --global core.quotepath false

# 4. 换行符（Windows）
git config --global core.autocrlf true

# 5. 常用别名
git config --global alias.st status
git config --global alias.lg "log --oneline --graph --all --decorate"

# 6. 检查最终生效结果与来源
git config --list --show-origin
```

> [!failure] 没配 `user.name` / `user.email` 会怎样
> ```text
> *** Please tell me who you are.
> Run
>   git config --global user.email "you@example.com"
>   git config --global user.name "Your Name"
> fatal: unable to auto-detect email address
> ```
> 这是**新手第一次 commit 最常见的报错**，照着提示配一次就永久解决。

---

> [!quote] 一句话记忆
> **`git config` = Git 的"设置"面板**：用 `--global` / `--local` 决定这条设置管多大范围，用 `--list --show-origin` 看清"谁覆盖了谁"。

---

## 相关笔记

- [[本地配置与全局配置（Local VS Global Config）]] —— 三层配置的作用范围与优先级
- [[git init]] —— 初始化仓库，会创建本仓库的 `.git/config`
- [[什么是版本控制]] —— 提交里"作者"从哪来
- [[为什么使用版本控制]] —— 协作与留痕的背景

---
参考：Pro Git 第 1 章 —— 初次运行 Git 前的配置
