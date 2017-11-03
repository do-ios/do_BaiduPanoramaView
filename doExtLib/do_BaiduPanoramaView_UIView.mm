//
//  do_BaiduPanoramaView_View.m
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_BaiduPanoramaView_UIView.h"

#import "doInvokeResult.h"
#import "doUIModuleHelper.h"
#import "doScriptEngineHelper.h"
#import "doIScriptEngine.h"
#import "doServiceContainer.h"
#import "doIModuleExtManage.h"
#import "BaiduPanoSDK.framework/Headers/BaiduPanoramaView.h"
#import "doJsonHelper.h"
#import "doIOHelper.h"
#import "doIPage.h"

@interface do_BaiduPanoramaView_UIView()<BaiduPanoramaViewDelegate>
@property (nonatomic,strong) NSMutableArray *markerIDs;
@end

@implementation do_BaiduPanoramaView_UIView
{
    BaiduPanoramaView *panoramaView;
    NSMutableArray *markInfos;
}
#pragma mark - doIUIModuleView协议方法（必须）
//引用Model对象
- (void) LoadView: (doUIModule *) _doUIModule
{
    _model = (typeof(_model)) _doUIModule;
    NSString *_BMKMapKey = [[doServiceContainer Instance].ModuleExtManage GetThirdAppKey:@"baiduPanorama.plist" :@"baiduPanoramaAppKey" ];
    CGRect frame = CGRectMake(0, 0, _model.RealWidth, _model.RealHeight);
    BaiduPanoramaView *panorama = [[BaiduPanoramaView alloc]initWithFrame:frame key:_BMKMapKey];
    //防止闪退
    [NSThread sleepForTimeInterval:2];
    panoramaView = panorama;
    panorama.delegate = self;
    [self addSubview:panorama];

    self.markerIDs = [NSMutableArray array];
    markInfos = [NSMutableArray array];
}
//销毁所有的全局对象
- (void) OnDispose
{
    //自定义的全局属性,view-model(UIModel)类销毁时会递归调用<子view-model(UIModel)>的该方法，将上层的引用切断。所以如果self类有非原生扩展，需主动调用view-model(UIModel)的该方法。(App || Page)-->强引用-->view-model(UIModel)-->强引用-->view
    [panoramaView removeFromSuperview];
    panoramaView.delegate = nil;
    panoramaView = nil;
    self.markerIDs = nil;
    [markInfos removeAllObjects];
    markInfos = nil;
}
//实现布局
- (void) OnRedraw
{
    //实现布局相关的修改,如果添加了非原生的view需要主动调用该view的OnRedraw，递归完成布局。view(OnRedraw)<显示布局>-->调用-->view-model(UIModel)<OnRedraw>
    
    //重新调整视图的x,y,w,h
    [doUIModuleHelper OnRedraw:_model];
    panoramaView.frame = CGRectMake(0, 0, _model.RealWidth, _model.RealHeight);
}

#pragma mark - TYPEID_IView协议方法（必须）
#pragma mark - Changed_属性
/*
 如果在Model及父类中注册过 "属性"，可用这种方法获取
 NSString *属性名 = [(doUIModule *)_model GetPropertyValue:@"属性名"];
 
 获取属性最初的默认值
 NSString *属性名 = [(doUIModule *)_model GetProperty:@"属性名"].DefaultValue;
 */
- (void)change_imageLevel:(NSString *)newValue
{
    //自己的代码实现
    ImageDefinition imageLevel;
    int level = [newValue intValue];
    if (level < 1) {
        imageLevel = ImageDefinitionLow;
    }
    else if (level > 3)
    {
        imageLevel = ImageDefinitionHigh;
    }
    else
    {
        imageLevel = ImageDefinitionMiddle;
    }
    [panoramaView setPanoramaImageLevel:imageLevel];
}
- (void)change_zoomLevel:(NSString *)newValue
{
    //自己的代码实现
    int level = [newValue intValue];
    if (level < 1) {
        level = 1;
    }
    else if(level > 5)
    {
        level = 5;
    }
    [panoramaView setPanoramaZoomLevel:level];
}

#pragma mark -
#pragma mark - 同步异步方法的实现
//同步
- (void)addImageMarkers:(NSArray *)parms
{
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    //参数字典_dictParas
    doInvokeResult *_invokeResult = [parms objectAtIndex:2];
    //自己的代码实现
    @try {
        NSArray *nodes = [doJsonHelper GetOneArray:_dictParas :@"data"];
        [markInfos addObjectsFromArray:nodes];
        NSString *filePath;
        for (NSDictionary *node in nodes)
        {
            NSString *ID = [doJsonHelper GetOneText:node :@"id" :@""];
            NSString *latitude = [doJsonHelper GetOneText:node :@"latitude" :@""];
            NSString *longitude = [doJsonHelper GetOneText:node :@"longitude" :@""];
            NSString *url = [doJsonHelper GetOneText:node :@"url" :@""];
            filePath  = [doIOHelper GetLocalFileFullPath:_model.CurrentPage.CurrentApp :url];
            UIImage *image = [UIImage imageNamed:filePath];
            BaiduPanoImageOverlay *imageOverlay = [[BaiduPanoImageOverlay alloc] init];
            imageOverlay.overlayKey = ID;
            [self.markerIDs addObject:ID];
            imageOverlay.coordinate = CLLocationCoordinate2DMake([latitude floatValue], [longitude floatValue]);
            imageOverlay.height = 1;//单位为 m
            imageOverlay.size = CGSizeMake(image.size.width + 4, image.size.height + 4);
            imageOverlay.image = image;
            [panoramaView addOverlay:imageOverlay];
            
        }
        [_invokeResult SetResultBoolean:YES];

    }
    @catch (NSException *exception) {
        [_invokeResult SetResultBoolean:NO];
    }
}
- (void)addTextMarkers:(NSArray *)parms
{
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    doInvokeResult *_invokeResult = [parms objectAtIndex:2];
    //参数字典_dictParas
    @try {
        UIColor *color;
        NSArray *nodes = [doJsonHelper GetOneArray:_dictParas :@"data"];
        [markInfos addObjectsFromArray:nodes];
        for (NSDictionary *node in nodes)
        {
            NSString *ID = [doJsonHelper GetOneText:node :@"id" :@""];
            NSString *latitude = [doJsonHelper GetOneText:node :@"latitude" :@""];
            NSString *longitude = [doJsonHelper GetOneText:node :@"longitude" :@""];
            NSString *text = [doJsonHelper GetOneText:node :@"text" :@""];
            NSString *fontColor = [doJsonHelper GetOneText:node :@"fontColor" :@""];
            NSString *fontSize = [doJsonHelper GetOneText: node :@"fontSize" :@""];
            color = [doUIModuleHelper GetColorFromString:fontColor :[UIColor blackColor]];
            BaiduPanoLabelOverlay *textOverlay = [[BaiduPanoLabelOverlay alloc] init];
            textOverlay.overlayKey = ID;
            [self.markerIDs addObject:ID];
            textOverlay.coordinate = CLLocationCoordinate2DMake([latitude floatValue],[longitude floatValue]);
            textOverlay.height         = 1;//单位为 m
            // 字体颜色
            // 背景颜色
            textOverlay.textColor = color;
            textOverlay.backgroundColor = [UIColor clearColor];
            textOverlay.fontSize  = [fontSize floatValue];
            // 支持换行
            textOverlay.text      = text;
            // 边缘距
            textOverlay.edgeInsets = UIEdgeInsetsMake(2, 3, 4, 5);
            [panoramaView addOverlay:textOverlay];
            
        }
        [_invokeResult SetResultBoolean:YES];
        
    }
    @catch (NSException *exception) {
        [_invokeResult SetResultBoolean:NO];
    }
}
- (void)removeAll:(NSArray *)parms
{
    for (NSString *ID in self.markerIDs) {
        [panoramaView removeOverlay:ID];
    }
}
- (void)removeMarker:(NSArray *)parms
{
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    //参数字典_dictParas
    //自己的代码实现
    NSArray *ids = [doJsonHelper GetOneArray:_dictParas :@"ids"];
    for (NSString *ID in ids) {
        [panoramaView removeOverlay:ID];
    }
}
- (void)showPanoramaView:(NSArray *)parms
{
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    NSString *latitude = [doJsonHelper GetOneText:_dictParas :@"latitude" :@""];
    NSString *longitude = [doJsonHelper GetOneText:_dictParas :@"longitude" :@""];
    [panoramaView setPanoramaWithLon:[longitude floatValue] lat:[latitude floatValue]];
}
#pragma mark - anoramaView代理方法
- (void)panoramaLoadFailed:(BaiduPanoramaView *)panoramaView error:(NSError *)error
{
    NSLog(@"error===%@",error.description);
}
- (void)panoramaWillLoad:(BaiduPanoramaView *)panoramaView
{
    
}

/**
 * @abstract 全景图中的覆盖物点击事件
 * @param overlayId 覆盖物标识
 */
- (void)panoramaView:(BaiduPanoramaView *)panoramaView overlayClicked:(NSString *)overlayId
{
    NSMutableDictionary *node = [NSMutableDictionary dictionary];
    for (NSDictionary *tempDict in markInfos) {
        if ([[tempDict objectForKey:@"id"]isEqualToString:overlayId]) {
            [node setObject:overlayId forKey:@"id"];
            [node setObject:[tempDict objectForKey:@"latitude"] forKey:@"latitude"];
            [node setObject:[tempDict objectForKey:@"longitude"] forKey:@"longitude"];
            if ([tempDict.allKeys containsObject:@"url"]) {
                [node setObject:@"ImageMark" forKey:@"type"];
                [node setObject:[tempDict objectForKey:@"url"] forKey:@"info"];
            }
            else if([tempDict.allKeys containsObject:@"text"])
            {
                [node setObject:@"TextMark" forKey:@"type"];
                [node setObject:[tempDict objectForKey:@"text"] forKey:@"info"];
            }
        }
    }
    doInvokeResult *invokeResult = [[doInvokeResult alloc]init];
    [invokeResult SetResultNode:node];
    [_model.EventCenter FireEvent:@"touchMarker" :invokeResult];
}
#pragma mark - 私有方法
- (UIImage *)cutImage:(UIImage*)image
{
    //压缩图片
    CGImageRef imageRef = nil;
    CGFloat scaleW = image.size.width * _model.XZoom;
    CGFloat scaleH = image.size.height * _model.YZoom;
    imageRef = CGImageCreateWithImageInRect([image CGImage], CGRectMake(0, 0, scaleW, scaleH));
    return [UIImage imageWithCGImage:imageRef];
}
#pragma mark - doIUIModuleView协议方法（必须）<大部分情况不需修改>
- (BOOL) OnPropertiesChanging: (NSMutableDictionary *) _changedValues
{
    //属性改变时,返回NO，将不会执行Changed方法
    return YES;
}
- (void) OnPropertiesChanged: (NSMutableDictionary*) _changedValues
{
    //_model的属性进行修改，同时调用self的对应的属性方法，修改视图
    [doUIModuleHelper HandleViewProperChanged: self :_model : _changedValues ];
}
- (BOOL) InvokeSyncMethod: (NSString *) _methodName : (NSDictionary *)_dicParas :(id<doIScriptEngine>)_scriptEngine : (doInvokeResult *) _invokeResult
{
    //同步消息
    return [doScriptEngineHelper InvokeSyncSelector:self : _methodName :_dicParas :_scriptEngine :_invokeResult];
}
- (BOOL) InvokeAsyncMethod: (NSString *) _methodName : (NSDictionary *) _dicParas :(id<doIScriptEngine>) _scriptEngine : (NSString *) _callbackFuncName
{
    //异步消息
    return [doScriptEngineHelper InvokeASyncSelector:self : _methodName :_dicParas :_scriptEngine: _callbackFuncName];
}
- (doUIModule *) GetModel
{
    //获取model对象
    return _model;
}

@end
