---
title: 前端 | JavaScript 让我为之癫狂
date: 2023-09-15 15:59:42
tags:
- 前端
- JavaScript
- 痛苦
---

## Scene 1

用 pbkdf2 写好密码哈希模块部署之后，网站整个打不开了。网站加载时就直接报错：

```
TypeError: can't access property "from", n is undefined
```

我尝试从 ChatGPT 和 StackOverflow 寻找答案，但我一点思路都没有！所以我摆烂了一会。

在几分钟后，我突然想到我或许应该在本地跑一下，来避免变量名被混淆。报错信息变成了：

```
TypeError: can't access property "from", Buffer is undefined
```

我发现这个 `Buffer` 在代码中是 `buffer.Buffer`，其中 `buffer` 是 `import` 出来的。我又尝试在 ChatGPT 和 StackOverflow 寻找答案，还是没思路，所以又放弃了。

### Fix

摆烂几小时之后，我决定再试一次。在绝望边缘，我发现安装一下 `buffer` 库，一切就都好了！

只能说这是因为 `pbkdf2` 库没有处理好自己的依赖关系，这就是为什么 JavaScript 傻呗！

## Scene 2

一个 JavaScript 函数成为了黑洞，这是我的血压发生的变化。

调试时，我把代码改成：

```javascript
export function hash(password, saltString) {
  console.log(0)
  const pbkdf2 = require("pbkdf2")
  console.log(0)
  const salt = fromHexString(saltString)
  console.log(0)
  const derivedKey = pbkdf2.pbkdf2Sync(password, salt, 10000, 32, 'sha512');
  console.log(0)
  const key = derivedKey.toString('hex')
  console.log(0)
  return key
}
```

然后只输出了 3 个 0。又是 `pbkdf2` 干的好事！

由于之前以字符串作为 `salt` 是有用的，我想测试下是不是因为 `salt` 的类型是 `TypedArray` 才导致寄掉：

```javascript
export function hash(password, saltString) {
  console.log(0)
  const pbkdf2 = require("pbkdf2")
  console.log(0)
  const salt = fromHexString(saltString)
  console.log(salt)
  const tester = pbkdf2.pbkdf2Sync(password, "123abc", 10000, 32, 'sha512');
  console.log(tester)
  const derivedKey = pbkdf2.pbkdf2Sync(password, salt, 10000, 32, 'sha512');
  console.log(0)
  const key = derivedKey.toString('hex')
  console.log(0)
  return key
}
```

果然在第二次 `pbkdf2Sync` 的调用处寄掉了！这里我确认了 `salt` 是一个长度为 32 的 `Uint8Array`，但同样的代码在另一个前端是正常工作的！

对比：

### 账户前端的代码

```javascript
export function hash(password, salt) {
  const pbkdf2 = require("pbkdf2")
  console.log(`hashing password with salt ${salt}`)
  const derivedKey = pbkdf2.pbkdf2Sync(password, salt, 10000, 32, 'sha512');
  const key = derivedKey.toString('hex')
  console.log(key);
  return key
}
```

```
hashing password with salt 237,154,219,59,23,19,10,206,7,62,20,221,187,178,16,34,27,129,234,68,237,195,38,224,75,61,124,108,96,44,222,129
ed3ce14e8cfed46e7d654e02dd8415de553f4e5fadbf67ac75f770917b2d2d86
```

### 首页前端的代码

```javascript
export function hash(password, saltStr) {
  const pbkdf2 = require("pbkdf2")
  const salt = fromHexString(saltStr)
  console.log(`hashing password with salt ${salt}`)
  const derivedKey = pbkdf2.pbkdf2Sync(password, salt, 10000, 32, 'sha512');
  const key = derivedKey.toString('hex')
  console.log(0)
  return key
}
```

```
hashing password with salt 237,154,219,59,23,19,10,206,7,62,20,221,187,178,16,34,27,129,234,68,237,195,38,224,75,61,124,108,96,44,222,129
```

然后就什么都没了！

我进行了一个更清晰的对比：

```javascript
export function hash(password, saltStr) {
  const pbkdf2 = require("pbkdf2")
  const fakeSalt = new Uint8Array([1, 2, 3])
  console.log(`[test] hashing password with salt ${fakeSalt}`)
  const fakeKey = pbkdf2.pbkdf2Sync(password, fakeSalt, 10000, 32, 'sha512');
  console.log(fakeKey)
  const salt = fromHexString(saltStr)
  console.log(`hashing password with salt ${salt}`)
  const derivedKey = pbkdf2.pbkdf2Sync(password, salt, 10000, 32, 'sha512');
  const key = derivedKey.toString('hex')
  console.log(0)
  return key
}
```

第一次调用 `pbkdf2Sync`，程序就寄掉了！

### Fix

重装 `pbkdf2` 包就好了。真的是重装而不是之前没装，我只能说灵车！
