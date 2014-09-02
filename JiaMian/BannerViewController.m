//
//  BannerViewController.m
//  JiaMian
//
//  Created by wanyang on 14-8-24.
//  Copyright (c) 2014年 wy. All rights reserved.
//

#import "BannerViewController.h"
#import "CategoryCell.h"

@interface BannerViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate>
{
    NSMutableArray* bannerArr;
    NSMutableArray* categroyArr;
    
    NSTimer* timer;
    UICollectionReusableView* headerView;
}
@property (retain, nonatomic) UIPageControl* pageControl;
@property (retain, nonatomic) UILabel* bannerTitleLabel;
@end

#define kScrollViewTag 6001
#define kPageControllTag 6002
#define kCategoryCellIdentifier @"CategoryCell"
@implementation BannerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
    timer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(handleScrollByTime) userInfo:nil repeats:YES];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO];
    [timer invalidate];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    bannerArr = [NSMutableArray array];
    categroyArr = [NSMutableArray array];
    [self fetchDataFromServer:nil];
    
    UIView *bgView = [[UIView alloc]init];
    bgView.backgroundColor = UIColorFromRGB(0xf6f5f1);
    self.collectionView.backgroundView = bgView;
    
    UINib* nib = [UINib nibWithNibName:NSStringFromClass([CategoryCell class])
                                bundle:[NSBundle mainBundle]];
    [self.collectionView registerNib:nib forCellWithReuseIdentifier:kCategoryCellIdentifier];
}
- (void)handleScrollByTime
{
    UIScrollView* scrollV = (UIScrollView*)[headerView viewWithTag:kScrollViewTag];
    NSInteger newPage = (self.pageControl.currentPage + 1) % bannerArr.count;
    [self.pageControl setCurrentPage:newPage];
    [scrollV setContentOffset:CGPointMake(320 * newPage, 0) animated:YES];
    [self.bannerTitleLabel setText:[self bannerTitleLabelText:self.pageControl]];
}
- (void)fetchDataFromServer:(UIRefreshControl*)object
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSArray* banners = [[NetWorkConnect sharedInstance] getBannersByCount:5];
        NSArray* categories = [[NetWorkConnect sharedInstance] getCategoriesByCount:5 orderId:0];
        if (banners.count > 0) {
            [bannerArr removeAllObjects];
            [bannerArr addObjectsFromArray:banners];
        }
        if (categories.count > 0) {
            [categroyArr removeAllObjects];
            [categroyArr addObjectsFromArray:categories];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView reloadData];
        });
    });
    
    if (object && object.isRefreshing) {
        [object endRefreshing];
    }
}
#pragma mark UIScrollViewDelegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.pageControl.currentPage = floorf(scrollView.contentOffset.x / 320);
    timer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(handleScrollByTime) userInfo:nil repeats:YES];
    
    [self.bannerTitleLabel setText:[self bannerTitleLabelText:self.pageControl]];
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [timer invalidate];
    timer  = nil;
}
#pragma mark UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return categroyArr.count;
}
- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CategoryCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCategoryCellIdentifier
                                                                   forIndexPath:indexPath];
    CategoryModel* category = [categroyArr objectAtIndex:indexPath.row];
    [cell.titleLabel setText:category.title];
    [cell.descriptionLabel setText:category.description];
    [cell.bgImageView setImageWithURL:[NSURL URLWithString:category.background_url] placeholderImage:nil];
    return cell;
}
#pragma mark UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    CategoryModel* category = [categroyArr objectAtIndex:indexPath.row];
    if (101 == category.category_type) //圈内八卦
    {
        BOOL isLogIn = [USER_DEFAULT boolForKey:kUserLogIn];
        UIStoryboard* mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
        if ( NO == isLogIn )
        {
            RegAndLoginViewController* logInVC = [mainStoryboard instantiateViewControllerWithIdentifier:@"LogInVCIdentifier"];
            [self presentViewController:logInVC animated:YES completion:nil];
        }
        else
        {
            HomePageViewController* homeVC = [mainStoryboard instantiateViewControllerWithIdentifier:@"HomePageVcIdentifier"];
            [self.navigationController pushViewController:homeVC animated:YES];
        }
    }
}
- (UICollectionReusableView*)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ( [kind isEqualToString:UICollectionElementKindSectionHeader] )
    {
        headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                        withReuseIdentifier:@"BannerHeaderIdentifier"
                                                               forIndexPath:indexPath];
        [headerView addSubview:self.bannerTitleLabel];
        [headerView addSubview:self.pageControl];
        
        UIScrollView* scrollV = (UIScrollView*)[headerView viewWithTag:kScrollViewTag];
        NSInteger banerCount = [bannerArr count];
        CGSize scrollVSize =scrollV.bounds.size;
        [scrollV setContentSize:CGSizeMake(scrollVSize.width * banerCount, scrollVSize.height)];
        [scrollV setDelegate:self];
        
        for (int i = 0; i < banerCount; i++)
        {
            UIImageView* imageView = [[UIImageView alloc] initWithFrame:CGRectMake(scrollVSize.width * i, 0,
                                                                                   scrollVSize.width, scrollVSize.height)];
            BannerModel* banner = (BannerModel*)[bannerArr objectAtIndex:i];
            [imageView setImageWithURL:[NSURL URLWithString:banner.background_url] placeholderImage:nil];
            [scrollV addSubview:imageView];
        }
        return headerView;
    }
    return nil;
}
- (UIPageControl*)pageControl
{
    if (_pageControl == nil) {
        _pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(260, 150, 40, 10)];
        _pageControl.backgroundColor = [UIColor clearColor];
        _pageControl.currentPageIndicatorTintColor = [UIColor blueColor];
        _pageControl.pageIndicatorTintColor = [UIColor grayColor];
    }
    _pageControl.numberOfPages = bannerArr.count;
    return _pageControl;
}
- (UILabel*)bannerTitleLabel {
    if (_bannerTitleLabel == nil) {
        _bannerTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 140, 250, 20)];
        [_bannerTitleLabel setTextColor:[UIColor whiteColor]];
        [_bannerTitleLabel setBackgroundColor:[UIColor clearColor]];
        [_bannerTitleLabel setFont:[UIFont systemFontOfSize:14]];
    }
    return _bannerTitleLabel;
}
- (NSString*)bannerTitleLabelText:(UIPageControl*)pageControl {
    BannerModel* banner = [bannerArr objectAtIndex:pageControl.currentPage];
    return banner.title;
}
#pragma mark UICollectionViewDelegateFlowLayout
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 10.0f;
}
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 10.0f;
}
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(15.0f, 10.0f, 15.0f, 20.0f);
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(140.0f, 140.0f);
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section
{
    return CGSizeMake(0, 0);
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return CGSizeMake(320, 170);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
