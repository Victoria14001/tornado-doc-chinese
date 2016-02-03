介绍
------------

`Tornado <http://www.tornadoweb.org>`_ 是一个基于Python的Web服务框架和
异步网络库, 最早开发与 `FriendFeed
<http://friendfeed.com>`_ 公司.  通过利用非阻塞网络 I/O, Tornado
可以承载成千上万的活动连接, 完美的实现了
`长连接 <http://en.wikipedia.org/wiki/Push_technology#Long_polling>`_,
`WebSockets <http://en.wikipedia.org/wiki/WebSocket>`_,
和其他对于每一位用户来说需要长连接的程序.

Tornado 可以被分为以下四个主要部分:

* Web 框架 (包括用来创建 Web 应用程序的 `.RequestHandler` 类, 还有很多其它支持的类).
* HTTP 客户端和服务器的实现 (`.HTTPServer` 和  `.AsyncHTTPClient`).
* 异步网络库 (`.IOLoop` 和 `.IOStream`), 对 HTTP 的实现提供构建模块, 还可以用来实现其他协议.
* 协程库 (`tornado.gen`) 让用户通过更直接的方法来实现异步编程, 而不是通过回调的方式.


Tornado web 框架和 HTTP 服务器提供了一整套
`WSGI <http://www.python.org/dev/peps/pep-3333/>`_ 的方案.
可以让Tornado编写的Web框架运行在一个WSGI容器中 (`.WSGIAdapter`), 
或者使用 Tornado HTTP 服务器作为一个WSGI容器 (`.WSGIContainer`), 
这两种解决方案都有各自的局限性, 为了充分享受Tornado为您带来的特性,你需要同时使用
Tornado的web框架和HTTP服务器.
