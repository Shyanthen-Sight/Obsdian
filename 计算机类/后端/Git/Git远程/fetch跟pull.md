# fetch 跟 pull —— 拉取远程更新

> [!abstract] 一句话
> ==`fetch` 是"只下载、不合并"，`pull` 是"下载并合并"==。更准确地说：`git pull` = `git fetch` + `git merge`（或 `git rebase`）。理解这一条，你就理解了远程协作里最容易出错的那部分——因为 `pull` 那步"隐式合并"会悄悄动你的工作区，而 `fetch` 永远只更新本地缓存、绝不碰你的文件。

---

## 一、先复习：远程跟踪分支

远程仓库的分支，在本地以 `origin/main` 这样的**远程跟踪分支**存在（见 [[查看分支]]）：

```text
远程 (GitHub)                本地
  main  ────fetch 复制───→   origin/main   ← 只读"快照"，随 fetch 更新
                                   │
                            pull/merge 把它并进来
                                   ▼
                               main          ← 你真正工作的分支
```

> [!info] 三个名字，三种东西
> - `origin/main` —— **远程跟踪分支**：上次 `fetch` 时远程 `main` 的**快照**，你不能在这上面提交
> - `main` —— **本地分支**：你干活、提交的地方
> - `origin` —— **远程名**（地址簿里的一行），见 [[管理远程]]
>
> `fetch` 更新的是**上面那个快照**；`pull` 还会继续把快照**并进**下面那个本地分支。

---

## 二、`git fetch`：只下载，不动你

```bash
git fetch                    # 拉取当前分支的默认远程（通常是 origin）
git fetch origin             # 拉取指定远程的所有分支
git fetch origin main        # 只拉 origin 的 main
git fetch --all              # 拉取所有远程
git fetch --prune            # ★ 顺带删掉"远程已消失"的本地跟踪引用
git fetch --tags             # 连同标签一起拉
```

> [!success] fetch 的最大优点：绝对安全
> 它**只更新 `refs/remotes/*` 这批快照**，==不碰你的工作区、不碰你的本地分支、不会产生冲突==。
> 拉错了、想反悔，都没关系——你的文件一个字节没变。
> 所以"不确定远程发生了什么"时，**先 fetch 看看**，永远是最稳的第一步。

> [!tip] `--prune` 值得设成默认
> 别人删了远程分支，你本地的 `origin/旧名` 不会自动消失，`git branch -vv` 会显示 `[gone]`。
> 一劳永逸：
> ```bash
> git config --global fetch.prune true
> ```

---

## 三、`git pull`：fetch + merge

```bash
git pull                     # = fetch 当前远程 + merge 进当前分支
git pull origin main         # = fetch origin main + merge origin/main
git pull --rebase            # = fetch + rebase（把本地提交"续"到远程之后）
git pull --no-rebase         # 强制用 merge（覆盖配置）
```

> [!warning] `pull` 会**动你的工作区**
> 因为它那步 `merge` 会改写你当前分支、可能触发冲突、可能生成合并提交。
> 若手里有**未提交的改动**，`pull` 可能被拒或弄得一团乱——先 `git stash` 或先提交，再 pull。

> [!info] `pull` 的"隐式合并"到底合了谁
> 合并的对象是 **`FETCH_HEAD`**（刚 fetch 下来的那个远程分支顶端）。
> 所以说 `git pull origin main` ≈ `git fetch origin main` + `git merge FETCH_HEAD`。

---

## 四、`pull --rebase`：保持历史一条直线

```text
merge 版 pull（默认）：
    A ── B ── C ────── M   ← 多出一个合并提交
             \        /
              D ── E

rebase 版 pull：
    A ── B ── C ── D' ── E'  ← 你的提交被"搬到"远程最新之后，没有分叉
```

> [!tip] 团队约定：`pull.rebase`
> ```bash
> git config --global pull.rebase true   # 以后 git pull 默认走 rebase
> ```
> **铁律**：rebase 会**重写提交哈希**，只能用于**别人没拉过**的本地提交。
> 已推给别人/已合并的提交，不要 rebase。详见 [[推送远程]] 中强推的注意事项。

> [!note] 该选 merge 还是 rebase？
> - 想保留"这里曾有分叉"的真实形状 → 默认 merge
> - 想要线性、干净、像一条直线 → `--rebase`
> 这是**团队风格**问题，开工前对齐；一个人在本地同步，rebase 通常更清爽。

---

## 五、最佳实践：fetch → 看 → 再合并

比起直接 `pull`（蒙着眼合并），更稳的姿势是**分两步**：

```bash
git fetch                              # 1. 只下载，不动我
git log --oneline HEAD..origin/main    # 2. 远程"进来了哪些"提交？
git log --oneline origin/main..HEAD    #    我"要推出去哪些"提交？
git diff HEAD origin/main              # 3. 远程到底改了哪些内容？
git merge origin/main                  # 4a. 确认无误，合并（或）
git rebase origin/main                 # 4b. 或 rebase
```

> [!success] 为什么这样更好
> `pull` 把"下载"和"合并"揉成一步，出了冲突你都不知道是拉取失败还是合并失败。
> 拆成两步后：**fetch 阶段永远安全**，你有机会先看清差异、决定 merge 还是 rebase，再动手。

> [!info] 两条 log 的方向别记反
> - `HEAD..origin/main` —— 远程**有而我没有**的（= 即将"进来"的）→ 该 pull
> - `origin/main..HEAD` —— 我**有而远程没有**的（= 即将"出去"的）→ 该 push
>
> 记忆法：==左边是排除项，"A..B" = 在 B 中不在 A 中==。`git branch -vv` 的 `ahead` / `behind` 就是它们的计数版。

---

## 六、完整示例

```bash
# 场景一：日常同步主分支
git switch main
git fetch                                  # 先看
git status                                 # 确认工作区干净
git pull --rebase                          # 拉取并重新应用本地提交

# 场景二：想知道远程改了啥再决定
git fetch origin
git log --oneline --graph HEAD..origin/main   # 看看进了哪些
git diff HEAD origin/main                      # 看内容差异
git merge origin/main                          # 满意就合并

# 场景三：远程分支被删了
git fetch --prune                          # 清掉 expired 的 origin/旧名
git branch -vv                             # [gone] 应消失

# 场景四：拉取时遇到冲突
git fetch
git merge origin/main                      # 冲突了
git status                                 # 看 Unmerged paths
# 解决文件、删掉 <<<< ==== >>>> 记号
git add <文件>
git commit                                 # 完成合并（详见 [[合并基础]]）
```

> [!success] 成功标志
> `git branch -vv` 里 `behind` 归零、本地与 `origin/xxx` 对齐；
> `git log --oneline --graph` 能看到本地提交已接在远程最新之后。

---

## 七、常见困惑

> [!question] `fetch` 和 `pull` 到底差在哪？
> 一句话：==`pull` = `fetch` + `merge`==。
> `fetch` 只更新远程跟踪分支（快照），`pull` 还多一步把快照合并进你的当前分支。

> [!question] 为什么我 `git fetch` 后 `git log` 没变化？
> 因为 `fetch` 只动了 `origin/main` 这个快照，**没动你的 `main`**。
> 想看变化，用 `git log HEAD..origin/main`；想让 `main` 也跟上，得 `git merge origin/main` 或 `pull`。

> [!question] `pull` 提示要设上游 / 说不知道拉哪个远程？
> 该分支还没设上游。先 `git push -u origin <分支>` 或 `git branch -u origin/<分支>` 设好，
> 之后 `git pull` 才认得方向。见 [[推送远程]]。

> [!question] `pull` 时提示 "divergent branches" 要你选策略？
> 新版 Git 在没配置默认策略、且确实需要合并时会提示。
> 按需选 merge 或 rebase，或直接写死配置：
> ```bash
> git config --global pull.rebase false   # 永远 merge
> # 或
> git config --global pull.rebase true    # 永远 rebase
> ```

> [!question] 未提交的改动会不会被 `pull` 冲掉？
> `pull` 的合并步骤若发现会覆盖你的本地改动，**会拒绝**并让你先处理，一般不会静默丢失。
> 稳妥做法：动 `pull` 前先 `git stash` 或先提交。见 [[工作目录]]、[[暂存区]]。

> [!question] rebase 式 pull 之后，本地提交的哈希变了，有问题吗？
> 只要这些提交**还没推给别人**，就没问题——变的是你自己的、未公开的历史。
> 若已经推过，rebase 会造成分叉，别人 pull 会很痛苦。**别对已公开的提交 rebase**。

---

> [!quote] 一句话记忆
> **`fetch` 是"把远程的快照拿回来"，`pull` 是"顺手并进我的分支"**。想稳，就 ==fetch 先看、再决定 merge 还是 rebase==；想一次到位，`pull --rebase` 换直线历史。方向永远是"远程 → 本地"。

---

## 相关笔记

- [[推送远程]] —— 反方向：把本地提交送进远程
- [[管理远程]] —— `origin` 等远程名从哪来
- [[克隆仓库]] —— 第一次把远程"全量"取下来的方式
- [[查看分支]] —— `origin/main` 是什么、`ahead`/`behind`/`[gone]` 怎么读
- [[合并基础]] —— `pull` 背后的 merge、冲突如何解决
- [[删除分支]] —— `fetch --prune` 清理已消失的远程跟踪引用
- [[提交]] —— merge 产生的合并提交与父提交
- [[工作目录]] —— `pull` 前为何要先处理未提交改动

---

参考：Pro Git 第 2 章 —— Git 基础（从远程仓库中抓取与拉取）；第 3 章 —— Git 分支（远程分支 · 拉取）
