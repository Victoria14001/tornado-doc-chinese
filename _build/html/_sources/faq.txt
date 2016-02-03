问题与解答
==========================

.. contents::
   :local:

为什么在例子中调用 ``time.sleep()`` 不会并发执行?
-----------------------------------------------------------------

Many people's first foray into Tornado's concurrency looks something like
this::

   class BadExampleHandler(RequestHandler):
       def get(self):
           for i in range(5):
               print(i)
               time.sleep(1)

Fetch this handler twice at the same time and you'll see that the second
five-second countdown doesn't start until the first one has completely
finished. The reason for this is that `time.sleep` is a **blocking**
function: it doesn't allow control to return to the `.IOLoop` so that other
handlers can be run.

Of course, `time.sleep` is really just a placeholder in these examples,
the point is to show what happens when something in a handler gets slow.
No matter what the real code is doing, to achieve concurrency blocking
code must be replaced with non-blocking equivalents. This means one of three things:

1. *Find a coroutine-friendly equivalent.* For `time.sleep`, use
   `tornado.gen.sleep` instead::

    class CoroutineSleepHandler(RequestHandler):
        @gen.coroutine
        def get(self):
            for i in range(5):
                print(i)
                yield gen.sleep(1)

   When this option is available, it is usually the best approach.
   See the `Tornado wiki <https://github.com/tornadoweb/tornado/wiki/Links>`_
   for links to asynchronous libraries that may be useful.

2. *Find a callback-based equivalent.* Similar to the first option,
   callback-based libraries are available for many tasks, although they
   are slightly more complicated to use than a library designed for
   coroutines. These are typically used with `tornado.gen.Task` as an
   adapter::

    class CoroutineTimeoutHandler(RequestHandler):
        @gen.coroutine
        def get(self):
            io_loop = IOLoop.current()
            for i in range(5):
                print(i)
                yield gen.Task(io_loop.add_timeout, io_loop.time() + 1)

   Again, the
   `Tornado wiki <https://github.com/tornadoweb/tornado/wiki/Links>`_
   can be useful to find suitable libraries.

3. *Run the blocking code on another thread.* When asynchronous libraries
   are not available, `concurrent.futures.ThreadPoolExecutor` can be used
   to run any blocking code on another thread. This is a universal solution
   that can be used for any blocking function whether an asynchronous
   counterpart exists or not::

    executor = concurrent.futures.ThreadPoolExecutor(8)

    class ThreadPoolHandler(RequestHandler):
        @gen.coroutine
        def get(self):
            for i in range(5):
                print(i)
                yield executor.submit(time.sleep, 1)

See the :doc:`Asynchronous I/O <guide/async>` chapter of the Tornado
user's guide for more on blocking and asynchronous functions.


我的代码是异步的, 但它不能在两个浏览器标签页上并行运行.
------------------------------------------------------------------------------

即使你是用了异步和非阻塞的控制器, 你会发现在测试过程中可能也会出现问题. 
流量器将会发现你试图在两个不同的标签页加载同一个页面,这时浏览器会延迟加载
第二个页面一直等到第一个页面加载完成. 如果你想要看到异步的效果,
请尝试以下两种方法中的任意一个:

* 在url上添加一些参数让请求变得不同. 之前是将
  ``http://localhost:8888`` 在两个标签页中打开, 现在可以尝试在一个标签页中打开
  ``http://localhost:8888/?x=1`` 而后在另一个标签页打开 ``http://localhost:8888/?x=2`` .

* 使用两个不同的浏览器. 例如, Firefox 和 Chrome 将会同时加载同样的url而不会等待对方.

