模版和 UI
================

.. testsetup::

   import tornado.web

Tornado 包含了一个简单, 快速, 灵活的模版语言.
这章节也描述了与语言相关的国际化问题.

Tornado 也可以使用其它的 Python 模版语言,
虽然没有将这些系统的整合到
`.RequestHandler.render` 中. 而是简单的将模版转换成字符串发送给 `.RequestHandler.write`

设置模版
~~~~~~~~~~~~~~~~~~~~~

默认情况下, Tornado 会寻找在当前 ``.py`` 文件相同目录下的所关联的模版文件.
如果要将模版文件放到另外一个目录中, 使用 ``template_path`` `应用程序设置
<.Application.settings>` (或者覆盖 `.RequestHandler.get_template_path`
如果你在不同的处理程序中有不同的模版).

如果要从非文件系统路径加载模版, 在子类 `tornado.template.BaseLoader` 
中配置设置 ``template_loader`` .

被编译过的模版默认时被缓存的; 要关闭缓存使得每次每次对于文件的改变都是可见的, 
使用应用程序设置 ``compiled_template_cache=False``
或者 ``debug=True``.


模版语法
~~~~~~~~~~~~~~~

Tornado 模本文件仅仅是一个 HTML (或者其他基于文本的文件格式) 附加
Python 控制语句和内建的表达式::

    <html>
       <head>
          <title>{{ title }}</title>
       </head>
       <body>
         <ul>
           {% for item in items %}
             <li>{{ escape(item) }}</li>
           {% end %}
         </ul>
       </body>
     </html>

如果你将这个模版文件保存为 "template.html" 然后将你的 Python 文件保存在同一目录, 
你可以用这种方式来使用模版:

.. testcode::

    class MainHandler(tornado.web.RequestHandler):
        def get(self):
            items = ["Item 1", "Item 2", "Item 3"]
            self.render("template.html", title="My title", items=items)

.. testoutput::
   :hide:

Tornado 模版支持 *控制语句 (control statements)* 和 *表达式 (expressions)* .
控制语句被 ``{%`` and ``%}`` 包裹着, 例如.,
``{% if len(items) > 2 %}``. 表达式被 ``{{`` 和
``}}`` 围绕, 再例如., ``{{ items[0] }}``.

模版中的控制语句多多少少与 Python 中的控制语句相映射. 我们支持
``if``, ``for``, ``while``, 和 ``try``, 所有这些都包含在
``{%  %}`` 之中. 我们也支持 *模板继承*
使用 ``extends`` 和 ``block`` 语句, 详见 `tornado.template`.

表达式可以时任何的 Python 表达式, 包括函数调用.
模版代码可以在以下对象和函数的命名空间中被执行.
(注意这个列表可用在 `.RequestHandler.render` 和
`~.RequestHandler.render_string`. 如果你直接在 `.RequestHandler` 外使用
`tornado.template` 模块, 下面许多别名是不可用的).

- ``escape``:  `tornado.escape.xhtml_escape` 的别名
- ``xhtml_escape``:  `tornado.escape.xhtml_escape` 的别名
- ``url_escape``:  `tornado.escape.url_escape` 的别名
- ``json_encode``:  `tornado.escape.json_encode` 的别名
- ``squeeze``:  `tornado.escape.squeeze` 的别名
- ``linkify``:  `tornado.escape.linkify` 的别名
- ``datetime``:  Python `datetime` 模块
- ``handler``: 目前的 `.RequestHandler` 对象
- ``request``:  `handler.request <.HTTPServerRequest>` 的别名
- ``current_user``:  `handler.current_user
  <.RequestHandler.current_user>` 的别名
- ``locale``:  `handler.locale <.Locale>` 的别名
- ``_``:  `handler.locale.translate <.Locale.translate>` 的别名
- ``static_url``:  `handler.static_url <.RequestHandler.static_url>` 的别名
- ``xsrf_form_html``:  `handler.xsrf_form_html
  <.RequestHandler.xsrf_form_html>` 的别名
- ``reverse_url``:  `.Application.reverse_url` 的别名
- 所有 ``ui_methods`` 和 ``ui_modules`` 的
  ``Application`` 设置
- 所有传递给 `~.RequestHandler.render` 或者
  `~.RequestHandler.render_string` 的参数

当你真正创建一个应用程序时, 你可能会去查看所有 Tornado 模版的特性,
特别时模版继承. 这些内容详见 `tornado.template`
部分 (某些特性, 包括 ``UIModules`` 在
`tornado.web` 模块中描述)

在引擎下, Tornado 模版被直街翻译成 Python. 
在你模版文件中的表达式将会被翻译成 Python 函数来代表原来的模版;
我们不在模版语言中阻止任何东西; 我们创造它的目的时为了提供更灵活的特性,
而不是有严格限制的模版系统.
因此, 如果你在你的模版文件中随意写入了表达式, 你再执行时将会得到相依随机的错误.

默认情况下, 所有模版文件的输出将会被 `tornado.escape.xhtml_escape` 方法转义. 
这个设置可以通过给 `.Application` 传递全局参数 ``autoescape=None`` 或者使用
`.tornado.template.Loader` 构造器进行修改, 或者在模版文件中检测到
``{% autoescape None %}`` , 或者简单的将 ``{{ ... }}`` 替换成 ``{% raw ...%}`` 的表达式.
此外, 可以在设置这些地方的转义函数为 ``None`` 已达到相同的效果.


注意, 尽管 Tornado's 的自动转义在防止
XSS 漏洞上是有帮助的, 但是不能适用于所有的情况.  出现在适当位置的表达式, 
例如 Javascript 或者 CSS, 可能需要额外的转义. 
此外, 必须要额外注意使用在 HTML 中使用双括号和 `.xhtml_escape` 中包含一些不可信的内容,
或者在属性中使用单独的转义函数 (查看示例. http://wonko.com/post/html-escaping)

国际化
~~~~~~~~~~~~~~~~~~~~

目前用户的位置 (不论用户是否登陆) 在请求处理程序中的 ``self.locale`` 和 
模版中的 ``locale`` 都是可用的. 位置的名字 (例如, ``en_US``)  在 ``locale.name`` 中是可用的,
你也可以通过 `.Locale.translate` 方法来翻译字符串.
模版中也有一个全局函数叫做 ``_()`` 用来翻译字符串.
翻译函数有两种形式::

    _("翻译这段文字")

这将会根据用户的位置直接翻译, 还有::

    _("A person liked this", "%(num)d people liked this",
      len(people)) % {"num": len(people)}


可以根据第三个参数的数量来决定单复数形式. 在以上的例子中, 
第一个翻译将会在 ``len(people)`` 是 ``1`` 时被激活, 
在其它情况下会激活第二个翻译.

大多是翻译时利用 Python 中的变量占位符 ( 前面例子中的 ``%(num)d`` ) 
占位符在翻译时可以被替换.

这是一个正确的国际化模版::

    <html>
       <head>
          <title>FriendFeed - {{ _("Sign in") }}</title>
       </head>
       <body>
         <form action="{{ request.path }}" method="post">
           <div>{{ _("Username") }} <input type="text" name="username"/></div>
           <div>{{ _("Password") }} <input type="password" name="password"/></div>
           <div><input type="submit" value="{{ _("Sign in") }}"/></div>
           {% module xsrf_form_html() %}
         </form>
       </body>
     </html>

默认情况下, 我们通过用户通过浏览器发送的首部 ``Accept-Language`` 来确定语言.
当我们不能找到默认的语言时我们使用 ``en_US`` 作为 ``Accept-Language`` 的值.
如果你希望用户自己设定自己的位置, 你可以通过修改默认选项 `.RequestHandler.get_user_locale`
来实现:

.. testcode::

    class BaseHandler(tornado.web.RequestHandler):
        def get_current_user(self):
            user_id = self.get_secure_cookie("user")
            if not user_id: return None
            return self.backend.get_user_by_id(user_id)

        def get_user_locale(self):
            if "locale" not in self.current_user.prefs:
                # Use the Accept-Language header
                return None
            return self.current_user.prefs["locale"]

.. testoutput::
   :hide:

如果 ``get_user_locale`` 返回 ``None``, 我们将会再使用
``Accept-Language`` 头部来确定.

`tornado.locale` 模块支持两种格式的翻译:
一种使用 `getttext` 和有关工具的 ``.mo`` 格式, 
另一种时简单的 ``.csv`` 格式. 应用程序将会在启动时调用
`tornado.locale.load_translations` 或者
`tornado.locale.load_gettext_translations`; 查看这些支持格式方法来获取更详细的信息.

你可以通过调用方法
`tornado.locale.get_supported_locales()` 来查看支持的地理位置. 
用户的位置将会基于它所在的最近位置. 例如, 用户的位置是 ``es_GT`` ,
``es`` 是支持的, ``self.locale`` 对那个请求将会设置为 ``es`` .
但如果勋章寻找失败 ``en_US`` 将会作为默认设置.

.. _ui-modules:

UI 模版
~~~~~~~~~~

Tornado 支持 *UI 模版* 为了更加简单的支持标准,
在你的程序中重用 UI 组件. UI 模块就像特殊的方法调用一样用来显示页面上的组件, 
它们也可以被报装在 CSS 和 JavaScript 中.

例如, 如果你正在实现一个博客, 你想把博客的入口同时放置在主页和每一页的入口,
你可以定义一个 ``Entry`` 模块来实现它们. 首先, 创建一个 Python 模块当作一个 UI 模块,
例如  ``uimodules.py``::

    class Entry(tornado.web.UIModule):
        def render(self, entry, show_comments=False):
            return self.render_string(
                "module-entry.html", entry=entry, show_comments=show_comments)

在 ``ui_modules`` 设置中告诉 Tornado 使用 ``uimodules.py`` ::

    from . import uimodules

    class HomeHandler(tornado.web.RequestHandler):
        def get(self):
            entries = self.db.query("SELECT * FROM entries ORDER BY date DESC")
            self.render("home.html", entries=entries)

    class EntryHandler(tornado.web.RequestHandler):
        def get(self, entry_id):
            entry = self.db.get("SELECT * FROM entries WHERE id = %s", entry_id)
            if not entry: raise tornado.web.HTTPError(404)
            self.render("entry.html", entry=entry)

    settings = {
        "ui_modules": uimodules,
    }
    application = tornado.web.Application([
        (r"/", HomeHandler),
        (r"/entry/([0-9]+)", EntryHandler),
    ], **settings)

在一个模版中, 你可以利用 ``{% module %}`` 语句来调用一个模版. 
例如, 你可以在 ``home.html`` 中调用 ``Entry`` 模块::

    {% for entry in entries %}
      {% module Entry(entry) %}
    {% end %}

还有 ``entry.html`` 中::

    {% module Entry(entry, show_comments=True) %}

模块可以通过覆盖包含定制的 CSS 和 JavaScript 方法 ``embedded_css``, ``embedded_javascript``, ``javascript_files`` , 或者 ``css_files`` 方法::

    class Entry(tornado.web.UIModule):
        def embedded_css(self):
            return ".entry { margin-bottom: 1em; }"

        def render(self, entry, show_comments=False):
            return self.render_string(
                "module-entry.html", show_comments=show_comments)

CSS 和 JavaScript 模块只会被载入一次不论多少模块在页面中使用了它. 
CSS 总是被包含在页面的 ``<head>`` 标签中,
而且 JavaScript 也总是在页面底部的 ``</body>`` 之前.


当附加的 Python 代码不需要的时候, 模版文件自己可以是一个模块.
例如, 上面的例子可以在下面的 ``module-entry.html`` 中被重写::

    {{ set_resources(embedded_css=".entry { margin-bottom: 1em; }") }}
    <!-- more template html... -->

这个被修改过的模块可以这样调用

    {% module Template("module-entry.html", show_comments=True) %}

``set_resources`` 方法仅在模版通过 ``{% module Template(...) %}`` 调用有效. 
不像 ``{% include ... %}`` 指令, 模版模块在模版容器中有一个不同的命名空间 - 
它们只能看到全局模版的命名空间和自己的关键字参数.
