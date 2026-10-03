# Java abstract 关键字

> 来源：[抽象类abstract_abstract抽象类-CSDN博客](https://blog.csdn.net/2201_76081438/article/details/141566088)

## 1. 抽象类是什么

==`abstract` 修饰的类叫做抽象类==，==`abstract` 修饰的方法叫做抽象方法==。

抽象方法只对方法进行定义（声明），并不实现，具体的实现交给子类去完成。

```java
public abstract class Animal {
    public abstract void run();   // 没有方法体，只有分号
}
```

## 2. 为什么要有抽象类

### 2.1 先看继承

==继承的本质就是代码的复用==。

如果父类的方法在子类中不适用，就需要用到重写。但由此引出一个问题：==如果所有的方法子类都需要重写，那么定义父类还有必要吗？==

当然有——这要从多态说起。

### 2.2 再看多态
![[Pasted image 20260921132003.png]]
==多态就是父类的引用指向子类的对象==。

```java
Animal a = new Dog();
Animal b = new Cat();
Animal c = new Pig();
```

使用多态能更好地表达 Java 代码，但==如果不继承，就无法使用多态==，所以==有必要定义父类==。

### 2.3 抽象类的方案

抽象类中可以定义抽象方法：==只定义方法、不实现方法==，既==减少了代码的冗余==，又==保留了多态的能力==。

**父类 Animal：**

```java
public abstract class Animal {
    public abstract void run();
}
```

**三个子类 Pig、Dog、Cat：**

```java
public class Pig extends Animal {
    public void run() {
        System.out.println("猪跑得很快");
    }
}

public class Dog extends Animal {
    public void run() {
        System.out.println("狗跑得很快");
    }
}

public class Cat extends Animal {
    public void run() {
        System.out.println("猫跑得很快");
    }
}
```

## 3. 抽象类的十大特点

### 3.1 ==abstract 修饰的类叫抽象类，abstract 修饰的方法叫抽象方法==

### 3.2 抽象方法必须在子类中重写并实现，不需要在抽象类中实现

==前提是子类不是抽象类==；如果子类也是抽象类，可以不实现，继续往下传递。

### 3.3 ==抽象类一定是父类==

### 3.4 只有抽象类中才能有抽象方法，普通类中不能有抽象方法

### 3.5 ==抽象类中不一定非要写抽象方法，也可以写普通方法==

```java
public abstract class Animal {
    public abstract void run();

    public void flay() {
        System.out.println("所有动物都能飞");
    }
}
```

### 3.6 抽象类不能被实例化，只能使用多态

也就是说它==不能被创建对象==，只能通过 `父类引用 = new 子类对象()` 的方式使用。

### 3.7 final 关键字和 abstract 不能同时使用

- ==`final` 修饰的类不能被继承==，==`final` 修饰的方法不能被重写==；
- 而 ==`abstract` 修饰的类只能被继承==，==`abstract` 修饰的方法子类必须要重写==。

两者语义完全相反，故互斥。

### 3.8 abstract 修饰的方法不能被 static 修饰

因为 ==`static` 修饰的方法叫做类方法，属于类==；而 ==`abstract` 修饰的方法属于对象==。

### 3.9 抽象方法不能使用 private 访问修饰符修饰

因为 ==`private` 修饰的方法只能在本类中使用，子类访问不到==；而 ==`abstract` 修饰的方法子类必须要重写==。

### 3.10 抽象类是有构造器的，但它的构造器不能创建对象

抽象类的构造器==目的是为了完成一些必要的初始化操作==，比如给 `name` 赋值。

**父类 Animal：**

```java
public abstract class Animal {
    private String name;

    public Animal(String name) {
        this.name = name;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }
}
```

**子类 Dog：**

```java
public class Dog extends Animal {
    public Dog(String name) {
        super(name);          // 调用父类构造器完成初始化
    }
}
```

**测试类：**

```java
public class Test {
    public static void main(String[] args) {
        Animal a = new Dog("小狗");
        System.out.println(a.getName());   // 输出：小狗
    }
}
```

## 4. 要点速查

| 组合 | 是否允许 | 原因 |
| --- | --- | --- |
| `abstract` + `final` | ❌ | 一个要求必须被继承/重写，一个禁止被继承/重写 |
| `abstract` + `static` | ❌ | 抽象方法属于对象，静态方法属于类 |
| `abstract` + `private` | ❌ | private 子类访问不到，无法重写 |
| `abstract` 类 + 普通方法 | ✅ | 抽象类中允许存在已实现的方法 |

## 5. 普通继承与抽象类继承的区别

### 5.1 普通继承：父类是一个"能直接用"的类

普通父类的==所有方法都有方法体==，子类==可以不重写任何一个方法==，直接把父类的实现拿过来用。

```java
// 普通父类：方法是完整的
public class Animal {
    public void run() {
        System.out.println("动物在跑");
    }
}

// 子类什么都不写，也能正常工作
public class Dog extends Animal {
}

public class Test {
    public static void main(String[] args) {
        Animal a = new Animal();   // ✅ 可以实例化
        a.run();                   // 动物在跑

        Dog d = new Dog();         // ✅ 直接复用父类实现
        d.run();                   // 动物在跑
    }
}
```

普通继承的重点是=="复用"==：父类提供一套现成的实现，子类觉得合适就照单全收，觉得不合适再重写。==重写是"可选"的==。

### 5.2 抽象类继承：父类是一个"必须被打磨"的半成品

抽象类==不能被实例化==，并且它的抽象方法==子类必须重写==，==重写是"强制"的==。

```java
public abstract class Animal {
    public abstract void run();   // 只有规范，没有实现
}

public class Dog extends Animal {
    @Override
    public void run() {           // 不写这段就编译报错
        System.out.println("狗跑得很快");
    }
}

public class Test {
    public static void main(String[] args) {
        // Animal a = new Animal();  // ❌ 编译错误，抽象类不能创建对象
        Animal a = new Dog();        // ✅ 只能通过多态获得实例
        a.run();                     // 狗跑得很快
    }
}
```

抽象类继承的重点是=="约束"==：父类只把=="必须有什么行为"==定下来，=="具体怎么做"==完全交给子类。==编译器会替你检查子类有没有实现==，这在多人协作时比口头约定可靠得多。

### 5.3 对比表

| 对比维度 | 普通继承（普通类作父类） | 抽象类继承 |
| --- | --- | --- |
| 父类能否实例化 | ✅ `new Animal()` | ❌ 只能 `Animal a = new Dog()` |
| 方法是否有方法体 | ==所有方法都必须有== | 抽象方法没有，普通方法有 |
| 子类是否必须重写 | 任意，可选择重写 | ==抽象方法必须重写==（非抽象子类） |
| 多态是否必须 | 可选，不用多态也能直接创建父类对象 | ==必须==，否则拿不到实例 |
| 编译期约束力 | 弱，漏写方法不报错 | ==强，漏写抽象方法直接编译报错== |
| 设计意图 | 复用已有代码 | 定义行为规范，强制子类实现 |
| 语义 | "是一个" + "拿来就用" | "是一个" + "必须自己实现" |

### 5.4 需要注意的两点

1. ==抽象类继承是普通继承的超集==。抽象类里同样可以写普通方法，子类照样能直接复用；它比普通类只多了一条"可以存在没有方法体的方法"。
2. ==抽象类并没有取代普通继承，只是把"建议重写"升级成了"必须重写"==。当一组子类中只有部分方法需要各自实现、其余方法可以共用时，抽象类是最合适的选择。

### 5.5 如何选择

- **子类行为与父类完全一致** → 用==普通继承==，直接复用即可，不必引入抽象。
- **子类共享字段与部分实现，但关键行为各不相同** → 用==抽象类==（典型如模板方法模式）。
- **只想规定"必须有哪些行为"，没有可共享的实现** → 用==接口==，比抽象类更轻、更灵活。

## 6. 相关笔记

- [[继承|继承]]
- [[面向抽象编程|面向抽象编程]]
- [[开闭原则|开闭原则]]
- [[java中的权限修饰符|Java 中的权限修饰符]]
- [[父类的构造方法与子类的关系|父类的构造方法与子类的关系]]
