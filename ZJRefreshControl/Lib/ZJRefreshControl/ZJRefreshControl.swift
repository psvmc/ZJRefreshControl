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
    fileprivate var totalViewHeight:CGFloat  =   568;
    fileprivate let showViewHeight:CGFloat   =   44;
    fileprivate let minTopPadding:CGFloat    =   9;
    fileprivate let maxTopPadding:CGFloat    =   5;
    fileprivate let minTopRadius:CGFloat     =   12.5;
    fileprivate let maxTopRadius:CGFloat     =   16;
    fileprivate let minBottomRadius:CGFloat  =   3;
    fileprivate let maxBottomRadius:CGFloat  =   16;
    fileprivate let minBottomPadding:CGFloat =   4;
    fileprivate let maxBottomPadding:CGFloat =   6;
    fileprivate let minArrowSize:CGFloat     =   2;
    fileprivate let maxArrowSize:CGFloat     =   3;
    fileprivate let minArrowRadius:CGFloat   =   5;
    fileprivate let maxArrowRadius :CGFloat  =   7;
    fileprivate let maxDistance:CGFloat      =   53;
    
    fileprivate  var refreshShapeLayer:CAShapeLayer!;
    fileprivate  var refreshArrowLayer:CAShapeLayer!;
    fileprivate  var refreshHighlightLayer:CAShapeLayer!;
    fileprivate  var ignoreInset:Bool = false;
    fileprivate  var ignoreOffset:Bool = false;
    fileprivate  var didSetInset:Bool = false;
    fileprivate  var shapeTintColor:UIColor!;
    
    //记录上次距离底部的距离
    fileprivate var tempBottomSpace:CGFloat = 0;
    //记录连续递减的次数，解决无限加载bug
    fileprivate var tempAdd:CGFloat = 0;
    
    ///上拉多少距离开始加载更多
    internal var loadMoreSpace:CGFloat = 60;
    
    //下拉刷新旋转的样式
    internal var refreshActivity:UIActivityIndicatorView!;
    internal var activityIndicatorViewStyle:UIActivityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray;
    
    fileprivate var refreshing = false;
    fileprivate var scrollView:UIScrollView!;
    fileprivate var originalContentInset:UIEdgeInsets!;
    fileprivate var topOrigin = CGPoint.zero;
    
    //刷新方法
    var refreshBlock:()->() = {};

    //加载更多相关
    fileprivate var loadmoreBlock:()->() = {};
    
    //是否加载更多
    fileprivate var loadmore = false;
    //是否正在加载更多
    fileprivate var loadingmore = false;
    //加载更多旋转的样式
    internal var loadmoreActivity:UIActivityIndicatorView!;
    
    //顶部偏移
    fileprivate var topOffset:CGFloat = 0;
    
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(scrollView:UIScrollView,refreshBlock:@escaping ()->(),loadmoreBlock:@escaping ()->()){
        self.init(scrollView: scrollView,activityIndicatorView:nil,refreshBlock: refreshBlock,loadmoreBlock: loadmoreBlock);
    }
    
    convenience init(scrollView:UIScrollView,refreshBlock:@escaping ()->()){
        self.init(scrollView: scrollView,activityIndicatorView:nil,refreshBlock: refreshBlock,loadmoreBlock: {});
        self.loadmore = false;
    }
    
    init(scrollView:UIScrollView, activityIndicatorView activity:UIView?,refreshBlock:@escaping ()->(),loadmoreBlock:@escaping ()->()){
        totalViewHeight = UIScreen.main.bounds.height;
        self.loadmore = true;
        self.loadmoreBlock = loadmoreBlock;
        let frame = CGRect(x: 0, y: (-totalViewHeight + scrollView.contentInset.top), width: scrollView.frame.size.width, height: totalViewHeight);
        super.init(frame:frame);
        self.backgroundColor = UIColor.clear;
        self.scrollView = scrollView;
        self.originalContentInset = scrollView.contentInset;
        
        //旋转图标
        self.refreshActivity = UIActivityIndicatorView(activityIndicatorStyle: self.activityIndicatorViewStyle);
        self.addSubview(refreshActivity);

        shapeTintColor = UIColor(red: 155.0 / 255.0, green: 162.0 / 255.0, blue: 172.0 / 255.0, alpha: 1.0)
        layerAdd();
        
        //添加观察者
        scrollView.addObserver(self, forKeyPath: "contentOffset", options: NSKeyValueObservingOptions.new, context: nil);
        scrollView.addObserver(self, forKeyPath: "contentInset", options: NSKeyValueObservingOptions.new, context: nil);
        self.refreshBlock = refreshBlock;
        scrollView.addSubview(self);
        //scrollView.sendSubviewToBack(self);
        
        loadmoreViewAdd();
        hideRefreshView();
        //self.backgroundColor = UIColor.blueColor()
    }
    
    //设置顶部偏移量
    func setTopOffset(_ topOffset:CGFloat){
        self.topOffset = topOffset;
        self.frame.origin.y = (-totalViewHeight + self.scrollView.contentInset.top + topOffset);
    }
    
    fileprivate func isCanRefresh() -> Bool{
        if(self.refreshing || self.loadingmore){
            return false;
        }else{
            return true;
        }
    }
    
    
    fileprivate func hideRefreshView(){
        refreshShapeLayer.isHidden = true;
        refreshArrowLayer.isHidden = true;
        refreshHighlightLayer.isHidden = true;
    }
    
    fileprivate func showRefreshView(){
        refreshShapeLayer.isHidden = false;
        refreshArrowLayer.isHidden = false;
        refreshHighlightLayer.isHidden = false;
    }
    
    
    //刷新结束 记得调用该方法
    internal func endRefreshing() -> Void{
        if (self.refreshing) {
            self.refreshing = false;
            let blockScrollView = self.scrollView;
            
            UIView.animate(withDuration: 0.15, animations: {
                self.ignoreInset = true;
                blockScrollView?.contentInset = self.originalContentInset;
                
                }, completion: {
                    (b) -> Void in
                    blockScrollView?.contentInset = self.originalContentInset;
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
    
    fileprivate func delay(_ delay:Double, closure:@escaping ()->()) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
    }
    
    //加载更多视图的添加
    fileprivate func loadmoreViewAdd() -> Void{
        self.loadmoreActivity = UIActivityIndicatorView(activityIndicatorStyle: self.activityIndicatorViewStyle);
        self.loadmoreActivity.frame =  CGRect(x: 0, y: self.scrollView.frame.size.height + 20, width: 36, height: 36);
        self.loadmoreActivity.alpha = 0;
        self.loadmoreActivity.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1);
        self.loadmoreActivity.layer.cornerRadius = 18;
        self.loadmoreActivity.layer.masksToBounds = true;
        self.loadmoreActivity.layer.transform = CATransform3DMakeScale(0, 0, 1);
        self.scrollView.addSubview(self.loadmoreActivity);
        self.scrollView.sendSubview(toBack: self.loadmoreActivity);
        //给加载更多View留位置
        scrollView.contentInset.bottom += 40;
    }
    
    //加载更多显示
    fileprivate func loadmoreShow() -> Void{
        self.loadingmore  =  true;
        let contentSizeHeight = self.scrollView.contentSize.height;
        
        self.loadmoreActivity.center = CGPoint(x: self.scrollView.frame.width/2, y: contentSizeHeight + 20);
        self.loadmoreActivity.startAnimating();
        
        UIView.animate(withDuration: 0.5, animations: {
            self.loadmoreActivity.alpha = 1;
            self.loadmoreActivity.layer.transform = CATransform3DMakeScale(1, 1, 1);
            }, completion: {
                (b) -> Void in
                self.delay(0.5, closure: {
                    self.loadmoreBlock();
                })
        })
    }
    
    //加载更多隐藏
    fileprivate func loadmoreHide() -> Void{
        UIView.animate(withDuration: 0.2, animations: {
            self.loadmoreActivity.alpha = 0;
            self.loadmoreActivity.layer.transform = CATransform3DMakeScale(0.1, 0.1, 1);
            self.scrollView.contentInset.bottom -= self.showViewHeight;
            }, completion: {
                (b) -> Void in
                self.scrollView.contentInset.bottom += self.showViewHeight;
                self.loadmoreActivity.stopAnimating();
        })
    }
    
    
    fileprivate func lerp(_ a:CGFloat,b:CGFloat,p:CGFloat) -> CGFloat{
        return a + (b - a) * p;
    }
    
    //初始化变形气泡
    fileprivate func layerAdd() -> Void{
        refreshShapeLayer = CAShapeLayer(layer: layer);
        refreshArrowLayer = CAShapeLayer(layer: layer);
        refreshShapeLayer.addSublayer(refreshArrowLayer);
        refreshHighlightLayer = CAShapeLayer(layer: layer);
        refreshShapeLayer.addSublayer(refreshHighlightLayer);
        
        refreshShapeLayer.fillColor = shapeTintColor.cgColor;
        refreshShapeLayer.strokeColor = UIColor.darkGray.withAlphaComponent(0.5).cgColor;
        refreshShapeLayer.lineWidth = 0.5;
        refreshShapeLayer.shadowColor = UIColor.black.cgColor;
        refreshShapeLayer.shadowOffset = CGSize(width: 0, height: 1);
        refreshShapeLayer.shadowOpacity = 0.4;
        refreshShapeLayer.shadowRadius = 0.5;
        
        refreshArrowLayer.strokeColor = UIColor.darkGray.withAlphaComponent(0.5).cgColor;
        refreshArrowLayer.lineWidth = 0.5;
        refreshArrowLayer.fillColor = UIColor.white.cgColor;
        refreshHighlightLayer.fillColor = UIColor.white.withAlphaComponent(0.2).cgColor;
        
        self.layer.addSublayer(refreshShapeLayer);
    }
    
    //气泡隐藏
    fileprivate func layerHide() -> Void{
        let transform = CGAffineTransform(translationX: 0,y: 0);
        let pathMorph = CABasicAnimation(keyPath: "path");
        let toPath = CGMutablePath();
        let radius = lerp(minBottomRadius, b: maxBottomRadius, p: 0.2);
        toPath.addArc(center: topOrigin, radius: radius, startAngle: 0, endAngle: CGFloat(Double.pi), clockwise: true, transform: transform);
        let point1 = CGPoint(x: topOrigin.x - radius, y: topOrigin.y);
        toPath.addCurve(to: point1, control1: point1, control2: point1, transform: transform);
        let point2 = CGPoint(x: topOrigin.x + radius, y: topOrigin.y);
        toPath.addArc(center: topOrigin, radius: radius, startAngle: CGFloat(Double.pi), endAngle: 0, clockwise: true, transform: transform)
        toPath.addCurve(to: point2, control1: point2, control2: point2, transform: transform);
        
        toPath.closeSubpath();
        pathMorph.toValue = toPath;
        pathMorph.duration = 0.2;
        pathMorph.fillMode = kCAFillModeForwards;
        pathMorph.isRemovedOnCompletion = false;
        refreshShapeLayer.add(pathMorph, forKey: nil);
        
        let shadowPathMorph = CABasicAnimation(keyPath: "shadowPath");
        shadowPathMorph.duration = 0.2;
        shadowPathMorph.fillMode = kCAFillModeForwards;
        shadowPathMorph.isRemovedOnCompletion = false;
        shadowPathMorph.toValue = toPath;
        refreshShapeLayer.add(shadowPathMorph, forKey: nil);
        
        let alphaAnimation = CABasicAnimation(keyPath: "opacity");
        alphaAnimation.duration = 0.3;
        alphaAnimation.toValue = NSNumber(value: 0 as Float);
        alphaAnimation.fillMode = kCAFillModeForwards;
        alphaAnimation.isRemovedOnCompletion = false;
        refreshArrowLayer.add(alphaAnimation, forKey: nil);
        refreshHighlightLayer.add(alphaAnimation, forKey: nil);
        refreshShapeLayer.add(alphaAnimation, forKey: nil);
    }
    
    //气泡移除
    fileprivate func layerRemove() -> Void{
        refreshArrowLayer.removeFromSuperlayer();
        refreshHighlightLayer.removeFromSuperlayer();
        refreshShapeLayer.removeFromSuperlayer();
        refreshArrowLayer = nil;
        refreshHighlightLayer = nil;
        refreshShapeLayer = nil;
    }
    
    //刷新旋转出现
    fileprivate func refreshActivityShow()->Void{
        self.refreshActivity.center = CGPoint(x: floor(self.frame.size.width / 2), y: 0);
        self.refreshActivity.alpha = 0.0;
        self.refreshActivity.backgroundColor = UIColor.clear;
        CATransaction.begin();
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions);
        self.refreshActivity.layer.transform = CATransform3DMakeScale(0.1, 0.1, 1);
        self.refreshActivity.startAnimating();
        CATransaction.commit();
        
        UIView.animate(withDuration: 0.2, delay: 0.25,
            options: UIViewAnimationOptions.curveLinear,
            animations: {
                self.refreshActivity.alpha = 1;
                self.refreshActivity.layer.transform = CATransform3DMakeScale(1, 1, 1);
            },
            completion: {
                (b)->Void in
                self.delay(0.5, closure: {
                    self.refreshBlock();
                })
                
        });
    }
    
    //刷新旋转消失
    fileprivate func refreshActivityHide()->Void{
        UIView.animate(withDuration: 0.1, delay: 0.15,
            options: UIViewAnimationOptions.curveLinear,
            animations: {
                self.refreshActivity.alpha = 0;
                self.refreshActivity.layer.transform = CATransform3DMakeScale(0.1, 0.1, 1);
                self.refreshActivity.stopAnimating();
            },
            completion: {
                (b)->Void in
                //刷新后滚动到最上面
                let rect = CGRect(x: 0, y: 0, width: self.scrollView.bounds.width, height: 10);
                self.scrollView.scrollRectToVisible(rect, animated: true);
        });
    }
    
    
    
    override var isEnabled: Bool  {
        get {
            return super.isEnabled;
        }
        set {
            super.isEnabled = isEnabled;
            refreshShapeLayer.isHidden = !self.isEnabled;
        }
    }
    
    override var tintColor: UIColor!  {
        get {
            return super.tintColor;
        }
        set {
            shapeTintColor = tintColor;
            refreshShapeLayer.fillColor = shapeTintColor.cgColor;
        }
    }
    
    
    override func willMove(toSuperview newSuperview:UIView?) -> Void{
        super.willMove(toSuperview: newSuperview);
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
    fileprivate func scrollViewSpaceToButtom(_ scrollView: UIScrollView)->CGFloat{
        let offset = scrollView.contentOffset;
        let bounds = scrollView.bounds;
        let size = scrollView.contentSize;
        let inset = scrollView.contentInset;
        let currentOffset = offset.y + bounds.size.height - inset.bottom;
        let maximumOffset = size.height;
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
    override func observeValue(forKeyPath keyPath: String?, of ofObject: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) -> Void{
        
        if ( keyPath == "contentInset" ) {
            if (!ignoreInset) {
                self.originalContentInset = (change![NSKeyValueChangeKey.newKey]! as AnyObject).uiEdgeInsetsValue;
                self.frame.origin.y = (-totalViewHeight + self.scrollView.contentInset.top + topOffset);
            }
            return;
        }
        
        if (!self.isEnabled || self.ignoreOffset) {
            return;
        }
        
        //--------------------------加载更多--------------------------------------------
        if(self.loadmore && (!self.isAnimating())){
            
            let space = self.scrollViewSpaceToButtom(scrollView);
            
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
            }
            
            
        }
        //--------------------------加载更多结束------------------------------------------
        
        //修正autolayout中scrollview宽度的不准确
        self.frame = CGRect(x: 0, y: self.frame.origin.y, width: scrollView.frame.size.width, height: totalViewHeight);

        let offset = (change![NSKeyValueChangeKey.newKey]! as AnyObject).cgPointValue.y + self.originalContentInset.top;
        if(offset == 0){
            self.hideRefreshView();
        }else{
            self.showRefreshView();
        }
        if (refreshing) {
            if (offset != 0) {
                
                ignoreInset = true;
                ignoreOffset = true;
                
                if (offset < 0) {
                    if (offset >= -showViewHeight) {
                        //如果在刷新时上拉，调整scrollview的扩展显示区域
                        self.scrollView.contentInset = UIEdgeInsetsMake(self.originalContentInset.top - offset, self.originalContentInset.left, self.originalContentInset.bottom, self.originalContentInset.right);
                        self.refreshActivity.center = CGPoint(x: floor(self.frame.size.width / 2), y: totalViewHeight - showViewHeight/2 );
                    }
                }
                ignoreInset = false;
                ignoreOffset = false;
            }
            return;
        } else {
            if (!self.isCanRefresh()) {
                if (offset >= 0) {
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
        
        let path = CGMutablePath();
        let transform = CGAffineTransform(translationX: 0,y: 0);
        
        let verticalShift = max(0, -((maxTopRadius + maxBottomRadius + maxTopPadding + maxBottomPadding) + offset));
        let distance = min(maxDistance, fabs(verticalShift));
        let percentage = 1 - (distance / maxDistance);
        
        let currentTopPadding = self.lerp(minTopPadding, b: maxTopPadding, p: percentage);
        let currentTopRadius = lerp(minTopRadius, b: maxTopRadius, p: percentage);
        let currentBottomRadius = lerp(minBottomRadius, b: maxBottomRadius, p: percentage);
        let currentBottomPadding =  lerp(minBottomPadding, b: maxBottomPadding, p: percentage);
        
        var bottomOrigin = CGPoint(x: floor(self.bounds.size.width / 2), y: self.bounds.size.height - currentBottomPadding - currentBottomRadius);
        
        if (distance == 0) {
            topOrigin = CGPoint(x: floor(self.bounds.size.width / 2), y: bottomOrigin.y);
        } else {
            topOrigin = CGPoint(x: floor(self.bounds.size.width / 2), y: self.bounds.size.height + offset + currentTopPadding + currentTopRadius);
            if (percentage == 0) {
                bottomOrigin.y -= (fabs(verticalShift) - maxDistance);
                triggered = true;
            }
        }

        //上半圆 顺时针
        path.addArc(center: topOrigin, radius: currentTopRadius, startAngle: 0, endAngle: CGFloat(Double.pi), clockwise: true, transform: transform);
        
        //左半边的贝塞尔曲线
        let leftCp1 = CGPoint(x: lerp((topOrigin.x - currentTopRadius), b: (bottomOrigin.x - currentBottomRadius), p: 0.1), y: lerp(topOrigin.y, b: bottomOrigin.y, p: 0.2));
        let leftCp2 = CGPoint(x: lerp((topOrigin.x - currentTopRadius), b: (bottomOrigin.x - currentBottomRadius), p: 0.9), y: lerp(topOrigin.y, b: bottomOrigin.y, p: 0.2));
        let leftDestination = CGPoint(x: bottomOrigin.x - currentBottomRadius, y: bottomOrigin.y);
        path.addCurve(to: leftDestination, control1: leftCp1, control2: leftCp2, transform: transform);
        
        //下半圆
        path.addArc(center: bottomOrigin, radius: currentBottomRadius, startAngle: CGFloat(Double.pi), endAngle: 0, clockwise: true, transform: transform);
        
        //右半边的贝塞尔曲线
        let rightCp2 = CGPoint(x: lerp((topOrigin.x + currentTopRadius), b: (bottomOrigin.x + currentBottomRadius), p: 0.1), y: lerp(topOrigin.y, b: bottomOrigin.y, p: 0.2));
        let rightCp1 = CGPoint(x: lerp((topOrigin.x + currentTopRadius), b: (bottomOrigin.x + currentBottomRadius), p: 0.9), y: lerp(topOrigin.y, b: bottomOrigin.y, p: 0.2));
        let rightDestination = CGPoint(x: topOrigin.x + currentTopRadius, y: topOrigin.y);
        path.addCurve(to: rightDestination, control1: rightCp1, control2: rightCp2, transform: transform);
        
        path.closeSubpath();
        if(isAnimating()){
            return;
        }
        if (!triggered) {
            // 拉伸动画
            refreshShapeLayer.path = path;
            
            //圆形箭头
            let currentArrowSize = lerp(minArrowSize, b: maxArrowSize, p: percentage);
            let currentArrowRadius = lerp(minArrowRadius, b: maxArrowRadius, p: percentage);
            let arrowBigRadius = currentArrowRadius + (currentArrowSize / 2);
            let arrowSmallRadius = currentArrowRadius - (currentArrowSize / 2);
            let arrowPath = CGMutablePath();
            arrowPath.addArc(center: topOrigin, radius: arrowBigRadius, startAngle: 0, endAngle: CGFloat(3 * Double.pi / 2), clockwise: false, transform: transform);
            arrowPath.addLine(to: CGPoint(x:topOrigin.x,y:topOrigin.y - arrowBigRadius - currentArrowSize), transform: transform);
            arrowPath.addLine(to: CGPoint(x:topOrigin.x + (2 * currentArrowSize),y:topOrigin.y - arrowBigRadius + (currentArrowSize / 2)), transform: transform);
            arrowPath.addLine(to: CGPoint(x:topOrigin.x,y:topOrigin.y - arrowBigRadius + (2 * currentArrowSize)), transform: transform);
            arrowPath.addLine(to: CGPoint(x:topOrigin.x,y:topOrigin.y - arrowBigRadius + currentArrowSize), transform: transform);
            arrowPath.addArc(center: topOrigin, radius: arrowSmallRadius, startAngle: CGFloat(3 * Double.pi / 2), endAngle: 0, clockwise: true, transform: transform);
            arrowPath.closeSubpath();
            refreshArrowLayer.path = arrowPath;
            refreshArrowLayer.fillRule = kCAFillRuleEvenOdd;
            
            let highlightPath = CGMutablePath();
            highlightPath.addArc(center: topOrigin, radius: currentTopRadius, startAngle: 0, endAngle: CGFloat(Double.pi), clockwise: true, transform: transform);
            highlightPath.addArc(center: CGPoint(x:topOrigin.x,y:topOrigin.y + 1.25), radius: currentTopRadius, startAngle: CGFloat(Double.pi), endAngle: 0, clockwise: false, transform: transform);
            
            refreshHighlightLayer.path = highlightPath;
            refreshHighlightLayer.fillRule = kCAFillRuleNonZero;
        } else {
            //如果没刷新，就进行刷新
            if(!isAnimating()){
                layerHide();
                refreshActivityShow();
                self.refreshing = true;
                
            }
        }
        
    }
}
