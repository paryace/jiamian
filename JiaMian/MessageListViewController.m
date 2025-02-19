//
//  HomePageViewController.m
//  JiaMian
//
//  Created by wy on 14-4-26.
//  Copyright (c) 2014年 wy. All rights reserved.
//

#import "MessageListViewController.h"
#import "PublishMsgViewController.h"
#import "MessageDetailViewController.h"
#import "CommonMarco.h"
#import "UILabel+Extensions.h"
#import "UMFeedback.h"
#import "MsgTableViewCell.h"
#import "RNBlurModalView.h"
#import <QuartzCore/QuartzCore.h>
#import "ZDProgressView.h"
#import "MJRefresh.h"
#import "TWSpringyFlowLayout.h"


#define kTopicTextLabel   8999
#define kTopicImageView   8994
#define kTopicNumberLabel 8993
#define kFaYanBtnTag      8990
#define kTouPiaoBtnTag    8991

#define kVoteViewTag      8888
#define kVoteLabelHeight  50

// Strings
NSString * const kTWMessageViewControllerCellIdentifier = @"kTWMessageViewControllerCellIdentifier";

// Numerics
CGFloat const kTWMessageViewControllerCellPadding = 10;
CGFloat const kTWMessageViewControllerCellHeight = 50;




static NSString* msgCellIdentifier = @"MsgTableViewCellIdentifier";

@interface MessageListViewController () <PullTableViewDelegate, UITableViewDelegate, UITableViewDataSource,UMSocialUIDelegate>
{
    NSMutableArray* messageArray;
    UIView* parentView;
    UIImageView* plusImageView;
    BOOL flag; //是否点击加号
    
    BOOL isMoreViewOpen;
    BOOL isParentView;
    
    int messageType;  //热门 或 最新
    NSMutableArray* hotMsgArray;
    NSMutableArray* latestMsgArray;
    int i;//爱心点赞特效
    HMSegmentedControl* segmentedControl;
    NSIndexPath*savePath;
    NSArray*arr;
    BOOL isTap;
    NSInteger selectedRow;
}
@property (strong, nonatomic) UIView* moreBtnView;
@property (strong, nonatomic) UIButton* fayanBtn;
@property (strong, nonatomic) UIButton* toupiaoBtn;
@property (strong, nonatomic) UIView* lineView1;
@property (strong, nonatomic) UIView* lineView2;
@property (strong, nonatomic) UIView* deleteView;


@end

@implementation MessageListViewController




- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (UIButton*)fayanBtn {
    if (_fayanBtn == nil) {
        _fayanBtn =[[UIButton alloc]initWithFrame:CGRectMake(45, 0, 60, 45)];
        [_fayanBtn addTarget:self action:@selector(handleBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
        [_fayanBtn setTitle:@"发言" forState:UIControlStateNormal];
        [_fayanBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _fayanBtn.titleLabel.font = [UIFont systemFontOfSize: 16.0];//gray
        _fayanBtn.titleLabel.textColor=[UIColor whiteColor];
        _fayanBtn.tag = kFaYanBtnTag;
        _fayanBtn.backgroundColor=[UIColor clearColor];
    }
    return _fayanBtn;
}
- (UIButton*)toupiaoBtn {
    if (_toupiaoBtn == nil) {
        _toupiaoBtn =[[UIButton alloc]initWithFrame:CGRectMake(105, 0, 60, 45)];
        [_toupiaoBtn addTarget:self action:@selector(handleBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
        [_toupiaoBtn setTitle:@"投票" forState:UIControlStateNormal];
        [_toupiaoBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _toupiaoBtn.titleLabel.font = [UIFont systemFontOfSize: 16.0];
        _toupiaoBtn.titleLabel.textColor=[UIColor whiteColor];
        _toupiaoBtn.tag = kTouPiaoBtnTag;
        _toupiaoBtn.backgroundColor=[UIColor clearColor];
    }
    return _toupiaoBtn;
}
- (void)handleBtnPressed:(UIButton*)sender {
    
    [self handlePlusTapped];
    PublishMsgViewController* publishVC = [self.storyboard instantiateViewControllerWithIdentifier:@"PublishMsgVCIdentifier"];
    publishVC.isTouPiao = (sender.tag == kTouPiaoBtnTag);
    publishVC.categoryId = self.categoryId;
    [self.navigationController pushViewController:publishVC animated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Parallax effect
   /* UIInterpolatingMotionEffect *interpolationHorizontal = [[UIInterpolatingMotionEffect alloc]initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    interpolationHorizontal.minimumRelativeValue = @-20.0;
    interpolationHorizontal.maximumRelativeValue = @20.0;
    
    UIInterpolatingMotionEffect *interpolationVertical = [[UIInterpolatingMotionEffect alloc]initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    interpolationVertical.minimumRelativeValue = @-20.0;
    interpolationVertical.maximumRelativeValue = @20.0;
    
    // Configurte collection view
    self.pullTableView.backgroundColor = [UIColor clearColor];
    [self.pullTableView registerClass:[MsgTableViewCell class] forCellWithReuseIdentifier:kTWMessageViewControllerCellIdentifier];
    self.pullTableView.delegate = self;
    self.pullTableView.dataSource = self;
    
    */
    
    //--------------------------------------
    self.pullTableView.backgroundColor=UIColorFromRGB(0x344c62);
    self.pullTableView.separatorStyle = NO;
    messageType = 1;
    hotMsgArray = [NSMutableArray array];
    latestMsgArray = [NSMutableArray array];
    if (3 == _categoryId) //圈内八卦
    {
        self.title = @"圈内八卦";
        messageType = 2; //@"最新"
    }
    else
    {
        segmentedControl = [[HMSegmentedControl alloc] initWithSectionTitles:@[@"热门", @"最新"]];
        [segmentedControl setSelectionIndicatorHeight:2.0f];
        segmentedControl.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
        segmentedControl.frame = CGRectMake(80, 40, 130, 30);
        segmentedControl.segmentEdgeInset = UIEdgeInsetsMake(0, 10, 0, 10);
        segmentedControl.selectionStyle = HMSegmentedControlSelectionStyleFullWidthStripe;
        segmentedControl.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationDown;
        segmentedControl.selectedSegmentIndex = 0;
        [segmentedControl addTarget:self action:@selector(segmentedControlChangedValue:) forControlEvents:UIControlEventValueChanged];
        self.navigationItem.titleView=segmentedControl;
    }
    
    if (IOS_NEWER_OR_EQUAL_TO_7)
        self.navigationController.navigationBar.translucent = NO;
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.pullTableView.delegate = self;
    self.pullTableView.dataSource = self;
    self.pullTableView.pullDelegate = self;
    [self.pullTableView registerNib:[UINib nibWithNibName:@"MsgTableViewCell" bundle:nil] forCellReuseIdentifier:msgCellIdentifier];
    
    [self fetchDataFromServer];
    
    [NOTIFICATION_CENTER addObserver:self selector:@selector(handlePublishMsgSuccess) name:@"publishMessageSuccess" object:nil];
    [NOTIFICATION_CENTER addObserver:self selector:@selector(fetchDataFromServerForAreaChange) name:@"changeAreaSuccess" object:nil];
    [NOTIFICATION_CENTER addObserver:self selector:@selector(handleMsgChanged:) name:@"msgChangedNoti" object:nil];
    [NOTIFICATION_CENTER addObserver:self selector:@selector(handleRemoteNotification:) name:@"showRomoteNotification" object:nil];
    
    [[EaseMob sharedInstance].chatManager asyncLoginWithUsername:[USER_DEFAULT objectForKey:kSelfHuanXinId]
                                                        password:[USER_DEFAULT objectForKey:kSelfHuanXinPW]
                                                      completion:nil onQueue:nil];
    
    
    
    parentView = [[UIView alloc] initWithFrame:CGRectMake(0,350, 45, 45)];
    parentView.backgroundColor = UIColorFromRGB(0x263645);
    parentView.alpha = 0.8;
    plusImageView = [[UIImageView alloc] initWithFrame:CGRectMake(13.5, 13.5, 18, 18)];
    [plusImageView setImage:[UIImage imageNamed:@"plus2.png"]];
    [plusImageView setBackgroundColor:[UIColor clearColor]];
    
    [self.view addSubview:parentView];
    [parentView addSubview:plusImageView];
    UITapGestureRecognizer* plusTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handlePlusTapped)];
    plusTapGesture.numberOfTapsRequired = 1;
    [plusImageView setUserInteractionEnabled:YES];
    [parentView addGestureRecognizer:plusTapGesture];
    
    UITapGestureRecognizer*tap=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
    tap. cancelsTouchesInView=NO;
    [self.pullTableView addGestureRecognizer:tap];
    
}
-(void)handleTap
{
  
 //   _deleteView.transform=CGAffineTransformMakeTranslation(-30,0) ;
    [self dismissDeletView];

    
}


-(void)dismissDeletView
{
    [UIView animateWithDuration:0.4 animations:^{
        _deleteView.transform=CGAffineTransformMakeTranslation(100, 0);
        _deleteView.alpha=0;
        
        
    } completion:^(BOOL finished) {
        
        [_deleteView removeFromSuperview];
        //[parentView removeFromSuperview];
        
    }];
}

- (void)doRefreshAutomaticly { //自动触发下拉刷新
    [self.pullTableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
    if(!self.pullTableView.pullTableIsRefreshing) {
        self.pullTableView.pullTableIsRefreshing = YES;
        [self performSelector:@selector(refreshTable) withObject:nil afterDelay:0.5f];
    }
}
- (void)segmentedControlChangedValue:(HMSegmentedControl*)sender {
    messageType = (sender.selectedSegmentIndex == 0) ? 1 : 2;
    [self doRefreshAutomaticly];
}
- (void)handlePublishMsgSuccess {
    if (self.categoryId != 3) {
        messageType = 2; //最新
        segmentedControl.selectedSegmentIndex=1;
    }
    [self doRefreshAutomaticly];
}
- (void)handlePlusTapped
{
    if (NO == flag)
    {
        [UIView transitionWithView:parentView duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            parentView.frame = CGRectMake(0,350,165,45);
                            plusImageView.transform = CGAffineTransformMakeRotation(2.38);
                            [parentView addSubview:self.fayanBtn];
                            [parentView addSubview:self.toupiaoBtn];
                        } completion:^(BOOL finish){
                            flag = YES;
                            
                        }];
        //画线的
        self.lineView1 = [[UIView alloc] initWithFrame:CGRectMake(45,8,1.0f,30.0f)];
        [self.lineView1 setBackgroundColor:[UIColor whiteColor]];//lightGrayColor
        [parentView addSubview:self.lineView1];
        
        self.lineView2 = [[UIView alloc] initWithFrame:CGRectMake(105,8,1.0f,30.0f)];
        [self.lineView2 setBackgroundColor:[UIColor whiteColor]];
        [parentView addSubview:self.lineView2];
    }
    else
    {
        [UIView animateWithDuration:0.3 animations:^{
            plusImageView.transform = CGAffineTransformMakeRotation(0);
            [self.fayanBtn removeFromSuperview];
            [self.toupiaoBtn removeFromSuperview];
            [self.lineView1 removeFromSuperview];
            [self.lineView2 removeFromSuperview];
            parentView.frame = CGRectMake(0,350,45,45);
        } completion:^(BOOL finished) {
            flag = NO;
            isParentView = NO;
        }];
    }
}

- (void)handleMoreBtnAction:(UIButton*)sender
{
    UITableViewCell* cell = [UIView tableViewCellFromView:sender];
    NSIndexPath *indexPath = [self.pullTableView indexPathForCell:cell];
    MessageModel* currentMsg = [messageArray objectAtIndex:indexPath.row];
    NSString* btnTitle = sender.titleLabel.text;
    selectedRow=indexPath.row;
    if ([btnTitle isEqual:@"分享"])
    {
           [UMSocialSnsService presentSnsIconSheetView:self
                                             appKey:kUMengAppKey
                                          shareText:nil
                                         shareImage:nil
                                    shareToSnsNames:[NSArray arrayWithObjects:UMShareToSina, UMShareToWechatSession, UMShareToWechatTimeline, nil]
                                           delegate:self];
        
    }
    else if ([btnTitle isEqual:@"私信"]) {
        HxUserModel* hxUserInfo = [[NetWorkConnect sharedInstance] userGetByMsgId:currentMsg.message_id];
        ChatViewController* chatVC = [self.storyboard instantiateViewControllerWithIdentifier:@"PublishSiXinVCIndentifier"];
        NSLog(@"%ld",currentMsg.message_id);
        chatVC.chatter = hxUserInfo.user.easemob_name;
        chatVC.myHeadImage = hxUserInfo.my_head_image;
        chatVC.chatterHeadImage = hxUserInfo.chat_head_image;
        chatVC.customFlag = currentMsg.message_id;
        chatVC.message = currentMsg;
        [self.navigationController pushViewController:chatVC animated:YES];
        
    } else {
        [UIActionSheet showInView:self.pullTableView
                        withTitle:@"举报"
                cancelButtonTitle:@"Cancel"
           destructiveButtonTitle:nil
                otherButtonTitles:@[@"举报消息", @"举报用户"]
                         tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                             if (0 == buttonIndex) {
                                 NSDictionary* res = [[NetWorkConnect sharedInstance] reportMessageByMsgId:currentMsg.message_id];
                                 if (res) {
                                     AlertContent(@"举报消息成功");
                                 }
                             } else if (1 == buttonIndex) {
                                 NSDictionary* res = [[NetWorkConnect sharedInstance] reportUserByMsgId:currentMsg.message_id];
                                 if (res) {
                                     AlertContent(@"举报用户成功");
                                 }
                             }
                         }];
    }
    [_moreBtnView removeFromSuperview];
   
}

-(void)didSelectSocialPlatform:(NSString *)platformName withSocialData:(UMSocialData *)socialData
{
    
    MessageModel* currentMsg = [messageArray objectAtIndex:selectedRow];
    NSString* shareText = [NSString stringWithFormat:@"\"%@\"",currentMsg.text];
    if (platformName == UMShareToSina) {
        if ([currentMsg.topics count]>0) {
        shareText=[shareText stringByAppendingString:[currentMsg.topics lastObject]];
         }else if([currentMsg.area.area_name length]>0)
        {
        shareText=[shareText stringByAppendingString:currentMsg.area.area_name];
        }

    }else if (platformName==UMShareToWechatSession)
    {
        if ([currentMsg.votes  count]>0) {
            shareText=[shareText stringByAppendingString:@"我参与了匿名投票"];
        }else
        {
            shareText=[shareText stringByAppendingString:@"分享一个匿名秘密给你"];
        }
 
    }else if ( platformName==UMShareToWechatTimeline)
    {
        if ([currentMsg.votes  count]>0) {
            shareText=[shareText stringByAppendingString:@"我参与了匿名投票"];
        }else
        {
            shareText=[shareText stringByAppendingString:@"分享一个匿名秘密给你"];
        }
    }
    
    shareText=[shareText stringByAppendingString:@"@假面app"];
    shareText =  [shareText stringByAppendingString:[NSString stringWithFormat:@"http://www.jiamian.mobi/share/%ld",currentMsg.message_id]];
    NSLog(@"%@",shareText);
    socialData.shareText = shareText;
    
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    //[self.deleteView removeFromSuperview];
    [self dismissDeletView];
    [self.moreBtnView removeFromSuperview];
    [UIView animateWithDuration:0.3 animations:^{
        plusImageView.transform = CGAffineTransformMakeRotation(0);
        [self.fayanBtn removeFromSuperview];
        [self.toupiaoBtn removeFromSuperview];
        [self.lineView1 removeFromSuperview];
        [self.lineView2 removeFromSuperview];
        parentView.frame = CGRectMake(0,350,45,45);
    } completion:^(BOOL finished) {
        flag = NO;
    }];
}


- (void)handleRemoteNotification:(NSNotification*)notification
{
    NSDictionary* userInfo = [notification userInfo];
    NSInteger msgId = [[userInfo valueForKey:@"message_id"] integerValue];
    
    NSLog(@"%s, msgId = %ld", __FUNCTION__, (long)msgId);
    MessageModel* msg = [[NetWorkConnect sharedInstance] messageShowByMsgId:msgId];
    if (msg)
    {
        MessageDetailViewController* msgDetailVC = [self.storyboard instantiateViewControllerWithIdentifier:@"MessageDetailVCIdentifier"];
        msgDetailVC.selectedMsg = msg;
        [self.navigationController pushViewController:msgDetailVC animated:YES];
    }
}
- (void)handleMsgChanged:(NSNotification*)notification
{
    MessageModel* tappedMsg = (MessageModel*)[notification.userInfo objectForKey:@"changedMsg"];
    NSUInteger index = [messageArray indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        MessageModel* msg = (MessageModel*)obj;
        return msg.message_id == tappedMsg.message_id;
    }];
    if (index != NSNotFound)
    {
        [messageArray replaceObjectAtIndex:index withObject:tappedMsg];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.pullTableView reloadData];
    });
}


- (void)fetchDataFromServer
{
    [SVProgressHUD setOffsetFromCenter:UIOffsetMake(0,50)];
    [SVProgressHUD setFont:[UIFont systemFontOfSize:16]];
    [SVProgressHUD showWithStatus:@"加载中..."];
     messageArray = [NSMutableArray array];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSArray* hotMsgs = [[NetWorkConnect sharedInstance] categoryMsgWithType:messageType // 1:热门
                                                                     categoryId:_categoryId
                                                                        sinceId:0
                                                                          maxId:INT_MAX
                                                                          count:20];
        [messageArray addObjectsFromArray:hotMsgs];
        [hotMsgArray addObjectsFromArray:hotMsgs];
        
        NSArray* latestMsgs = [[NetWorkConnect sharedInstance] categoryMsgWithType:2  //最新
                                                                        categoryId:_categoryId
                                                                           sinceId:0
                                                                             maxId:INT_MAX
                                                                             count:20];
        [latestMsgArray addObjectsFromArray:latestMsgs];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            [self.pullTableView reloadData];
        });
    });
}
- (void)fetchDataFromServerForAreaChange
{
    messageArray = [NSMutableArray array];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSArray* requestRes = [[NetWorkConnect sharedInstance] categoryMsgWithType:messageType
                                                                        categoryId:_categoryId
                                                                           sinceId:0
                                                                             maxId:INT_MAX
                                                                             count:20];
        if (messageType == 1) {
            [hotMsgArray removeAllObjects];
            [hotMsgArray addObjectsFromArray:requestRes];
        } else {
            [latestMsgArray removeAllObjects];
            [latestMsgArray addObjectsFromArray:requestRes];
        }
        [messageArray addObjectsFromArray:requestRes];
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.pullTableView reloadData];
        });
    });
}
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"PageOne"];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UITableView Delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return messageArray.count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MessageModel* currentMsg = (MessageModel*)[messageArray objectAtIndex:indexPath.row];
    NSInteger voteNumber = currentMsg.votes.count;
    if (0 == voteNumber) {
        return SCREEN_WIDTH + 10;
    } else {
        return SCREEN_WIDTH + 10 + (voteNumber*50);
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MsgTableViewCell*cell;
   // cell = [tableView dequeueReusableCellWithIdentifier:msgCellIdentifier];

    if (cell==nil) {
        
    cell =[[[NSBundle mainBundle]loadNibNamed:@"MsgTableViewCell" owner:self options:nil]lastObject];
      //  NSLog(@"!!!!!!!");
    }else
    {
        //NSLog(@"????????");
    }
    //cell.tag=indexPath.row;
    //NSLog(@"%d",cell.tag);
    
    //cell颜色和去掉线
    cell.backgroundColor=UIColorFromRGB(0x344c62);
    tableView.separatorStyle = NO;
   // NSLog(@"%d",indexPath.row);
    MessageModel* currentMsg = (MessageModel*)[messageArray objectAtIndex:indexPath.row];
   
    
    cell.msgTextLabel.text = currentMsg.text;
    if ([currentMsg.topics count]>0) {
        
        NSString*str=[currentMsg.topics firstObject];
        
        if ([str length]>8) {
            str=[str  substringToIndex:8];
            str=[str  stringByAppendingString:@"..." ];
            
        cell.areaLabel.text=[NSString stringWithFormat:@"#%@#",str];
        }else
        {
        
        cell.areaLabel.text=[NSString stringWithFormat:@"#%@#",[currentMsg.topics firstObject]];
        }
    }else
    {
        cell.areaLabel.text = currentMsg.area.area_name;
    }
    cell.commentNumLabel.text = [NSString stringWithFormat:@"%d", currentMsg.comments_count];
   
    cell.likeNumLabel.text = [NSString stringWithFormat:@"%d", currentMsg.likes_count];
   
    if (currentMsg.is_official)
    {
        cell.likeNumLabel.text = @"all";
        cell.areaLabel.text = @"假面官方团队";
    }
    [cell.likeImageView setUserInteractionEnabled:YES];
    UITapGestureRecognizer *likeImageTap =  [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(likeImageTap:)];
    [likeImageTap setNumberOfTapsRequired:1];
    [cell.likeImageView addGestureRecognizer:likeImageTap];
    
    [cell.moreImageView setUserInteractionEnabled:YES];
    UITapGestureRecognizer *moreImageTap =  [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(onDemoButton:)];
    [moreImageTap setNumberOfTapsRequired:1];
    [cell.moreImageView addGestureRecognizer:moreImageTap];
    
    
    
    [cell.deleteImageView setUserInteractionEnabled:YES];
    UITapGestureRecognizer *deleteImageTap =  [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(deleteButton:)];
    [deleteImageTap setNumberOfTapsRequired:1];
    [cell.deleteImageView addGestureRecognizer:deleteImageTap];
    
    cell.selectionStyle = UITableViewCellAccessoryNone;
    if (currentMsg.votes.count != 0) {
        [cell.contentView addSubview:[self configureVoteView:currentMsg.votes]];
    } else {
        UIView* voteView = (UIView*)[cell.contentView viewWithTag:kVoteViewTag];
        [voteView removeFromSuperview];
    }
   
    if (currentMsg.voted) {


    }else
    {
        UIView*vote=[cell viewWithTag:kVoteViewTag];
        for (int j=0; j<[currentMsg.votes count]; j++) {
            UILabel*label=(UILabel*)[vote viewWithTag:(j+99)];
            label.hidden=YES;
        }

    }
    
    if (currentMsg.background_url && currentMsg.background_url.length > 0)
    {
        
    [cell.bgImageView sd_setImageWithURL:[NSURL URLWithString: currentMsg.background_url ]];
        
    }
    else
    {
        [cell.bgImageView setImage:nil];
        int bgImageNo = currentMsg.background_no2;
        NSString* imageName = [NSString stringWithFormat:@"bg_drawable_%d@2x.jpg", bgImageNo];
        [cell.bgImageView setImage:[UIImage imageNamed:imageName]];
        
    }
    
    return cell;
}



- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    [cell.contentView setBackgroundColor:[UIColor clearColor]];
    MessageModel* currentMsg = (MessageModel*)[messageArray objectAtIndex:indexPath.row];
    MsgTableViewCell* msgCell = (MsgTableViewCell*)cell;

    [msgCell.commentImageView setImage:[UIImage imageNamed:@"comment_white"]];
    [msgCell.likeImageView setImage:[UIImage imageNamed:@"ic_like"]];
    if (currentMsg.has_like)
    {
        [msgCell.likeImageView setImage:[UIImage imageNamed:@"ic_liked"]];
    }
    
}
#pragma mark - PullTableViewDelegate
- (void)pullTableViewDidTriggerRefresh:(PullTableView *)pullTableView
{
    [self performSelector:@selector(refreshTable) withObject:nil afterDelay:1.5f];
}

- (void)pullTableViewDidTriggerLoadMore:(PullTableView *)pullTableView
{
    [self performSelector:@selector(loadMoreDataToTable) withObject:nil afterDelay:3.0f];
}

#pragma mark - Refresh and load more methods
- (void)refreshTable
{
//    if (0 == [messageArray count])
//        return;
    self.pullTableView.pullTableIsRefreshing = YES;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSArray* requestRes = [[NetWorkConnect sharedInstance] categoryMsgWithType:messageType
                                                                        categoryId:_categoryId
                                                                           sinceId:0
                                                                             maxId:INT_MAX
                                                                             count:20];
        if (messageType == 1) {
            [hotMsgArray removeAllObjects];
            [hotMsgArray addObjectsFromArray:requestRes];
        } else {
            [latestMsgArray removeAllObjects];
            [latestMsgArray addObjectsFromArray:requestRes];
        }
        [messageArray removeAllObjects];
        [messageArray addObjectsFromArray:requestRes];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            if ( _pullTableView.pullTableIsRefreshing )
            {
                _pullTableView.pullLastRefreshDate = [NSDate date];
                _pullTableView.pullTableIsRefreshing = NO;
                [_pullTableView reloadData];
            }
        });
    });
}

- (void)loadMoreDataToTable
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        MessageModel* lastMessage = [messageArray lastObject];
        NSArray* loadMoreRes = [[NetWorkConnect sharedInstance] categoryMsgWithType:messageType categoryId:_categoryId sinceId:0 maxId:lastMessage.message_id count:20];
        
        __block NSInteger fromIndex = [messageArray count];
        [messageArray addObjectsFromArray:loadMoreRes];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
            
            for(id result __unused in loadMoreRes)
            {
                [indexPaths addObject:[NSIndexPath indexPathForRow:fromIndex inSection:0]];
                fromIndex++;
            }
            
            [_pullTableView beginUpdates];
            [_pullTableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationMiddle];
            [_pullTableView endUpdates];
            if (indexPaths.count > 0)
                [_pullTableView scrollToRowAtIndexPath:indexPaths[0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
            self.pullTableView.pullTableIsLoadingMore = NO;
        });
    });
}

- (IBAction)publishMessage:(id)sender
{
    NSDictionary* msgLimmit = [[NetWorkConnect sharedInstance] userMessageLimit];
    
    if (nil == msgLimmit)
        return;
    if( [[msgLimmit objectForKey:@"remain_count"] integerValue] > 0 )
    {
        PublishMsgViewController* publisMsgVC = [self.storyboard instantiateViewControllerWithIdentifier:@"PublishMsgVCIdentifier"];
        [self.navigationController pushViewController:publisMsgVC animated:YES];
    }
    else
    {
        AlertContent(@"为了保证社区纯净，您每天发布次数有限，今天已达上限");
    }
}

- (void)likeImageTap:(UITapGestureRecognizer*)gestureRecognizer
{
    MsgTableViewCell* tappedCell = (MsgTableViewCell*)[UIView tableViewCellFromTapGestture:gestureRecognizer];
    
    NSIndexPath* tapIndexPath = [self.pullTableView indexPathForCell:tappedCell];
    MessageModel* currentMsg = (MessageModel*)[messageArray objectAtIndex:tapIndexPath.row];
    if (currentMsg.has_like)
        return;
    
    //爱心特效
    tappedCell.likeImageView.layer.contents = (id)[UIImage imageNamed:(i%2==0?@"2":@"1")].CGImage;
    CAKeyframeAnimation *k = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    k.values = @[@(0.1),@(1.0),@(1.5)];
    k.keyTimes = @[@(0.0),@(0.5),@(0.8),@(1.0)];
    k.calculationMode = kCAAnimationLinear;
    
    i++;
    [tappedCell.likeImageView.layer addAnimation:k forKey:@"SHOW"];
    [tappedCell.likeImageView setImage:[UIImage imageNamed:@"ic_liked.png"]];
    
    tappedCell.likeNumLabel.text = [NSString stringWithFormat:@"%d", currentMsg.likes_count + 1];
    
    MessageModel* message = [[NetWorkConnect sharedInstance] messageLikeByMsgId:currentMsg.message_id];
    if (message)
    {
        [messageArray replaceObjectAtIndex:tapIndexPath.row withObject:message];
    }
}

- (IBAction)onDemoButton:(id)sender {
    RNBlurModalView *modal;
    UIView *moreView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 150)];
    moreView.backgroundColor = [UIColor whiteColor];
    moreView.layer.cornerRadius = 3.f;
    modal = [[RNBlurModalView alloc] initWithViewController:self view:moreView];
    [modal show];
    
    NSArray* btnTitles = @[@"私信", @"分享", @"举报"];
    for (NSInteger k = 0; k < btnTitles.count; k++) {
        UIButton* button = [[UIButton alloc]initWithFrame:CGRectMake(0, k* 50, 200, 50)];
        [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [button setTitle:btnTitles[k] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(handleMoreBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [moreView addSubview:button];
    }
    
    for (NSInteger k = 1; k <= 2; ++k) {
        UIView* lineView = [[UIView alloc] initWithFrame:CGRectMake(10, 50 * k, 180, 1.0f)];
        [lineView setBackgroundColor:[UIColor lightGrayColor]];
        [moreView addSubview:lineView];
    }
}

- (UIView*)configureVoteView:(NSArray*)votes {
    NSInteger voteNumber = votes.count;
    UIView* voteView = [[UIView alloc] initWithFrame:CGRectMake(0, 320, 320, kVoteLabelHeight * voteNumber)];
    voteView.tag = kVoteViewTag;
    [voteView setBackgroundColor:[UIColor whiteColor]];
    for (NSInteger k = 0; k < voteNumber; k++) {
        
        VoteModel* vote = (VoteModel*)[votes objectAtIndex:k];
        ZDProgressView*progressView=[[ZDProgressView alloc] initWithFrame:CGRectMake(0, k * kVoteLabelHeight, 320, kVoteLabelHeight)];
        progressView.prsColor = UIColorFromRGB(0x78c4fe);
        progressView.progress = vote.pecentage/100.0;
        progressView.borderWidth = 0;
        progressView.tag = vote.voteId;
        progressView.text = vote.content;
        UILabel*precentageLabel = [[UILabel alloc] initWithFrame:CGRectMake(250, 10, 60, 30)];
        precentageLabel.text = [NSString stringWithFormat:@"%d%s", vote.pecentage, "%"];
        precentageLabel.tag = k+99;
        precentageLabel.textAlignment = NSTextAlignmentCenter;
        precentageLabel.textColor = UIColorFromRGB(0x666666);
        precentageLabel.backgroundColor = [UIColor clearColor];
        [progressView addSubview:precentageLabel];
        [voteView addSubview:progressView];
        
        UIButton*but=[[UIButton alloc] initWithFrame:CGRectMake(0, k * kVoteLabelHeight,320, kVoteLabelHeight)];
        [but addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
        but.tag = vote.voteId;
        but.backgroundColor = [UIColor clearColor];
        [voteView addSubview:but];
        
    }
    return voteView;
}


- (IBAction)deleteButton:(UITapGestureRecognizer*)gestureRecognizer{
    NSLog(@"delete");
    _deleteView=[[UIView alloc]initWithFrame:CGRectMake(170, 13, 140, 28)];
    _deleteView.backgroundColor=[UIColor whiteColor];
    CGPoint location = [gestureRecognizer locationInView:self.pullTableView];
    NSIndexPath *indexPath = [self.pullTableView indexPathForRowAtPoint:location];
    UITableViewCell *cell = [self.pullTableView cellForRowAtIndexPath:indexPath];
    _deleteView.layer.masksToBounds = YES;
    _deleteView.layer.cornerRadius = 10.0;
    _deleteView.layer.borderWidth = 1.0;
    _deleteView.alpha=0;
    _deleteView.transform=CGAffineTransformMakeScale(0, 0);
    _deleteView.transform=CGAffineTransformMakeTranslation(30, 0);
    [cell.contentView addSubview:_deleteView];
    
    
    UIButton* button=[[UIButton alloc]initWithFrame:CGRectMake(0, 0, 140, 28)];
    button.backgroundColor=[UIColor clearColor];
    [button addTarget:self action:@selector(deletePressed:) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"     不想在看到" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    button.tag=indexPath.row;
    [_deleteView addSubview:button];
    
    UIImageView* image=[[UIImageView alloc]initWithFrame:CGRectMake(10, 1.5, 25, 25)];
    [image setImage:[UIImage imageNamed:@"delete_after.png"]];
    [_deleteView addSubview:image];
    
  
    [UIView animateWithDuration:0.4 animations:^{
        _deleteView.transform=CGAffineTransformMakeScale(1, 1);
        _deleteView.alpha=1;
        _deleteView.transform=CGAffineTransformMakeTranslation(0, 0);
        
    } completion:^(BOOL finished) {
        _deleteView.transform=CGAffineTransformIdentity;
    }];
    
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(isMoreViewOpen) {
        [_moreBtnView removeFromSuperview];
        isMoreViewOpen = NO;
        return;
    }
    savePath=indexPath;
    
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    MessageDetailViewController* msgDetailVC = [self.storyboard instantiateViewControllerWithIdentifier:@"MessageDetailVCIdentifier"];
    msgDetailVC.delegate=self;
    msgDetailVC.selectedPath=indexPath;
    msgDetailVC.selectedMsg = (MessageModel*)[messageArray objectAtIndex:indexPath.row];
    [self.navigationController pushViewController:msgDetailVC animated:YES];
}

-(void)refreshTableViewCell:(NSIndexPath*)indexPath withArray:(NSArray*)voteArr withOther:(MessageModel*)othArr
{
    
    arr=voteArr;
    savePath=indexPath;
    isTap=YES;
    [messageArray replaceObjectAtIndex:indexPath.row withObject:othArr];
    
}

-(void)buttonAction:(UIButton*)sender
{
    
    UIView*vote= [sender superview];
    if ([vote isKindOfClass:[UIView class]]!=YES ) {
        return;
    }
    NSLog(@"%@",vote);
    MsgTableViewCell *tableViewCell = (MsgTableViewCell*)vote.superview;
    while (tableViewCell) {
        if ([tableViewCell isKindOfClass:[MsgTableViewCell class]]) {
            break;
        }
        tableViewCell = (MsgTableViewCell*)tableViewCell.superview;
    }
    NSIndexPath *indexPath = [_pullTableView indexPathForCell:tableViewCell];
    NSLog(@"%d",indexPath.row);
    MessageModel* currentMsg=[messageArray objectAtIndex:indexPath.row];
    if (currentMsg.voted==1)
    {
        NSLog(@"voted");
    }else
    {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            MessageModel* mesMode= [[NetWorkConnect sharedInstance] messageVote:sender.tag ];
            NSArray*voteArr=mesMode.votes;
            [messageArray replaceObjectAtIndex:indexPath.row withObject:mesMode];
            dispatch_sync(dispatch_get_main_queue(), ^{
                
                
                for (int j=0; j<[voteArr count]; j++) {
                    
                    VoteModel*voteModal=[voteArr objectAtIndex:j];
                    ZDProgressView*progressView= (ZDProgressView*)[vote viewWithTag:voteModal.voteId];
                    UILabel*label=(UILabel*)[vote viewWithTag:j+99];
                    if ([label isKindOfClass:[UILabel class]]==YES) {
                        label.text=[NSString stringWithFormat:@"%d%s",voteModal.pecentage,"%"];
                        label.hidden=NO;
                    }
                    
                    
                    
                    [UIView animateWithDuration:0.3 animations:^{
                        
                        progressView.progress=voteModal.pecentage/100.0;
                        
                    } completion:^(BOOL finished) {
                        
                    }];
                }
            });
        });
        
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"PageOne"];
    if ( savePath&&isTap) {
        
        UITableViewCell*cell=[self.pullTableView cellForRowAtIndexPath:savePath];
        UIView*vote=[cell viewWithTag:kVoteViewTag];
        for (int j=0; j<[arr count]; j++) {
            
            VoteModel*voteModal=[arr objectAtIndex:j];
            ZDProgressView*progressView= (ZDProgressView*)[vote viewWithTag:voteModal.voteId];
            UILabel*label=(UILabel*)[vote viewWithTag:j+99];
            if ([label isKindOfClass:[UILabel class]]==YES) {
                label.text=[NSString stringWithFormat:@"%d%s",voteModal.pecentage,"%"];
                label.hidden=NO;
            }
            progressView.progress=voteModal.pecentage/100.0;
            NSLog(@"%@",progressView);
            
        }
        savePath=nil;
        isTap=NO;
        
    }
}

- (void)deletePressed:(UIButton*)sender {
    
    MessageModel* currentMsg=[messageArray objectAtIndex:sender.tag];
    if (currentMsg.is_owner) {
        [UIAlertView showWithTitle:@"提示" message:@"是否要删除自已发送的消息" style:UIAlertViewStyleDefault cancelButtonTitle:@"取消" otherButtonTitles:@[@"确定"] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex==0) {
                
            }else
            {
                [self deleteMes:currentMsg.message_id messageIndex:sender.tag];
            }
        }];
        
    }else
    {
        [self deleteMes:currentMsg.message_id messageIndex:sender.tag];
    }
    
}


-(void)deleteMes:(NSInteger)messageId messageIndex:(NSInteger)tag
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSDictionary*result=[[NetWorkConnect sharedInstance] deleteMessage:messageId ];
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (result==nil) {
                NSLog(@"失败！");
            }else
            {
                [messageArray removeObjectAtIndex:tag];
                
                [self.pullTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:tag inSection:0]] withRowAnimation:UITableViewRowAnimationFade ];
            }
            
        });
    });
}
@end
