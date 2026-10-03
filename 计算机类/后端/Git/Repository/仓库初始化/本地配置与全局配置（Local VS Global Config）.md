

> [!abstract] 一句话
> Git 的配置分**三层**（system / global / local），作用范围**从大到小**、优先级**从小到大**：==**越靠近具体仓库的配置，越能覆盖上面两层**==。`--global` 管"整台电脑上的所有仓库"，`--local` 只管"当前这一个仓库"。

---

## 一、三层作用域一览

| 层级             | 选项         | 管多大范围           | 典型内容                  |
| -------------- | ---------- | --------------- | --------------------- |
| **系统级** system | `--system` | 本机**所有用户**的所有仓库 | 罕见的机器级默认              |
| **全局级** global | `--global` | 当前**用户**的所有仓库   | ==姓名、邮箱、编辑器、别名==      |
| **本地级** local  | `--local`  | **仅当前仓库**       | ==该仓库专用邮箱、远端地址、分支追踪== |

> [!info] 为什么要有"全局"和"本地"之分
> 因为有太多设置是**"我这个人"的**（我叫什么、用什么编辑器），也有不少是**"这个项目"的**（用哪个邮箱提交、推到哪里）。
> 全局配置负责把**共性**设一次；本地配置负责为**特例**做覆盖，两者配合才不用在每个仓库里重复劳动。

---

## 二、核心规则：优先级

```text
优先级（高 → 低）：  local   >   global   >   system
作用范围（小 → 大）：  local   <   global   <   system
```

> [!tip] 一句话记住
> ==**范围越小，话越重**==。同一个键在多层都设了，**就近的那个赢**。
> 可以理解为 CSS 的层叠、或"文件系统就近查找"——离得近的定义覆盖远的。

### 2.1 单值配置：就近覆盖

```bash
git config --system user.email "sys@example.com"
git config --global user.email "personal@example.com"
git config --local  user.email "work@example.com"

git config user.email      # → work@example.com   （local 覆盖了 global 和 system）
```

### 2.2 多值配置：累加，不是覆盖

对**天然支持多个值**的键（如 `--add` 添加的条目），低优先级的先列出、高优先级的后列出，**并不互相覆盖**：

```bash
git config --global --add url."git@github.com:".insteadOf "gh:"
git config --local  --add url."git@gitlab.com:".insteadOf "gl:"
git config --get-all url."git@github.com:".insteadOf   # 两个都在
```

> [!warning] 别把"覆盖"和"累加"搞混
> `user.name` 这类**标量键**是覆盖；`--add` 过的**多值键**是累加。
> 判断依据很简单：这个键在文件里**出现了几次**。出现两次及以上的，就是多值、按顺序全生效。

---

## 三、配置文件都在哪

| 层级     | Windows                                      | macOS / Linux                            |
| ------ | -------------------------------------------- | ---------------------------------------- |
| system | `C:\Program Files\Git\etc\gitconfig`         | `/etc/gitconfig`                         |
| global | `%USERPROFILE%\.gitconfig`（即 `~/.gitconfig`） | `~/.gitconfig`（或 `~/.config/git/config`） |
| local  | `<仓库>\.git\config`                           | `<仓库>/.git/config`                       |

> [!note] `.git/config` 会跟着仓库走
> `--local` 写进的是**仓库内部的 `.git/config`**：这个仓库被拷贝、被 `git clone` 之后……注意——**`.git/config` 不会被 clone 带走**（`user.*`、`remote.*` 等都在本地重新生成或手配）。
> 想随仓库分发给所有人，要用**受版本管理的 `.gitattributes` / 模板**，而不是本地配置。

> [!tip] 顺序可自定义：`GIT_CONFIG_*` 环境变量
> 一般不折腾。默认顺序就是 `system → global → local`，后面的覆盖前面的。

---

## 四、怎么看"某个值到底来自哪一层"

这是排查配置问题的核心手段：

```bash
git config --list --show-origin      # 每个配置项 + 它的来源文件
git config --list --show-scope       # 每个配置项 + 它的作用域（system/global/local）
git config --show-origin --get user.email   # 只查这一个键来自哪里
```

输出示例：

```text
file:C:/Program Files/Git/etc/gitconfig   core.symlinks=false   ← system
file:C:/Users/Zhang/.gitconfig            user.name=张三         ← global
file:C:/proj/.git/config                  user.email=work@x.com  ← local（覆盖了 global 的邮箱）
```

> [!success] 为什么这个命令这么重要
> 配置不生效时，你以为是没写上，其实是**写到了另一层、或被更高优先级覆盖了**。
> `--show-origin` 直接告诉你"这个值从哪个文件读来的"，问题当场定位。

---

## 五、典型场景

### 场景一：全局用私人邮箱，公司仓库用公司邮箱

```bash
git config --global user.email "me@personal.com"      # 全局：个人邮箱
cd ~/work/company-project
git config --local  user.email "me@company.com"       # 本地：覆盖成公司邮箱
```

> [!example] 这就是 local 覆盖 global 的标准用法
> 全局设一次"默认身份"，个别仓库只需要**补一条不同项**，不必把整套配置重写一遍。
> 离开这个仓库后，其他项目依然用全局邮箱，互不影响。

### 场景二：同一台机器管工作 / 个人两套账号

```bash
# 全局默认 = 个人
git config --global user.name "Zhang San"
git config --global user.email "me@personal.com"

# 每个公司仓库里覆盖 = 公司
git config --local user.name "San Zhang"
git config --local user.email "san@company.com"
```

### 场景三：只想给单个仓库换个编辑器 / 关掉某项设置

```bash
git config --local core.editor vim        # 只这个仓库用 vim
git config --local commit.gpgsign false   # 只这个仓库不签名
```

---

## 六、常见坑

> [!failure] 在仓库外写 `--local`：`fatal: not in a git directory`
> `--local` 必须有仓库才能写。先 `git init`（见 [[git init]]）或进入已有仓库，再执行。

> [!failure] `--global` 报找不到 HOME：`fatal: $HOME not set`
> Git 靠 `HOME`（Windows 上常是 `USERPROFILE`）定位全局配置文件。环境变量缺失会导致 `--global` 失败。

> [!danger] 优先级记反了
> 很多人误以为"全局配置更权威、能压过本地"——**正好相反**。
> ==**local 优先于 global 优先于 system**==。全局是"默认值"，本地才是"最终决定"。

> [!warning] 以为设了 `--global` 就到处生效
> `--global` 只覆盖**当前用户**。换用户、换管理员账号、用 `sudo`（其 HOME 不同）都会读到另一套配置。

---

## 七、完整对照示例

```bash
# ── 全局：一次配好，管所有仓库 ──────────────────
git config --global user.name  "Zhang San"
git config --global user.email "me@personal.com"
git config --global init.defaultBranch main
git config --global core.editor "code --wait"

# ── 本地：只为这个仓库打补丁 ────────────────────
cd ~/work/api-service
git config --local  user.email "san@company.com"    # 换成公司邮箱
git config --local  core.editor "vim"               # 这个项目偏好 vim

# ── 验证：看清每一层各设了什么、谁在生效 ──────────
git config --list --show-scope | grep -E 'user\.|core\.editor'

# 预期：
#   global  user.name=Zhang San
#   global  user.email=me@personal.com        ← 被下面覆盖
#   local   user.email=san@company.com        ← 实际生效
#   local   core.editor=vim                   ← 实际生效
```

---

> [!quote] 一句话记忆
> **global 是"我这个人"的默认设置，local 是"这个项目"的临时覆盖；同一个键，==离仓库越近的越说了算==**（local > global > system）。

---

## 相关笔记

- [[git config]] —— 读写配置的命令与常用配置项
- [[git init]] —— 初始化仓库时会创建本地配置 `.git/config`
- [[什么是版本控制]] —— 提交、作者等概念
- [[为什么使用版本控制]] —— 协作背景

---
参考：Pro Git 第 1 章 —— 初次运行 Git 前的配置；`git help config`
