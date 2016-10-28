//
//  ViewController.swift
//  ZJRefreshControl
//
//  Created by 张剑 on 2016/10/28.
//  Copyright © 2016年 张剑. All rights reserved.
//

import UIKit

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    var tableData:[[[String:String]]] = [[]];
    
    var refreshControl:ZJRefreshControl!;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UINib.init(nibName: "IndexTableViewCell", bundle: nil), forCellReuseIdentifier: "IndexTableViewCell");
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        initData();
        initRefresh();
    }
    
    func initData(){
        self.tableData[0].removeAll();
        self.tableData[0].append(["name":"张三"]);
        self.tableData[0].append(["name":"李四"]);
        self.tableData[0].append(["name":"王五"]);
        self.tableData[0].append(["name":"赵六"]);
        self.tableView.reloadData();
    }
    
    func initRefresh(){
        refreshControl = ZJRefreshControl(scrollView: tableView,refreshBlock: {
            self.dropViewDidBeginRefreshing();
            },loadmoreBlock: {
                self.dropViewDidBeginLoadmore();
        });
    }
    
    func delay(_ delay:Double, closure:@escaping ()->()) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
    }
    
    //下拉刷新调用的方法
    func dropViewDidBeginRefreshing()->Void{
        print("-----刷新数据-----");
        self.initData();
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.tableData.count;
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableData[section].count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let itemData  = self.tableData[indexPath.section][indexPath.row];
        let  cell = tableView.dequeueReusableCell(withIdentifier: "IndexTableViewCell", for: indexPath) as! IndexTableViewCell;
        cell.nameLabel.text = itemData["name"];
        return cell;
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40;
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if(section == 0){
            return 0.01;
        }else{
            return 20;
        }
    }

}

