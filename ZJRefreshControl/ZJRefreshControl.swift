//
//  ZJRefreshControl.swift
//  ecms_ios
//
//  Created by PSVMC on 15/7/4.
//
//

import UIKit

class ZJRefreshControl: UIControl {
    
    //一些常量
    private let totalViewHeight:CGFloat  =   400;
    private let showViewHeight:CGFloat   =   44;
    private let minTopPadding:CGFloat    =   9;
    private let maxTopPadding:CGFloat    =   5;
    private let minTopRadius:CGFloat     =   12.5;
    private let maxTopRadius:CGFloat     =   16;
    private let minBottomRadius:CGFloat  =   3;
    private let maxBottomRadius:CGFloat  =   16;
    private let minBottomPadding:CGFloat =   4;
    private let maxBottomPadding:CGFloat =   6;
    private let minArrowSize:CGFloat     =   2;
    private let maxArrowSize:CGFloat     =   3;
    private let minArrowRadius:CGFloat   =   5;
    private let maxArrowRadius :CGFloat  =   7;
    private let maxDistance:CGFloat      =   53;
    
    
    private var scrollViewContentInsetTop:CGFloat  = 0;
    
    private  var refreshShapeLayer:CAShapeLayer!;
    private  var refreshArrowLayer:CAShapeLayer!;
    private  var refreshHighlightLayer:CAShapeLayer!;
    private  var canRefresh:Bool = true;
    private  var ignoreInset:Bool = false;
    private  var ignoreOffset:Bool = false;
    private  var didSetInset:Bool = false;
    private  var hasSectionHeaders:Bool = false;
    private  var shapeTintColor:UIColor!;
    
    //记录上次距离底部的距离
    private var tempBottomSpace:CGFloat = 0;
    //记录连续递减的次数，解决无限加载bug
    private var tempAdd:CGFloat = 0;
    
    ///上拉多少距离开始加载更多
    internal var loadMoreSpace:CGFloat = 70;
    
    //旋转的样式
    internal var refreshActivity:UIActivityIndicatorView!;
    internal var activityIndicatorViewStyle:UIActivityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray;
    
    private var refreshing = false;
    private var scrollView:UIScrollView!;
    private var originalContentInset:UIEdgeInsets!;
    private var topOrigin = CGPointZero;
    
    //刷新方法
    var refreshBlock:()->() = {};
    
    
    //加载更多相关
    private var loadmoreBlock:()->() = {};
    
    //是否加载更多
    private var loadmore = false;
    //是否正在加载更多
    private var loadingmore = false;
    internal var loadmoreActivity:UIActivityIndicatorView!;
    
    
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(scrollView:UIScrollView,refreshBlock:()->(),loadmoreBlock:()->()){
        self.init(scrollView: scrollView,activityIndicatorView:nil,refreshBlock: refreshBlock,loadmoreBlock: loadmoreBlock);
    }
    
    convenience init(scrollView:UIScrollView,refreshBlock:()->()){
        self.init(scrollView: scrollView,activityIndicatorView:nil,refreshBlock: refreshBlock,loadmoreBlock: {});
        self.loadmore = false;
    }
    
    init(scrollView:UIScrollView, activityIndicatorView activity:UIView?,refreshBlock:()->(),loadmoreBlock:()->()){
        self.loadmore = true;
        self.loadmoreBlock = loadmoreBlock;
        var frame = CGRectMake(0, (-totalViewHeight + scrollView.contentInset.top), scrollView.frame.size.width, totalViewHeight);
        super.init(frame:frame);
        self.backgroundColor = UIColor.whiteColor();
        self.scrollView = scrollView;
        self.originalContentInset = scrollView.contentInset;
        
        //旋转图标
        self.refreshActivity = UIActivityIndicatorView(activityIndicatorStyle: self.activityIndicatorViewStyle);
        
        
        self.addSubview(refreshActivity);
        self.sendSubviewToBack(refreshActivity);
        
        shapeTintColor = UIColor(red: 155.0 / 255.0, green: 162.0 / 255.0, blue: 172.0 / 255.0, alpha: 1.0)
        
        layerAdd();
        
        //添加观察者
        scrollView.addObserver(self, forKeyPath: "contentOffset", options: NSKeyValueObservingOptions.New, context: nil);
        scrollView.addObserver(self, forKeyPath: "contentInset", options: NSKeyValueObservingOptions.New, context: nil);
        self.refreshBlock = refreshBlock;
        scrollView.addSubview(self);
        loadmoreViewAdd();
        self.scrollViewContentInsetTop = self.scrollView.contentInset.top;
        hideRefreshView();
    }
    
    private func hideRefreshView(){
        refreshShapeLayer.hidden = true;
        refreshArrowLayer.hidden = true;
        refreshHighlightLayer.hidden = true;
    }
    
    private func showRefreshView(){
        refreshShapeLayer.hidden = false;
        refreshArrowLayer.hidden = false;
        refreshHighlightLayer.hidden = false;
    }
    
    
    //刷新结束 记得调用该方法
    internal func endRefreshing() -> Void{
        if (self.refreshing) {
            self.refreshing = false;
            var blockScrollView = self.scrollView;
            
            UIView.animateWithDuration(0.15, animations: {
                self.ignoreInset = true;
                blockScrollView.contentInset = self.originalContentInset;
                
                }, completion: {
                    (b) -> Void in
                    blockScrollView.contentInset = self.originalContentInset;
                    self.ignoreInset = false;
                    self.refreshActivityHide();
                    self.layerRemove();
                    self.layerAdd();
                    self.hideRefreshView();
            })
            
            
        }
    }
    
    //加载结束 记得调用该方法
    internal func endLoadingmore() -> Void{
        self.loadingmore = false;
        self.loadmoreHide();
    }
    
    //加载更多视图的添加
    private func loadmoreViewAdd() -> Void{
        self.loadmoreActivity = UIActivityIndicatorView(activityIndicatorStyle: self.activityIndicatorViewStyle);
        self.loadmoreActivity.frame =  CGRectMake(0, self.scrollView.frame.size.height + 20, self.scrollView.bounds.width, totalViewHeight);
        self.loadmoreActivity.alpha = 0;
        self.loadmoreActivity.layer.transform = CATransform3DMakeScale(0, 0, 1);
        self.scrollView.addSubview(self.loadmoreActivity);
        //给加载更多View留位置
        scrollView.contentInset.bottom += 40;
    }
    
    //加载更多显示
    private func loadmoreShow() -> Void{
        self.loadingmore  =  true;
        var contentSizeHeight = self.scrollView.contentSize.height;
        
        self.loadmoreActivity.center = CGPointMake(self.scrollView.frame.width/2, contentSizeHeight + 20);
        self.loadmoreActivity.startAnimating();
        
        UIView.animateWithDuration(0.5, animations: {
            
            self.loadmoreActivity.alpha = 1;
            self.loadmoreActivity.layer.transform = CATransform3DMakeScale(1, 1, 1);
            }, completion: {
                (b) -> Void in
        })
    }
    
    //加载更多隐藏
    private func loadmoreHide() -> Void{
        UIView.animateWithDuration(0.2, animations: {
            self.loadmoreActivity.alpha = 0;
            self.loadmoreActivity.layer.transform = CATransform3DMakeScale(0.1, 0.1, 1);
            self.scrollView.contentInset.bottom -= self.showViewHeight;
            }, completion: {
                (b) -> Void in
                self.scrollView.contentInset.bottom += self.showViewHeight;
                self.loadmoreActivity.stopAnimating();
        })
    }
    
    
    private func lerp(a:CGFloat,b:CGFloat,p:CGFloat) -> CGFloat{
        return a + (b - a) * p;
    }
    
    //初始化变形气泡
    private func layerAdd() -> Void{
        refreshShapeLayer = CAShapeLayer(layer: layer);
        refreshArrowLayer = CAShapeLayer(layer: layer);
        refreshShapeLayer.addSublayer(refreshArrowLayer);
        refreshHighlightLayer = CAShapeLayer(layer: layer);
        refreshShapeLayer.addSublayer(refreshHighlightLayer);
        
        refreshShapeLayer.fillColor = shapeTintColor.CGColor;
        refreshShapeLayer.strokeColor = UIColor.darkGrayColor().colorWithAlphaComponent(0.5).CGColor;
        refreshShapeLayer.lineWidth = 0.5;
        refreshShapeLayer.shadowColor = UIColor.blackColor().CGColor;
        refreshShapeLayer.shadowOffset = CGSizeMake(0, 1);
        refreshShapeLayer.shadowOpacity = 0.4;
        refreshShapeLayer.shadowRadius = 0.5;
        
        refreshArrowLayer.strokeColor = UIColor.darkGrayColor().colorWithAlphaComponent(0.5).CGColor;
        refreshArrowLayer.lineWidth = 0.5;
        refreshArrowLayer.fillColor = UIColor.whiteColor().CGColor;
        
        refreshHighlightLayer.fillColor = UIColor.whiteColor().colorWithAlphaComponent(0.2).CGColor;
        
        self.layer.addSublayer(refreshShapeLayer);
    }
    
    //气泡隐藏
    private func layerHide() -> Void{
        var pathMorph = CABasicAnimation(keyPath: "path");
        var toPath = CGPathCreateMutable();
        var radius = lerp(minBottomRadius, b: maxBottomRadius, p: 0.2);
        CGPathAddArc(toPath, nil, topOrigin.x, topOrigin.y, radius, 0, CGFloat(M_PI), true);
        CGPathAddCurveToPoint(toPath, nil, topOrigin.x - radius, topOrigin.y, topOrigin.x - radius, topOrigin.y, topOrigin.x - radius, topOrigin.y);
        CGPathAddArc(toPath, nil, topOrigin.x, topOrigin.y, radius, CGFloat(M_PI), 0, true);
        CGPathAddCurveToPoint(toPath, nil, topOrigin.x + radius, topOrigin.y, topOrigin.x + radius, topOrigin.y, topOrigin.x + radius, topOrigin.y);
        CGPathCloseSubpath(toPath);
        pathMorph.toValue = toPath;
        pathMorph.duration = 0.2;
        pathMorph.fillMode = kCAFillModeForwards;
        pathMorph.removedOnCompletion = false;
        refreshShapeLayer.addAnimation(pathMorph, forKey: nil);
        
        var shadowPathMorph = CABasicAnimation(keyPath: "shadowPath");
        shadowPathMorph.duration = 0.2;
        shadowPathMorph.fillMode = kCAFillModeForwards;
        shadowPathMorph.removedOnCompletion = false;
        shadowPathMorph.toValue = toPath;
        refreshShapeLayer.addAnimation(shadowPathMorph, forKey: nil);
        
        var alphaAnimation = CABasicAnimation(keyPath: "opacity");
        alphaAnimation.duration = 0.3;
        alphaAnimation.toValue = NSNumber(float: 0);
        alphaAnimation.fillMode = kCAFillModeForwards;
        alphaAnimation.removedOnCompletion = false;
        refreshArrowLayer.addAnimation(alphaAnimation, forKey: nil);
        refreshHighlightLayer.addAnimation(alphaAnimation, forKey: nil);
        refreshShapeLayer.addAnimation(alphaAnimation, forKey: nil);
    }
    
    //气泡移除
    private func layerRemove() -> Void{
        refreshArrowLayer.removeFromSuperlayer();
        refreshHighlightLayer.removeFromSuperlayer();
        refreshShapeLayer.removeFromSuperlayer();
        refreshArrowLayer = nil;
        refreshHighlightLayer = nil;
        refreshShapeLayer = nil;
    }
    
    //刷新旋转出现
    private func refreshActivityShow()->Void{
        self.refreshActivity.center = CGPointMake(floor(self.frame.size.width / 2), 0);
        self.refreshActivity.alpha = 0.0;
        CATransaction.begin();
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions);
        self.refreshActivity.layer.transform = CATransform3DMakeScale(0.1, 0.1, 1);
        self.refreshActivity.startAnimating();
        CATransaction.commit();
        
        UIView.animateWithDuration(0.2, delay: 0.25,
            options: UIViewAnimationOptions.CurveLinear,
            animations: {
                
                self.refreshActivity.alpha = 1;
                self.refreshActivity.layer.transform = CATransform3DMakeScale(1, 1, 1);
            },
            completion: nil);
    }
    
    //刷新旋转消失
    private func refreshActivityHide()->Void{
        UIView.animateWithDuration(0.1, delay: 0.15,
            options: UIViewAnimationOptions.CurveLinear,
            animations: {
                self.refreshActivity.alpha = 0;
                self.refreshActivity.layer.transform = CATransform3DMakeScale(0.1, 0.1, 1);
                self.refreshActivity.stopAnimating();
            },
            completion: {
                (b)->Void in
                //刷新后滚动到最上面
                var rect = CGRectMake(0, 0, self.scrollView.bounds.width, 10);
                self.scrollView.scrollRectToVisible(rect, animated: true);
        });
        
        
    }
    

    
    override var enabled: Bool  {
        get {
            return super.enabled;
        }
        set {
            super.enabled = enabled;
            refreshShapeLayer.hidden = !self.enabled;
        }
    }
    
    override var tintColor: UIColor!  {
        get {
            return super.tintColor;
        }
        set {
            shapeTintColor = tintColor;
            refreshShapeLayer.fillColor = shapeTintColor.CGColor;
        }
    }
    
    
    override func willMoveToSuperview(newSuperview:UIView?) -> Void{
        super.willMoveToSuperview(newSuperview);
        if (newSuperview == nil) {
            self.scrollView.removeObserver(self, forKeyPath: "contentOffset");
            self.scrollView.removeObserver(self, forKeyPath: "contentInset");
            self.scrollView = nil;
        }
    }
    
    
    func isAnimating() -> Bool {
        return (self.refreshing || self.loadingmore);
    }
    
    //距离scrollView底部的距离
    private func scrollViewSpaceToButtom(scrollView: UIScrollView)->CGFloat{
        var offset = scrollView.contentOffset;
        var bounds = scrollView.bounds;
        var size = scrollView.contentSize;
        var inset = scrollView.contentInset;
        var currentOffset = offset.y + bounds.size.height - inset.bottom;
        var maximumOffset = size.height;
        var space:CGFloat = 0;
        //当currentOffset与maximumOffset的值相等时，说明scrollview已经滑到底部了。也可以根据这两个值的差来让他做点其他的什么事情
        //contentSize>bounds时
        if(bounds.height < size.height){
            space = maximumOffset - currentOffset;
        }else{
            space = -offset.y;
        }
        return space;
    }
    
    //事件
    override func observeValueForKeyPath(keyPath: String, ofObject: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) -> Void{
        
        if ( keyPath == "contentInset" ) {
            if (!ignoreInset) {
                self.originalContentInset = change["new"]!.UIEdgeInsetsValue();
                self.frame.origin.y = (-totalViewHeight + self.scrollView.contentInset.top);
                
            }
            return;
        }
        
        if (!self.enabled || self.ignoreOffset) {
            return;
        }
        
        //--------------------------加载更多--------------------------------------------
        if(self.loadmore && (!self.isAnimating())){
            
            var contentSizeHeight = self.scrollView.contentSize.height;
            var frameHeight = self.scrollView.frame.height;
            var space = self.scrollViewSpaceToButtom(scrollView);
            
            var isCanLoadMore = false;

            if(tempBottomSpace < 0 && space < -loadMoreSpace && tempAdd > 3){
                isCanLoadMore = true;
            }
            if(space < tempBottomSpace){
                tempAdd += 1;
                tempBottomSpace = space;
            }else{
                tempAdd = 0;
                tempBottomSpace = 0;
            }
            
            if(isCanLoadMore){
                
                self.loadingmore = true;
                tempBottomSpace = 0;
                tempAdd = 0;
                loadmoreShow();
                loadmoreBlock();
            }
            
            
        }
        //--------------------------加载更多结束------------------------------------------
        
        var offset = change["new"]!.CGPointValue().y + self.originalContentInset.top;
        if(offset == 0){
            self.hideRefreshView();
        }else{
            self.showRefreshView();
        }
        if (refreshing) {
            if (offset != 0) {
                
                CATransaction.begin();
                CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
                
                self.refreshShapeLayer.position = CGPointMake(0, maxDistance + offset + showViewHeight);
                
                CATransaction.commit();
                
                ignoreInset = true;
                ignoreOffset = true;
                
                if (offset < 0) {
                    if (offset >= -showViewHeight) {
                        //如果在刷新时上拉，调整scrollview的扩展显示区域
                        self.scrollView.contentInset = UIEdgeInsetsMake(self.originalContentInset.top - offset, self.originalContentInset.left, self.originalContentInset.bottom, self.originalContentInset.right);
                        self.refreshActivity.center = CGPointMake(floor(self.frame.size.width / 2), totalViewHeight-showViewHeight+showViewHeight/2);
                        if (!self.scrollView.dragging) {
                            if (!didSetInset) {
                                didSetInset = true;
                                hasSectionHeaders = false;
                                
                                if(self.scrollView.isKindOfClass(UITableView)){
                                    
                                    for (var i = 0; i < (self.scrollView as! UITableView).numberOfSections(); ++i) {
                                        
                                        if ((self.scrollView as! UITableView).rectForHeaderInSection(i).size.height > 0) {
                                            hasSectionHeaders = true;
                                            break;
                                        }
                                    }
                                }
                            }
                            if (hasSectionHeaders) {
                                self.scrollView.contentInset = UIEdgeInsetsMake(min(-offset, showViewHeight)+self.originalContentInset.top, self.originalContentInset.left, self.originalContentInset.bottom, self.originalContentInset.right);
                                
                            } else {
                                self.scrollView.contentInset = UIEdgeInsetsMake(showViewHeight+self.originalContentInset.top, self.originalContentInset.left, self.originalContentInset.bottom, self.originalContentInset.right);
                            }
                        } else if (didSetInset && hasSectionHeaders) {
                            self.scrollView.contentInset = UIEdgeInsetsMake(-offset+self.originalContentInset.top, self.originalContentInset.left, self.originalContentInset.bottom, self.originalContentInset.right);
                        }
                    }
                } else if (hasSectionHeaders) {
                    self.scrollView.contentInset = self.originalContentInset;
                }
                ignoreInset = false;
                ignoreOffset = false;
            }
            return;
        } else {
            if (!canRefresh) {
                if (offset >= 0) {
                    canRefresh = true;
                    didSetInset = false;
                } else {
                    return;
                }
            } else {
                if (offset >= 0) {
                    return;
                }
            }
        }
        
        var triggered = false;
        
        var path = CGPathCreateMutable();
        
        var verticalShift = max(0, -((maxTopRadius + maxBottomRadius + maxTopPadding + maxBottomPadding) + offset));
        var distance = min(maxDistance, fabs(verticalShift));
        var percentage = 1 - (distance / maxDistance);
        
        var currentTopPadding = self.lerp(minTopPadding, b: maxTopPadding, p: percentage);
        var currentTopRadius = lerp(minTopRadius, b: maxTopRadius, p: percentage);
        var currentBottomRadius = lerp(minBottomRadius, b: maxBottomRadius, p: percentage);
        var currentBottomPadding =  lerp(minBottomPadding, b: maxBottomPadding, p: percentage);
        
        var bottomOrigin = CGPointMake(floor(self.bounds.size.width / 2), self.bounds.size.height - currentBottomPadding - currentBottomRadius);
        
        if (distance == 0) {
            topOrigin = CGPointMake(floor(self.bounds.size.width / 2), bottomOrigin.y);
        } else {
            topOrigin = CGPointMake(floor(self.bounds.size.width / 2), self.bounds.size.height + offset + currentTopPadding + currentTopRadius);
            if (percentage == 0) {
                bottomOrigin.y -= (fabs(verticalShift) - maxDistance);
                triggered = true;
            }
        }
        
        
        CGPathAddArc(path, nil, topOrigin.x, topOrigin.y, currentTopRadius, 0, CGFloat(M_PI), true);
        
        
        var leftCp1 = CGPointMake(lerp((topOrigin.x - currentTopRadius), b: (bottomOrigin.x - currentBottomRadius), p: 0.1), lerp(topOrigin.y, b: bottomOrigin.y, p: 0.2));
        var leftCp2 = CGPointMake(lerp((topOrigin.x - currentTopRadius), b: (bottomOrigin.x - currentBottomRadius), p: 0.9), lerp(topOrigin.y, b: bottomOrigin.y, p: 0.2));
        var leftDestination = CGPointMake(bottomOrigin.x - currentBottomRadius, bottomOrigin.y);
        
        CGPathAddCurveToPoint(path, nil, leftCp1.x, leftCp1.y, leftCp2.x, leftCp2.y, leftDestination.x, leftDestination.y);
        
        
        CGPathAddArc(path, nil, bottomOrigin.x, bottomOrigin.y, currentBottomRadius, CGFloat(M_PI), 0, true);
        
        
        var rightCp2 = CGPointMake(lerp((topOrigin.x + currentTopRadius), b: (bottomOrigin.x + currentBottomRadius), p: 0.1), lerp(topOrigin.y, b: bottomOrigin.y, p: 0.2));
        var rightCp1 = CGPointMake(lerp((topOrigin.x + currentTopRadius), b: (bottomOrigin.x + currentBottomRadius), p: 0.9), lerp(topOrigin.y, b: bottomOrigin.y, p: 0.2));
        var rightDestination = CGPointMake(topOrigin.x + currentTopRadius, topOrigin.y);
        
        CGPathAddCurveToPoint(path, nil, rightCp1.x, rightCp1.y, rightCp2.x, rightCp2.y, rightDestination.x, rightDestination.y);
        CGPathCloseSubpath(path);
        if(isAnimating()){
            
            return;
        }
        if (!triggered) {
            // 拉伸动画
            refreshShapeLayer.path = path;
            refreshShapeLayer.shadowPath = path;
            
            var currentArrowSize = lerp(minArrowSize, b: maxArrowSize, p: percentage);
            var currentArrowRadius = lerp(minArrowRadius, b: maxArrowRadius, p: percentage);
            var arrowBigRadius = currentArrowRadius + (currentArrowSize / 2);
            var arrowSmallRadius = currentArrowRadius - (currentArrowSize / 2);
            var arrowPath = CGPathCreateMutable();
            CGPathAddArc(arrowPath, nil, topOrigin.x, topOrigin.y, arrowBigRadius, 0, CGFloat(3 * M_PI_2), false);
            CGPathAddLineToPoint(arrowPath, nil, topOrigin.x, topOrigin.y - arrowBigRadius - currentArrowSize);
            CGPathAddLineToPoint(arrowPath, nil, topOrigin.x + (2 * currentArrowSize), topOrigin.y - arrowBigRadius + (currentArrowSize / 2));
            CGPathAddLineToPoint(arrowPath, nil, topOrigin.x, topOrigin.y - arrowBigRadius + (2 * currentArrowSize));
            CGPathAddLineToPoint(arrowPath, nil, topOrigin.x, topOrigin.y - arrowBigRadius + currentArrowSize);
            CGPathAddArc(arrowPath, nil, topOrigin.x, topOrigin.y, arrowSmallRadius, CGFloat(3 * M_PI_2), 0, true);
            CGPathCloseSubpath(arrowPath);
            refreshArrowLayer.path = arrowPath;
            refreshArrowLayer.fillRule = kCAFillRuleEvenOdd;
            
            var highlightPath = CGPathCreateMutable();
            CGPathAddArc(highlightPath, nil, topOrigin.x, topOrigin.y, currentTopRadius, 0, CGFloat(M_PI), true);
            CGPathAddArc(highlightPath, nil, topOrigin.x, topOrigin.y + 1.25, currentTopRadius, CGFloat(M_PI), 0, false);
            
            refreshHighlightLayer.path = highlightPath;
            refreshHighlightLayer.fillRule = kCAFillRuleNonZero;
            
            
        } else {
            //如果没刷新，就进行刷新
            if(!isAnimating()){
                
                layerHide();
                refreshActivityShow();
                
                self.refreshing = true;
                
                self.canRefresh = false;
                
                self.refreshBlock();
            }
        }
        
    }
    
    
}
