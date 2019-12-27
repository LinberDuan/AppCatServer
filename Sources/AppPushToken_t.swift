//
//  AppPushToken_t.swift
//  AppCatServer
//
//  Created by inVault on 2018/12/12.
//

import PerfectLib
import Foundation
import StORM
import MySQLStORM

class AppPushToken_t: MySQLStORM {
    
    var id: Int = 0
    var owner: String = ""
    var channel: String = ""
    var token: String = ""
    var creater: String = ""
    var createTime: String = ""
    var editer: String = ""
    var editTime: String = ""
    
    
    override open func table() -> String {
        return "app_pushToken_t"
    }
    
    override func to(_ this: StORMRow) {
        
        id   =   Int(this.data["id"] as! Int32)
        if let o = this.data["owner"] {
            owner = o as! String
        }
        if let o = this.data["channel"] {
            channel = o as! String
        }
        if let o = this.data["token"] {
            token = o as! String
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
    
    func rows() -> [AppPushToken_t] {
        var rows = [AppPushToken_t]()
        for i in 0..<self.results.rows.count {
            let row = AppPushToken_t()
            row.to(self.results.rows[i])
            rows.append(row)
        }
        return rows
    }
    //    override func makeRow() {
    //        self.to(self.results.rows[0])
    //    }
}

