import PerfectLib
import PerfectHTTP
import PerfectHTTPServer
import PerfectNet
import PerfectNotifications
import MySQLStORM
import PerfectLogger
import Foundation

Config.load()

LogFile.location = "/var/log/appcatserver.log"

LogFile.info("AppCatServer Start")


func runProc(cmd: String, args: [String], read: Bool = false) throws -> String? {
    let envs = [("PATH", "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin")]
    let proc = try SysProcess(cmd, args: args, env: envs)
    var ret: String?
    if read {
        var ary = [UInt8]()
        while true {
            do {
                guard let s = try proc.stdout?.readSomeBytes(count: 1024), s.count > 0 else {
                    break
                }
                ary.append(contentsOf: s)
            } catch PerfectLib.PerfectError.fileError(let code, _) {
                if code != EINTR {
                    break
                }
            }
        }
        ret = UTF8Encoding.encode(bytes: ary)
    }
    let res = try proc.wait(hang: true)
    if res != 0 {
        let s = try proc.stderr?.readString()
        throw  PerfectError.systemError(Int32(res), s!)
    }
    return ret
}


// 应用程序名称，我们用这个名称来配置，但是不一定非得是这个形式
let notificationsAppId = "cn.linber.ios.AppCat"

let apnsTeamIdentifier = "XRH73YGX7V"
let apnsKeyIdentifier = "C3MJQM9GBT"
let apnsPrivateKey = Config.getWorkDir() +  "AuthKey_C3MJQM9GBT.p8"

let thisFile = File(apnsPrivateKey)
if (!thisFile.exists) {
    print("推送证书不存在:\(apnsPrivateKey)")
    LogFile.error("推送证书不存在:\(apnsPrivateKey)")
}

NotificationPusher.addConfigurationAPNS(name: notificationsAppId,
                                        production: false,
                                        keyId: apnsKeyIdentifier,
                                        teamId: apnsTeamIdentifier,
                                        privateKeyPath: apnsPrivateKey)

MySQLConnector.host        = Config.getDBHost()
MySQLConnector.username    = Config.getDBUser()
MySQLConnector.password    = Config.getDBPwd()
MySQLConnector.database    = Config.getDBName()
MySQLConnector.port        = 3306
MySQLConnector.method = .network
MySQLConnector.charset = "utf8"

let networkServer = NetworkServerManager()
networkServer.startServer()

//
//
//let thisFile = File(Dir.workingDir.path + "files/"+"helloWorld.txt")
//try thisFile.open(.readWrite)
//try thisFile.write(string: "Hello, World!2")
//thisFile.close()
//
