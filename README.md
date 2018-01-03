# ZJRefreshControl

`ios` `下拉刷新` `上拉加载更多` `swift`


## 简介

+ 参照了`ODRefreshControl`，用`swift`写成
+ 添加了`上拉加载更多`  
+ 要使用本效果`swift`必须为`4`

## 效果演示  

![效果演示](https://github.com/psvmc/ZJRefreshControl/raw/master/Images/refresh01.gif)

## 调用方式


```
pod 'ZJRefreshControl',git: 'https://github.com/psvmc/ZJRefreshControl.git'
```

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
    print("-----刷新数据-----");
    self.delay(1.5, closure: {
    	//结束下拉刷新必须调用
      self.refreshControl.endRefreshing();
    });
}
    
//上拉加载更多调用的方法
func dropViewDidBeginLoadmore()->Void{
    print("-----加载数据-----");
    self.delay(1.5, closure: {
    	//结束加载更多必须调用
      self.refreshControl.endLoadingmore();
    });
}
    
//延迟执行方法
func delay(_ delay:Double, closure:@escaping ()->()) {
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
} 
```

（3）注意点  

+ `上拉加载`和`下拉刷新`结束后必须调用相应的`结束方法`

```swift
//结束下拉刷新
self.refreshControl.endRefreshing();
//结束加载更多
self.refreshControl.endLoadingmore();	
```

+ 上面的延迟调用只是模拟数据的请求中消耗的时间，使用时不用该方法
+ 上面示例中的参数中`msgTableView`可以是`UITableview`或者是任何`继承``UIScrollView`的对象实例
+ 不能初始化`refreshControl`多次 会导致显示错误


刷新动画位置不对请用下面方法矫正 负数向上移动 正数向下移动

```swift
refreshControl.setTopOffset(-64);
```
