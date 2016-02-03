协程
==========

.. testsetup::

   from tornado import gen

Tornado 中推荐用 **协程** 来编写异步代码. 协程使用 Python 中的关键字 ``yield`` 
来替代链式回调来实现挂起和继续程序的执行(像在 `gevent
<http://www.gevent.org>`_ 中使用的轻量级线程合作的方法有时也称作协程,
但是在 Tornado 中所有协程使用异步函数来实现的明确的上下文切换).

协程和异步编程的代码一样简单, 而且不用浪费额外的线程, . 它们还可以减少上下文切换 `让并发更简单
<https://glyph.twistedmatrix.com/2014/02/unyielding.html>`_ .

Example::

    from tornado import gen

    @gen.coroutine
    def fetch_coroutine(url):
        http_client = AsyncHTTPClient()
        response = yield http_client.fetch(url)
        # 在 Python 3.3 之前的版本中, 从生成器函数
        # 返回一个值是不允许的,你必须用
        #   raise gen.Return(response.body)
        # 来代替
        return response.body

.. _native_coroutines:

Python 3.5: ``async`` 和 ``await``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Python 3.5 引入了 ``async`` 和 ``await`` 关键字 (使用了这些关键字的函数通常被叫做
"native coroutines" ). 从 Tornado 4.3 开始, 在协程基础上你可以使用这些来代替 ``yield``.
简单的通过使用 ``async def foo()`` 来代替 ``@gen.coroutine`` 装饰器, 用 ``await`` 来代替 yield.
文档的剩余部分还是使用 ``yield`` 来兼容旧版本的 Python, 但是 ``async`` 和 ``await`` 在可用时将会运行的更快::

    async def fetch_coroutine(url):
        http_client = AsyncHTTPClient()
        response = await http_client.fetch(url)
        return response.body

``await`` 关键字并不像 ``yield`` 更加通用.
例如, 在一个基于 ``yield`` 的协程中你可以生成一个列表的 ``Futures``,
但是在原生的协程中你必须给列表报装 `tornado.gen.multi`. 
你也可以使用 `tornado.gen.convert_yielded`
将使用 ``yield`` 的任何东西转换成用 ``await`` 工作的形式.

虽然原生的协程不依赖于某种特定的框架
(例如. 它并没有使用像 `tornado.gen.coroutine` 或者
`asyncio.coroutine` 装饰器), 不是所有的协程都和其它程序兼容.这里有一个 *协程运行器* 
在第一个协程被调用时进行选择, 然后被所有直接调用 ``await`` 的协程库共享.
Tornado 协程运行器设计时就时多用途且可以接受任何框架的 awaitable 对象.
其它协程运行器可能会有更多的限制(例如, ``asyncio`` 协程运行器不能接收其它框架的协程).
由于这个原因, 我们推荐你使用 Tornado 的协程运行器来兼容任何框架的协程.
在 Tornado 协程运行器中调用一个已经用了asyncio协程运行器的协程,只需要用
`tornado.platform.asyncio.to_asyncio_future` 适配器.


他是如何工作的
~~~~~~~~~~~~

一个含有 ``yield`` 的函数时一个 **生成器** . 所有生成器都是异步的;
调用它时将会返回一个对象而不是将函数运行完成.
``@gen.coroutine`` 修饰器通过 ``yield`` 表达式通过产生一个 `.Future` 对象和生成器进行通信.

这是一个协程装饰器内部循环的额简单版本::

    # Simplified inner loop of tornado.gen.Runner
    def run(self):
        # send(x) makes the current yield return x.
        # It returns when the next yield is reached
        future = self.gen.send(self.next)
        def callback(f):
            self.next = f.result()
            self.run()
        future.add_done_callback(callback)

装饰器从生成器接收一个 `.Future` 对象, 等待 (非阻塞的) `.Future` 完成, 然后 "解开" `.Future`
将结果像 ``yield`` 语句一样返回给生成器. 大多数异步代码从不直接接触到 `.Future` 类,
除非 `.Future` 立即通过异步函数返回给 ``yield`` 表达式.

怎样调用协程
~~~~~~~~~~~~~~~~~~~~~~~

协程在一般情况下不抛出异常: 在 `.Future` 被生成时将会把异常报装进来.
这意味着正确的调用协程十分的重要, 否则你可能忽略很多错误::

    @gen.coroutine
    def divide(x, y):
        return x / y

    def bad_call():
        # This should raise a ZeroDivisionError, but it won't because
        # the coroutine is called incorrectly.
        divide(1, 0)

近乎所有情况中, 任何一个调用协程自身的函数必须时协程, 通过利用关键字 ``yield`` 来调用.
当你在覆盖了父类中的方法, 请查阅文档来判断协程是否被支持 (
文档中应该写到那个方法 "可能是一个协程" 或者 "可能返回一个
`.Future`")::

    @gen.coroutine
    def good_call():
        # yield will unwrap the Future returned by divide() and raise
        # the exception.
        yield divide(1, 0)

有时你并不想等待一个协程的返回值. 在这种情况下我们推荐你使用 `.IOLoop.spawn_callback`,
这意味着 `.IOLoop` 负责调用. 如果它失败了,
`.IOLoop` 会在日志中记录调用栈::

    # The IOLoop will catch the exception and print a stack trace in
    # the logs. Note that this doesn't look like a normal call, since
    # we pass the function object to be called by the IOLoop.
    IOLoop.current().spawn_callback(divide, 1, 0)

最后, 在程序的最顶层, *如果 `.IOLoop` 没有正在运行,* 你可以启动 `.IOLoop`, 运行协程, 然后通过
 `.IOLoop.run_sync` 方法来停止 `.IOLoop`. 这通常被用来启动面向批处理程序的 ``main`` 函数::

    # run_sync() doesn't take arguments, so we must wrap the
    # call in a lambda.
    IOLoop.current().run_sync(lambda: divide(1, 0))

协程模式
~~~~~~~~~~~~~~~~~~

结合 callbacks
^^^^^^^^^^^^^^^^^^^^^^^^^^

为了使用回调来代替 `.Future` 与异步代码进行交互, 讲这个调用报装在 `.Task` 中.
这将会在你生成的 `.Future` 对象中添加一个回调参数:

.. testcode::

    @gen.coroutine
    def call_task():
        # Note that there are no parens on some_function.
        # This will be translated by Task into
        #   some_function(other_args, callback=callback)
        yield gen.Task(some_function, other_args)

.. testoutput::
   :hide:

调用阻塞函数
^^^^^^^^^^^^^^^^^^^^^^^^^^

在协程中调用阻塞函数的最简单方法时通过使用 
`~concurrent.futures.ThreadPoolExecutor`, 这将返回与协程兼容的
``Futures`` ::

    thread_pool = ThreadPoolExecutor(4)

    @gen.coroutine
    def call_blocking():
        yield thread_pool.submit(blocking_func, args)

并行
^^^^^^^^^^^

协程装饰器能识别列表或者字典中的 ``Futures`` ,并且并行等待这些 ``Futures``:

.. testcode::

    @gen.coroutine
    def parallel_fetch(url1, url2):
        resp1, resp2 = yield [http_client.fetch(url1),
                              http_client.fetch(url2)]

    @gen.coroutine
    def parallel_fetch_many(urls):
        responses = yield [http_client.fetch(url) for url in urls]
        # responses is a list of HTTPResponses in the same order

    @gen.coroutine
    def parallel_fetch_dict(urls):
        responses = yield {url: http_client.fetch(url)
                            for url in urls}
        # responses is a dict {url: HTTPResponse}

.. testoutput::
   :hide:

交叉存取技术
^^^^^^^^^^^^

有时保存一个 `.Future` 比立刻yield它更有用, 你可以在等待它之前执行其他操作:

.. testcode::

    @gen.coroutine
    def get(self):
        fetch_future = self.fetch_next_chunk()
        while True:
            chunk = yield fetch_future
            if chunk is None: break
            self.write(chunk)
            fetch_future = self.fetch_next_chunk()
            yield self.flush()

.. testoutput::
   :hide:

循环
^^^^^^^

因为在Python中无法使用 ``for`` 或者 ``while`` 循环 ``yield`` 迭代器,
并且捕获yield的返回结果.  相反, 你需要将循环和访问结果区分开来,
这是一个 `Motor <http://motor.readthedocs.org/en/stable/>`_ 的例子::

    import motor
    db = motor.MotorClient().test

    @gen.coroutine
    def loop_example(collection):
        cursor = db.collection.find()
        while (yield cursor.fetch_next):
            doc = cursor.next_object()

在后台运行
^^^^^^^^^^^^^^^^^^^^^^^^^

`.PeriodicCallback` 和通常的协程不同. 相反, 协程中
通过使用 `tornado.gen.sleep` 可以包含 ``while True:`` 循环::

    @gen.coroutine
    def minute_loop():
        while True:
            yield do_something()
            yield gen.sleep(60)

    # Coroutines that loop forever are generally started with
    # spawn_callback().
    IOLoop.current().spawn_callback(minute_loop)

有时可能会遇到一些复杂的循环. 例如, 上一个循环每 ``60+N`` 秒运行一次, 
其中 ``N`` 时 ``do_something()`` 的耗时.为了精确运行 60 秒,使用上面的交叉模式::

    @gen.coroutine
    def minute_loop2():
        while True:
            nxt = gen.sleep(60)   # Start the clock.
            yield do_something()  # Run while the clock is ticking.
            yield nxt             # Wait for the timer to run out.
