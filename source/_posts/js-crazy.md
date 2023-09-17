---
title: Frontend | JavaScript drives me CRAZY
date: 2023-09-15 15:59:42
tags:
- Frontend
- JavaScript
- Suffer
---

## Scene 1

After finishing a pbkdf2-based password hashing module and deploying, the website instantly *exploded*.

Upon loading, I got:

```
TypeError: can't access property "from", n is undefined
```

I asked ChatGPT and StackOverflow, but I have *no* idea what the meow is going on! So I stopped programming for a while.

After several minutes, it came to me that I'd better run it locally, so that variable names are not obsfucated. I got:

```
TypeError: can't access property "from", Buffer is undefined
```

I checked the code, and noticed that the `Buffer` comes from `buffer.Buffer`. I asked ChatGPT and StackOverflow again, still not getting any clues. So I gave up again.

### Fix

After several hours, I decided to try again. Just when I'm about to give up, I tried installing `buffer` library, and everything worked!

It seemed that `pbkdf2` library *can't* resolve it's dependencies well, this is why JS is bad.

## Scene 2

A JavaScript function terminated the whole call stack *without throwing an error*. This is what happened to my blood pressure.

I changed my code to:

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

and I got 3 zeros being logged. The `pbkdf2` meowed up again!

I changed the code to the following, to see if it's because type of `salt` changed to `TypedArray`:

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

The function stuck at the second `pbkdf2Sync`! Note that `salt` is indeed a `Uint8Array(32)`, and this actually works in account frontend!

Let's do a comparison:

### Code in account-frontend

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

### Code in cloud-ide

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

And nothing following!

I made a better comparison:

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

The first call of `pbkdf2Sync` failed!

### Fix

Reinstalling `pbkdf2` package solves the problem.
