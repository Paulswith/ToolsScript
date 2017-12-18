//  weibo: http://weibo.com/xiaoqing28
//  blog:  http://www.alonemonkey.com
//
//  putongDylib.m
//  putongDylib
//
//  Created by dobby on 2017/12/10.
//  Copyright (c) 2017年 Dobby. All rights reserved.
//

#import "putongDylib.h"
#import <CaptainHook/CaptainHook.h>
#import "PreCustomObject.h"
#import <Cycript/Cycript.h>
#import <Foundation/Foundation.h>
#import <objc/message.h>
#import <FLEX/FLEXManager.h>
#import <CoreData/NSFetchRequest.h>



#pragma mark - 一些全局宏宅基地
static NSString * const CHOOSE_STU = @"chooseStudent";
static NSString * const CHOOSE_ALL = @"chooseAll";
static NSString * const MODIFY_LOC = @"modifyLocation";
static NSString * const LAST_MESSAGE = @"lastMessage";
static NSString * const INFINITE_CHOOSE = @"InfiniteChoose";
static NSString * const AUTO_BORING_CHAT = @"AutoBoringChat";

#define  TT_CONFIG [NSUserDefaults standardUserDefaults]
#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define LOC_CACHE_latitude @"Location_latitude"
#define LOC_CACHE_longitude @"Location_longitude"
#define CHAT_KEY @""   // "图灵机器人 - key"


typedef NS_ENUM(NSUInteger,HandleType) {
    HandleRecieveCount,       // 当前已拉总数,自动选的时候会对此求余来停止
    HandleAutoLikeAll,          // 无条件选妹子
    HandleDislikeElseStudent, //  选妹子(条件为isStudent==YES)
    HandleModifyLocation,       // 修改定位
    HandleInfiniteChoose,      // 不会HandleRecieveCount, 而是不停止选妹
    HandleAutoBoringChat     // 对某聊天窗口自动尬聊, 图灵机器人
};

#pragma mark - ------------------------------------add controller workSpace---------------------------------------------------------------------
@interface DBNewFunViewController: UIViewController <UITableViewDataSource,UITableViewDelegate,MKMapViewDelegate>

@property (weak, nonatomic) UIView *placeHolderTitleView;
@property (weak, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSArray <NSString *>*cellNameArray;
@property (strong) id sharedSuggested;
@property (strong) id profileInfo;
@property(strong,nonatomic) NSArray *unswipedUsers; //已拉取的数组
@property(weak,nonatomic) MKMapView *mapView;
@property(assign,nonatomic) CGPoint  center;
@property(weak,nonatomic) UILabel *locationLabel; //地理信息展示
@property(assign,nonatomic) CLLocationCoordinate2D coordinate; //存储地理信息
@end

@implementation DBNewFunViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.sharedSuggested = objc_msgSend(objc_getClass("SuggestedUsersCollection"),@selector(sharedCollection));
    self.cellNameArray = @[@"已拉取用户(自动选是对此求余)",@"自动选妹子(hui保存至document/)",@"自动筛选学生",@"改定位(上方点击保存且此处打开)",@"是否启动无限选妹",@"聊天自动尬聊"];
    [self setupTitleViews];
    [self setupMapViews];
    [self setupBottomViews];
}

#pragma mark - tableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.cellNameArray.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CELL" forIndexPath:indexPath];
    UISwitch *switchBtn = [[UISwitch alloc] init];
    switchBtn.tag = indexPath.row;
    [switchBtn addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = switchBtn;
    cell.textLabel.text = self.cellNameArray[indexPath.row];
    if (indexPath.row == 0) {
        self.unswipedUsers = (NSArray *)objc_msgSend(self.sharedSuggested, @selector(unswipedUsers));
        NSInteger unswipedUserscount = [self.unswipedUsers count];
        cell.textLabel.text = [NSString stringWithFormat:@"已拉取用户:%ld",unswipedUserscount];
    }else if (indexPath.row == 1) {
        switchBtn.on = [[TT_CONFIG objectForKey:CHOOSE_ALL] boolValue];
    }else if (indexPath.row == 2) {
        switchBtn.on = [[TT_CONFIG objectForKey:CHOOSE_STU] boolValue];
    }else if (indexPath.row == 3) {
        switchBtn.on = [[TT_CONFIG objectForKey:MODIFY_LOC] boolValue];
    }else if (indexPath.row == 4) {
        switchBtn.on = [[TT_CONFIG objectForKey:INFINITE_CHOOSE] boolValue];
    }else if (indexPath.row == 5) {
        switchBtn.on = [[TT_CONFIG objectForKey:AUTO_BORING_CHAT] boolValue];
    }
    return cell;
}

#pragma mark - tableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)switchAction:(UISwitch *)switchBtn {
    NSString *value = [NSString stringWithFormat:@"%@",switchBtn.isOn?@"1":@"0"];
    NSLog(@"修改值为:%@",value);
    switch (switchBtn.tag) {
        case HandleRecieveCount:
            [self.tableView reloadData];
            break;
        case HandleAutoLikeAll:
            [TT_CONFIG setObject:value forKey:CHOOSE_ALL];
            [TT_CONFIG synchronize];
            NSLog(@"-------------选妹子Set-YES");
            break;
        case HandleDislikeElseStudent:
            [TT_CONFIG setObject:value forKey:CHOOSE_STU];
            [TT_CONFIG synchronize];
            NSLog(@"-------------选学生Set-YES");
            break;
        case HandleModifyLocation:
            [TT_CONFIG setObject:value forKey:MODIFY_LOC];
            [TT_CONFIG synchronize];
        case HandleInfiniteChoose:
            [TT_CONFIG setObject:value forKey:INFINITE_CHOOSE];
            [TT_CONFIG synchronize];
            break;
        case HandleAutoBoringChat:
            [TT_CONFIG setObject:value forKey:AUTO_BORING_CHAT];
            [TT_CONFIG synchronize];
            break;
        default:
            break;
    }
}

#pragma mark - titleView设计
- (void)setupTitleViews {
    UIView *placeHolderTitleView = [[UIView alloc] initWithFrame:CGRectMake(0, 20, SCREEN_WIDTH, 30)];
    [self.view addSubview:placeHolderTitleView];
    // 关闭和保存按钮
    CGFloat centW = SCREEN_WIDTH / 4;
    UIButton *closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, centW, 30)];
    [closeBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [closeBtn setTitle:@"退出" forState:UIControlStateNormal];
    [placeHolderTitleView addSubview:closeBtn];
    
    UIButton *saveBtn = [[UIButton alloc] initWithFrame:CGRectMake(centW * 3, 0, centW, 30)];
    [saveBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [saveBtn setTitle:@"保存" forState:UIControlStateNormal];
    [placeHolderTitleView addSubview:saveBtn];
    
    [closeBtn addTarget:self action:@selector(closeAction) forControlEvents:UIControlEventTouchDown];
    [saveBtn addTarget:self action:@selector(saveAction) forControlEvents:UIControlEventTouchDown];
    
    // 下方即时展示location
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(centW, 0, centW * 2, 30)];
    NSString *lat = [TT_CONFIG objectForKey:LOC_CACHE_latitude];
    NSString *lon = [TT_CONFIG objectForKey:LOC_CACHE_longitude];
    [label setText:[NSString stringWithFormat:@"(%@,%@)",lat,lon]];
    [label setFont:[UIFont systemFontOfSize:10]];
    [label setBackgroundColor:[UIColor grayColor]];
    [placeHolderTitleView addSubview:label];
    self.locationLabel = label;
}
- (void)setupMapViews {
    // 地图View创建展示
    UIView *placeHolderUpView = [[UIView alloc] initWithFrame:CGRectMake(0, 50, SCREEN_WIDTH, (self.view.frame.size.height-20)/2)];
    [self.view addSubview:placeHolderUpView];
    MKMapView *mapview = [[MKMapView alloc] initWithFrame:placeHolderUpView.frame];
    mapview.delegate = self;
    [self.view addSubview:mapview];
    self.mapView = mapview;
    UIImage *iconImage = [UIImage imageNamed:@"icon"];
    UIImageView *icon = [[UIImageView alloc] initWithImage:iconImage];
    [icon setClipsToBounds:YES];
    icon.center = CGPointMake(mapview.center.x, mapview.center.y - (iconImage.size.height/2) -50);
    [self.mapView addSubview:icon];
    /*
    // 设置缓存定位初始化显示   runloop crash , App已经存在一个地图实例,这里二次创建了.
    NSString *latitude = [TT_CONFIG objectForKey:LOC_CACHE_latitude];
    NSString *longitude = [TT_CONFIG objectForKey:LOC_CACHE_longitude];
    if (latitude.doubleValue || longitude.doubleValue) {
        CLLocationCoordinate2D cacheLaco = CLLocationCoordinate2DMake(latitude.doubleValue, longitude.doubleValue);
        self.mapView.region = MKCoordinateRegionMake(cacheLaco, MKCoordinateSpanMake(1000, 1000));
        [self.mapView setCenterCoordinate:cacheLaco];
    }
     */
}
- (void)setupBottomViews {
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.mapView.frame), SCREEN_WIDTH, SCREEN_HEIGHT - CGRectGetMaxY(self.mapView.frame))];
    tableView.delegate = self;
    tableView.dataSource = self;
    self.tableView = tableView;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"CELL"];
    [self.view addSubview:tableView];
}

#pragma mark - saveAndCloseAction
- (void)closeAction {
    [self dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"DELLO");
    switch (self.mapView.mapType) {
        case MKMapTypeHybrid:
        {
            self.mapView.mapType = MKMapTypeStandard;
        }
            break;
        case MKMapTypeStandard:
        {
            self.mapView.mapType = MKMapTypeHybrid;
        }
            break;
        default:
            break;
    }
    self.mapView.mapType = MKMapTypeStandard;
    self.mapView.showsUserLocation = NO;
    [self.mapView.layer removeAllAnimations];
    [self.mapView removeAnnotations:_mapView.annotations];
    [self.mapView removeOverlays:_mapView.overlays];
    [self.mapView removeFromSuperview];
    self.mapView.delegate = nil;
    self.mapView = nil;
}
- (void)saveAction {
    [TT_CONFIG setObject:[NSString stringWithFormat:@"%f",self.coordinate.latitude] forKey:LOC_CACHE_latitude];
    [TT_CONFIG setObject:[NSString stringWithFormat:@"%f",self.coordinate.longitude] forKey:LOC_CACHE_longitude];
    [TT_CONFIG synchronize];
    [self.locationLabel setText:@"位置信息已保存"];
}

#pragma mark - 地理编码代理
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    self.coordinate = [mapView convertPoint:mapView.center toCoordinateFromView:self.view];
    NSLog(@"(%f,%f)",self.coordinate.latitude,self.coordinate.longitude);
    [self.locationLabel setText:[NSString stringWithFormat:@"(%f,%f)",self.coordinate.latitude,self.coordinate.longitude]];
}

@end
#pragma mark - -----------------------------------------------workSpace---end-------------------------------------------------------


#pragma mark - -----------------------------------------------HookMain分割线-------------------------------------------------------
static __attribute__((constructor)) void entry(){
    NSLog(@"\n               🎉!!！congratulations!!！🎉\n👍----------------insert dylib success----------------👍");
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
//        [[FLEXManager sharedManager] showExplorer];
        CYListenServer(6666);
    }];
}

#pragma mark - 属性/方法/类/声明
CHDeclareClass(P1HomeLookingViewController)
CHDeclareClass(P1HelpCenterHomeViewController)
CHDeclareClass(P1HomeNearbyViewController)
CHDeclareClass(P1MessagesView)


#pragma mark - HOOK => "-[P1HomeNearbyViewController checkIfShouldShowAlertViewForDismissTopUserWithLike:dragVelocity:cancelDragAction:]"
//去除当自动操作的时候, 碰到喜欢的时候弹匹配成功,虽然基本不可能..
CHOptimizedMethod(3, self, void, P1HomeNearbyViewController,checkIfShouldShowAlertViewForDismissTopUserWithLike,BOOL,arg1,dragVelocity,struct CGPoint,arg2,cancelDragAction,id,arg3) {
    BOOL shouldChooseAll = [[TT_CONFIG objectForKey:CHOOSE_ALL] boolValue];
    BOOL shouldChooseStu = [[TT_CONFIG objectForKey:CHOOSE_STU] boolValue];
    if (shouldChooseAll || shouldChooseStu) {
        CHSuper(3, P1HomeNearbyViewController,checkIfShouldShowAlertViewForDismissTopUserWithLike,arg1,dragVelocity,arg2,cancelDragAction,nil);
    }else {
        CHSuper(3, P1HomeNearbyViewController,checkIfShouldShowAlertViewForDismissTopUserWithLike,arg1,dragVelocity,arg2,cancelDragAction,arg3);
    }
}

#pragma mark - HOOK => "-[P1HomeLookingViewController userLocation]"
//定位更改
CHOptimizedMethod(0, self, CLLocation*,P1HomeLookingViewController,userLocation) {
    BOOL shouldModifyLoc = [[TT_CONFIG objectForKey:MODIFY_LOC] boolValue];
    if(shouldModifyLoc == YES) {
        NSString *latitude = [TT_CONFIG objectForKey:LOC_CACHE_latitude];
        NSString *longitude = [TT_CONFIG objectForKey:LOC_CACHE_longitude];
        if (latitude.doubleValue || longitude.doubleValue) {
            NSLog(@"----自定义位置并清空原有的拉取数组");
            id instanceSug = [objc_getClass("SuggestedUsersCollection") performSelector:@selector(sharedCollection)];
            [instanceSug performSelector:@selector(clearUsers)];
            [instanceSug performSelector:@selector(clearSwipedUsers)];
            CLLocation *lacationInfo = [[CLLocation alloc] initWithLatitude:latitude.doubleValue longitude:longitude.doubleValue];
            NSLog(@"%@",lacationInfo);
            return lacationInfo;
        }
    }
    return CHSuper(0, P1HomeLookingViewController, userLocation);
}

#pragma mark - HOOK => "-[P1HelpCenterHomeViewController tableView:didSelectRowAtIndexPath:]"
//hook自定义设置的入口
CHOptimizedMethod(2, self, void, P1HelpCenterHomeViewController, tableView, UITableView *, arg1, didSelectRowAtIndexPath, NSIndexPath*, indexPath) {
    if(indexPath.row ==0 ) {
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:[DBNewFunViewController new] animated:YES completion:^{
            NSLog(@"展示自定义VC");
        }];
    }else {
        CHSuper(2, P1HelpCenterHomeViewController, tableView, arg1, didSelectRowAtIndexPath, indexPath);
    }
}

#pragma mark - HOOK => "-[P1HomeNearbyViewController maximumVisibleUserCardCount]"
//  翻到牌的数量限制等,不知道啥限制,去掉
CHOptimizedMethod(0, self, NSUInteger, P1HomeNearbyViewController, maximumVisibleUserCardCount) {
    return INT_MAX;
}

#pragma mark - HOOK => "-[P1HomeNearbyViewController viewDidAppear]"
// 缓存自动跑的照片信息 & 自动选妹操作
CHOptimizedMethod(1, self, void, P1HomeNearbyViewController,viewDidAppear, BOOL, arg1) {
    CHSuper(1,P1HomeNearbyViewController,viewDidAppear, arg1);
    // 创建文件缓存
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *document =  NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *cacheTxt = [document stringByAppendingPathComponent:@"cache.txt"];
    NSLog(@"%@",cacheTxt);
    if ([manager fileExistsAtPath:cacheTxt] == NO) {
        [manager createFileAtPath:cacheTxt contents:nil attributes:nil];
    };
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:cacheTxt];
    // 从配置看是否要进行自动操作
    BOOL shouldChooseAll = [[TT_CONFIG objectForKey:CHOOSE_ALL] boolValue];
    BOOL shouldChooseStu = [[TT_CONFIG objectForKey:CHOOSE_STU] boolValue];
    if (shouldChooseAll || shouldChooseStu) {
        [NSThread sleepForTimeInterval:5.0];
        id sharedSuggested = [objc_getClass("SuggestedUsersCollection") performSelector:@selector(sharedCollection)];
        NSArray *unswipedUsers = (NSArray *)[sharedSuggested performSelector:@selector(unswipedUsers)];
        NSInteger unswipedUserscount = [unswipedUsers count];
        UIButton *dislikeButton = [self dislikeButton];
        UIButton *likeButton = [self likeButton];
        if ([[TT_CONFIG objectForKey:INFINITE_CHOOSE] boolValue]) {
            unswipedUserscount = INT_MAX;
        }
        // 卡片的 view
        static int i = 0;
        [NSTimer scheduledTimerWithTimeInterval:2 repeats:YES block:^(NSTimer * _Nonnull timer) {
            UserObject *userObject = [[self topUserCard] performSelector:@selector(user)];
            ProfileInfo *profileInfo = userObject.profile;
            BOOL isStudent = profileInfo.isStudent;
            NSDictionary *workDict = [profileInfo.work toDictionary];
            NSDictionary *studyDict = [profileInfo.studies toDictionary];
            NSString *formatStr = [NSString stringWithFormat:@"名字:%@ -- 年龄:%d岁, -- %@学生,%@加入探探,家乡:%@,工作信息:%@;学校信息:%@\n",\
                                   userObject.name,userObject.age,isStudent?@"是":@"不是",userObject.createdTime,profileInfo.hometown,workDict,studyDict];
            NSLog(@"%@",formatStr);
            // 写入缓存
            [fileHandle seekToEndOfFile];
            [fileHandle writeData:[formatStr dataUsingEncoding:NSUTF8StringEncoding]];
            for (id picObject in userObject.pictures ) {
                // 图片url
                NSString *url = [picObject performSelector:@selector(url)];
                [fileHandle seekToEndOfFile];
                [fileHandle writeData:[[NSString stringWithFormat:@"%@\n",url] dataUsingEncoding:NSUTF8StringEncoding]];
            }
            // 全部喜欢就全部点like
            if (shouldChooseAll == YES) {
                [likeButton sendActionsForControlEvents:[likeButton allControlEvents]];   // 用下面的方法可以避免有喜欢了弹出来挡住
            }else{
                // 第二种清空就是dislikeElseStu
                if (isStudent == NO) {
                    [dislikeButton sendActionsForControlEvents:[dislikeButton allControlEvents]];
                }else{
                    [likeButton sendActionsForControlEvents:[likeButton allControlEvents]];
                }
            }
            NSLog(@"当前是第%d个",i);
            // 退出
            i++;
            if (i % unswipedUserscount == 0) {
               [timer invalidate];
                [TT_CONFIG setObject:@"0" forKey:CHOOSE_ALL];
                [TT_CONFIG setObject:@"0" forKey:CHOOSE_STU];
                [TT_CONFIG synchronize];
            }
        }];
    }
    NSLog(@"是否开始自动撸卡片? --  --------------> %@",shouldChooseStu || shouldChooseAll?@"是的":@"暂不需要");
}

#pragma mark - HOOK => "-[P1ConversationTableView controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:]"
// 实现自动聊天操作
CHOptimizedMethod(5, self, void, P1MessagesView,controller,id,arg1,didChangeObject,MessageObject*,arg2,atIndexPath,id,arg3,forChangeType,NSUInteger,arg4,newIndexPath,id,arg5) {
    BOOL shouldAutoBoringChat = [[TT_CONFIG objectForKey:AUTO_BORING_CHAT] boolValue];
    if (shouldAutoBoringChat) {
        ConversationObject *conversation = [self conversationObject];
        NSComparisonResult compareResult = [[conversation latestReceivedTime] compare:[conversation latestReadMessageCreatedTime]];
        
        if (compareResult == NSOrderedDescending && !conversation.isRead && ![arg2.owner isCurrentUser]) {
            NSString *message = conversation.messageCollection.latestNormalMessage.message;
            
            NSString *lastMessage = [TT_CONFIG objectForKey:LAST_MESSAGE];
            if (![lastMessage isEqualToString:message]) {  //  这里会收到重复的通知 ,可能这里并不是最佳hook的位置
                NSLog(@"内容=%@\n,发送者=%@\n",conversation.messageCollection.latestNormalMessage.message,arg2.owner.name);
                [TT_CONFIG setObject:message forKey:LAST_MESSAGE];
                [TT_CONFIG synchronize];
                P1MessagesViewController *messageVC = (P1MessagesViewController *)[self.superview nextResponder];
                __weak typeof(messageVC) weakMessageVC = messageVC;
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://www.tuling123.com/openapi/api"]];
                request.HTTPMethod = @"POST";
                NSString *reqStr = [NSString stringWithFormat:@"key=%@&info=%@&userid=探探小助手",CHAT_KEY,message];
                request.HTTPBody = [reqStr dataUsingEncoding:NSUTF8StringEncoding];
                NSURLSession *session = [NSURLSession sharedSession];
                NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                    if(error){
                        NSLog(@"向机器人通信失败:%@",error);
                    }
                    NSError *jsonSerialError;
                    NSDictionary *rspData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonSerialError];
                    if (jsonSerialError) {
                        NSLog(@"解析机器人消息回包失败 : %@",jsonSerialError);
                    }
                    NSString *text = [rspData objectForKey:@"text"];
                    if (text) {
                        [weakMessageVC sendMessage:text];
                        NSLog(@"发送信息:%@",text);
                    }else {
                        [weakMessageVC sendMessage:@"你怎么样都是最美最可爱的  --鲁迅"];
                    }
                }];
                [task resume];
            }
        }
    }
    CHSuper(5, P1MessagesView,controller,arg1,didChangeObject,arg2,atIndexPath,arg3,forChangeType,arg4,newIndexPath,arg5);
}


#pragma mark - replace区
CHConstructor{
    CHLoadLateClass(P1HelpCenterHomeViewController);
    CHLoadLateClass(P1HomeNearbyViewController);
    CHLoadLateClass(P1HomeLookingViewController);
    CHLoadLateClass(P1MessagesView);
    CHClassHook(2, P1HelpCenterHomeViewController, tableView,didSelectRowAtIndexPath);
    CHClassHook(0, P1HomeLookingViewController,userLocation);
    CHClassHook(1, P1HomeNearbyViewController,viewDidAppear);
    CHClassHook(0, P1HomeNearbyViewController, maximumVisibleUserCardCount);
    CHClassHook(3, P1HomeNearbyViewController, checkIfShouldShowAlertViewForDismissTopUserWithLike, dragVelocity,cancelDragAction);
//    CHClassHook(1, P1ConversationsViewController,viewWillAppear);
    CHClassHook(5, P1MessagesView,controller,didChangeObject,atIndexPath,forChangeType,newIndexPath);
}
#pragma mark - -----------------------------------------------HookMain分割线---------------end-------------------------------------
