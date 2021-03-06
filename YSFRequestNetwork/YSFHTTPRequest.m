//
//  YSFHTTPRequest.m
//  HuiBao
//
//  Created by 玛丽 on 2017/11/22.
//  Copyright © 2017年 玛丽. All rights reserved.
//

#import "YSFHTTPRequest.h"
#import "OpenUDID.h"

@implementation YSFHTTPRequestResult

- (id)initWithJSON:(id)json{
    self = [super init];
    if (self) {
        NSDictionary *dicJson = [json isKindOfClass:[NSDictionary class]]?json:[self returnDictionaryWithData:json];
        self.msg     = [dicJson objectForKey:@"msg"];
        self.status  = [[dicJson objectForKey:@"status"] integerValue];
        self.data    = [dicJson objectForKey:@"data"];
        self.json    = dicJson;
    }
    return self;
}

- (id)objectForKey:(NSString *)key{
    return [self.json objectForKey:key];
}


// NSData转dictonary
-(NSDictionary*)returnDictionaryWithData:(NSData*)data{
    if (data == nil) {
        return @{};
    }
    NSDictionary* myDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    return myDictionary;
}

@end

@implementation YSFHTTPRequest
+ (void)initialize{
#if DEBUG
    //  只有在DEBUG下才会访问内网服务器
//    [YSFNetWorkHelper setDebugProxyHost:@"192.168.0.130" proxyPort:80 baseUrl:BASEAURL];
#endif
}
///** 登录*/
//+ (NSURLSessionTask *)getLoginWithParameters:(id)parameters success:(YSFRequestSuccess)success failure:(YSFRequestFailure)failure
//{
//    return [self requestWithURL:YSFString(@"smb/w_v_l_v2") parameters:parameters success:success failure:failure];
//}
///** 退出*/
//+ (NSURLSessionTask *)getExitWithParameters:(id)parameters success:(YSFRequestSuccess)success failure:(YSFRequestFailure)failure
//{
//    return [self requestWithURL:YSFString(@"smb/w_g_v_c") parameters:parameters success:success failure:failure];
//}
+ (id)cacheWithURL:(NSString *)URL parameters:(NSDictionary *)parameter{
    [self setRequestHeader:parameter];
    URL = [self accessToken:URL param:parameter];
    return  [YSFNetworkCache httpCacheForURL:URL parameters:parameter];
}

#pragma mark - 请求的公共方法
+ (void)setRequestHeader:(NSDictionary *)param {
    [YSFNetWorkHelper setValue:[UIDevice appCurVersion] forHTTPHeaderField:@"versionname"];
    [YSFNetWorkHelper setValue:[NSString stringWithFormat:@"%@",@(WIDTH)] forHTTPHeaderField:@"screen_w"];
    [YSFNetWorkHelper setValue:[NSString stringWithFormat:@"%@",@(HEIGHT)] forHTTPHeaderField:@"screen_h"];
    [YSFNetWorkHelper setValue:@"1" forHTTPHeaderField:@"agent"];
    [YSFNetWorkHelper setValue:[UIDevice phoneVersion] forHTTPHeaderField:@"sys_ver"];
    [YSFNetWorkHelper setValue:[OpenUDID value] forHTTPHeaderField:@"imei"];
    YunShiFinanceLoginInfoModel *loginInfo =  [YunShiFinanceLoginInfoModel sharedLoginInfo];
    if ([loginInfo isExistUserToken])
    {
        //  如果登录了就传登录信息
        [YSFNetWorkHelper setValue:[loginInfo accessToken] forHTTPHeaderField:@"accessToken"];
        
        if (param) {
            if ([param objectForKey:@"userId"] == nil){
                [YSFNetWorkHelper setValue:[NSString stringWithFormat:@"%@",[loginInfo userid]] forHTTPHeaderField:@"userId"];
            }
        }else{
            [YSFNetWorkHelper setValue:[NSString stringWithFormat:@"%@",[loginInfo userid]] forHTTPHeaderField:@"userId"];
        }
    }
}

+ (NSString *)accessToken:(NSString *)URL param:(NSDictionary *)param {
    YunShiFinanceLoginInfoModel *loginInfo =  [YunShiFinanceLoginInfoModel sharedLoginInfo];
    if ([loginInfo isExistUserToken])
    {
        if ([URL containsString:@"accessToken"] == NO && [[param allKeys] containsObject:@"accessToken"] == NO) {
            if ([URL containsString:@"?"]) {
                URL = NSStringFormat(@"%@&accessToken=%@",URL,[loginInfo accessToken]);
            }else{
                URL = NSStringFormat(@"%@?accessToken=%@",URL,[loginInfo accessToken]);
            }
        }
        
        if ([URL containsString:@"userId"] == NO && [[param allKeys] containsObject:@"userId"] == NO) {
            if ([URL containsString:@"?"]) {
                URL = NSStringFormat(@"%@&userId=%@",URL,[loginInfo userid]);
            }else{
                URL = NSStringFormat(@"%@?userId=%@",URL,[loginInfo userid]);
            }
        }
    }
    
    if ([URL containsString:@"appcode"] == NO) {
        if ([URL containsString:@"?"]) {
            URL = NSStringFormat(@"%@&appcode=37eNVhSuL8wsvq8lmLbdpiK5AQeOhjx1",URL);
        }else{
            URL = NSStringFormat(@"%@?appcode=37eNVhSuL8wsvq8lmLbdpiK5AQeOhjx1",URL);
        }
    }
    
    return URL;
}

+ (NSURLSessionTask *)POSTWithURL:(NSString *)URL parameters:(NSDictionary *)parameter success:(YSFRequestSuccessAndCache)success failure:(YSFRequestFailure)failure isResponseCache:(BOOL)isResponseCache {
    // 发起请求
    return [self POSTWithURL:URL  parameters:parameter responseCache:^(YSFHTTPRequestResult *result) {
        isResponseCache?success(result,YES):nil;
    } success:^(YSFHTTPRequestResult *result) {
        success?success(result,NO):nil;
    } failure:^(NSError *error) {
        failure?failure(error):nil;
    }];
}

+ (NSURLSessionTask *)POSTWithURL:(NSString *)URL parameters:(NSDictionary *)parameter success:(YSFRequestSuccess)success failure:(YSFRequestFailure)failure {
    // 发起请求
    return [self POSTWithURL:URL parameters:parameter responseCache:nil success:success failure:^(NSError *error) {
        failure?failure(error):nil;
    }];
}


+ (NSURLSessionTask *)POSTWithURL:(NSString *)URL parameters:(NSDictionary *)parameter responseCache:(YSFRequestSuccess)responseCache success:(YSFRequestSuccess)success failure:(YSFRequestFailure)failure {
    // 在请求之前你可以统一配置你请求的相关参数 ,设置请求头, 请求参数的格式, 返回数据的格式....这样你就不需要每次请求都要设置一遍相关参数
    [YSFNetWorkHelper setRequestTimeoutInterval:8.0];
    [YSFNetWorkHelper openNetworkActivityIndicator:YES];
    [YSFNetWorkHelper setRequestSerializer:YSFRequestSerializerHTTP];
    [YSFNetWorkHelper setResponseSerializer:YSFResponseSerializerHTTP];
    [self setRequestHeader:parameter];
    URL = [self accessToken:URL param:parameter];
    // 发起请求
    return [YSFNetWorkHelper POST:URL parameters:parameter responseCache:^(id responseObject) {
        [YSFNetWorkHelper openNetworkActivityIndicator:NO];
        if ([[parameter allKeys] containsObject:@"page"]) {
            NSInteger page = [parameter[@"page"] integerValue];
            if (page <= 1) {
                responseCache ? responseCache([[YSFHTTPRequestResult alloc] initWithJSON:responseObject]):nil;
            }
        }else{
            responseCache ? responseCache([[YSFHTTPRequestResult alloc] initWithJSON:responseObject]):nil;
        }
    } success:^(id responseObject) {
        // 在这里你可以根据项目自定义其他一些重复操作,比如加载页面时候的等待效果, 提醒弹窗....
        [YSFNetWorkHelper openNetworkActivityIndicator:NO];
        YSFHTTPRequestResult *result = [[YSFHTTPRequestResult alloc] initWithJSON:responseObject];
        success? success(result):nil;
    } failure:^(NSError *error) {
        [self parseError:error];
        // 同上
        [YSFNetWorkHelper openNetworkActivityIndicator:NO];
        failure?failure(error):nil;
    }];
}

+ (NSURLSessionTask *)GETWithURL:(NSString *)URL parameters:(NSDictionary *)parameter success:(YSFRequestSuccessAndCache)success failure:(YSFRequestFailure)failure isResponseCache:(BOOL)isResponseCache {

    // 发起请求
    return [self GETWithURL:URL parameters:parameter responseCache:^(YSFHTTPRequestResult *result) {
        isResponseCache?success(result,YES):nil;
    } success:^(YSFHTTPRequestResult *result) {
        success?success(result,NO):nil;
    } failure:failure];
}

+ (NSURLSessionTask *)GETWithURL:(NSString *)URL parameters:(NSDictionary *)parameter success:(YSFRequestSuccess)success failure:(YSFRequestFailure)failure {

    // 发起请求
    return [self GETWithURL:URL parameters:parameter responseCache:nil success:success failure:failure];
}


+ (NSURLSessionTask *)GETWithURL:(NSString *)URL parameters:(NSDictionary *)parameter responseCache:(YSFRequestSuccess)responseCache success:(YSFRequestSuccess)success failure:(YSFRequestFailure)failure {
    
    // 在请求之前你可以统一配置你请求的相关参数 ,设置请求头, 请求参数的格式, 返回数据的格式....这样你就不需要每次请求都要设置一遍相关参数
    [YSFNetWorkHelper setRequestTimeoutInterval:8.0];
    [YSFNetWorkHelper openNetworkActivityIndicator:YES];
    [YSFNetWorkHelper setRequestSerializer:YSFRequestSerializerHTTP];
    [YSFNetWorkHelper setResponseSerializer:YSFResponseSerializerHTTP];
    [YSFNetWorkHelper openLog];
    [self setRequestHeader:parameter];
    
    URL = [self accessToken:URL param:parameter] ;

    // 发起请求
    return [YSFNetWorkHelper GET:URL parameters:parameter responseCache:^(id responseObject) {
        [YSFNetWorkHelper openNetworkActivityIndicator:NO];
        if ([[parameter allKeys] containsObject:@"page"]) {
            NSInteger page = [parameter[@"page"] integerValue];
            if (page <= 1) {
                responseCache ? responseCache([[YSFHTTPRequestResult alloc] initWithJSON:responseObject]):nil;
            }
        }else{
            responseCache ? responseCache([[YSFHTTPRequestResult alloc] initWithJSON:responseObject]):nil;
        }
        
    } success:^(id responseObject) {
        //请求的头部信息；（我们执行网络请求的时候给服务器发送的包头信息）
       
        // 在这里你可以根据项目自定义其他一些重复操作,比如加载页面时候的等待效果, 提醒弹窗....
        [YSFNetWorkHelper openNetworkActivityIndicator:NO];
        YSFHTTPRequestResult *result = [[YSFHTTPRequestResult alloc] initWithJSON:responseObject];
       
            success? success(result):nil;
    } failure:^(NSError *error) {
        // 同上
        [YSFNetWorkHelper openNetworkActivityIndicator:NO];
        [self parseError:error];
         failure?failure(error):nil;
    }];
}

/**
 上传图片
 
 @param module 模块儿（装修圈：forum，效果图：effect ，头像：avatar， 活动：user_active）
 @param imageArray 图片数组
 @param progressBlock 加载进度的回调
 @param success 成功的回调
 @param failure 失败的回调
 */
+ (void )uploadWithModule:(NSString *)module
                            imageArray:(NSArray<UIImage *> *)imageArray
                              progress:(void (^)(NSProgress *progress,UIImage *image))progressBlock
                               success:(void (^)(NSArray *urls,NSArray *imgs))success
                               failure:(YSFRequestFailure)failure{
    [YSFNetWorkHelper openNetworkActivityIndicator:YES];
    [self setRequestHeader:nil];
    NSMutableDictionary *dict = @{@"module":module?:@"forum",@"maxSize":@(10485760)}.mutableCopy;

    NSMutableArray *temArray = [NSMutableArray array];
    NSMutableArray *temImgArray = [NSMutableArray array];
     for (NSInteger i = 0; i < imageArray.count; i ++) {
        [YSFNetWorkHelper uploadImagesWithURL:module
                                  parameters:dict name:module
                                      images:@[imageArray[i]]
                                   fileNames:nil
                                  imageScale:0.5
                                   imageType:@"png"
                                    progress:^(NSProgress *progress) {
                                       
                                    } success:^(id responseObject) {
                                        YSFHTTPRequestResult *result = [[YSFHTTPRequestResult alloc] initWithJSON:responseObject];
                                        if (result.status == 200) {
                                            NSArray *url = result.data[@"url"];
                                            if (url) {
                                                [temArray addObject:url.firstObject];
                                                [temImgArray addObject:imageArray[i]];
                                                //当所有图片上传成功后再将结果进行回调
                                                if (temArray.count == imageArray.count) {
                                                    success(temArray,temImgArray);
                                                    [YSFNetWorkHelper openNetworkActivityIndicator:NO];
                                                }
                                            }else{
                                                success(temArray,temImgArray);
                                                [YSFNetWorkHelper openNetworkActivityIndicator:NO];
                                            }
                                        }
                                    } failure:^(NSError *error) {
                                        // 同上
                                        [YSFNetWorkHelper openNetworkActivityIndicator:NO];
//                                        [self parseError:error];
                                        failure(error);
                                    }];
    }
}



/**
 下载文件

 @param url 下载链接
 @param fileDir 保存在缓存目录下
 @param progressBlock 下载进度
 @param success 成功后的回调
 @param failure 失败的回调
 */
+ (void)downFileWithUrl:(NSString *)url
                filrDir:(NSString *)fileDir
               progress:(void (^)(NSProgress *progress))progressBlock
                success:(void (^)(NSString *filePath))success
                failure:(YSFRequestFailure)failure{
    NSString *urlStr =  [url containsString:@"http"]?url:BASEAURL_PATH(url);
    [YSFNetWorkHelper downloadWithURL:urlStr fileDir:fileDir progress:progressBlock success:success failure:failure];
}

+ (void)parseError:(NSError *)error{
#ifdef DEBUG
    /*
    NSData * data = error.userInfo[@"com.alamofire.serialization.response.error.data"];
    if (data)
    {
        NSString * str = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        TGWebViewController *web = [[TGWebViewController alloc] init];
        web.attributeStr = str;
        web.webTitle = YSFLocalizedString(@"服务器的错误原因");
        web.progressColor = COLOR_MAIN;
        [([UIApplication sharedApplication].keyWindow.rootViewController) showViewController:web sender:nil];
    }
     */
#else
#endif
}



@end
