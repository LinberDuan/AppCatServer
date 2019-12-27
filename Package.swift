//软件包管理
import PackageDescription

let versions = Version(0,0,0)..<Version(10,0,0)
let urls = [
    "https://github.com/PerfectlySoft/Perfect-HTTPServer.git",      //HTTP服务
//    "https://github.com/PerfectlySoft/Perfect-MySQL.git",           //MySQL服务
    "https://github.com/PerfectlySoft/Perfect-Mustache.git",         //Mustache
    "https://github.com/PerfectlySoft/Perfect-Zip.git",
    "https://github.com/PerfectlySoft/Perfect-MySQL.git",
    "https://github.com/SwiftORM/MySQL-StORM",
    "https://github.com/PerfectlySoft/Perfect-INIParser.git",
    "https://github.com/PerfectlySoft/Perfect-Notifications.git",
    "https://github.com/PerfectlySoft/Perfect-Logger.git",
]

let package = Package(
    name: "AppCatServer",
    targets: [],
    dependencies: urls.map { .Package(url: $0, versions: versions) }
)
