//
//  AppItem_t.swift
//  AppCatServer
//
//  Created by 段林波 on 2018/12/12.
//

import PerfectLib
import Foundation
import StORM
import MySQLStORM


class AppItem_t: MySQLStORM {
    
    var appId: Int = 0
    var owner: String = ""
    var channel: String = ""
    var bundleId: String = ""
    var downloadUrl: String = ""
    var appIconUrl: String = ""
    var version: String = ""
    var buildVersion: String = ""
    var title: String = ""
    var subTitle: String = ""
    var des: String = ""
    var fileHash: String = ""
    var creater: String = ""
    var createTime: String = ""
    var editer: String = ""
    var editTime: String = ""
    var fileSize: Int = 0
    var branch: String = ""
    
    
    override open func table() -> String {
        return "app_list_t"
    }
    
    override func to(_ this: StORMRow) {
        
        appId   =   Int(this.data["appId"] as! Int32)
        fileSize   =   Int(this.data["fileSize"] as! Int32)
        if let o = this.data["owner"] {
            owner = o as! String
        }
        if let o = this.data["channel"] {
            channel = o as! String
        }
        if let o = this.data["bundleId"] {
            bundleId = o as! String
        }
        if let o = this.data["downloadUrl"] {
            downloadUrl = o as! String
        }
        if let o = this.data["appIconUrl"] {
            appIconUrl = o as! String
        }
        if let o = this.data["version"] {
            version = o as! String
        }
        if let o = this.data["buildVersion"] {
            buildVersion = o as! String
        }
        if let o = this.data["title"] {
            title = o as! String
        }
        if let o = this.data["subTitle"] {
            subTitle = o as! String
        }
        if let o = this.data["des"] {
            des = o as! String
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
        if let o = this.data["branch"] {
            branch = o as! String
        }
    }
    
    func rows() -> [AppItem_t] {
        var rows = [AppItem_t]()
        for i in 0..<self.results.rows.count {
            let row = AppItem_t()
            row.to(self.results.rows[i])
            rows.append(row)
        }
        return rows
    }
    
    open func getJSONValues() -> [String : Any] {
        return [
            JSONDecoding.objectIdentifierKey:AppGroup.registerName,
            "appId":appId,
            "owner":owner,
            "channel":channel,
            "bundleId": bundleId,
            "downloadUrl": downloadUrl,
            "appIconUrl": appIconUrl,
            "version": version,
            "buildVersion": buildVersion,
            "title": title,
            "subTitle": subTitle,
            "describe": des,
            "fileHash": fileHash,
            "creater": creater,
            "createTime": createTime,
            "editer": editer,
            "editTime": editTime,
            "fileSize": fileSize,
            "branch": branch,
        ]
    }
    //    override func makeRow() {
    //        self.to(self.results.rows[0])
    //    }
}
