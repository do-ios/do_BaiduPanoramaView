//
//  do_BaiduPanoramaView_UI.h
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol do_BaiduPanoramaView_IView <NSObject>

@required
//属性方法
- (void)change_imageLevel:(NSString *)newValue;
- (void)change_zoomLevel:(NSString *)newValue;

//同步或异步方法
- (void)addImageMarkers:(NSArray *)parms;
- (void)addTextMarkers:(NSArray *)parms;
- (void)removeAll:(NSArray *)parms;
- (void)removeMarker:(NSArray *)parms;
- (void)showPanoramaView:(NSArray *)parms;


@end