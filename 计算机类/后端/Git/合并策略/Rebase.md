# Rebase —— 把提交"搬"到另一条线顶端

> [!abstract] 一句话
> ==`rebase` 把当前分支上的一串提交**挨个摘下来、复制到目标分支顶端重新提交一遍**==。结果是不产生合并节点、历史变成一条直线——看起来"像一开始就在最新代码上开发的"。代价是**提交被重写（哈希变了）**，所以有一条铁律：**只 rebase 别人没拉过的提交**。

> [!warning] 它改写历史，不是移动历史
> rebase 之后的提交是**全新的提交**（新哈希），旧提交被丢弃（但 reflog 里还找得到）。
> 对**已推送、别人可能已拉取**的分支做 rebase，会给协作者制造混乱。见第五节的黄金法则。

---

## 一、rebase 到底做了什么

```text
【rebase 前】
      A ── B ── C          ← main
      │
      D ── E               ← feature（你想让它在 main 最新代码之上）

【rebase 后】git switch feature && git rebase main
      A ── B ── C          ← main
                 │
                 D' ── E'   ← feature（D、E 被"重放"为新提交 D'、E'）
```

> [!info] 关键理解
> - `D`、`E` **不是被移动**，而是被**逐个重放**到 `C` 之上，生成新的 `D'`、`E'`（内容相同、父不同，故哈希不同）。
> - 原来的 `D`、`E` 成了"孤儿提交"，暂时还能靠 `git reflog` 找回（见第八节）。
> - **不产生合并提交**，所以 `git log` 是笔直的一条线。

---

## 二、基本用法

```bash
# 场景：feature 分支基于旧的 main，先把 feature 挪到最新 main 之上
git switch feature
git rebase main              # 把 feature 的独有提交重放到 main 顶端

# 或：在 main 上把别人的改动"接"进来（等价于在 feature 上 rebase main）
git switch feature
git rebase main
```

> [!tip] rebase 的方向
> `git rebase <upstream>` = **把当前分支**的独有提交，搬到 `<upstream>` 之上。
> 和 `merge` 一样，**先站对分支**；方向反了会得到意外的结果。

---

## 三、交互式 rebase：`-i`

```bash
git rebase -i HEAD~3           # 整理最近 3 个提交
git rebase -i <某个提交哈希>    # 整理那之后的提交
```

会打开编辑器，列出待处理提交，每行一个动作：

```text
pick  a1b2c3d 添加登录接口
pick  e4f5g6h 修个笔误
pick  i7j8k9l 再加日志

# 命令：
# p, pick   = 保留这个提交（默认）
# r, reword = 保留，但修改提交信息
# e, edit   = 停下来，让你修改这个提交的内容
# s, squash = 并入上一个提交，并合并两者的提交信息
# f, fixup  = 并入上一个提交，丢弃本提交的信息
# d, drop   = 删除这个提交
# 上下移动行 = 调整提交顺序
```

> [!success] 三种高频用途
> - `reword`：改提交信息（不改内容，哈希变）。
> - `squash` / `fixup`：把多个小提交压成一个（详见 [[Squash]]）。
> - `drop`：删掉一个不该有的提交。

> [!warning] 交互式 rebase 会重写这些提交
> 被 `-i` 动过的提交都会变新哈希。**同样只对未推送/未共享的提交做**。

---

## 四、rebase vs merge：怎么选

| 维度 | merge | rebase |
|---|---|---|
| 历史形状 | 保留分叉，有合并节点 | 直线，无分叉 |
| 提交哈希 | 原提交不变 | 被重放，**哈希改变** |
| 是否有合并提交 | 三方合并时有 | 从不产生 |
| 对已推送历史 | 安全 | **危险**（改写公开历史） |
| 适用 | 合入主干、长期分支 | 整理本地、保持特性分支最新 |

> [!tip] 常见的组合策略
> - 在**自己的特性分支**上：`git rebase main` 保持分支最新（保持线性）。
> - 合回**主干**时：用 `git merge --no-ff` 留下一个合并节点。
> - 于是主干有清晰的汇入点，特性分支内部又保持干净——兼顾可读与线性。
> - 直接相关：[[Fast-Forward vs Non-FF]]。

---

## 五、黄金法则：不要 rebase 公开历史

> [!warning] 铁律
> ==**只 rebase 那些还没有被推送、或确定没有别人基于它工作的提交。**==
> 一旦你 rebase 了别人已经拉取的分支并强推，别人的历史就和你的对不上了，会产生重复提交、诡异的冲突。

```bash
git push --force-with-lease    # 若确实需要强推，用这个而不是 --force
```

> [!info] 为什么用 `--force-with-lease`
> 它在推送前检查远程分支是否**仍是你上次看到的样子**：如果别人已推了新东西，它**拒绝覆盖**。
> `--force` 则会无条件覆盖，可能抹掉别人的提交。见 [[推送远程]]。

---

## 六、rebase 途中遇到冲突

重放每个提交时都可能撞车，Git 会**逐个提交**停下来让你解决：

```bash
git status                     # 看冲突文件（rebase in progress）
# 编辑文件，删掉 <<<< ==== >>>> 记号
git add <解决好的文件>
git rebase --continue          # 继续重放下一个提交

git rebase --skip              # 跳过当前这个提交（当它已无意义时）
git rebase --abort             # 整个放弃，回到 rebase 之前的状态
```

> [!warning] rebase 里 `--ours` / `--theirs` 与 merge **相反**
> - **merge 时**：`--ours` = 当前分支，`--theirs` = 被合进来的分支。
> - **rebase 时**：Git 在"重放我的提交"，所以 ==**`--ours` 反而是 upstream（对方）那一侧，`--theirs` 才是你正在重放的提交**==。
>
> 记不住就别用 `--ours/--theirs`，直接手改更安全。详见 [[冲突处理]]。

> [!note] rebase 冲突可能比你想象的多
> merge 只解决**一次**冲突（把所有分歧一次性摊开）；rebase 是**逐个提交**重放，可能每个提交都撞一次。
> 这是 rebase 相对 merge 的一个实际代价。

---

## 七、几个常用变体

```bash
git rebase --onto main feature topic   # 把 topic 上"从 feature 之后"的提交，搬到 main 之上
git rebase --autosquash                # 配合 fixup! / squash! 提交信息自动排布（常与 -i 同用）
git rebase --exec "npm test" HEAD~3    # 每个提交重放后跑一次命令，可用于二分定位哪次提交引入问题
git pull --rebase                      # 拉取远程时用 rebase 而非 merge，保持本地线性
```

> [!tip] `git pull --rebase` 是常见配置
> 它把"远程新提交"放到你本地提交之下，避免每次 pull 都产生一个无意义的合并提交。
> 可设默认：`git config --global pull.rebase true`。

---

## 八、安全网：reflog

rebase 改错、`--abort` 之后还想找回旧状态，靠 `reflog`：

```bash
git reflog                     # 看 HEAD 最近去了哪（含被丢弃的提交）
git reset --hard HEAD@{3}      # 回到 reflog 里的某个位置
```

> [!success] 别慌
> 被 rebase 丢弃的提交没被立刻删除，reflog 一般保留 90 天。**只要没 `gc` 清理，几乎都能找回**。
> 但这是"事后补救"，不是"可以随便 rebase 公开分支"的理由。

---

## 九、常见困惑

> [!question] rebase 会丢代码吗？
> 正常使用不会。它把提交内容原样重放；只要冲突解决正确，代码一致。丢代码的是"rebase 了共享分支还强推"这类误用。

> [!question] rebase 之后提交哈希为什么全变了？
> 因为父提交变了（现在挂在新的顶端），而哈希由内容和父共同决定。内容相同、父不同 → 哈希不同。

> [!question] `git pull` 和 `git pull --rebase` 差在哪？
> 前者用 merge 整合远程改动（可能产生合并提交），后者用 rebase（保持直线）。团队偏好决定用哪个。

> [!question] 我已经把分支 push 出去了，还能 rebase 吗？
> 技术上能，但**不要**——除非这是你**独占**的分支且已告知协作者。否则改用 merge，或至少用 `--force-with-lease` 并提前通知。

> [!question] rebase 到一半乱了怎么办？
> `git rebase --abort` 完整回退；若已 `--continue` 完才发现不对，用 `git reflog` + `git reset --hard` 回到 rebase 前。

> [!question] merge 和 rebase 到底哪个"对"？
> 没有对错，是**历史哲学**问题：merge 忠实记录"什么时候分的、什么时候合的"；rebase 追求"一条干净的直线"。==**唯一硬规矩：别 rebase 公开历史。**==

---

> [!quote] 一句话记忆
> **rebase = 把提交摘下来、重放到新顶端**：换来直线历史，代价是**哈希重写**。==**能 rebase 的前提只有一个：这些提交别人还没拉过。**==

---

## 相关笔记

- [[合并基础]] —— merge 的方向、冲突与基本流程
- [[Fast-Forward vs Non-FF]] —— 与 rebase 相对的"保留分叉"思路
- [[Squash]] —— 用交互式 rebase 压缩提交
- [[冲突处理]] —— rebase 里的冲突与 `--ours/--theirs` 反转
- [[推送远程]] —— `--force-with-lease` 的安全强推
- [[fetch跟pull]] —— `pull --rebase` 在拉取时的作用
- [[提交]] —— 父提交、哈希与历史形状
- [[查看commit历史]] —— `--graph` 看直线还是分叉

---

参考：Pro Git 第 3.6 节 —— Git 分支（变基）；`git help rebase`
