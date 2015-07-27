# ZJRefreshControl
ios 下拉刷新 上拉加载更多 swift

####简介
本组件效果参照了ODRefreshControl，用swift写成，添加了上拉加载更多  
要使用本效果`swift`必须为`1.2`
####效果演示  
![效果演示](https://github.com/psvmc/ZJRefreshControl/raw/master/Images/refresh01.gif)
####调用方式
（1）定义全局对象变量

```swift
	var refreshControl:ZJRefreshControl!;
```

（2）初始化

```swift

	//只有下拉刷新
	refreshControl = ZJRefreshControl(scrollView: appTableView, refreshBlock: {
            self.dropViewDidBeginRefreshing()
	})
	
	//下拉刷新和上拉加载更多
	refreshControl = ZJRefreshControl(scrollView: msgTableView,refreshBlock: {
                self.dropViewDidBeginRefreshing();
            },loadmoreBlock: {
                self.dropViewDidBeginLoadmore();
	});
	
	//下拉刷新调用的方法
	func dropViewDidBeginRefreshing()->Void{
        println("-----刷新数据-----");
        self.delay(1.5, closure: {
        	//结束下拉刷新必须调用
          self.refreshControl.endRefreshing();
        });
    }
    
    //上拉加载更多调用的方法
    func dropViewDidBeginLoadmore()->Void{
        println("-----加载数据-----");
        self.delay(1.5, closure: {
        	//结束加载更多必须调用
          self.refreshControl.endLoadingmore();
        });
    }
    
    //延迟执行方法
	func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
    
```

（3）注意点  

+ 上拉加载和下拉刷新结束后必须调用响应的结束方法
+ 上面的延迟调用只是模拟数据的请求中消耗的时间，使用时不用该方法

