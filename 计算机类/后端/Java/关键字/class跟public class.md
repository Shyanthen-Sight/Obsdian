# 1.类的访问权限

1.为了==控制某个类的访问权限== ，修饰词必须出现在关键字class之前。例如：
```
public class Animal {}
```

2.在编写类的时候可以使用==两种方式定义类==：

（1）public class定义类：
```
public class Animal{
	...
}
```

（2）class定义类：
```
class Animal{
   ...
}
```

# 2.public class定义类

1.如果一个类声明的时候使用public class进行声明，则==类名称必须与文件名完全一致==

2.==被public修饰的类可以被其他包访问==。如果现在的库名==是com==，那么就可容易通过下面的声明访问Animal

```
import com.Animal;
或者
import com.*;
```

# 3.class定义类

1. 如果一个类声明的时候使用了class进行了声明，则作为==启动类的名称可以与文件名称不一致==，但是执行的时候肯定执行的是生成后的名称。

2. 没有public修饰的类，==该类就拥有了包访问权限==，==即该类只可以用于该包之中==。

```
例如：定义一个类（文件名为：Animal.java）
class AnimalDemo{//声明一个类，
	public static void main(String[] args){//主方法
		System.out.prinln("Helloworld!!!");//系统输出，在屏幕上打印。
	}
}
```

文件名称为Animal.java，文件名称与类名称不一致，但是因为使用了class声明，此时编译不会产生任何错误

但是生成之后的class文件名称是和class声明名称完全一致的AnimalDemo.class,执行的时候不能执行Animal.java,==而是应该执行AnimalDemo.java==

在一个 *.java的文件中，只能有一个public class的声明，但是允许多个class的声明

```
public class AnimalDemo{
	public static void main(String[] args){
		System.out.println("HelloWorld!!");
	}
}
class Dog{}
class Pig{}

```

在上面的文件中，定义了三个类，那么此时程序编译之后会形成==三个*.class文件==。

# 4. class定义的类只具有包访问权限，该类不能被其他包访问

```
// 文件：com/example/a/Animal.java

package com.example.a;

class Animal {   // 注意：class 前面没有 public
    void eat() { }
}
```

```
// 文件：com/example/b/Main.java

package com.example.b;

import com.example.a.Animal;  // ❌ 编译错误！

public class Main {
    public static void main(String[] args) {
        Animal a = new Animal();  // 无法访问
    }
}
```

`Animal` 没有写 `public`，==所以**只有 `com.example.a` 这个包内部的类**能使用它==。包外的代码（包括 `import` 进来）都无法引用这个类，编译器会直接报错