.. Tornado documentation master file, created by
   sphinx-quickstart on Sun Jan 31 23:16:19 2016.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

.. title:: Tornado Web 服务器

|Tornado Web Server|
====================

.. |Tornado Web Server| image:: tornado.png
    :alt: Tornado Web Server

`Tornado <http://www.tornadoweb.org>`_ 是一个基于Python的Web服务框架和
异步网络库, 最早开发与 `FriendFeed
<http://friendfeed.com>`_ 公司.  通过利用非阻塞网络 I/O, Tornado
可以承载成千上万的活动连接, 完美的实现了
`长连接 <http://en.wikipedia.org/wiki/Push_technology#Long_polling>`_,
`WebSockets <http://en.wikipedia.org/wiki/WebSocket>`_,
和其他对于每一位用户来说需要长连接的程序.

快速链接
-----------


* 下载版本4.4: `tornado-4.4.dev1.tar.gz <https://pypi.python.org/packages/source/t/tornado/tornado-4.4.dev1.tar.gz>`_ (:doc:`发布说明 <releases>`)
* `Source (github) <https://github.com/tornadoweb/tornado>`_
* 邮件列表: `discussion <http://groups.google.com/group/python-tornado>`_ 和 `announcements <http://groups.google.com/group/python-tornado-announce>`_
* `Stack Overflow <http://stackoverflow.com/questions/tagged/tornado>`_
* `Wiki <https://github.com/tornadoweb/tornado/wiki/Links>`_


Hello, world
------------

这是一个基于Tornado的简易 "Hello, world" web应用程序::

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

这个例子没有用到任何Tornado的异步特性;
如果有需要请查看这个例子 `简易聊天室
<https://github.com/tornadoweb/tornado/tree/stable/demos/chat>`_.

安装
------------

**自动安装**::

    pip install tornado

Tornado 可以在 `PyPI <http://pypi.python.org/pypi/tornado>`_ 中被找到.而且可以通过 ``pip`` 或者 ``easy_install``来安装.注意这样安装Tornado
可能不会包含源代码中的示例程序, 所以你或许会需要一份软件的源代码.

**手动安装**: 下载 `tornado-4.4.dev1.tar.gz <https://pypi.python.org/packages/source/t/tornado/tornado-4.4.dev1.tar.gz>`_.

.. parsed-literal::

    tar xvzf tornado-|version|.tar.gz
    cd tornado-|version|
    python setup.py build
    sudo python setup.py install

Tornado源代码 `被托管在的 GitHub
<https://github.com/tornadoweb/tornado>`_.

**环境要求**: Tornado 4.3 可以运行在 Python 2.7, 和 3.3+
对于 Python 2, 版本 2.7.9 以上是被 *强烈*
推荐的由于这些版本提供了SSL. 除了在 ``pip`` 或者 ``setup.py install``
中安装的依赖需求包之外, 以下包有可能会被用到:

* `concurrent.futures <https://pypi.python.org/pypi/futures>`_ is the
  recommended thread pool for use with Tornado and enables the use of
  `~tornado.netutil.ThreadedResolver`.  It is needed only on Python 2;
  Python 3 includes this package in the standard library.
* `pycurl <http://pycurl.sourceforge.net>`_ is used by the optional
  ``tornado.curl_httpclient``.  Libcurl version 7.19.3.1 or higher is required;
  version 7.21.1 or higher is recommended.
* `Twisted <http://www.twistedmatrix.com>`_ may be used with the classes in
  `tornado.platform.twisted`.
* `pycares <https://pypi.python.org/pypi/pycares>`_ is an alternative
  non-blocking DNS resolver that can be used when threads are not
  appropriate.
* `Monotime <https://pypi.python.org/pypi/Monotime>`_ adds support for
  a monotonic clock, which improves reliability in environments
  where clock adjustments are frequent.  No longer needed in Python 3.3.
* `monotonic <https://pypi.python.org/pypi/monotonic>`_ adds support for
  a monotonic clock. Alternative to Monotime.  No longer needed in Python 3.3.

**平台**: Tornado 应该运行在类 Unix 平台, 对于Linux (通过 ``epoll``) 和
BSD (通过 ``kqueue``) 可以获得更好的性能和可扩展性, 但我们仅推荐它们来不熟产品
(虽然 Mac OS X 也是基于 BSD 的,并且也支持 kqueue, 但是它的网络性能十分的差所以
我们只推荐用它来进行开发). Tornado 也可以运行在 Windows 上, 
虽然这并不是官方所推荐的, 我们仅仅推荐用它来做开发. 

文档
-------------

这篇文档同时还有 `PDF 和 Epub 格式
<https://readthedocs.org/projects/tornado/downloads/>`_.


.. toctree::
   :titlesonly:

   guide
   webframework
   http
   networking
   coroutine
   integration
   utilities
   faq
   releases



Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`

讨论和支持
----------------------

你可以在 `Tornado 开发人员邮件列表 <http://groups.google.com/group/python-tornado>`_ 
中对 Tornado 进行讨论, 并且可以在 `GitHub 问题跟踪
<https://github.com/tornadoweb/tornado/issues>`_
中汇报问题.  其他的资源可以在 `Tornado wiki
<https://github.com/tornadoweb/tornado/wiki/Links>`_
中找到.  新版本通知在 `通知邮件列表 <http://groups.google.com/group/python-tornado-announce>`_.

Tornado 遵循 `Apache License, Version 2.0
<http://www.apache.org/licenses/LICENSE-2.0.html>`_.

本网页和所有的文档都遵循 `Creative
Commons 3.0 <http://creativecommons.org/licenses/by/3.0/>`_.

中文文档由 `我是黑夜 <http://github.com/deepdarkness>`_ 翻译完成.
译文版权归原作者和译者所有.