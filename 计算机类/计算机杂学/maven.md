---
tags:
  - 工具
  - Java
---

# Maven

> 一句话：Maven 是 Java 项目的==**依赖管理 + 构建自动化工具**==——它让你"要什么库自动下载、编译打包一条命令搞定"。

## 是什么

- Apache Maven 是一个 **Java 项目的项目管理与构建自动化工具**（官方定位：software project management and comprehension tool）
- 名字来自意第绪语（Yiddish），意思是"**知识的积累者**"
- 出身：2002 年诞生于 Apache Jakarta Turbine 项目（为了简化项目构建流程），后来独立为 Apache 顶级项目，2004 年发布 1.0
- 它干活的方式：**读一个叫 `pom.xml` 的文件，然后自动把活干完**
  - POM = **P**roject **O**bject **M**odel（项目对象模型）
  - 你在 `pom.xml` 里声明："我的项目叫什么、需要哪些第三方库、要怎么打包"——剩下的都交给 Maven

### 核心思想：约定优于配置（Convention over Configuration）

Maven 规定好了一套**标准目录结构**，代码放哪、测试放哪、产物放哪都有约定，只要遵守约定，配置几乎不用写：

```
my-project
├── pom.xml                    ← 核心配置文件（Maven 的"身份证 + 需求清单"）
├── src
│   ├── main
│   │   ├── java               ← 主代码（.java 文件）
│   │   ├── resources          ← 主配置文件（.properties / .xml 等）
│   │   └── webapp             ← 网页文件（只有 war 项目才有）
│   └── test
│       ├── java               ← 测试代码（JUnit 等）
│       └── resources          ← 测试用的配置
└── target                     ← 编译 / 打包产物（自动生成，可随时删）
```

- 凡是 Maven 项目，目录都长这样 → 换项目零学习成本，IDEA / Eclipse 也能自动识别
- `target/` 是你"构建"的产物目录，`mvn clean` 就是删掉它

### pom.xml 里有什么（坐标：GAV）

Maven 用 **groupId + artifactId + version** 三样东西唯一确定一个 jar 包，叫做**坐标**（类似"省 + 市 + 街道"的门牌号）：

| 元素                | 含义                                        |
| ----------------- | ----------------------------------------- |
| `groupId`         | 组织 / 公司标识（一般倒写域名，如 `com.example`）         |
| `artifactId`      | 项目 / 模块名（如 `my-app`）                      |
| `version`         | 版本号；以 `-SNAPSHOT` 结尾表示"开发中的快照版"，会不断更新     |
| `packaging`       | 打包类型：`jar`（默认）/ `war`（Web 项目）/ `pom`（父工程） |
| `properties`      | 自定义变量（如统一 JDK 版本、统一依赖版本号）                 |
| `dependencies`    | 依赖列表（每个依赖 = 一个坐标）                         |
| `build / plugins` | 构建插件配置                                    |
| `parent`          | 继承父 POM（Spring Boot 项目开头就是它）              |
|                   |                                           |

### 它**不是**什么（新手最容易混的点）

- 不是编程语言 —— 它不写业务代码
- 不是 IDE —— IDEA / Eclipse 是 IDE，它们内部**调用** Maven
- 不是版本控制工具 —— 那是 Git 的活：**Git 管代码的历史版本，Maven 管依赖库的版本**
- 不是服务器 —— Tomcat 才负责跑 Web 项目，Maven 只负责把项目"打包好"，谁运行是另一回事

## 产生原因（为什么会有 Maven）

要理解 Maven 为什么出现，得先看它接手的"烂摊子"。

### 前传：手工时代 → Ant 时代

- **纯手工时代**：用 `javac` 一个个编译、`jar` 命令打包、classpath 手动拼——项目一变大就彻底失控
- **Ant 时代（2000 年）**：Ant 是第一个流行的 Java 构建工具（本身是 Tomcat 项目的副产品），把"编译、打包"的步骤写进 `build.xml`，一条命令自动执行，解决了"自动化"的问题——但它是"**手动挡**"：你得把每一步怎么做都写出来

### Ant 留下的四个坑（Maven 要解决的就是它们）

1. **没有标准**：每个项目从零写自己的 `build.xml`，同样一件事（如编译）十个项目十种写法
2. **没有依赖管理**：用到的 jar 要手动下载、放进 lib 目录——当时甚至**直接把 jar 包提交进 CVS 版本库**，仓库越滚越大，同一个库每个项目各存一份
3. **传递依赖噩梦（JAR Hell）**：A 依赖 B，B 又依赖 C、D……靠人肉一个个找齐几乎不可能，版本冲突、重复 jar 满地都是
4. **目录结构随意**：源码放哪都行，新人接手得先读完构建脚本才知道项目长什么样

### 起点：Jakarta Turbine 项目

- 2002 年前后，Apache 的 **Jakarta Turbine** 项目里，多个子项目各有一套自己的 Ant 脚本、各自把 jar 提交进 CVS，想统一构建、跨项目共享产物极其痛苦
- 最初由 Jason van Zyl 发起，目标就是给这些乱象一个统一的答案

官方文档里对初衷的表述，可以概括成四个目标：

1. **统一的构建方式**（a standard way to build the projects）
2. **清晰定义项目由什么组成**（a clear definition of what the project consisted of）
3. **方便发布项目信息**（an easy way to publish project information）
4. **跨项目共享 jar 包**（a way to share JARs across several projects）

### Maven 的解法：从"怎么做"到"要什么"

- 本质上是一次思路转变：Ant 是**命令式**（告诉工具每一步怎么做），Maven 是**声明式**（告诉工具项目是什么样、要什么，怎么做交给它）

| 当时的问题 | Maven 的解法 |
| --- | --- |
| 每个项目一套构建脚本、写法各异 | 统一的**生命周期**：`mvn package` 到哪个项目都一样 |
| 手动管 jar，甚至提交进版本库 | **坐标 + 仓库**：写在 `pom.xml` 里自动下载，不再进版本库 |
| 传递依赖靠人肉找齐（JAR Hell） | 自动解析传递依赖，冲突自动仲裁 |
| 项目结构五花八门 | **约定优于配置**的标准目录结构 |
| 项目信息散落各处 | `pom.xml` 集中声明，还能自动生成项目文档站点 |

### 后来呢

- 演进：Maven 1.0（2004）→ Maven 2（2005，重写）→ Maven 3（2010，现在主流）
- 它确立的"坐标 + 仓库 + 生命周期"模式成了 Java 生态的事实标准——连后来的 Gradle 也沿用（Gradle 直接复用 Maven 中央仓库和本地 `.m2` 仓库）

## 作用

Maven 的职能可以拆成两大块：**依赖管理**（找库）和**构建**（编译打包），外加多模块管理、插件机制等加分项。

### 1. 依赖管理（最常用、感知最强的功能）

**没有 Maven 的世界**：要用某个库 → 去官网手动下载 jar 包 → 复制到项目 lib 目录 → 在 IDE 里手动加进 classpath。如果这个库又依赖别的库（传递依赖），你还得把它的依赖一个个找齐……升级、卸载全是手工活。

**有 Maven 的世界**：在 `pom.xml` 里写几行坐标，完事：

```xml
<dependencies>
    <!-- 想用 MySQL 驱动？写坐标即可 -->
    <dependency>
        <groupId>com.mysql</groupId>
        <artifactId>mysql-connector-j</artifactId>
        <version>8.3.0</version>
    </dependency>
    <!-- scope 决定依赖在什么阶段生效：test 表示只在测试时用 -->
    <dependency>
        <groupId>junit</groupId>
        <artifactId>junit</artifactId>
        <version>4.13.2</version>
        <scope>test</scope>
    </dependency>
</dependencies>
```

Maven 自动完成的事：

- 去仓库把 jar 下载下来，存到**本地仓库**（`C:\Users\你的用户名\.m2\repository`）
- 自动把它**间接依赖的库**（传递依赖）也一起下载
- 卸载依赖：把这几行删掉即可，干净利落
- 版本冲突时自动按"**路径最短优先、先声明优先**"帮你选一个版本

**仓库体系**：

| 仓库 | 位置 | 说明 |
| --- | --- | --- |
| 本地仓库 | 自己电脑 `C:\Users\用户名\.m2\repository` | 本机所有项目**共用**，下载一次到处用 |
| 中央仓库 | `repo.maven.apache.org` | Apache 官方的"总仓库"，全球唯一 |
| 私服 | 公司内网（Nexus / Artifactory） | 代理中央仓库 + 存公司内部的 jar |
| 镜像 | 如阿里云 | 把"去中央仓库拿"改成"去阿里云拿"，国内提速用 |

- 小技巧：不知道某个库的坐标怎么写？去 **[mvnrepository.com](https://mvnrepository.com)** 搜库名，复制坐标粘贴进 `pom.xml` 即可
- 国内必做：在 `C:\Users\用户名\.m2\settings.xml` 里配置阿里云镜像，下载速度天壤之别
- 和 npm 的一个区别：npm 是每个项目一个 `node_modules`，Maven 是**整台电脑共用一个 `.m2` 仓库**

### 2. 项目构建（编译 → 测试 → 打包一条龙）

"构建"= 把源代码变成可运行 / 可交付的东西。Maven 把整个流程标准化成**生命周期（Lifecycle）**，内置三套：`clean`（清理）、`default`（构建，主力）、`site`（生成文档网站）。default 里的关键阶段：

| 阶段 | 干什么 |
| --- | --- |
| `compile` | 编译主代码 → `target/classes` |
| `test` | 运行测试代码 |
| `package` | 打包成 jar / war → `target/` |
| `install` | 把打好的包装进**本地仓库**（本机其他项目就能引用） |
| `deploy` | 上传到远程仓库 / 私服（团队共享） |

**最重要的规则：阶段是有顺序的，执行一个阶段会自动先执行它前面的所有阶段。**
所以 `mvn package` = 编译 + 测试 + 打包一步到位，不需要一条条敲。

常用命令速查：

| 命令 | 作用 |
| --- | --- |
| `mvn clean` | 清理 `target/`（构建出问题时先来一发） |
| `mvn clean package` | 清理 + 打包（最常用组合） |
| `mvn clean install` | 清理 + 打包 + 装进本地仓库（多模块项目常用） |
| `mvn test` | 只跑测试 |
| `mvn clean package -DskipTests` | 跳过测试直接打包（赶时间时用） |
| `mvn dependency:tree` | 打印依赖树（排查依赖冲突的利器） |

- 命令的通用格式：`mvn 生命周期阶段名` 或 `mvn 插件名:目标名`（如 `dependency:tree` 就是插件目标）

### 3. 多模块 / 父工程（继承与聚合）

- 大项目可以拆成多个子模块，用一个**父 pom** 统一管理版本和配置（子模块 `<parent>` 继承）
- 父工程一口气构建所有模块（聚合）
- 你以后看 Spring Boot 项目，`pom.xml` 开头 `<parent>spring-boot-starter-parent</parent>` 就是父 POM 的用法——版本统一由它管

### 4. 插件机制

- Maven 本身功能很少，**几乎所有功能都是插件干的**：编译、测试、打包、甚至生成网站
- `mvn` 命令本质是"**调用插件里的目标（goal）**"，理解这一点，各种 `xxx:yyy` 命令就不神秘了

## 跟什么类似

### ① 同定位的"包管理器 + 构建工具"（各语言都有）

| 语言 / 生态 | 类似工具 | 配置文件 | 仓库 |
| --- | --- | --- | --- |
| Java | **Maven** / Gradle | `pom.xml` / `build.gradle` | Maven 中央仓库 |
| JavaScript（Node.js） | npm / yarn / pnpm | `package.json` | npm registry |
| Python | pip / Poetry | `requirements.txt` / `pyproject.toml` | PyPI |
| Rust | Cargo | `Cargo.toml` | crates.io |
| Go | Go Modules | `go.mod` | Go Proxy |
| .NET | NuGet | `*.csproj` | nuget.org |

- 其中 **Rust 的 Cargo 是最像的**：管依赖 + 编译 + 测试 + 发布，定位和 Maven 几乎一模一样
- **npm 是最常被拿来对比的**（如果你写过 Vue / 前端，就很好理解）：`package.json` ↔ `pom.xml`，`npm install` ↔ Maven 自动解析依赖
- 区别：npm / pip 主要管**依赖**；Maven 是"依赖 + 构建"合体，更像 "npm + 一份固定的构建脚本"

### ② Java 圈内的三代工具：Ant → Maven → Gradle

| | Ant（2000） | **Maven（2004）** | Gradle（2008） |
| --- | --- | --- | --- |
| 配置方式 | XML 写"每一步怎么做"（命令式） | XML 声明"我是谁、我要谁"+ 约定 | Groovy / Kotlin 脚本，可编程 |
| 依赖管理 | 基本没有，手动管 jar | **内置，自动下载** | 内置，自动下载 |
| 特点 | 灵活但啰嗦 | 规范、统一、生态最大、资料最多 | 灵活、构建快，Android 官方默认 |
| 现状 | 老项目 | **Java 后端主流** | 新项目和 Android 越来越多 |

- 演进关系：Ant 是"手动挡"（每步自己写），Maven 是"自动挡 + 自动采购"，Gradle 是"可编程的自动挡"
- 选型建议：新手先学 Maven 就够了，学会 Maven 再碰 Gradle 会非常快

### ③ 生活化类比

- **装修队长**：
  - `pom.xml` = 你的装修需求清单；中央仓库 = 建材市场；本地仓库 `.m2` = 你家储藏室
  - 依赖管理 = 队长按清单去市场买材料，还自动把配套零件（传递依赖）一起配齐、存进储藏室
  - 构建 = 按标准工序施工：清场（clean）→ 砌墙（compile）→ 验收（test）→ 交付成品（package）
  - `target/` = 工地，里面打好的 jar 就是交付的房子
- **点外卖**：你只勾选想吃什么（写坐标），平台负责去商家取货、送上门、放进你的储物柜（`.m2`），下次直接取用
- 一句话：**Maven 之于 Java ≈ npm 之于 Node ≈ 装修队长之于毛坯房**

## 常见问题（新手）

- **下载依赖特别慢 / 失败**：国内网络直连中央仓库的问题 → 配阿里云镜像（改 `.m2/settings.xml`）
- **IDEA 里依赖飘红（波浪线）**：点右侧 **Maven 面板 → 刷新（Reload）** 按钮，重新下载即可
- **jar 包下载到哪了**：本地仓库 `C:\Users\你的用户名\.m2\repository`；治疑难杂症时可以整个删掉让它重新下
- **两个库依赖了同一个 jar 的不同版本**：`mvn dependency:tree` 看依赖树，Maven 会自动帮你仲裁选一个，不放心可用 `<exclusions>` 手动排除
- **要不要自己装 Maven**：不用。IDEA 内置 Maven 3，新建项目时勾选 Maven 即可；想用更高版本可在 Settings → Build Tools → Maven 里指定
