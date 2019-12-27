//
//  AppItem.swift
//  AppCatServer
//
//  Created by 段林波 on 2018/12/2.
//

import Foundation
import PerfectLib

open class AppItem: JSONConvertibleObject {
    
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
    var describe: String = ""
    var fileHash: String = ""
    var creater: String = ""
    var createTime: String = ""
    var editer: String = ""
    var editTime: String = ""
    var fileSize: Int = 0
    var branch: String = ""
    
    static let registerName = "appItem"
    
    override open func getJSONValues() -> [String : Any] {
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
            "describe": describe,
            "fileHash": fileHash,
            "creater": creater,
            "createTime": createTime,
            "editer": editer,
            "editTime": editTime,
            "fileSize": fileSize,
            "branch": branch,
        ]
    }
    
}
