//
//  IOSIpaPackageManager.swift
//  AppCatServer
//
//  Created by 段林波 on 2018/11/30.
//

import Foundation

import PerfectLib
import PerfectMustache
import PerfectZip
import PerfectMySQL
import PerfectNotifications
import PerfectLogger


open class IOSIpaPackageManager {
    
    var filePath: String
    var ipaFileName: String
    var plistFileName: String
    var uuid: String
    var uuidPath: String
    
    var fullSizeImg: String
    var displayImg: String
    var bundleIdentifier: String
    var bundleVersion: String
    var bundleShortVersionString: String
    var bundleName: String
    var bundleDisplayName: String
    
    var plistUrl: String
    var appIconUrl: String
    var dowloadUrl: String
    
    var urlPath: String
    
    var fileSize: Int
    
    var channel: String
    var title: String
    var subTitle: String
    var describe: String
    var buildId: String
    var branch: String
    
    var createDate: String
    
    internal init() {
        
        
        uuid = Foundation.UUID().uuidString.stringByReplacing(string: "-", withString: "")
        
        uuidPath = uuid + "/"
        
        filePath = Config.getFilesDir() + uuidPath;
        
        ipaFileName = uuid + ".ipa"
        plistFileName = uuid + ".plist"
        
        fullSizeImg = "appicon.png"
        displayImg = "appicon.png"
        
        urlPath = Config.getFilesUrlPrefix() + uuidPath
        
        bundleIdentifier = ""
        bundleVersion = ""
        bundleShortVersionString = ""
        bundleName = ""
        bundleDisplayName = ""
        
        plistUrl = ""
        appIconUrl = ""
        dowloadUrl = ""
        
        fileSize = 0
        
        channel = "ios"
        title = ""
        subTitle = ""
        describe = ""
        buildId = ""
        branch = ""
        createDate = ""
        
    }
    
    //MARK: generate plist
    func generatePlistFile() -> String? {
        
        let d1 = [
            "ipaUrl" : urlPath + ipaFileName,
            "fullSizeImgUrl" : urlPath + fullSizeImg,
            "displayImgUrl" : urlPath + displayImg,
            "bundleIdentifier" : bundleIdentifier,
            "bundleVersion" : bundleVersion,
            "title" : bundleDisplayName
            ] as [String:Any]
        let context = MustacheEvaluationContext(templateContent: iosTemplatesPlist, map: d1)
        let collector = MustacheEvaluationOutputCollector()
        do {
            let responseString = try context.formulateResponse(withCollector: collector)
            
            let thisFile = File(filePath + plistFileName)
            try thisFile.open(.readWrite)
            try thisFile.write(string: responseString)
            thisFile.close()
            
        } catch {
            print("createPlistFile Error:\(error)")
            return error.localizedDescription
        }
        
        plistUrl = urlPath + plistFileName
        
        dowloadUrl = "itms-services://?action=download-manifest&url=" + plistUrl
        
        return nil
    }
    
    
    
    //MARK: ipa parse
    public func ipaParse(tmpIpaPath: String, fileSize: Int, params: Dictionary<String, Any>) -> String? {
        
        
        self.fileSize = fileSize
        // 创建路径用于存储已上传文件
        do {
            try Dir(filePath).create()
        } catch {
            print(error)
            return error.localizedDescription
        }
        
        
        channel = params["channel"]  as? String ?? "ios"
        title = params["title"]  as? String ?? ""
        subTitle = params["subTitle"] as? String ?? ""
        describe = params["describe"] as? String ?? ""
        buildId = params["buildId"] as? String ?? ""
        branch = params["branch"] as? String ?? ""
        
        let zippy = Zip()
        
        var fileTitle = ""
        
        let sourceDir = Config.getTmpDir() + uuid
        
        // 创建路径用于解压路径
        let fileDir = Dir(sourceDir)
        do {
            try fileDir.create()
        } catch {
            print(error)
            return error.localizedDescription
        }
        
        let unZipResult = zippy.unzipFile(
            source: tmpIpaPath,
            destination: sourceDir,
            overwrite: true
        )
        print("Unzip Result: \(unZipResult.description)")
        
        func closure(file: String) {
            fileTitle = file
        }
        
        let fileDir2 = Dir(sourceDir + "/Payload")
        do {
            try fileDir2.forEachEntry(closure: closure)
        } catch {
            print(error)
            return error.localizedDescription
        }
        
        
        //读取plist文件
        
        let plist = NSDictionary(contentsOfFile: fileDir.path + "Payload/" + fileTitle + "Info.plist")
        
        bundleIdentifier = plist?.value(forKey: "CFBundleIdentifier") as! String
        bundleVersion = buildId ?? (plist?.value(forKey: "CFBundleVersion") as! String)
        bundleShortVersionString = plist?.value(forKey: "CFBundleShortVersionString") as! String
        bundleName = plist?.value(forKey: "CFBundleName") as! String
        bundleDisplayName = plist?.value(forKey: "CFBundleDisplayName") as? String ?? bundleName
        
        
        var iconName = ""
        
        if let t = plist?.value(forKeyPath: "CFBundleIcons.CFBundlePrimaryIcon.CFBundleIconFiles") {
            iconName = (t as! Array).last  ?? "AppIcon60x60" as String
            
        }
        
        
        // 将文件转移到正式目录中，如果目标位置已经有同名文件则进行覆盖操作。
        let imgPath = fileDir.path + "Payload/" + fileTitle + iconName + "@3x.png"
        let thisFile = File(imgPath)
        if (thisFile.exists) {
            do {
                let _ = try thisFile.moveTo(path: filePath + fullSizeImg,  overWrite: true)
            } catch {
                print(error)
                return error.localizedDescription
            }
        }
        
        print("filePath:\(filePath)")
        
        appIconUrl = urlPath + fullSizeImg;
        
        let thisIpaFile = File(tmpIpaPath)
        do {
            let _ = try thisIpaFile.moveTo(path: filePath + ipaFileName,  overWrite: true)
        } catch {
            print(error)
            return error.localizedDescription
        }
        
        //删除解压后文件及目录
        do {
            try FileManager.default.removeItem(atPath: sourceDir)
        } catch {
            print(error)
            return error.localizedDescription
        }
        
        var errMsg = generatePlistFile()
        if(errMsg != nil) {
            
            return errMsg
        }
        
        
        errMsg = saveToDB()
        if(errMsg != nil) {
            //数据存储出错，回滚删除文件
            do {
                try FileManager.default.removeItem(atPath: filePath)
            } catch {
                print(error)
                return error.localizedDescription
            }
            return errMsg
        }
        
        //处理成功
        //推送消息
        pushMsg()
        
        return nil
    }
    
    public func pushMsg() -> String? {
        
        let notificationsAppId = "cn.linber.ios.AppCat"
        
        var errMsg: String
        
        let mysql = MySQL()
        let connected = mysql.connect(host: Config.getDBHost(),
                                      user: Config.getDBUser(),
                                      password: Config.getDBPwd(),
                                      db: Config.getDBName())
        
        guard connected else {
            // 验证一下连接是否成功
            errMsg = mysql.errorMessage()
            print(errMsg)
            LogFile.error(errMsg)
            
            return errMsg
        }
        
        // 运行查询（比如返回在options数据表中的所有数据行）
        let querySuccess = mysql.query(statement: "select token from app_pushToken_t where channel = 'ios'")
        
        // 确保查询完成
        guard querySuccess else {
            errMsg = mysql.errorMessage()
            print(errMsg)
            LogFile.error(errMsg)
            
            return errMsg
        }
        
        // 在当前会话过程中保存查询结果
        let results = mysql.storeResults()! //因为上一步已经验证查询是成功的，因此这里我们认为结果记录集可以强制转换为期望的数据结果。当然您如果需要也可以用if-let来调整这一段代码。
        
        if ( results.numRows() > 0 ) {
            
            var tokenList: Array<String> = Array()
            
            results.forEachRow { row in
                tokenList.append(row[0] ?? "")
            }
            
            let pushBody = """
            \(subTitle)
            版本: \(bundleVersion) (build: \(bundleShortVersionString))  更新时间: \(createDate)
            """
            let n = NotificationPusher(apnsTopic: notificationsAppId)
            n.pushAPNS(
                configurationName: notificationsAppId,
                deviceTokens: tokenList,
                notificationItems: [.alertTitle("\(title) - 发版提示"), .alertBody(pushBody), .sound("newPackge.wav"), .contentAvailable]) {
                    responses in
                    LogFile.info("pushAPNS\(responses)")
                    print("pushAPNS\(responses)")
            }
        }
        
        return nil
        
    }
    
    public func saveToDB() -> String? {
        
        var errMsg: String
        
        let mysql = MySQL()
        let connected = mysql.connect(host: Config.getDBHost(),
                                      user: Config.getDBUser(),
                                      password: Config.getDBPwd(),
                                      db: Config.getDBName())
        
        guard connected else {
            // 验证一下连接是否成功
            errMsg = mysql.errorMessage()
            print(errMsg)
            
            return errMsg
        }
        
        // 运行查询（比如返回在options数据表中的所有数据行）
        let querySuccess = mysql.query(statement: "select bundleId from app_group_t where channel = 'ios' and bundleId = '\(bundleIdentifier)'")
        
        
        print("querySuccess:\(querySuccess)")
        
        // 确保查询完成
        guard querySuccess else {
            errMsg = mysql.errorMessage()
            print(errMsg)
            
            return errMsg
        }
        
        // 在当前会话过程中保存查询结果
        let results = mysql.storeResults()! //因为上一步已经验证查询是成功的，因此这里我们认为结果记录集可以强制转换为期望的数据结果。当然您如果需要也可以用if-let来调整这一段代码。
        
        let dateFormate = DateFormatter()
        dateFormate.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let date = Date()
        let stringOfDate = dateFormate.string(from: date)
        
        createDate = stringOfDate
        
        print(stringOfDate)
        
        
        
        if ( results.numRows() <= 0 ) {
            //未上传过新增一条
            let insertSql = """
            insert into app_group_t(owner, channel, bundleId, creater, createTime, editer, editTime)
            values('admin', 'ios', '\(bundleIdentifier)', 'admin', '\(stringOfDate)', 'admin', '\(stringOfDate)')
            """
            
            
            print("insertSql:\(insertSql)")
            
            let insertQuerySuccess = mysql.query(statement: insertSql)
            
            guard querySuccess else {
                errMsg = mysql.errorMessage()
                print(errMsg)
                
                return errMsg
            }
            
        }
        
                
        let appItem_t = AppItem_t()
        
        appItem_t.owner = "admin"
        appItem_t.channel = "ios"
        appItem_t.bundleId = bundleIdentifier
        appItem_t.downloadUrl = dowloadUrl
        appItem_t.appIconUrl = appIconUrl
        appItem_t.version = bundleShortVersionString
        appItem_t.buildVersion = bundleVersion
        appItem_t.title = title
        appItem_t.subTitle = subTitle
        appItem_t.des = describe
        appItem_t.creater = "admin"
        appItem_t.createTime = stringOfDate
        appItem_t.editer = "admin"
        appItem_t.editTime = stringOfDate
        appItem_t.fileSize = fileSize
        appItem_t.branch = branch
        do {
            try appItem_t.save()
            
        } catch {
            print(error)
            return error.localizedDescription
        }
        
//
////        未上传过新增一条
//        let insertListSql = """
//        insert into app_list_t(
//        `owner`, channel, bundleId, downloadUrl, appIconUrl,
//        version, buildVersion, title, subTitle, `describe`,
//        creater, createTime, editer, editTime, fileSize, branch)
//        values(
//        'admin', 'ios', '\(bundleIdentifier)', '\(dowloadUrl)', '\(appIconUrl)', '\(bundleShortVersionString)',
//        '\(bundleVersion)', '\(title)', '\(subTitle)', '\(describe)',
//        'admin', '\(stringOfDate)', 'admin', '\(stringOfDate)', \(fileSize), '\(branch)')
//        """
//
//        print("insertListSql:\(insertListSql)")
//        let insertQuerySuccess = mysql.query(statement: insertListSql)
//
//        guard insertQuerySuccess else {
//            errMsg = mysql.errorMessage()
//            print(errMsg)
//
//            return errMsg
//        }
//
//
//        defer {
//            //这个延后操作能够保证在程序结束时无论什么结果都会自动关闭数据库连接
//            mysql.close()
//        }
////
        
        return nil
        
    }
    
    
    static func getAppGroup(channel:String) -> Array<Any> {
//
//        let appGroup_t = AppGroup_t()
//
//
//
//        do {
//            let sql = "SELECT * FROM app_group_t"
//
//            print("sql:\(sql)")
//            try appGroup_t.sql(sql, params: [])
////            try appGroup_t.sql(whereclause: sql, params: [], orderby: ["editTime DESC", "groupId DESC"])
//
//            var appGroups: Array<Any> = Array()
//            appGroup_t.rows().forEach { (appGroup) in
//
//                print("appGroup")
//                var appGroupDic = appGroup.getJSONValues()
//                //获取最近一条list记录
//                let appList = getAppList(bundleId: appGroup.bundleId, limit: 1)
//                var appJson = [String : Any]()
//                if(appList.count>0) {
//                    appJson = appList[0] as! [String : Any]
//                }
//
//                appGroupDic.updateValue(appJson, forKey: "app")
//
//                appGroups.append(appGroupDic)
//            }
//
//            print("appGroups:\(appGroups)")
//
//            return appGroups
//        }
//        catch {
//            print("getAppGroup:\(error)")
//            return []
//        }
//
        
        let mysql = MySQL()
        let connected = mysql.connect(host: Config.getDBHost(),
                                      user: Config.getDBUser(),
                                      password: Config.getDBPwd(),
                                      db: Config.getDBName())

        guard connected else {
            // 验证一下连接是否成功
            print(mysql.errorMessage())
            return []
        }

        // 运行查询（比如返回在options数据表中的所有数据行）
        let querySuccess = mysql.query(statement: "select * from app_group_t where channel = '\(channel)' order by editTime desc, groupId desc limit 500")

        // 确保查询完成
        guard querySuccess else {
            print(mysql.errorMessage())
            return []
        }

        // 在当前会话过程中保存查询结果
        let results = mysql.storeResults()! //因为上一步已经验证查询是成功的，因此这里我们认为结果记录集可以强制转换为期望的数据结果。当然您如果需要也可以用if-let来调整这一段代码。

        if ( results.numRows() > 0 ) {

            var appGroups: Array<Any> = Array()

            results.forEachRow { row in

                let appGroup = AppGroup()
                appGroup.groupId = Int(row[0] ?? "") ?? 0
                appGroup.owner = row[1] ?? ""
                appGroup.channel = row[2] ?? ""
                appGroup.bundleId = row[3] ?? ""
                appGroup.creater = row[4] ?? ""
                appGroup.createTime = row[5] ?? ""
                appGroup.editer = row[6] ?? ""
                appGroup.editTime = row[7] ?? ""

                //获取最近一条list记录
                let appList = getAppList(channel: channel, bundleId: appGroup.bundleId, limit: 1)
                var appJson = [String : Any]()
                if(appList.count>0) {
                    appJson = appList[0] as! [String : Any]
                }

                var appGroupDic = appGroup.getJSONValues()
                appGroupDic.updateValue(appJson, forKey: "app")

                appGroups.append(appGroupDic)

            }

            return appGroups


        }
        
        return []
        
    }
    
    static func getAppList(channel: String, bundleId: String, limit: Int = 500) -> Array<Any> {
        
//        let appItem_t = AppItem_t()
//
//        do {
//            let sql = "select * from app_list_t where channel = 'ios' and bundleId=? order by editTime desc, appId desc limit  \(limit)"
//            try appItem_t.select(whereclause:sql , params: [bundleId], orderby: [])
//            var AppList: Array<Any> = Array()
//            appItem_t.rows().forEach { (appItem) in
//                AppList.append(appItem.getJSONValues())
//            }
//
//            return AppList
//        }
//        catch {
//            print("getAppList:\(error)")
//            return []
//        }
        
        let mysql = MySQL()
        let connected = mysql.connect(host: Config.getDBHost(),
                                      user: Config.getDBUser(),
                                      password: Config.getDBPwd(),
                                      db: Config.getDBName())

        guard connected else {
            // 验证一下连接是否成功
            print(mysql.errorMessage())
            return []
        }

        // 运行查询（比如返回在options数据表中的所有数据行）
        let querySuccess = mysql.query(statement: "select * from app_list_t where channel = '\(channel)' and bundleId='\(bundleId)' order by editTime desc, appId desc limit  \(limit)")

        // 确保查询完成
        guard querySuccess else {
            print(mysql.errorMessage())
            return []
        }

        // 在当前会话过程中保存查询结果
        let results = mysql.storeResults()! //因为上一步已经验证查询是成功的，因此这里我们认为结果记录集可以强制转换为期望的数据结果。当然您如果需要也可以用if-let来调整这一段代码。

        if ( results.numRows() > 0 ) {

            var AppList: Array<Any> = Array()

            results.forEachRow { row in

                let appItem = AppItem()
                appItem.appId = Int(row[0] ?? "") ?? 0
                appItem.owner = row[1] ?? ""
                appItem.channel = row[2] ?? ""
                appItem.bundleId = row[3] ?? ""
                appItem.downloadUrl = row[4] ?? ""
                appItem.appIconUrl = row[5] ?? ""
                appItem.version = row[6] ?? ""
                appItem.buildVersion = row[7] ?? ""
                appItem.title = row[8] ?? ""
                appItem.subTitle = row[9] ?? ""
                appItem.describe = row[10] ?? ""
                appItem.fileSize = Int(row[11] ?? "") ?? 0
                appItem.fileHash = row[12] ?? ""

                appItem.creater = row[13] ?? ""
                appItem.createTime = row[14] ?? ""
                appItem.editer = row[15] ?? ""
                appItem.editTime = row[16] ?? ""
                appItem.branch = row[17] ?? ""

                AppList.append(appItem.getJSONValues())

            }

            return AppList


        }
        
        return []
        
    }
    
    static func savePushToken(params: Dictionary<String, Any>) -> String? {
        let mysql = MySQL()
        let connected = mysql.connect(host: Config.getDBHost(),
                                      user: Config.getDBUser(),
                                      password: Config.getDBPwd(),
                                      db: Config.getDBName())
        
        guard connected else {
            // 验证一下连接是否成功
            print(mysql.errorMessage())
            return mysql.errorMessage()
        }
        
        let token = params["token"] as? String ?? ""
        
        let querySuccess = mysql.query(statement: "select `token` from app_pushToken_t where channel = 'ios' and `token` = '\(token)'")
        
        // 确保查询完成
        guard querySuccess else {
            
            return mysql.errorMessage()
        }
        
        // 在当前会话过程中保存查询结果
        let results = mysql.storeResults()! //因为上一步已经验证查询是成功的，因此这里我们认为结果记录集可以强制转换为期望的数据结果。当然您如果需要也可以用if-let来调整这一段代码。
        
        let dateFormate = DateFormatter()
        dateFormate.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let date = Date()
        let stringOfDate = dateFormate.string(from: date)
        print(stringOfDate)
        
        
        if ( results.numRows() <= 0 ) {
            let insertListSql = """
            insert into app_pushToken_t(
            `owner`, channel, `token`,creater, createTime, editer, editTime)
            values(
            'admin', 'ios', '\(token)', 'admin', '\(stringOfDate)', 'admin', '\(stringOfDate)')
            """
            
            let insertQuerySuccess = mysql.query(statement: insertListSql)
            
            guard insertQuerySuccess else {
                
                return mysql.errorMessage()
            }
        }
        
        
        return nil
        
    }
    
}



let iosTemplatesPlist = """
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
<key>items</key>
<array>
<dict>
<key>assets</key>
<array>
<dict>
<key>kind</key>
<string>software-package</string>
<key>url</key>
<string>{{ipaUrl}}</string>
</dict>
<dict>
<key>kind</key>
<string>full-size-image</string>
<key>needs-shine</key>
<true/>
<key>url</key>
<string>{{fullSizeImgUrl}}</string>
</dict>
<dict>
<key>kind</key>
<string>display-image</string>
<key>needs-shine</key>
<true/>
<key>url</key>
<string>{{displayImgUrl}}</string>
</dict>
</array>
<key>metadata</key>
<dict>
<key>bundle-identifier</key>
<string>{{bundleIdentifier}}</string>
<key>bundle-version</key>
<string>{{bundleVersion}}</string>
<key>kind</key>
<string>software</string>
<key>title</key>
<string>{{title}}</string>
</dict>
</dict>
</array>
</dict>
</plist>
"""
