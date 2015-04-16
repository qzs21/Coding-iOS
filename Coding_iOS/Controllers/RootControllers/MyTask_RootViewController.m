//
//  MyTask_RootViewController.m
//  Coding_iOS
//
//  Created by 王 原闯 on 14-7-29.
//  Copyright (c) 2014年 Coding. All rights reserved.
//

#import <CoreText/CoreText.h>
#import "MyTask_RootViewController.h"
#import "Coding_NetAPIManager.h"
#import "EditTaskViewController.h"
#import "RDVTabBarController.h"

@interface MyTask_RootViewController ()

@property (strong, nonatomic) Projects *myProjects;
@property (strong, nonatomic) NSMutableDictionary *myProTksDict;
@property (strong, nonatomic) NSMutableArray *myProjectList;

@property (strong, nonatomic) XTSegmentControl *mySegmentControl;
@property (strong, nonatomic) iCarousel *myCarousel;
@end

@implementation MyTask_RootViewController

#pragma mark TabBar
- (void)tabBarItemClicked{
    if (_myCarousel.currentItemView && [_myCarousel.currentItemView isKindOfClass:[ProjectTaskListView class]]) {
        ProjectTaskListView *listView = (ProjectTaskListView *)_myCarousel.currentItemView;
        [listView tabBarItemClicked];
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"我的任务";
    
    _myProjects = [Projects projectsWithType:ProjectsTypeAll andUser:nil];
    _myProTksDict = [[NSMutableDictionary alloc] initWithCapacity:1];
    _myProjectList = [[NSMutableArray alloc] initWithObjects:[Project project_All], nil];
    //添加myCarousel
    self.myCarousel = ({
        iCarousel *icarousel = [[iCarousel alloc] init];
        icarousel.dataSource = self;
        icarousel.delegate = self;
        icarousel.decelerationRate = 1.0;
        icarousel.scrollSpeed = 1.0;
        icarousel.type = iCarouselTypeLinear;
        icarousel.pagingEnabled = YES;
        icarousel.clipsToBounds = YES;
        icarousel.bounceDistance = 0.2;
        [self.view addSubview:icarousel];
        [icarousel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view).insets(UIEdgeInsetsMake(kMySegmentControlIcon_Height, 0, 0, 0));
        }];
        icarousel;
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self resetCurView];
}


- (void)resetCurView{
    if (!_myProjects.isLoading) {
        __weak typeof(self) weakSelf = self;
        [[Coding_NetAPIManager sharedManager] request_ProjectsHaveTasks_WithObj:_myProjects andBlock:^(id data, NSError *error) {
            if (data) {
                weakSelf.myProjectList = [[NSMutableArray alloc] initWithObjects:[Project project_All], nil];
                [weakSelf.myProjectList addObjectsFromArray:((Projects*)data).list];
            }
            [weakSelf configSegmentControl];
        }];
    }
}

- (void)configSegmentControl{
    //添加滑块
    if (_mySegmentControl) {
        [_mySegmentControl removeFromSuperview];
    }
    
    __weak typeof(self) weakSelf = self;
    CGRect segmentFrame = CGRectMake(0, 0, kScreen_Width, kMySegmentControlIcon_Height);
    _mySegmentControl = [[XTSegmentControl alloc] initWithFrame:segmentFrame Items:_myProjectList selectedBlock:^(NSInteger index) {
        [weakSelf.myCarousel scrollToItemAtIndex:index animated:NO];
    }];
    [self.view addSubview:_mySegmentControl];
    
    if (_myCarousel.currentItemIndex != 0) {
        _myCarousel.currentItemIndex = 0;
    }
    [_myCarousel reloadData];
}

#pragma mark iCarousel M
- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel{
    return [_myProjectList count];
}
- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index reusingView:(UIView *)view{
    Project *curPro = [_myProjectList objectAtIndex:index];
    Tasks *curTasks = [_myProTksDict objectForKey:curPro.id];
    if (!curTasks) {
        curTasks = [Tasks tasksWithPro:curPro queryType:TaskQueryTypeAll];
        [_myProTksDict setObject:curTasks forKey:curPro.id];
    }
    
    ProjectTaskListView *listView = (ProjectTaskListView *)view;
    if (listView) {
        [listView setTasks:curTasks];
    }else{
        __weak typeof(self) weakSelf = self;
        listView = [[ProjectTaskListView alloc] initWithFrame:carousel.bounds tasks:curTasks block:^(ProjectTaskListView *taskListView, Task *task) {
            EditTaskViewController *vc = [[EditTaskViewController alloc] init];
            vc.myTask = task;
            vc.taskChangedBlock = ^(Task *curTask, TaskEditType type){
                [taskListView refreshToQueryData];
            };
            [weakSelf.navigationController pushViewController:vc animated:YES];
        } tabBarHeight:CGRectGetHeight(self.rdv_tabBarController.tabBar.frame)];
    }
    return listView;
}

- (void)carouselDidScroll:(iCarousel *)carousel{
    if (_mySegmentControl) {
        float offset = carousel.scrollOffset;
        if (offset > 0) {
            [_mySegmentControl moveIndexWithProgress:offset];
        }
    }
}
- (void)carouselCurrentItemIndexDidChange:(iCarousel *)carousel{
    if (_mySegmentControl) {
        _mySegmentControl.currentIndex = carousel.currentItemIndex;
    }
    ProjectTaskListView *curView = (ProjectTaskListView *)carousel.currentItemView;
    [curView refreshToQueryData];
}

@end
