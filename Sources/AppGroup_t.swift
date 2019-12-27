//
//  AppGroup_t.swift
//  AppCatServer
//
//  Created by 段林波 on 2018/12/12.
//

import PerfectLib
import Foundation
import StORM
import MySQLStORM

class AppGroup_t: MySQLStORM {
    
    var groupId: Int = 0
    var owner: String = ""
    var channel: String = ""
    var bundleId: String = ""
    var creater: String = ""
    var createTime: String = ""
    var editer: String = ""
    var editTime: String = ""
    
    
    override open func table() -> String {
        return "app_group_t"
    }
    
    override func to(_ this: StORMRow) {
        
        groupId   =   Int(this.data["groupId"] as! Int32)
        if let o = this.data["owner"] {
            owner = o as! String
        }
        if let o = this.data["channel"] {
            channel = o as! String
        }
        if let o = this.data["bundleId"] {
            bundleId = o as! String
        }
        if let o = this.data["creater"] {
            creater = o as! String
        }
        if let o = this.data["createTime"] {
            createTime = o as! String
        }
        if let o = this.data["editer"] {
            editer = o as! String
        }
        if let o = this.data["editTime"] {
            editTime = o as! String
        }
    }
    
    func rows() -> [AppGroup_t] {
        var rows = [AppGroup_t]()
        for i in 0..<self.results.rows.count {
            let row = AppGroup_t()
            row.to(self.results.rows[i])
            rows.append(row)
        }
        return rows
    }
    
    open func getJSONValues() -> [String : Any] {
        return [
            //            JSONDecoding.objectIdentifierKey:AppGroup.registerName,
            "groupId":groupId,
            "owner":owner,
            "channel":channel,
            "bundleId": bundleId,
            "creater": creater,
            "createTime": createTime,
            "editer": editer,
            "editTime": editTime,
        ]
    }
    //    override func makeRow() {
    //        self.to(self.results.rows[0])
    //    }
}
