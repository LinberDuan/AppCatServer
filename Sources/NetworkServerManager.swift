//
//  NetworkServerManager.swift
//  AppCat
//
//  Created by 段林波 on 2018/11/28.
//

import PerfectLib
import PerfectHTTP
import PerfectHTTPServer
import PerfectNet
import PerfectMustache
import PerfectZip
import minizip

open class NetworkServerManager {
    
    fileprivate var routes: Routes
    internal init() {
        routes = Routes()
        configureRoutes(routes: &routes)
        
    }
    
    public func startServer() {
        
        do {
            print("启动HTTP服务")
            try HTTPServer.launch(name: Config.getHost(),
                                  port: Config.getPort(),
                                  routes: routes,
                                  responseFilters: [(Filter404(), .high)])
        } catch PerfectError.networkError(let err, let msg) {
            print("网络出现错误:\(err) \(msg)")
        } catch {
            print("网络未知错误:\(error)")
        }
    }
    
    //MARK: 注册路由
    fileprivate func configureRoutes(routes: inout Routes) {
        // 添加接口，请求方式，路径
        
        routes.add(method: .get, uri: "/", handler: handler)
        routes.add(method: .get, uri: "/upload", handler: handler)
        routes.add(method: .post, uri: "/api/upload", handler: apiUploadHandle)
        routes.add(method: .post, uri: "/api/getAppGroup", handler: getAppGroupHandle)
        routes.add(method: .post, uri: "/api/getAppList", handler: getAppListHandle)
        routes.add(method: .post, uri: "/api/pushToken", handler: apiPushToken)
        //        routes.add(method: .get, uri: "/api/**", handler: apiHandle)
        routes.add(method: .post, uri: "/api/**", handler: apiHandle)
        routes.add(method: .get, uri: "/**",
                   handler: pageFileHandle)
    }
    
    
    //MARK: 默认handler
    func handler(request: HTTPRequest, response: HTTPResponse) {
        
        // Respond with a simple message.
        response.setHeader(.contentType, value: "text/html; charset=utf-8")
        response.appendBody(string:"""
                <form
                    method="POST"
                    enctype="multipart/form-data"
                    action="/api/upload">
                    文件:
                    <input type="file" name="filetoupload">
                    <br>
                    标题: <input type="text" name="title">
                    <br>
                    副标题: <input type="text" name="subTitle">
                    <br>
                    更新说明: <input type="text" name="describe">
                    <br>
                    buildId: <input type="text" value="1" name="buildId">
                    <br>
                    channel:
                        <select name="channel">
                            <option value="ios">IOS</option>
                            <option value="android">Android</option>
                        </select>
                    <br>
                    
                    <input type="submit">
                </form>
            """)
        // Ensure that response.completed() is called when your processing is done.
        response.completed()
    }
    
    //MARK: api 接口handler
    func apiHandle(request: HTTPRequest, response: HTTPResponse)  {
        
        
        //    print("request path:\(request.pathComponents)")
        print("request.param:\(request.params())")
        
        let params = request.params()
        if (params.count > 0) {
            
            let reqJson0 = params[0].0
            
            do {
                let reqObj0 = try reqJson0.jsonDecode() as? [String:Any]
                print("reqObj0:\(reqJson0)")
            } catch {
                
            }
            
            
            
        }
        
        if let acceptEncoding = request.header(.acceptEncoding) {
            print("acceptEncoding:\(acceptEncoding)")
        }
        
        if let v1 = request.param(name: "k1") {
            print("v1:\(v1)")
        }
        
        response.setHeader(.contentType, value: "text/json")
        response.appendBody(string: baseResponseBodyJSONData())
        // Ensure that response.completed() is called when your processing is done.
        response.completed()
    }
    
    
    //MARK: 文件上传
    func apiUploadHandle(request: HTTPRequest, response: HTTPResponse)  {
        
        response.setHeader(.contentType, value: "text/json")
        
        let channel = request.param(name: "channel") ?? ""
        let title = request.param(name: "title") ?? ""
        let subTitle = request.param(name: "subTitle") ?? ""
        let describe = request.param(name: "describe") ?? ""
        let buildId = request.param(name: "buildId") ?? ""
        let branch = request.param(name: "branch") ?? ""
        
        // 通过操作fileUploads数组来掌握文件上传的情况
        // 如果这个POST请求不是分段multi-part类型，则该数组内容为空
        
        if let uploads = request.postFileUploads, uploads.count > 0 {
            // 创建一个字典数组用于检查已经上载的内容
            var ary = [[String:Any]]()
            var values = Dictionary<String, Any>()
            
            var params = Dictionary<String, Any>()
            params["channel"] = channel
            params["title"] = title
            params["subTitle"] = subTitle
            params["describe"] = describe
            params["buildId"] = buildId
            params["branch"] = branch
            
            for upload in uploads {
                ary.append([
                    "fieldName": upload.fieldName,  //字段名
                    "contentType": upload.contentType, //文件内容类型
                    "fileName": upload.fileName,    //文件名
                    "fileSize": upload.fileSize,    //文件尺寸
                    "tmpFileName": upload.tmpFileName   //上载后的临时文件名
                    ])
                
                //                 将文件转移走，如果目标位置已经有同名文件则进行覆盖操作。
                let thisFile = File(upload.tmpFileName)
                do {
                    let tmpIpaPath = Config.getTmpDir() + upload.fileName
                    let _ = try thisFile.moveTo(path: tmpIpaPath, overWrite: true)
                    
                    if("ios" == channel) {
                        let ios = IOSIpaPackageManager()
                        
                        let errMsg = ios.ipaParse(tmpIpaPath: tmpIpaPath, fileSize: upload.fileSize, params: params)
                        
                        if( errMsg != nil) {
                            response.appendBody(string: baseResponseBodyJSONData(resp: false, message: errMsg!))
                            response.completed(status: .internalServerError)
                            return
                        }
                        
                        response.appendBody(string: baseResponseBodyJSONData(resp: true, message: "success", data: ["dowloadUrl": ios.dowloadUrl ]))
                        
                    }
                    else if("android" == channel) {
                        let android = AndroidApkPackageManager()
                        
                        let errMsg = android.apkParse(tmpFilePath: tmpIpaPath, fileSize: upload.fileSize, params: params)
                        
                        if( errMsg != nil) {
                            response.appendBody(string: baseResponseBodyJSONData(resp: false, message: errMsg!))
                            response.completed(status: .internalServerError)
                            return
                        }
                        
                        response.appendBody(string: baseResponseBodyJSONData(resp: true, message: "success", data: ["dowloadUrl": android.dowloadUrl ]))
                    }
                    
                    
                   
                    response.completed()
                    return
                    //
                    
                } catch {
                    print(error)
                    response.appendBody(string: baseResponseBodyJSONData(resp: false, message: error.localizedDescription))
                    response.completed(status: .internalServerError)
                    return
                }
            }
            values["files"] = ary
            values["count"] = ary.count
        }
        else {
            
            response.appendBody(string: baseResponseBodyJSONData(resp: false, message: "no files found"))
            response.completed(status: .internalServerError)
            
            return
        }
        
    }
    
    //MARK: 获取AppGroup List
    func getAppGroupHandle(request: HTTPRequest, response: HTTPResponse)  {
        
        response.setHeader(.contentType, value: "text/json")
        let channel = request.param(name: "channel") ?? "ios"
        var data = [Any]()
        //        if(channel == "ios") {
        //            data = IOSIpaPackageManager.getAppGroup()
        //        }
        data = IOSIpaPackageManager.getAppGroup(channel: channel)
        response.appendBody(string: baseResponseBodyJSONData(data: data))
        // Ensure that response.completed() is called when your processing is done.
        response.completed()
        
    }
    
    //MARK: 获取AppList
    func getAppListHandle(request: HTTPRequest, response: HTTPResponse)  {
        
        response.setHeader(.contentType, value: "text/json")
        let channel = request.param(name: "channel") ?? "ios"
        let bundleId = request.param(name: "bundleId") ?? ""
        var data = [Any]()
        //        if(channel == "ios") {
        //            data = IOSIpaPackageManager.getAppList(bundleId: bundleId)
        //        }
        data = IOSIpaPackageManager.getAppList(channel: channel, bundleId: bundleId)
        response.appendBody(string: baseResponseBodyJSONData(data: data))
        // Ensure that response.completed() is called when your processing is done.
        response.completed()
        
    }
    
    func apiPushToken(request: HTTPRequest, response: HTTPResponse) {
        response.setHeader(.contentType, value: "text/json")
        
        let channel = request.param(name: "channel")
        let token = request.param(name: "token") ?? ""
        var params = Dictionary<String, Any>()
        params["channel"] = channel
        params["token"] = token
        //        if(channel == "ios") {
        //            data = IOSIpaPackageManager.getAppList(bundleId: bundleId)
        //        }
        let errMsg = IOSIpaPackageManager.savePushToken(params: params)
        if( errMsg != nil) {
            response.appendBody(string: baseResponseBodyJSONData(resp: false, message: errMsg!))
            response.completed(status: .internalServerError)
            return
        }
        
        response.appendBody(string: baseResponseBodyJSONData(resp: true, message: "success"))
        response.completed()
        return
        
    }
    
    //MARK: 页面文件
    func pageFileHandle(request: HTTPRequest, response: HTTPResponse)  {
        
        StaticFileHandler(documentRoot: Config.getWebRoot(), allowResponseFilters: true).handleRequest(request: request, response: response)
    }
    
    
    //MARK: 404过滤
    struct Filter404: HTTPResponseFilter {
        func filterBody(response: HTTPResponse, callback: (HTTPResponseFilterResult) -> ()) {
            callback(.continue)
        }
        
        func filterHeaders(response: HTTPResponse, callback: (HTTPResponseFilterResult) -> ()) {
            if case .notFound = response.status {
                response.bodyBytes.removeAll()
                response.setBody(string: "The file \(response.request.path) was not found.")
                response.setHeader(.contentLength, value: "\(response.bodyBytes.count)")
                callback(.done)
            } else {
                callback(.continue)
            }
        }
    }
    
    
    
    //MARK: 通用响应格式
    func baseResponseBodyJSONData(resp: Bool = true, message: String = "", data: Any! = "") -> String {
        var result = Dictionary<String, Any>()
        result.updateValue(resp, forKey: "result")
        result.updateValue(message, forKey: "message")
        if (data != nil) {
            result.updateValue(data, forKey: "data")
        } else {
            result.updateValue("", forKey: "data")
        }
        guard let jsonString = try? result.jsonEncodedString() else {
            return ""
        }
        return jsonString
    }
    
    
}
