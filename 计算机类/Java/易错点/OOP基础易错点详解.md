# Java OOP 基础易错点详解（带可运行示例）

> 关联笔记：[[构造方法]]、[[成员变量]]、[[方法]]、[[static关键字]]、[[嵌套类]]、[[java中的权限修饰符]]、[[创建对象]]、[[使用对象]]

## 一句话解释

**初学者在 OOP 阶段踩的坑，本质上只有两句话：一是「东西该属于类还是属于对象」（static 与非 static），二是「这段代码写在什么位置」（类里、方法里、静态上下文里）。** 下面按这个思路，把每个易错点都配上一段能跑（或一定会报错）的代码。

---

## 一、成员变量 vs 局部变量：默认值的有无

| 维度    | 成员变量                                            | 局部变量         |
| ----- | ----------------------------------------------- | ------------ |
| 声明位置  | 类体中、方法外                                         | 方法内、形参、代码块内  |
| 默认值   | ==有==（`0` / `0.0` / `false` / `null`）           | ==没有，必须先赋值== |
| 生命周期  | 随对象（或类）存在                                       | 方法结束即销毁      |
| 可用修饰符 | `public`、`protected`、`private`、`static`、`final` | 只能用 `final`  |

```java
public class Demo {
    int count;        // 成员变量，不写初值也有默认值 0
    String name;      // 默认值 null

    void test() {
        int localInt;                          // 局部变量，没有默认值
        // System.out.println(localInt);       // 编译错误：variable localInt
        //                                     // might not have been initialized
        System.out.println(count);             // 合法，输出 0
        System.out.println(name);              // 合法，输出 null
        localInt = 1;                          // 先赋值
        System.out.println(localInt);          // 现在才合法，输出 1
    }
}
```

一句话记法：**成员变量是「住在房子里的家具」，搬进来时就有默认摆设；局部变量是「临时拿在手里的工具」，不自己拿着就是空的。**

---

## 二、构造方法：三个高频易错点

### 1. 构造方法的作用是「对象初始化」，不是「给成员变量赋值」

判断题「构造方法的作用是给成员变量赋值」是**错的**。给成员变量赋值只是初始化里==最常见==的一种操作，不是唯一作用，==构造方法里还可以做校验、打日志、申请资源==。

```java
public class Connection {
    private String url;

    public Connection(String url) {
        System.out.println("开始创建连接：" + url);          // 打日志，初始化动作之一
        if (url == null || url.isEmpty()) {                  // 数据校验，初始化动作之二
            throw new IllegalArgumentException("url 不能为空");
        }
        this.url = url;                                      // 给成员变量赋值，初始化动作之三
    }
}
```

三种动作都发生在同一个构造方法里，所以「构造方法 = 给成员变量赋值」的说法太窄了。

### 2. ==构造方法前面不能加 `class` 关键字==

错得最典型的一种写法，是把「定义类」的语法和「定义构造方法」的语法混在一起：

```java
public class Student {
    private String name;

    // public class Student(String name) {   // 编译错误：';' expected
    //     this.name = name;
    // }

    public Student(String name) {            // 正确写法
        this.name = name;
    }
}
```

原因很直白：==`class` 是用来「声明一个类」的关键字，只能出现在类的定义头上==；而构==造方法的名字本来就必须和类名一样==，前面再写一遍 `class`，编译器读到 `Student` 后面那个 `(` 时就在等分号了。

==**构造方法前面只能加访问修饰符：**==

```java
public class Student {
    private String name;

    public Student(String name) { this.name = name; }   // 公开，谁都能 new
    private Student() { }                               // 私有，只有本类能 new
}
```

### 3. 类名前面一加 `void`，它就不是构造方法了

```java
public class Dog {
    public Dog() { }         // 正确，构造方法
    // public void Dog() { } // 编译器把它当成普通方法
}
```

一旦写上返回值类型（哪怕是 `void`），编译器就把它算作一个「碰巧和类同名」的普通方法，`new Dog()` 永远调不到它。详见 [[构造方法]]。

---

## 三、内部类的三种形态：`new` 的写法各不相同

这是最容易连报好几个错的地方。三种内部类的 `new` 方式完全不同，先看对比表：

| 类型 | 定义位置 | 能否在 `main` 里直接 `new` | 正确写法 |
| --- | --- | --- | --- |
| 成员内部类 | 类内、方法外、无 `static` | 不能 | `new Outer().new Inner()` |
| 静态内部类 | 类内、方法外、有 `static` | 能 | `new Outer.Inner()` |
| 局部内部类 | 方法内部 | —（只能在定义它的方法里用） | `new Local()`，仅限该方法内 |

### 1. 成员内部类：依附外部类对象而死

```java
public class Outer {
    private int num = 10;

    class Inner {                              // 成员内部类：没有 static
        void show() {
            System.out.println(num);           // 能访问外部类的成员，连 private 都行
        }
    }

    public static void main(String[] args) {
        // Inner in = new Inner();
        // 编译错误：non-static variable this cannot be referenced
        //           from a static context
    }
}
```

**为什么报错**：成员内部类属于外部类的「某个对象」，==必须有外部类对象当宿主==，内部类对象才有内存。而 `main` 是静态方法，运行到这一行时可能一个 `Outer` 对象都还没创建，编译器不敢放行。

两种改法：

```java
// 改法一：先 new 外部类，再挂着它 new 内部类（语法：外部对象.new 内部类()）
public class Outer {
    class Inner { void show() { System.out.println("内部类"); } }

    public static void main(String[] args) {
        Outer outer = new Outer();
        Outer.Inner in = outer.new Inner();     // 注意中间这个 .new
        in.show();
    }
}
```

```java
// 改法二：直接给内部类加 static，升级成静态内部类
public class Outer {
    static class Inner { void show() { System.out.println("内部类"); } }

    public static void main(String[] args) {
        Inner in = new Inner();                 // 不再报错
        in.show();
    }
}
```

### 2. 静态内部类：初学者最省事的写法

==静态内部类属于「类本身」==，不依附任何对象，所以在静态 `main` 里可以直接 `new`：

```java
public class Outer {
    static class StaticInner {
        void show() { System.out.println("我是静态内部类"); }
    }

    public static void main(String[] args) {
        StaticInner a = new StaticInner();               // 外部类内部：直接 new
        Outer.StaticInner b = new Outer.StaticInner();   // 其他类里：类名.类名
        a.show();
        b.show();
    }
}
```

代价是：==静态内部类**只能直接访问外部类的静态成员**==，访问不到外部类的实例变量。取舍看需求。

### 3. 局部内部类：定义在方法里，规则最特殊

```java
public class Outer {
    public static void main(String[] args) {
        // public class Local { }        // 编译错误：modifier public not allowed here
        // private class Local { }       // 同样报错，private 也不允许
        // protected class Local { }     // 同样报错

        class Local {                    // 正确：什么都不写
            void show() { System.out.println("我是局部内部类"); }
        }

        Local l = new Local();           // 方法内可以正常定义、正常 new
        l.show();                        // 输出：我是局部内部类
    }

    // Local l2 = new Local();          // 编译错误：cannot find symbol
    //                                  // 出了 main 方法，Local 这个名字就不存在了
}
```

三条必须记住的规则：

1. **绝对不能加 `public` / `private` / `protected`**，只能不写，或写 `final` / `abstract`。
2. **`class` 关键字必须保留**，删掉就不是定义一个类了，直接语法报错。
3. **作用域只在当前方法内**，方法外看不见这个类，自然也不能用它声明变量。

> [!warning] 别把「不能加修饰符」误解成「不能写」
> 局部内部类是完全合法的语法，定义、`new`、调用方法都没问题，只是被禁止使用访问修饰符而已。

---

## 四、static 上下文：一条口诀解决所有报错

### 1. 底层区别

- **静态成员**==：属于类，类加载时就存在，不需要 `new`==。
- **非静态成员**：==属于对象，必须 `new` 之后才分配内存、才存在==。

### 2. 万能口诀

- 静态上下文（`main`、静态方法）：**只能直接访问静态成员**。
- 非静态上下文（实例方法）：**静态、非静态全都能访问**。

### 3. 完整示例

```java
public class StaticDemo {
    int instanceNum = 10;                        // 非静态：属于对象
    static int staticNum = 20;                   // 静态：属于类

    void instanceMethod() {                      // 非静态方法
        System.out.println(instanceNum);         // 合法
        System.out.println(staticNum);           // 合法
    }

    static void staticMethod() {                 // 静态方法
        System.out.println(staticNum);           // 合法
        // System.out.println(instanceNum);
        // 编译错误：non-static variable instanceNum cannot be referenced
        //           from a static context
    }

    public static void main(String[] args) {
        staticMethod();                          // 合法
        // instanceMethod();
        // 编译错误：non-static method instanceMethod() cannot be referenced
        //           from a static context

        new StaticDemo().instanceMethod();       // 正确：先 new 出对象，再调实例方法
    }
}
```

**为什么必须这样**：`main` 是程序入口，JVM 调用它的时候可能一个 `StaticDemo` 对象都没有。如果允许静态方法直接读写 `instanceNum`，那它读的是「哪个对象的 `instanceNum`」？说不清楚，所以编译器直接禁止。想访问，就先自己 `new` 一个出来。

---

## 五、getter / setter：什么时候才是必须的

很多初学者以为「每个类都要写 get/set」，其实它取决于成员变量有没有被 `private` 修饰。

### 1. 不写 `private`（默认权限）

```java
public class Student {
    String name;         // 默认权限，同包内可直接访问
}

Student s = new Student();
s.name = "小明";         // 完全合法，能跑
System.out.println(s.name);
```

这时候 get/set **不是必须的**，写不写都能运行。

### 2. 写了 `private`（封装的标准写法）

```java
public class Student {
    private int score;

    public int getScore() {                 // getter：读
        return score;
    }

    public void setScore(int score) {       // setter：写，顺便做校验
        if (score < 0 || score > 100) {
            throw new IllegalArgumentException("分数必须在 0~100 之间");
        }
        this.score = score;
    }
}
```

```java
Student s = new Student();
s.setScore(95);                  // 必须走 setter
System.out.println(s.getScore());   // 95
// s.score = 95;
// 编译错误：score has private access in Student
s.setScore(-10);                 // 运行时抛出异常：分数必须在 0~100 之间
```

**setter 的真正价值就在这里**：把「非法值」挡在类外面。如果字段是公开的，`s.score = -10` 谁都拦不住。

### 3. 小结

| 字段修饰符 | 外部能否 `对象.字段` 直接读写 | get/set 是否必须 |
| --- | --- | --- |
| 默认（不写） | 能 | 不是必须，但建议写 |
| `public` | 能 | 不是必须，但建议写 |
| `private` | 不能 | 必须写，否则外部无法访问 |

**get/set 是封装规范，不是语法强制；只有字段私有化之后，它才变成必需品。**

---

## 六、方法什么时候该加 `static`：只看一件事

**判断标准只有一句话：这个方法体里用没用到对象的成员变量（或者说 `this`）。**

### 1. 可以不依赖对象 → 加 `static`

```java
public class MathUtil {
    public static int max(int a, int b) {   // 只用参数算，不碰任何对象数据
        return a > b ? a : b;
    }
}

int m = MathUtil.max(3, 7);                 // 类名.方法()，不用 new 对象
```

工具类方法都长这样——只靠参数就能算出结果，跟「哪个对象」毫无关系。JDK 的 `Math.abs`、`Arrays.sort` 都是静态方法。

### 2. 必须依赖对象 → 不能加 `static`

```java
public class Student {
    private int score;

    public int getScore() {                 // 读的是「这个对象」的 score
        return score;
    }

    public boolean isPass() {               // 判断的是「这个对象」及不及格
        return score >= 60;
    }
}

Student s = new Student();
s.isPass();                                 // 必须通过对象调用，否则不知道算谁的
```

如果给 `isPass()` 硬加 `static`，方法体里的 `score` 立刻变成编译错误：`non-static variable score cannot be referenced from a static context`。

### 3. 对比表

| 场景 | 是否加 `static` | 调用方式 | 例子 |
| --- | --- | --- | --- |
| 工具类方法（只用参数） | 加 | `类名.方法()` | `Math.max(1, 2)` |
| 程序入口 `main` | 强制加 | JVM 调用 | `public static void main(String[] args)` |
| 访问 / 修改对象成员变量 | 绝对不能加 | `对象.方法()` | `student.isPass()` |
| 普通业务方法（求和、判断、打印自己的信息） | 绝对不能加 | `对象.方法()` | `dog.bark()` |

---

## 七、类的两种合法放置位置：为什么都不报错

### 1. 放在方法外（顶级类）

```java
public class Main {          // 一个 .java 文件里最多 1 个 public 顶级类
}

class Helper {               // 普通顶级类可以有多个
}
```

- 作用域：整个 `.java` 文件都有效。
- 规则：`public` 顶级类最多一个，且文件名必须与它同名。

### 2. 放在方法内（局部内部类）

```java
public class Main {
    public static void main(String[] args) {
        class Temp {                        // 局部内部类
            int value = 1;
        }
        Temp t = new Temp();
        System.out.println(t.value);        // 输出 1
    }
}
```

- 作用域：仅当前方法内有效。
- 规则：不能带访问修饰符、必须带 `class`。

### 3. 对比

| 维度 | 顶级类（方法外） | 局部内部类（方法内） |
| --- | --- | --- |
| 作用域 | 整个文件 | 仅当前方法 |
| 访问修饰符 | `public` / 默认 | 禁止使用 |
| 能否被其他类用 | 能 | 不能 |
| 是否语法合法 | 是 | 是 |

**两者都是合法的 Java 语法，只是作用域和修饰符规则不同，所以都不会报错**——报错往往不是「位置不对」，而是「位置和修饰符搭配错了」。

---

## 八、常见编译错误速查表

| 写错的代码 | 编译器报错关键字 | 根本原因 | 正确改法 |
| --- | --- | --- | --- |
| 类体里写 `public class Student() {}` | `';' expected` | 构造方法不能带 `class` | 去掉 `class` |
| `main` 里直接 `new Inner()`（成员内部类） | `non-static variable this cannot be referenced from a static context` | 成员内部类依附外部类对象 | `new Outer().new Inner()` 或给内部类加 `static` |
| 静态方法里访问实例变量 | `non-static variable xxx cannot be referenced from a static context` | 静态上下文里对象可能还不存在 | 先 `new` 对象，或把成员改成 `static` |
| 静态方法里调用实例方法 | `non-static method xxx() cannot be referenced from a static context` | 同上 | `new 类名().方法()` |
| 方法里写 `public class Local {}` | `modifier public not allowed here` | 局部内部类禁止访问修饰符 | 去掉 `public` |
| 方法外使用局部内部类 | `cannot find symbol` | 作用域只在方法内 | 挪到方法内使用 |
| 局部变量没赋值就使用 | `might not have been initialized` | 局部变量没有默认值 | 先手动赋值 |
| 外部直接读 `private` 字段 | `has private access in xxx` | 权限不够 | 通过 getter / setter |

---

## 九、自测判断题

1. 构造方法的作用是给成员变量赋值。（错 —— 是对象初始化，赋值只是其中一种操作）
2. 构造方法可以写成 `public class Dog() {}`。（错 —— 不能带 `class`）
3. 静态内部类可以直接在静态 `main` 方法里 `new`。（对）
4. 局部内部类可以加 `public` 修饰符。（错 —— 修饰符一律不允许）
5. 静态方法里可以直接访问实例变量。（错 —— 必须先 `new` 出对象）
6. 成员变量不赋初值也能使用，会拿到默认值。（对 —— `0` / `0.0` / `false` / `null`）
7. 成员变量不写 `private` 时，不写 getter/setter 程序也能跑。（对 —— 但不是好习惯）
8. 非静态方法可以访问静态成员。（对 —— 实例方法什么都能碰）
9. 写在方法内部的类会报错。（错 —— 语法合法，只是不能加访问修饰符）
10. 一个 `.java` 文件里可以有多个类。（对 —— 但最多一个 `public` 顶级类）

---

## 十、一句话总结

**静态与非静态的分界线是「要不要先 `new` 对象」，位置与修饰符的分界线是「这段代码写在哪里」——把这两条线对齐，OOP 阶段九成的编译错误都能自己读懂。**

---

## 关联笔记

- [[构造方法]] —— 构造方法的完整语法、重载、`this(...)`、默认构造方法
- [[成员变量]] —— 实例变量与静态变量的划分
- [[方法]] —— 普通方法的定义与调用
- [[static关键字]] —— 静态成员与静态上下文的完整规则
- [[嵌套类]] —— 内部类 / 嵌套类的系统讲解
- [[java中的权限修饰符]] —— 决定 `对象.成员` 能否访问
- [[创建对象]] —— `new` 的过程与对象数组
- [[使用对象]] —— 对象创建之后怎么用
