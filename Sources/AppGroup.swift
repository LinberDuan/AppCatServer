//
//  AppGroup.swift
//  AppCatServer
//
//  Created by 段林波 on 2018/12/2.
//

import Foundation
import PerfectLib

open class AppGroup: JSONConvertibleObject {

    var groupId: Int = 0
    var owner: String = ""
    var channel: String = ""
    var bundleId: String = ""
    var creater: String = ""
    var createTime: String = ""
    var editer: String = ""
    var editTime: String = ""
    
    static let registerName = "appGroup"
    
    override open func getJSONValues() -> [String : Any] {
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
    
}
