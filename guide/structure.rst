.. currentmodule:: tornado.web

.. testsetup::

   import tornado.web

Tornado web 应用程序结构
======================================

Tornado web 应用程序通常包含一个或多个
`.RequestHandler` 子类, 一个 `.Application` 对象来为每个控制器路由到达的请求,
和一个 ``main()`` 方法来启动服务器.

一个小型的 "hello world" 示例看起来是这样的:

.. testcode::

    import tornado.ioloop
    import tornado.web

    class MainHandler(tornado.web.RequestHandler):
        def get(self):
            self.write("Hello, world")

    def make_app():
        return tornado.web.Application([
            (r"/", MainHandler),
        ])

    if __name__ == "__main__":
        app = make_app()
        app.listen(8888)
        tornado.ioloop.IOLoop.current().start()

.. testoutput::
   :hide:

``Application`` 对象
~~~~~~~~~~~~~~~~~~~~~~~~~~

`.Application` 对象用来负责全局的设置, 包括用来转发请求到控制器的路由表.

路由表是一系列 `.URLSpec` 对象 (或元组), 其中的每一个包含 (至少) 一个正则表达式和一个控制器类.
是顺序相关的; 将会路由到第一个被匹配的规则. 如果正则表达式中有捕获组, 
这些组会被当作 *路径参数* 而且会被传递到 控制器的 HTTP 方法中.  
如果一个字典当作 `.URLSpec` 被传递到第三个参数中时, 它将作为 *初始参数* 传递给
`.RequestHandler.initialize`.  最后, `.URLSpec` 可能会有一个名字
这样允许和
`.RequestHandler.reverse_url` 一起使用.

例如, 根 URL ``/`` 被映射到
``MainHandler`` 而且 ``/story/`` 形式的后面跟着数字的 URLs 被映射到 ``StoryHandler``. 
这个数字 (作为一个字符串) 将会传递到 ``StoryHandler.get``.

::

    class MainHandler(RequestHandler):
        def get(self):
            self.write('<a href="%s">link to story 1</a>' %
                       self.reverse_url("story", "1"))

    class StoryHandler(RequestHandler):
        def initialize(self, db):
            self.db = db

        def get(self, story_id):
            self.write("this is story %s" % story_id)

    app = Application([
        url(r"/", MainHandler),
        url(r"/story/([0-9]+)", StoryHandler, dict(db=db), name="story")
        ])

`.Application` 的构造方法可以通过关键字设定来开启一些可选的功能
; 详见 `.Application.settings` .

``RequestHandler`` 子类
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

大多数 Tornado web 应用程序的工作都是在 `.RequestHandler` 子类中完成的.
对于一个控制器子类来说主入口点被 ``get()`` 和 ``post()`` 等等这样的 HTTP 方法来控制着.
每一个控制器可能会定义一个或多个 HTTP 方法. 如上所述, 这些方法将会被匹配到相应
的路由组中并进行参数调用.

在控制器中, 像调用 `.RequestHandler.render` 或者
`.RequestHandler.write` 将会产生一个相应.  ``render()`` 通过名字作为参数加载一个
`.Template` . ``write()`` 将产生一个不使用模版的纯输出; 它接收字符串, 字节序列和字典 (dicts 
将会转换成
JSON).

许多在 `.RequestHandler` 中的方法被设计成为能够在子类中覆盖的方法以在整个应用程序中使用. 
通常是定义一个 ``BaseHandler`` 类来覆盖像
`~.RequestHandler.write_error` 和 `~.RequestHandler.get_current_user`
然后继承时使用你的 ``BaseHandler`` 而不是 `.RequestHandler`.

处理输入请求
~~~~~~~~~~~~~~~~~~~~~~

处理输入请求时可以勇 ``self.request`` 来代表当前处理的请求.
详情请查看
`~tornado.httputil.HTTPServerRequest` 的定义.

通过 HTML 表单形式的数据可以利用 `~.RequestHandler.get_query_argument`
和 `~.RequestHandler.get_body_argument` 等方法来转换成你需要的格式.

.. testcode::

    class MyFormHandler(tornado.web.RequestHandler):
        def get(self):
            self.write('<html><body><form action="/myform" method="POST">'
                       '<input type="text" name="message">'
                       '<input type="submit" value="Submit">'
                       '</form></body></html>')

        def post(self):
            self.set_header("Content-Type", "text/plain")
            self.write("You wrote " + self.get_body_argument("message"))

.. testoutput::
   :hide:

由于 HTML 表单的编码不能区分参数是一个值还是一个列表,
`.RequestHandler` 可以明确的声明想要的是一个值还是一个列表. 对于列表来说, 使用
`~.RequestHandler.get_query_arguments` 和
`~.RequestHandler.get_body_arguments` 而不是它们的单数形式.

通过 ``self.request.files`` 可以实现文件上传,
它会映射名字 ( HTML 标签的名字 ``<input type="file">``
元素) 到每一个文件中. 每一个文件将会生成一个字典
``{"filename":..., "content_type":..., "body":...}``.  ``files``
对象只有再被某些属性报装后才是有效的
(例如. 一个 ``multipart/form-data`` 的 Content-Type); 如果没有使用这种方法
原始的文件上传数据将会在 ``self.request.body`` 中.
默认上传的文件是缓存在内存当中的; 如果你上传的文件很大, 不适合缓存在内存当中, 详见
`.stream_request_body` 类修饰符.

由于 HTML 的编码形式十分古怪 (例如. 不区分单一参数还是列表参数), Tornado 不会试图去统一这些参数.
特别的, 我们不会解析 JSON 请求的请求体. 应用程序希望使用 JSON 在编码上代替
`~.RequestHandler.prepare` 来解析它们的请求::

    def prepare(self):
        if self.request.headers["Content-Type"].startswith("application/json"):
            self.json_args = json.loads(self.request.body)
        else:
            self.json_args = None

覆盖 RequestHandler 的方法
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

除了 ``get()``/``post()``/ 等等这些意外, 其它在
`.RequestHandler` 中的方法也可以被覆盖. 每次请求时, 会发生以下过程:

1. 一个新的 `.RequestHandler` 将会为每一个请求创建
2. `~.RequestHandler.initialize()` 在 `.Application` 的初始化配置参数下被调用. ``initialize``
   通常只保存成员变量传递的参数; 它将不会产生任何输出或者调用像
   `~.RequestHandler.send_error` 一样的方法.
3. `~.RequestHandler.prepare()` 被调用. 这时基类在与子类共享中最有用的一个方法,
   不论是否使用了 HTTP 方法 ``prepare`` 都将会被调用. ``prepare`` 可能会产生输出;
   如果她调用了 `~.RequestHandler.finish` (或者
   ``redirect``, 等等), 处理会在这终止.
4. HTTP方法将会被调用: ``get()``, ``post()``, ``put()``,
   等等. 如果 URL 正则表达式中包含匹配组, 它们将被传递当这些方法的参数中.
5. 当这些请求结束以后, 会调用 `~.RequestHandler.on_finish()` .
   对于同步处理来说调用会在 ``get()`` (等) 返回后立即执行;
   对于异步处理来说这将会发生在调用 `~.RequestHandler.finish()` 之后.

所有像这样可以被覆盖的方法都记录在
`.RequestHandler` 的文档中.  其中一些最常用的覆盖方法有:

- `~.RequestHandler.write_error` -
  输出一个HTML的出错信息
- `~.RequestHandler.on_connection_close` - 当与客户端断开时会被调用;
  应用程序将会检查这种情况并且停止后续的处理.
  要注意这里无法保证客户端断开时可以立刻被检测到.
- `~.RequestHandler.get_current_user` - 详见 :ref:`user-authentication`
- `~.RequestHandler.get_user_locale` - 给当前用户返回一个 `.Locale` 对象
- `~.RequestHandler.set_default_headers` - 可以用来设置
  在回应时的附加首部 (例如可以定制 ``Server``
  首部)

错误处理
~~~~~~~~~~~~~~

如果一个控制器抛出了异常, Tornado 将会调用
`.RequestHandler.write_error` 来生成一个错误页.
`tornado.web.HTTPError` 可以用来生成一个指定的错误状态码; 
其它异常时将会返回 500 .

在 debug 模式中默认的错误页中包含栈调用记录和一行的错误描述信息
 (例如. "500: Internal Server Error"). 要生成一个个人定制的错误页, 覆盖
`RequestHandler.write_error` (可以声明在父类中用来修改所有的控制器).这种方式可以正常的通过像 `~RequestHandler.write` 和 `~RequestHandler.render`
一样的方法来处理输出.
如果错误时由于异常引起的, ``exc_info`` 将作为关键字参数传递到错误信息中
(注意: 这里无法确保发生的异常就是当时在 `sys.exc_info` 中的异常, 所以
``write_error`` 必须使用例如像 `traceback.format_exception` 来代替
`traceback.format_exc`).

使用通常的处理方式来代替调用 ``write_error`` 也是可以的.
利用 `~.RequestHandler.set_status`, 写入一个应答, 然后返回.
特殊异常 `tornado.web.Finish` 在简单的返回不可用的情况下可能在抛出时不会调用 ``write_error`` 函数.

对于 404 错误, 利用 ``default_handler_class`` `Application设置
<.Application.settings>`.  处理器将会被覆盖
`~.RequestHandler.prepare` 方法而不是某个具体的例如
``get()`` HTTP 方法.  它将会产生一个用于描述信息的错误页: 
抛出一个 ``HTTPError(404)``
和覆盖 ``write_error``, 或者调用 ``self.set_status(404)``
在 ``prepare()`` 中直接生成.

重定向
~~~~~~~~~~~

在 Tornado 中重定向有两种重要的方式:
`.RequestHandler.redirect` 和利用 `.RedirectHandler`.

你可以在 `.RequestHandler` 中使用 ``self.redirect()`` 把用户重定向到其它地方.
可选参数 ``permanent`` 可以定义这个跳转是否时永久的.
``permanent`` 的默认值是
``False``, 它会产生一个 ``302 Found`` HTTP 状态码,适合用户在 ``POST`` 请求成功后的重定向.
如果 ``permanent`` 为真, ``301 Moved
Permanently`` HTTP 状态码将会被使用, 这将对于那些像跳转到正规 URL 页或者 SEO友好型的网页.

`.RedirectHandler` 可以在你的
`.Application` 路由表中直接设置跳转.  例如, 设置一条静态跳转::

    app = tornado.web.Application([
        url(r"/app", tornado.web.RedirectHandler,
            dict(url="http://itunes.apple.com/my-app-id")),
        ])

`.RedirectHandler` 也支持正则表达式替换.以下规则将会把所有以 ``/pictures/``
开头的请求 用 ``/photos/`` 来替代::

    app = tornado.web.Application([
        url(r"/photos/(.*)", MyPhotoHandler),
        url(r"/pictures/(.*)", tornado.web.RedirectHandler,
            dict(url=r"/photos/\1")),
        ])

不像 `.RequestHandler.redirect`, `.RedirectHandler` 默认使用的持久重定向. 
因为路由表是不会改变的, 在运行时它被假定时持久的, 在处理程序中发现重定向的时候,
可能时会改变的跳转结果.
通过 `.RedirectHandler` 定义的一个持久跳转链接, 在 `.RedirectHandler` 初始化参数中添加
``permanent=False`` .

异步处理
~~~~~~~~~~~~~~~~~~~~~

Tornado 处理程序默认是同步的: 当
``get()``/``post()`` 方法返回时, 结果将会被作为应答发送. 当运行的处理程序中所有请求都被阻塞时
, 任何需要长时间运行的处理程序应该被设计成异步的这样它们可以非阻塞的处理这一段程序.详情见
:doc:`async`; 这部分主要针对 `.RequestHandler` 子类中的异步技术.

使用异步处理程序的最简单方式是使用
`.coroutine` 修饰符. 这将会允许你通过关键字 ``yield`` 生成一个 非阻塞 I/O,
当协程没有相应之前不会有信息被发出. 查看 :doc:`coroutines` 获取更多信息.

在某些时候, 协程可能不如一些基于回调的方式更方便, 在这些情况下 `.tornado.web.asynchronous`
修饰符可以被取代.  这个修饰符通常不会自动发送应答; 相反请求将会被保持直到有些回调函数调用 `.RequestHandler.finish`. 这取决于应用程序来保证方法是会被掉用的,
否则用户的请求将会被简单的挂起.

这是一个利用 Tornado 的内建 `.AsyncHTTPClient` 来通过 FriendFeed API 发起调用的示例:

.. testcode::

    class MainHandler(tornado.web.RequestHandler):
        @tornado.web.asynchronous
        def get(self):
            http = tornado.httpclient.AsyncHTTPClient()
            http.fetch("http://friendfeed-api.com/v2/feed/bret",
                       callback=self.on_response)

        def on_response(self, response):
            if response.error: raise tornado.web.HTTPError(500)
            json = tornado.escape.json_decode(response.body)
            self.write("Fetched " + str(len(json["entries"])) + " entries "
                       "from the FriendFeed API")
            self.finish()

.. testoutput::
   :hide:

当 ``get()`` 返回时, 请求没有终止. 当 HTTP 客户端最终调用 ``on_response()`` 时,
请求依然是打开的, 当最终调用 ``self.finish()`` 时客户端的相应才被发出.

For comparison, here is the same example using a coroutine:

.. testcode::

    class MainHandler(tornado.web.RequestHandler):
        @tornado.gen.coroutine
        def get(self):
            http = tornado.httpclient.AsyncHTTPClient()
            response = yield http.fetch("http://friendfeed-api.com/v2/feed/bret")
            json = tornado.escape.json_decode(response.body)
            self.write("Fetched " + str(len(json["entries"])) + " entries "
                       "from the FriendFeed API")

.. testoutput::
   :hide:

更高级的异步示例, 请查看 `chat
example application
<https://github.com/tornadoweb/tornado/tree/stable/demos/chat>`_, 使用 `长轮询(long polling)
<http://en.wikipedia.org/wiki/Push_technology#Long_polling>`_.  实现的 AJAX 聊天室.用户如果想使用长轮询需要覆盖 ``on_connection_close()`` 来
在客户端结束后关闭链接 (注意查看方法文档中的警告).
