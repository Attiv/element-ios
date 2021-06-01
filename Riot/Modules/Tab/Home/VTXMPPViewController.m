//
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <XMPPFramework/XMPPFramework.h>
#import <CoreData/CoreData.h>
#import "VTXMPPViewController.h"
#import "PrefixHeader.pch"


const NSString * kCellId = @"rosterCell";

@interface VTXMPPViewController () <UITableViewDataSource, UITableViewDelegate, XMPPStreamDelegate, NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) XMPPStream * xmppStream;
@property (strong, nonatomic) NSManagedObjectContext *xmppManagedObjectContext;
@property (strong, nonatomic) NSManagedObjectContext *xmppRosterManagedObjectContext;
//显示在tableView上
@property(nonatomic,strong) NSFetchedResultsController *fetchedResultsController;

@end

@implementation VTXMPPViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	[self setupUI];
	[self configXMPP];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

-(void) setupUI {
	[self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellId];
}

#pragma mark - XMPP
-(void)configXMPP {
	if (nil == self.xmppStream) {
		self.xmppStream = [[XMPPStream alloc] init];
		[self.xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
		XMPPJID *jid = [XMPPJID jidWithUser:@"vitta" domain:@"xmpp-hosting.de" resource:@"iOS"];
		[self.xmppStream setMyJID:jid];


		// 创建重连组件
		XMPPReconnect *xmppReconnect = [[XMPPReconnect alloc]init];
		[xmppReconnect activate:self.xmppStream];
		// 创建消息保存策略
		XMPPMessageArchivingCoreDataStorage * messageStorage = [XMPPMessageArchivingCoreDataStorage sharedInstance];
		// 用消息保存策略创建消息保存组件
		XMPPMessageArchiving * xmppMessageArchiving = [[XMPPMessageArchiving alloc] initWithMessageArchivingStorage:messageStorage];
		[xmppMessageArchiving activate:self.xmppStream];
		// 消息保存组件上下文
		NSManagedObjectContext *xmppManagedObjectContext = messageStorage.mainThreadManagedObjectContext;
		self.xmppManagedObjectContext = xmppManagedObjectContext;


		XMPPRosterCoreDataStorage *xmppRosterCoreDataStorage = [[XMPPRosterCoreDataStorage alloc] init];
		XMPPRoster *xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:xmppRosterCoreDataStorage];
		[xmppRoster activate:self.xmppStream];
		[xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
		// 用户管理上下文
		NSManagedObjectContext* xmppRosterManagedObjectContext = xmppRosterCoreDataStorage.mainThreadManagedObjectContext;
		self.xmppRosterManagedObjectContext = xmppRosterManagedObjectContext;

		//从CoreData中获取数据
		//通过实体获取FetchRequest实体
		NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([XMPPUserCoreDataStorageObject class])];
		//添加排序规则
		NSSortDescriptor * sortD = [NSSortDescriptor sortDescriptorWithKey:@"jidStr" ascending:YES];
		[request setSortDescriptors:@[sortD]];


		//获取FRC
		self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.xmppRosterManagedObjectContext sectionNameKeyPath:nil cacheName:nil];
		self.fetchedResultsController.delegate = self;

		//获取内容

		NSError * error;
		if (![self.fetchedResultsController performFetch:&error]) {
			NSLog(@"%s  %@",__FUNCTION__,[error localizedDescription]);
		}

		[self.tableView reloadData];


		//连接服务器
		NSError *error2 = nil;
		[self.xmppStream connectWithTimeout:10 error:&error2];
		if (error2) {
			WLog(@"连接出错：%@",[error2 localizedDescription]);
		}
	}
}


//如果对方想添加我为好友（订阅我），会触发该回调
//可以在此回调后，弹出好友请求界面
- (void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence {
	WLog(@"didReceivePresenceSubscriptionRequest");
}
//可以根据此回调中presence的type判断是不是别人删除了好友
- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence {
	WLog(@"didReceivePresence");
}

//开始同步服务器发送过来的自己的好友列表
- (void)xmppRosterDidBeginPopulating:(XMPPRoster *)sender {
	WLog(@"xmppRosterDidBeginPopulating");
}
//同步结束
- (void)xmppRosterDidEndPopulating:(XMPPRoster *)sender {
	WLog(@"xmppRosterDidEndPopulating");
	NSError * error;
	NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([XMPPUserCoreDataStorageObject class])];
	NSArray *friends = [self.xmppRosterManagedObjectContext executeFetchRequest:request error:&error];
	for (XMPPUserCoreDataStorageObject *object in friends) {

		NSString *name = [object displayName];
		if (!name) {
			name = [object nickname];
		}
		if (!name) {
			name = [object jidStr];
		}

		WLog(@"aa %@",name);
	}
}

//收到每一个好友
- (void)xmppRoster:(XMPPRoster *)sender didReceiveRosterItem:(NSXMLElement *)item {
	WLog(@"didReceiveRosterItem");
}
//如果不是初始化同步来的roster,那么会自动存入我的好友存储器
- (void)xmppRosterDidChange:(XMPPRosterMemoryStorage *)sender {
	WLog(@"xmppRosterDidChange");
}

// 好友列表
-(BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq {
	WLog(@"%@", iq);
	return YES;
}


//连接后的回调
-(void)xmppStreamDidConnect:(XMPPStream *)sender
{
	//连接成功后认证用户名和密码
	NSError *error = nil;
	[self.xmppStream authenticateWithPassword:@"123123" error:&error];
	if (error) {
		WLog(@"认证错误：%@",[error localizedDescription]);
	}
}

//认证成功后的回调
-(void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
	WLog(@"登录成功");
}

//认证失败后的回调
-(void)xmppStream:sender didNotAuthenticate:(DDXMLElement *)error
{
	WLog(@"登录失败");
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	// Return the number of sections.
	NSArray *sections = [self.fetchedResultsController sections];
	return sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSArray *sectoins = [self.fetchedResultsController sections];
	id<NSFetchedResultsSectionInfo> sectionInfo = sectoins[section];

	NSLog(@"%ld", [sectionInfo numberOfObjects]);
	return [sectionInfo numberOfObjects];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

	//获取数据
	XMPPUserCoreDataStorageObject *roster = [self.fetchedResultsController objectAtIndexPath:indexPath];

//	UserInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:@"rosterCell" forIndexPath:indexPath];
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellId forIndexPath:indexPath];
	//roster.jidStr
//	[cell setCellValue:roster.nickname WithJid:@"(个性签名)"];

	return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 80;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
	[self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
        atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {

	switch(type) {
	case NSFetchedResultsChangeInsert:
		[self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
		 withRowAnimation:UITableViewRowAnimationFade];
		break;

	case NSFetchedResultsChangeDelete:
		[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
		 withRowAnimation:UITableViewRowAnimationFade];
		break;
	}
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
        atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
        newIndexPath:(NSIndexPath *)newIndexPath {

	UITableView *tableView = self.tableView;

	switch(type) {

	case NSFetchedResultsChangeInsert:
		[tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
		 withRowAnimation:UITableViewRowAnimationFade];
		break;

	case NSFetchedResultsChangeDelete:
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
		 withRowAnimation:UITableViewRowAnimationFade];
		break;

	case NSFetchedResultsChangeUpdate:
		[tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
		break;

	case NSFetchedResultsChangeMove:
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
		 withRowAnimation:UITableViewRowAnimationFade];
		[tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
		 withRowAnimation:UITableViewRowAnimationFade];
		break;
	}
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	[self.tableView endUpdates];
}

@end
