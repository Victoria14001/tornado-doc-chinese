异步和非阻塞 I/O
---------------------------------

实时的web特性通常需要为每个用户一个大部分时间都处于空闲的长连接.
在传统的同步web服务器中,这意味着需要给每个用户分配一个专用的线程,这样的开销是十分巨大的.

为了减小对于并发连接需要的开销,Tornado使用了一种单线程事件循环的方式.
这意味着所有应用程序代码都应该是异步和非阻塞的,因为在同一时刻只有一个操作是有效的.

异步和非阻塞这两个属于联系十分紧密而且通常交换使用,但是它们并不完全相同

阻塞
~~~~~~~~

一个函数通常在它等待返回值的时候被 **阻塞** .一个函数被阻塞可能由于很多原因:
网络I/O,磁盘I/O,互斥锁等等.事实上, *每一个* 函数都会被阻塞,只是时间会比较短而已,
当一个函数运行时并且占用CPU(举一个极端的例子来说明为什么CPU阻塞的时间必须考虑在内,
考虑以下密码散列函数像
`bcrypt <http://bcrypt.sourceforge.net/>`_, 这个函数需要占据几百毫秒的CPU时间,
远远超过了通常对于网络和磁盘请求的时间).

一个函数可以在某些方面阻塞而在其他方面不阻塞.举例来说, `tornado.httpclient` 
在默认设置下将阻塞与DNS解析,但是在其它网络请求时不会阻塞
(为了减轻这种影响,可以用 `.ThreadedResolver` 或通过正确配置 ``libcurl`` 使用
``tornado.curl_httpclient`` ).
在Tornado的上下文中我们通常讨论网络I/O上下文阻塞,虽然各种阻塞已经被最小化了.

异步
~~~~~~~~~~~~

一个 **异步** 函数在它结束前就已经返回了,而且通常会在程序中触发一些动作然后在后台执行一些任务.
(和正常的 **同步** 函数相比, 同步函数在返回之前做完了所有的事).  这里有几种类型的异步接口:

* 回调函数
* 返回一个占位符 (`.Future`, ``Promise``, ``Deferred``)
* 传送一个队列
* 回调注册 (例如. POSIX 信号)

不论使用哪一种类型的接口, *依据定义* 异步函数与他们的调用者有不同的交互方式;
但没有一种对调用者透明的方式可以将同步函数变成异步函数 (像 `gevent
<http://www.gevent.org>`_ 通过一种轻量的线程库来提供异步系统,但是实际上它并不能让事情变得异步)

示例
~~~~~~~~

一个简单的同步函数:

.. testcode::

    from tornado.httpclient import HTTPClient

    def synchronous_fetch(url):
        http_client = HTTPClient()
        response = http_client.fetch(url)
        return response.body

.. testoutput::
   :hide:

这时同样的函数但是被通过回调参数方式的异步方法重写了:

.. testcode::

    from tornado.httpclient import AsyncHTTPClient

    def asynchronous_fetch(url, callback):
        http_client = AsyncHTTPClient()
        def handle_response(response):
            callback(response.body)
        http_client.fetch(url, callback=handle_response)

.. testoutput::
   :hide:

再一次 通过 `.Future` 替代回调函数:

.. testcode::

    from tornado.concurrent import Future

    def async_fetch_future(url):
        http_client = AsyncHTTPClient()
        my_future = Future()
        fetch_future = http_client.fetch(url)
        fetch_future.add_done_callback(
            lambda f: my_future.set_result(f.result()))
        return my_future

.. testoutput::
   :hide:

The raw `.Future` version is more complex, but ``Futures`` are
nonetheless recommended practice in Tornado because they have two
major advantages.  Error handling is more consistent since the
`.Future.result` method can simply raise an exception (as opposed to
the ad-hoc error handling common in callback-oriented interfaces), and
``Futures`` lend themselves well to use with coroutines.  Coroutines
will be discussed in depth in the next section of this guide.  Here is
the coroutine version of our sample function, which is very similar to
the original synchronous version:

.. testcode::

    from tornado import gen

    @gen.coroutine
    def fetch_coroutine(url):
        http_client = AsyncHTTPClient()
        response = yield http_client.fetch(url)
        raise gen.Return(response.body)

.. testoutput::
   :hide:

The statement ``raise gen.Return(response.body)`` is an artifact of
Python 2, in which generators aren't allowed to return
values. To overcome this, Tornado coroutines raise a special kind of
exception called a `.Return`. The coroutine catches this exception and
treats it like a returned value. In Python 3.3 and later, a ``return
response.body`` achieves the same result.
