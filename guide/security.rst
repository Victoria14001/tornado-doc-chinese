认证与安全
===========================

.. testsetup::

   import tornado.web

Cookies 和 secure cookies
~~~~~~~~~~~~~~~~~~~~~~~~~~

你可以使用 ``set_cookie`` 方法在用户的浏览器中设置 cookies:

.. testcode::

    class MainHandler(tornado.web.RequestHandler):
        def get(self):
            if not self.get_cookie("mycookie"):
                self.set_cookie("mycookie", "myvalue")
                self.write("Your cookie was not set yet!")
            else:
                self.write("Your cookie was set!")

.. testoutput::
   :hide:

Cookies 是不安全的而且很容易被客户端修改. 如果你通过设置 cookies 来
识别当前登陆的用户, 你需要利用签名来防止 cookies 被伪造. Tornado 利用 
`~.RequestHandler.set_secure_cookie` 和
`~.RequestHandler.get_secure_cookie` 方法来对 cookies签名. 
为了使用这些方法, 你需要在创建应用程序时指定一个叫做 ``cookie_secret`` 的密匙. 
你可以在应用程序的设置中通过传递参数来注册密匙:

.. testcode::

    application = tornado.web.Application([
        (r"/", MainHandler),
    ], cookie_secret="__TODO:_GENERATE_YOUR_OWN_RANDOM_VALUE_HERE__")

.. testoutput::
   :hide:

对 cookies 签名后就有确定的编码后的值, 还有时间戳和一个 `HMAC <http://en.wikipedia.org/wiki/HMAC>`_ .
如果 cookes 过期或者签名不匹配, ``get_secure_cookie`` 将返回 ``None``
就如同这个 cookie 没有被设置一样. 这是一个安全版本的例子:

.. testcode::

    class MainHandler(tornado.web.RequestHandler):
        def get(self):
            if not self.get_secure_cookie("mycookie"):
                self.set_secure_cookie("mycookie", "myvalue")
                self.write("Your cookie was not set yet!")
            else:
                self.write("Your cookie was set!")

.. testoutput::
   :hide:

Tornado 的 secure cookies 保证完整性但不保证保密性.
就是说, cookie 将不会被修改, 但是它会让用户看到. ``cookie_secret`` 
是一个对称密钥, 所以它必须被保护起来 -- 
任何一个人得到密钥的值就将会制造一个签名的 cookie.

默认情况下, Tornado 的 secure cookies 将会在 30 天后过期. 如果要修改这个值,
使用 ``expires_days`` 关键词参数传递给 ``set_secure_cookie`` *和* 
``max_age_days`` 参数传递给 ``get_secure_cookie``.  这两个值的传递是相互独立的, 
你可能会在大多数情况下会使用一个 30 天内合法的密匙, 但是对某些敏感操作 
(例如修改账单信息) 你可以使用一个较小的 ``max_age_days`` .

Tornado 也支持多个签名的密匙, 这样可以使用密匙轮换. 
这样 ``cookie_secret`` 必须是一个具有整数作为密匙版本的字典. 
当前正在使用的签名密匙版本必须在应用程序中被设置为 ``key_version`` 
如果一个正确的密匙版本在 cookie 中被设置, 
密匙字典中的其它密匙也可以被用来作为 cookie 的签名认证, 
为了实现 cookie 的更新, 可以在 
`~.RequestHandler.get_secure_cookie_key_version` 中查询当前的密匙版本.

.. _user-authentication:

用户认证
~~~~~~~~~~~~~~~~~~~

当前通过认证的用户在请求处理器的 `self.current_user <.RequestHandler.current_user>` 当中, 
而且还存在于模版中的 ``current_user``. 默认情况下, ``current_user`` 的值为
``None``.

为了在你的应用程序中实现用户认证, 你需要覆盖请求控制器中的 ``get_current_user()`` 方法
来确认怎样获取当前登陆的用户, 例如, 从 cookie 的值中获取该信息. 
下面这个例子展示了通过用户的昵称来确定用户身份, 值被保存在 cookies 中:

.. testcode::

    class BaseHandler(tornado.web.RequestHandler):
        def get_current_user(self):
            return self.get_secure_cookie("user")

    class MainHandler(BaseHandler):
        def get(self):
            if not self.current_user:
                self.redirect("/login")
                return
            name = tornado.escape.xhtml_escape(self.current_user)
            self.write("Hello, " + name)

    class LoginHandler(BaseHandler):
        def get(self):
            self.write('<html><body><form action="/login" method="post">'
                       'Name: <input type="text" name="name">'
                       '<input type="submit" value="Sign in">'
                       '</form></body></html>')

        def post(self):
            self.set_secure_cookie("user", self.get_argument("name"))
            self.redirect("/")

    application = tornado.web.Application([
        (r"/", MainHandler),
        (r"/login", LoginHandler),
    ], cookie_secret="__TODO:_GENERATE_YOUR_OWN_RANDOM_VALUE_HERE__")

.. testoutput::
   :hide:

你可以使用 `Python
装饰器 (decorator) <http://www.python.org/dev/peps/pep-0318/>`_
`tornado.web.authenticated` 来获取登陆的用户. 
如果你的方法被这个装饰器所修饰, 若是当前的用户没有登陆, 则用户会被重定向到
``login_url`` (在应用程序设置中).
上面的例子也可以这样写:

.. testcode::

    class MainHandler(BaseHandler):
        @tornado.web.authenticated
        def get(self):
            name = tornado.escape.xhtml_escape(self.current_user)
            self.write("Hello, " + name)

    settings = {
        "cookie_secret": "__TODO:_GENERATE_YOUR_OWN_RANDOM_VALUE_HERE__",
        "login_url": "/login",
    }
    application = tornado.web.Application([
        (r"/", MainHandler),
        (r"/login", LoginHandler),
    ], **settings)

.. testoutput::
   :hide:

如果你的 ``post()`` 方法被 ``authenticated`` 修饰, 而且用户还没有登陆,
这时服务器会产生一个 ``403`` 错误.
``@authenticated`` 描述符仅仅是精简版的 ``if not self.current_user: self.redirect()`` ,
而且可能对于非浏览器的登陆者是不适用的.

点击 `Tornado Blog example application
<https://github.com/tornadoweb/tornado/tree/stable/demos/blog>`_ 
来查看一个完整的用户认证程序 (将用户的数据保存在 MySQL 数据库中).

第三方认证
~~~~~~~~~~~~~~~~~~~~~~~~~~

`tornado.auth` 模块既实现了认证, 而且还支持许多知名网站的认证协议, 
这其中包括 Google/Gmail, Facebook, Twitter, 和 FriendFeed.
模块内包含了通过这些网站登陆用户的方法, 并在允许的情况下访问该网站的服务. 
例如, 下载用户的地址薄或者在允许的情况下发布一条 Twitter 信息.

这里有一个 Google 身份认证的例子, 
在 cookie 中保存 Google 的认证信息用来进行后续的操作:

.. testcode::

    class GoogleOAuth2LoginHandler(tornado.web.RequestHandler,
                                   tornado.auth.GoogleOAuth2Mixin):
        @tornado.gen.coroutine
        def get(self):
            if self.get_argument('code', False):
                user = yield self.get_authenticated_user(
                    redirect_uri='http://your.site.com/auth/google',
                    code=self.get_argument('code'))
                # Save the user with e.g. set_secure_cookie
            else:
                yield self.authorize_redirect(
                    redirect_uri='http://your.site.com/auth/google',
                    client_id=self.settings['google_oauth']['key'],
                    scope=['profile', 'email'],
                    response_type='code',
                    extra_params={'approval_prompt': 'auto'})

.. testoutput::
   :hide:

详情可查看 `tornado.auth` 模块文档.

.. _xsrf:

跨站请求伪造防护
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

`跨站请求伪造(Cross-site request
forgery) <http://en.wikipedia.org/wiki/Cross-site_request_forgery>`_, 
XSRF, 是一个 web 应用程序要面临的常规问题 . 详见
`Wikipedia
文章 <http://en.wikipedia.org/wiki/Cross-site_request_forgery>`_ 查看关于 XSRF 的详细信息.

一个普遍被接受的防护 XSRF 做法是让每一个用户 cookie 都保存不可预测的值,
然后把那个值通过 form 额外的提交到你的站点. 如果 cookie 和 form 中提交的值不匹配,
那么请求很有可能是伪造的.

Tornado 内置有 XSRF 保护. 你需要在应用程序中设置 ``xsrf_cookies``:

.. testcode::

    settings = {
        "cookie_secret": "__TODO:_GENERATE_YOUR_OWN_RANDOM_VALUE_HERE__",
        "login_url": "/login",
        "xsrf_cookies": True,
    }
    application = tornado.web.Application([
        (r"/", MainHandler),
        (r"/login", LoginHandler),
    ], **settings)

.. testoutput::
   :hide:

如果设置了 ``xsrf_cookies`` , Tornado web 应用程序将会为每一个用户设置一个 ``_xsrf`` cookie
来拒绝所有与 ``_xsrf`` 的值不匹配的``POST``, ``PUT``, 和 ``DELETE`` 请求.
如果你将此设置打开, 你必须给每个通过 ``POST`` 提交表单中添加这个字段.
你可以通过特殊的 `.UIModule` ``xsrf_form_html()`` 来实现这些, 在模版中是可用的::

    <form action="/new_message" method="post">
      {% module xsrf_form_html() %}
      <input type="text" name="message"/>
      <input type="submit" value="Post"/>
    </form>

如果你提交一个 AJAX ``POST`` 请求, 你的每次请求需要在你的 JavaScript 中添加一个 
``_xsrf`` 的值. 这是一个我们在 FriendFeed  中用到的一个通过 AJAX 
``POST`` 方法来自动添加  ``_xsrf`` 值的 `jQuery <http://jquery.com/>`_ 函数::


    function getCookie(name) {
        var r = document.cookie.match("\\b" + name + "=([^;]*)\\b");
        return r ? r[1] : undefined;
    }

    jQuery.postJSON = function(url, args, callback) {
        args._xsrf = getCookie("_xsrf");
        $.ajax({url: url, data: $.param(args), dataType: "text", type: "POST",
            success: function(response) {
            callback(eval("(" + response + ")"));
        }});
    };

对于 ``PUT`` 和 ``DELETE`` 请求 (除了不像 ``POST`` 请求用到 form 编码参数),
XSRF token 会通过 HTTP 首部中的 ``X-XSRFToken`` 字段来传输.
XSRF cookie 在 ``xsrf_form_html`` 被使用时设置, 但是在一个非通常形式的
纯 JavaScript 应用程序中, 你可能需要手动设置 ``self.xsrf_token`` 
(仅通过读取这个属性就足以有效设置 cookie 了).

如果你需要对每一个基本的控制器自定义 XSRF 行为, 你一个覆盖
`.RequestHandler.check_xsrf_cookie()`. 例如,
如果你有一个不是通过 cookie 来认证的 API, 你可能需要让 
``check_xsrf_cookie()`` 不做任何事来禁用 XSRF 的保护功能.
然而, 如果你既支持 cookie 认证又支持 非基于 cookie 的认证,
这样当前请求通过 cookie 认证的 XSRF 保护就会十分的重要.
