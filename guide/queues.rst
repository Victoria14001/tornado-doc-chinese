:class:`~tornado.queues.Queue` 示例 - 一个并发网络爬虫
================================================================

.. currentmodule:: tornado.queues

Tornado 的 `tornado.queues` 模块对于协程实现了异步的 生产者 /
消费者 模型, 实现了类似于 Python 标准库中线程中的 `queue` 模块.

一个协程 yield `Queue.get` 将会在队列中有值时暂停.
如果队列设置了最大值, 协程会 yield `Queue.put` 暂停直到有空间来存放.


`~Queue` 从零开始维护了一系列未完成的任务.
`~Queue.put` 增加计数; `~Queue.task_done` 来减少它.

在这个网络爬虫的例子中, 队列开始仅包含 base_url. 当一个 worker 获取一个页面
他会讲链接解析并将其添加到队列中,
然后调用 `~Queue.task_done` 来减少计数. 最后, 一个
worker 获取到页面的 URLs 都是之前抓取过的, 队列中没有剩余的工作要做. worker
调用 `~Queue.task_done` 将计数减到0 . 主协程中等待 `~Queue.join`, 取消暂停并完成.

.. literalinclude:: ../demos/webspider/webspider.py
