//
//  AndroidApkPackageManager.swift
//  AppCatServer
//
//  Created by 段林波 on 2019/8/8.
//

import Foundation

import PerfectLib
import PerfectMustache
import PerfectZip
import PerfectMySQL
import PerfectNotifications
import PerfectLogger



open class AndroidApkPackageManager {
    
    var filePath: String
    var ipaFileName: String
    var uuid: String
    var uuidPath: String
    
    var fullSizeImg: String
    var displayImg: String
    var bundleIdentifier: String
    var bundleVersion: String
    var bundleShortVersionString: String
    var bundleName: String
    var bundleDisplayName: String
    
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
        
        ipaFileName = uuid + ".apk"
        
        fullSizeImg = "appicon.png"
        displayImg = "appicon.png"
        
        urlPath = Config.getFilesUrlPortPrefix() + uuidPath
        
        bundleIdentifier = ""
        bundleVersion = ""
        bundleShortVersionString = ""
        bundleName = ""
        bundleDisplayName = ""
        
        appIconUrl = ""
        dowloadUrl = ""
        
        fileSize = 0
        
        channel = "android"
        title = ""
        subTitle = ""
        describe = ""
        buildId = ""
        branch = ""
        createDate = ""
        
    }
    
    func parseParam(tmpFilePath: String) -> Error? {
        
        
        //获取包信息
        
        let cmd = Config.getAAPTPath()
        
        do {
            let output = try runProc(cmd: cmd, args: ["dump", "badging", tmpFilePath], read: true)
            
            let regex = try NSRegularExpression(pattern: "package: name='(\\S+)' versionCode='(\\d+)' versionName='(\\S+)'")
            // 1.3.开始匹配
            let res = regex.matches(in: output ?? "", options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, (output ?? "").count))
            let regex2 = try NSRegularExpression(pattern: "'(\\S+)'")
            
            let str1 = output?.substring(res[0].range.location, length: res[0].range.length) as? String ?? ""
            let res2 = regex2.matches(in: str1 ?? "", options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, (str1 ?? "").count))
            
            let bundleID = str1.substring(res2[0].range.location, length: res2[0].range.length) as? String ?? ""
            let versionCode = str1.substring(res2[1].range.location, length: res2[1].range.length) as? String ?? ""
            let versionName = str1.substring(res2[2].range.location, length: res2[2].range.length) as? String ?? ""
            
            let regex3 = try NSRegularExpression(pattern: "launchable-activity: name='(\\S+)'  label='(\\S+)' icon='(\\S+)'")
            let res3 = regex3.matches(in: output ?? "", options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, (output ?? "").count))
            
            //launchable-activity: name='com.safe.MainActivity'  label='Safe-Dev' icon='res/mipmap-mdpi-v4/safe_dev.png'
            let str2 = output?.substring(res3[0].range.location, length: res3[0].range.length) as? String ?? ""
            
            
            let regex4 = try NSRegularExpression(pattern: "'(\\S+)'")
            
            let res4 = regex4.matches(in: str2 ?? "", options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, (str2 ?? "").count))
            
            
            let label = str2.substring(res4[1].range.location, length: res4[1].range.length) as? String ?? ""
            let icon = str2.substring(res4[2].range.location, length: res4[2].range.length) as? String ?? ""
            
            bundleIdentifier = bundleID.stringByReplacing(string: "'", withString: "")
            bundleVersion = versionCode.stringByReplacing(string: "'", withString: "")
            bundleShortVersionString = versionName.stringByReplacing(string: "'", withString: "")
            bundleDisplayName = label.stringByReplacing(string: "'", withString: "")
            displayImg = icon.stringByReplacing(string: "'", withString: "")
            displayImg = displayImg.stringByReplacing(string: "mdpi", withString: "xxxhdpi")
            
            print("bundleIdentifier:", bundleIdentifier);
            print("bundleVersion:", bundleVersion);
            print("bundleShortVersionString:", bundleShortVersionString);
            print("bundleDisplayName:", bundleDisplayName);
            print("displayImg:", displayImg);
        } catch {
            return error
        }
        
        
        return nil
        
    }
    
    //MARK: apk parse
    public func apkParse(tmpFilePath: String, fileSize: Int, params: Dictionary<String, Any>) -> String? {
        
        self.fileSize = fileSize
        // 创建路径用于存储已上传文件
        do {
            try Dir(filePath).create()
        } catch {
            print(error)
            return error.localizedDescription
        }
        
        
        channel = params["channel"]  as? String ?? "android"
        title = params["title"]  as? String ?? ""
        subTitle = params["subTitle"] as? String ?? ""
        describe = params["describe"] as? String ?? ""
        buildId = params["buildId"] as? String ?? ""
        branch = params["branch"] as? String ?? ""
        
        
        let error = parseParam(tmpFilePath: tmpFilePath)
        
        if( error != nil ) {
            return error?.localizedDescription
        }
        
        
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
            source: tmpFilePath,
            destination: sourceDir,
            overwrite: true
        )
        print("Unzip Result: \(unZipResult.description)")
        
        

        
        // 将图标文件转移到正式目录中，如果目标位置已经有同名文件则进行覆盖操作。
        let imgPath = fileDir.path + displayImg
        let thisFile = File(imgPath)
        if (thisFile.exists) {
            do {
                let _ = try thisFile.moveTo(path: filePath + fullSizeImg,  overWrite: true)
            } catch {
                print(error)
                return error.localizedDescription
            }
        }
        
        
        appIconUrl = urlPath + fullSizeImg;
        let thisApkFile = File(tmpFilePath)
        do {
            let _ = try thisApkFile.moveTo(path: filePath + ipaFileName,  overWrite: true)
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
        
        
        
        dowloadUrl = urlPath + ipaFileName
    
        
        let errMsg = saveToDB()
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
        let querySuccess = mysql.query(statement: "select bundleId from app_group_t where channel = 'android' and bundleId = '\(bundleIdentifier)'")
        
        
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
            values('admin', '\(channel)', '\(bundleIdentifier)', 'admin', '\(stringOfDate)', 'admin', '\(stringOfDate)')
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
        appItem_t.channel = channel
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
        
      
        
        return nil
        
    }
    
    
    
    
}
