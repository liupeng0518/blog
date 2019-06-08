---
title: 五个步骤轻松弄懂 JSON Web Token（JWT）
date: 2017-05-25T15:45:00+08:00
categories: 
  - Web
tags: 
  - JWT
---

> 原文地址：https://medium.com/vandium-software/5-easy-steps-to-understanding-json-web-tokens-jwt-1164c0adfcec

本文将帮你理解 JSON Web Token（JWT） 的基本原理以及为什么要使用它。JWT 是确保应用的安全性和可靠性的重要一环。JWT 允许以一种安全的方式传达信息，比如用户数据。

为了理解 JWT 是如何工作的，我们先了解它的定义。

> JSON Web Token 是由 [RFC7519](https://tools.ietf.org/html/rfc7519) 定义的，是一个在双方之间安全的传达一组信息的 JSON 对象。由 header、payload 和 signature 三部分组成。

简单来说，JWT 只是一个如下格式的字符串：

```
header.payload.signature
```
<!--more-->

*要注意的是双引号字符串也是一个合法的 JSON 对象。*

我们用下面这个简单的示例图展示如何使用 JWT 。在这个例子里面的 3 个实体分别是用户、应用服务器和认证服务器。认证服务器向用户提供 JWT。使用 JWT，用户可以安全的与应用进行通讯。

![](images/how-use-jwt.webp)
*应用使用 JWT 校验用户的真实性的过程。*

在这个示例中，用户首先使用认证服务器的登录系统（用户和密码，或者第三方认证）登录认证服务器。随后认证服务器创建 JWT 然后发送给用户。当用户发起请求调用应用服务器的 API 时会附带上 JWT。在这一步，应用服务器会被配置为校验传入的 JWT 是否由认证服务器创建（校验的过程在后面会详细说明）。因此，当用户使用附带 JWT 的请求调用 API 的时候，应用服务器可以使用 JWT 来验证 API 请求是否来自一个可信任的用户。

接下来深入了解一下 JWT 是如何构建和校验的。

## Step 1. 创建 header

JWT 的 header 包含如何计算 JWT 签名的信息。header 是一个以下格式的 JSON 对象：

```json
{
    "typ": "JWT",
    "alg": "HS256"
}
```

在这个 JSON 对象中，"typ" 键对应的值表示对象是一个 JWT，"alg" 键对应的值表示使用了哪种 Hash 算法来创建的 JWT 签名。在我们的例子里是使用的 HMAC-SHA256 （带密钥 Hash）算法计算签名（在 Step 3 中有更详细的说明）。

## Step 2. 创建 payload

JWT 的 payload 即是 JWT 用于保存数据的部分（这部分数据也称为 JWT 的“声明”）。在我们的示例中，认证服务器创建了一个存储了用户信息的 JWT，特别是用户 ID。

```json
{
    "userId": "b08f86af-35da-48f2-8fab-cef3904660bd"
}
```

在我们的示例里，只是在 payload 中保存了一个声明。你也可以按你的喜好放入更多的声明。JWT 的 payload 中有几个不同的标准声明，像 `iss` —— 发行者、`sub`——主题、`exp`——过期时间这些。这些可选字段在创建 JWT 时可能会很有用。在[维基百科页面](https://en.wikipedia.org/wiki/JSON_Web_Token#Standard_field)上你可以查阅到更多的 JWT 标准字段。

需要注意，数据的大小会影响 JWT 的总体大小，通常情况下不需要关心这个问题。但是过大的 JWT 大小可能会对性能和传输延迟造成负面影响。

## Step 3. 创建 SIGNATURE

signature 是用下面的伪代码计算出来的：

```js
// signature algorithm
data = base64urlEncode( header ) + "." + base64urlEncode( payload );
signature = Hash( data, secret );
```

这个算法首先使用 base64url 编码在 Step 1 和 2 中创建的 header 和 payload。然后使用 `.` 将已经编码的字符串拼接。在我们的伪代码里拼接后字符串被赋值给 `data`。使用 JWT header 中指定的 Hash 算法，加上密钥对 `data` 字符串进行 Hash 得到 JWT 的 signature。

在我们的例子，header 和 payload 都被 base64url 编码为：
```js
// header
eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9
// payload
eyJ1c2VySWQiOiJiMDhmODZhZi0zNWRhLTQ4ZjItOGZhYi1jZWYzOTA0NjYwYmQifQ
```

然后拼接编码后的 header 和 payload，使用 `secret` 字符串作为密钥，对 `data` 字符串使用指定的签名算法（HS256）获得最终的 JWT signature：

```js
// signature
-xN_h82PHVTCMA9vdoHrcZxH-x5mb11y1537t3rGzcM
```

## Step 4. 将 JWT 的三个部分组合起来

现在我们有了创建 JWT 的所需要的三个部分。请不要忘记 JWT 的 *header.payload.signature* 结构，只要简单的使用 `.` 分隔、拼接所有的部分。使用已经 base64url 编码后的 header 和 payload ，以及在 Step 3 中得到 signature。

```js
// JWT Token
eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VySWQiOiJiMDhmODZhZi0zNWRhLTQ4ZjItOGZhYi1jZWYzOTA0NjYwYmQifQ.-xN_h82PHVTCMA9vdoHrcZxH-x5mb11y1537t3rGzcM
```

你可以用浏览器访问[jwt.io](http://jwt.io/)，尝试创建你自己的 JWT。

回到我们的例子，认证服务器现在可以把这个 JWT 发送给用户了。

**JWT 如何保护数据？**

重要的是要明白，使用 JWT 的目的不是为了以任何方式隐藏或者混淆数据。使用 JWT 是为了保证发送的数据是由可信的来源创建的。

如前面步骤所示，在 JWT 中的数据只是被**编码**和**签名**，并没有被**加密**。

编码数据的目的是为了转换数据的结构。对数据签名来保证接收者可以校验数据的来源。当然，编码和签名**不能保护数据**。JWT 的目的是为了验证数据的来源可靠性，并不是为了保护数据和防止未经授权的访问。有关编码和加密的区别，还有 Hash 如何工作的详细信息，可以参与[这篇文章](https://danielmiessler.com/study/encoding-encryption-hashing-obfuscation/#encoding))。

>JWT 仅仅是对数据签名和编码，并没有加密。因此， JWT 并不能保证数据的安全性。

## Step 5. 校验 JWT

在我们的 3 实体示例中，使用的 JWT 是由 HS256 算法签名，并且密钥只有应用服务器和认证服务器知晓。当应用开始认证过程时，应用服务器从认证服务器接收密钥。由于应用服务器得到了密钥，当用户使用附带 JWT 的请求调用 API 时，应用可以执行 Step 3 中相同的签名算法。然后，应用可以严重自身创建的签名是否与 JWT 中附带的签名一致（签名是否与认证服务器创建的 JWT 签名一致）。如果签名一致，则表示 JWT 是有效的，表明 API 请求来源可信。如果签名不一致，表示 JWT 无效，那么请求可能是对应用服务器的潜在攻击。通过校验 JWT，可以在应用和用户之间建立信任。

## 结论

我们学习了如何创建和验证 JWT，以及如何使用 JWT 来确保用户与应用间的可信任性。对于了解 JWT 基本原理和如何使用 JWT 这是一个良好的开端。JWT 仅仅是解决应用安全性与可信任性难题一部分方法。