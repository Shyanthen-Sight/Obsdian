
---
## Opening

【P1・封面：What Is GitHub?】

Good afternoon, everyone.

【P2・钩子引言 + 大问号】

I would like to begin with a small observation. Most of us have heard of GitHub — maybe from a job posting, maybe from a friend, or maybe from social media like Douyin. But if you ask a student what GitHub actually is, the answer is usually vague: "a website where programmers upload their code." That answer is not wrong, but it is far from complete.

【P3・Roadmap 路线图】

In the next ten minutes, I will explain what GitHub is, why almost every programmer in the world depends on it, and, most importantly for us as computer science students, how to make it work for our study, our projects, and our future career.

---

## Chapter 1. What Is GitHub?

【P4・Chapter 1 扉页】

Let's begin with the simplest definition.[英 /ˌdefɪ'nɪʃn/](cmd://Speak/_uk_/definition)

【P5・一句话定义】

GitHub is a website — a cloud platform — where people store, share, and work together on software projects.

But that's not the whole story. If that were all GitHub did, it would just be a hard drive in the cloud — and it's much more than that. I'd describe it as three things at once.

【P6・身份一：仓库】

First, it is a warehouse for code. Every project lives in what we call a **repository** — a folder that holds not only the files, but the complete history of every change ever made to them. Not just the latest version — all the versions.

【P7・身份二：社交网络】

Second, it is a social network for programmers. On GitHub you can follow other developers, star the projects you like, comment on someone's code, and report problems. Your profile is public. That means GitHub is also your résumé.

【P8・身份三：协作平台（三卡片）】

Third, it is a collaboration platform. It also gives you the tools to plan and build software together: **Issues** to track tasks, bugs, and feature requests; **Pull Requests** to propose changes that teammates can review and discuss before they are merged; and **Actions** to automatically test and deploy your code every time you push.

【P9・类比 + 四块大数字】

A simple **analogy**: Git is the engine; GitHub is the car, the road, and the entire city around it.

Here is one more fact worth knowing. GitHub was founded in 2008 and is now owned by Microsoft. Today it hosts more than four hundred million repositories, and over one hundred million developers use it. 

In other words: if you write software, this is the place where the world writes software with you.

---

## Chapter 2. How Should Computer Science Students Use GitHub?

【P10・Chapter 2 扉页】

So how should we, as computer science students, actually use it? Let me give you five concrete ways, from the easiest to the most valuable.

【P11・方式一：图书馆】

**Number one: use it as a library.** Some of the best learning material you will ever read is free on GitHub — you just need to know where to look. If you want to learn a language, a framework, or a whole field, search for it. Take Java as example : search "java tutorial" or "java learning", and you will find repositories full of examples, notes, and complete projects, with the best resources already collected in one place. And because reading other people's code is one of the fastest ways to become a better programmer, this library is open to you around the clock.

【P12・方式二：笔记本】

**Number two: use it as your notebook.** From your very first course project, put it on GitHub — not because anyone asked you to, but because you will thank yourself later. You will learn to write meaningful commit messages. You will be able to return to any earlier version of your code. And when something breaks, you can compare exactly what changed.

【P13・方式三：作品集】

**Number three: use it as your portfolio.** Here is a fact about the job market. When a recruiter or an interviewer looks at you, they cannot see what you can actually build. But they can open your GitHub profile, read your README, and look at your code. One well-documented project with a clear README will do more for you than a long list of entries on your résumé. Three solid projects beat thirty empty ones.

【P14・方式四：协作七步流程】

**Number four: use it to collaborate.** In group assignments and in real companies, the workflow is the same: you clone the project, create a branch for your feature, make your commits, push them, and open a pull request. Then your teammates review your code and leave comments, and once everyone agrees, your branch is merged. Learn this loop now — clone, branch, commit, push, pull request, review, merge — because it is exactly how professional teams work every single day. And if you want to contribute to open source, look for issues labeled **"good first issue"**. That label exists precisely to welcome beginners.

【P15・方式五：学生福利】

**Number five: use the student benefits.** GitHub offers a Student Developer Pack. With a student email address, you can get free access to a large set of developer tools: cloud credits, private repositories, and GitHub Copilot, an AI assistant that helps you write code. If you are a student and you have not applied yet, do it this week — it costs nothing.

【P16・安全警告（白底红标页）】

Before I move on, one warning. GitHub is public. Never put your passwords, API keys, or personal data into a public repository. And never post your professor's solution set, or copy someone else's project and present it as your own. Plagiarism on GitHub is still plagiarism — and it leaves a permanent, timestamped record.

---

## Chapter 3. What Is Git?

【P17・Chapter 3 扉页 + Git 定义】

Now let's go one level deeper, because to use GitHub well, you must understand what it was built on. So what is Git?

Git is a **version control system**. It was created in 2005 by Linus Torvalds — the same person who created Linux — to manage the development of the Linux kernel. And the key word here is **distributed**.

So, what does a version control system actually do? Imagine you are writing an essay. You save it as "essay_final.docx", then "essay_final_v2.docx", then "essay_final_really_final.docx". That is version control — done badly. Git does it properly. It records a snapshot of your project whenever you ask it to, and it stores those snapshots in a structured, comparable, and reliable way.

【P18・Git 四要点（slow）】

Let me give you four ideas that make Git click.

**First, a commit.** A commit is a saved snapshot, together with a message explaining why you made the change. Every commit has a unique ID. A project is not just its current state — it is the whole chain of commits that led there.

**Second, the three areas.** When you work with Git, your files move through three stages: the working directory, where you edit files; the staging area, where you choose which changes to include in the next snapshot; and the repository, where the history is permanently recorded. That is why the basic commands are: git add, to stage; git commit, to save; and git push, to upload.

**Third, branching.** This is Git's superpower. A branch creates a parallel line of development, so you can experiment freely without touching the main version. If the experiment works, you merge it back. If it fails, you delete the branch and nothing is lost. Branching in Git is cheap and fast — and that is the main reason Git won.

**Fourth, distributed.** There is no single central copy. Every developer who clones a repository has the full history on their own machine. That means you can commit and browse history offline, and it means no single server failure can destroy the project.

【P19・Git vs GitHub 对比】

So now the crucial distinction: **Git is the tool** — the technology that runs on your own computer. **GitHub is a service** — a platform that hosts Git repositories online. You can use Git without GitHub, and there are other hosts: GitLab, Bitbucket, Gitee. But GitHub is the biggest, and its workflow is the one you will meet in an interview.

【P20・十条命令 + 收尾金句】

Finally, let me put the essential commands in one breath: git init to start a repository; git clone to copy one from the internet; git status to see what changed; git add to stage; git commit to save; git push to upload; git pull to download; git branch and git switch to create and move between branches; and git log to read the story of your project. Ten commands. That is really all you need to begin. Everything else, you will learn the moment you need it.

---

## Closing

So, to summarize. **GitHub is where the world's code lives and where it is built together.** As students, we should use it as a library, as our notebook, as our portfolio, and as our rehearsal for teamwork. And underneath it all is **Git** — a version control system whose real gift is not storage, but freedom: the freedom to experiment, the freedom to make mistakes, and the freedom to always come back.

My advice is simple. Tonight, create an account. Tomorrow, push your first commit. A year from now, that first green square on your profile will look like a small thing — but it will be the beginning of the way you work for the rest of your career.

【P21・Thank You】

That is all for my presentation on GitHub.  Thank you for listening. If you have any questions, I would be happy to answer you. You can also find me on GitHub — my username is Shyanthen-Sight. Feel free to star my repositories or send me an issue.

---

## 演讲提示

**高频生词（先读顺）**

- repository /rɪˈpɒzətri/ 仓库；版本库

- version control system 版本控制系统

- commit 提交（名词 / 动词同形）

- distributed /dɪˈstrɪbjətɪd/ 分布式的

- staging area 暂存区

- branch /merge/clone 分支 / 合并 / 克隆

- résumé /ˈrezjumeɪ/ 简历

- plagiarism /ˈpleɪdʒərɪzəm/ 抄袭

**翻页节奏速查（共 21 页，约 10 分钟）**

|   |   |   |
|---|---|---|
|页码|讲到哪句翻页|累计时长|
|P1|上台停封面，说 "Good afternoon, everyone." 后翻页|0:00|
|P2|讲完整段钩子引言（"I would like to begin…far from complete."）|1:00|
|P3|讲完路线图 "next ten minutes…"||
|P4|"Let's begin with the simplest definition."|2:30|
|P5|讲完 "cloud platform" 定义 + "three things at once"||
|P6|"First, it is a warehouse…"||
|P7|"Second, it is a social network…"||
|P8|"Third, it is a collaboration platform…"||
|P9|讲完类比 + 四块数据||
|P10|"So how should we…five concrete ways"|5:30|
|P11|"Number one: use it as a library."||
|P12|"Number two: use it as your notebook."||
|P13|"Number three: use it as your portfolio."||
|P14|"Number four: use it to collaborate."||
|P15|"Number five: use the student benefits."||
|P16|"Before I move on, one warning."（放慢，强调）||
|P17|"Now let's go one level deeper…"|8:00|
|P18|"Let me give you four ideas…"||
|P19|"So now the crucial distinction…"||
|P20|"Finally, let me put the essential commands…" 讲完命令 + Closing 总结|9:30|
|P21|"That is all for my presentation…" 停在 Thank You 页等提问|10:00|