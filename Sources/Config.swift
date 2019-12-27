//
//  Config.swift
//  AppCatServer
//
//  Created by 段林波 on 2018/12/3.
//

import INIParser
import PerfectLib


/*
 ${HOME}/.AppCatServer/config.ini
 [Server]
 host = 127.0.0.1
 port = 8989
 protocolPrefix = http://
 
 MySql
 dbHost = 127.0.0.1
 dbUser = root
 dbPwd = root
 dbName = appcat
 
 Dir
 worDir = /Users/AppCat/AppCat/
 webRoot = /Users/AppCat/AppCat/webroot/
 tmpDir = /Users/AppCat/AppCat/tmp/
 filesDir = /Users/AppCat/AppCat/webroot/files/
 */


open class Config {
    
    fileprivate static var host = "127.0.0.1"
    fileprivate static var port = 8989
    fileprivate static var protocolPrefix = "http://"
    fileprivate static var dbHost = "127.0.0.1"
    fileprivate static var dbUser = "root"
    fileprivate static var dbPwd = "root"
    fileprivate static var dbName = "appcat"
    fileprivate static var workDir = Dir.workingDir.path
    fileprivate static var webRoot = Dir.workingDir.path + "webroot/"
    fileprivate static var tmpDir = Dir.workingDir.path + "tmp/"
    fileprivate static var filesDir = webRoot + "files/"
    fileprivate static var aaptPath = ""
    
    static func load() -> Any? {
        do {
            let ini = try INIParser("/Users/duanlinbo/.AppCatServer/config.ini")
            host = ini.sections["Server"]?["host"] ?? "127.0.0.1"
            port = Int(ini.sections["Server"]?["port"] ?? "") ?? 8989
            protocolPrefix = ini.sections["Server"]?["protocolPrefix"] ?? "http://"
            dbHost = ini.sections["MySql"]?["dbHost"] ?? "127.0.0.1"
            dbUser = ini.sections["MySql"]?["dbUser"] ?? "root"
            dbPwd = ini.sections["MySql"]?["dbPwd"] ?? "root"
            dbName = ini.sections["MySql"]?["dbName"] ?? "appcat"
            workDir = ini.sections["Dir"]?["worDir"] ?? Dir.workingDir.path
            webRoot = ini.sections["Dir"]?["webRoot"] ?? Dir.workingDir.path + "webroot/"
            tmpDir = ini.sections["Dir"]?["tmpDir"] ?? Dir.workingDir.path + "tmp/"
            filesDir = ini.sections["Dir"]?["filesDir"] ?? webRoot + "files/"
            aaptPath = ini.sections["Dir"]?["aaptPath"] ?? ""
            
            do {
                try Dir(workDir).create()
                try Dir(webRoot).create()
                try Dir(tmpDir).create()
                try Dir(filesDir).create()
            } catch {
                print("create Dir Err:\(error)")
                return error
            }
            
            
            print("WorkDir:\(workDir)")
            
            return nil
        } catch {
            print("Config.load Err:\(error)")
            return error
        }
    }
    
    static func getHost() -> String {
        return host
    }
    
    static func getPort() -> Int {
        return port
    }
    
    static func getProtocolPrefix() -> String {
        return protocolPrefix
    }
    
    static func getHostAddress() -> String {
        return protocolPrefix + host
    }
    
    
    static func getDBHost() -> String {
        return dbHost
    }
    
    static func getDBUser() -> String {
        return dbUser
    }
    
    static func getDBPwd() -> String {
        return dbPwd
    }
    
    static func getDBName() -> String {
        return dbName
    }
    
    static func getWorkDir() -> String {
        return workDir
    }
    
    static func getWebRoot() -> String {
        return webRoot
    }
    
    static func getTmpDir() -> String {
        return tmpDir
    }
    
    static func getFilesDir() -> String {
        return filesDir
    }
    
    static func getFilesUrlPrefix() -> String {
        return getHostAddress() + "/files/"
    }
    
    static func getFilesUrlPortPrefix() -> String {
        return getHostAddress() + ":" + String(getPort()) + "/files/"
    }
    
    static func getAAPTPath() -> String {
        return aaptPath
    }
}
