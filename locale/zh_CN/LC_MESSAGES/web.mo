��          L               |   ,   }   "  �   0   �     �  �       �  =   {    �      �     �  �   �   Here is a simple "Hello, world" example app: In general, methods on `RequestHandler` and elsewhere in Tornado are not thread-safe. In particular, methods such as `~RequestHandler.write()`, `~RequestHandler.finish()`, and `~RequestHandler.flush()` must only be called from the main thread. If you use multiple threads it is important to use `.IOLoop.add_callback` to transfer control back to the main thread before finishing the request, or to limit your use of other threads to `.IOLoop.run_in_executor` and ensure that your callbacks running in the executor do not refer to Tornado objects. See the :doc:`guide` for additional information. Thread-safety notes ``tornado.web`` provides a simple web framework with asynchronous features that allow it to scale to large numbers of open connections, making it ideal for `long polling <http://en.wikipedia.org/wiki/Push_technology#Long_polling>`_. Project-Id-Version: Tornado release
Report-Msgid-Bugs-To: 
POT-Creation-Date: 2021-06-08 09:51+0800
PO-Revision-Date: YEAR-MO-DA HO:MI+ZONE
Last-Translator: FULL NAME <EMAIL@ADDRESS>
Language: zh_CN
Language-Team: zh_CN <LL@li.org>
Plural-Forms: nplurals=1; plural=0
MIME-Version: 1.0
Content-Type: text/plain; charset=utf-8
Content-Transfer-Encoding: 8bit
Generated-By: Babel 2.9.1
 这里是一个简单的 "Hello, world" 示例应用程序： 通常来讲，Tornado中  `RequestHandler` 或其他位置的一些方法都是非线程安全的。特别需要注意的是 `~RequestHandler.write()`, `~RequestHandler.finish()`, and `~RequestHandler.flush()` 这些方法只能从主线程调用。如果你使用多线程，在完成一个请 求之前使用 `.IOLoop.add_callback` 将控制权传回主线程是非常重要的，或者限制其他线程 使用`.IOLoop.run_in_executor` 并且确保在执行器中你的回调函数不会引用Tornado对象。 更多信息参见 :doc:`guide`  线程安全注意事项 ``tornado.web`` 提供了一个具备允许大量开放链接功能的简单的异步web框架，使得很适合 `long polling <http://en.wikipedia.org/wiki/Push_technology#Long_polling>`_. 