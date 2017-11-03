//
//  do_BaiduPanoramaView_View.h
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "do_BaiduPanoramaView_IView.h"
#import "do_BaiduPanoramaView_UIModel.h"
#import "doIUIModuleView.h"

@interface do_BaiduPanoramaView_UIView : UIView<do_BaiduPanoramaView_IView, doIUIModuleView>
//可根据具体实现替换UIView
{
	@private
		__weak do_BaiduPanoramaView_UIModel *_model;
}

@end
