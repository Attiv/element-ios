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

#import "VTChatViewController.h"
#import "VTXMPPTool.h"
#import "PrefixHeader.pch"
#import <UITableView+FDTemplateLayoutCell.h>

const NSString *reusedCellId = @"chatCellId";

@interface VTChatViewController ()<UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate,NSFetchedResultsControllerDelegate,XMPPStreamDelegate>

//从数据库中获取发送内容的xmppManagedObjectContext
@property(nonatomic,strong) NSManagedObjectContext *xmppManagedObjectContext;

//显示在tableView上
@property(nonatomic,strong) NSFetchedResultsController *fetchedResultsController;

@property (strong, nonatomic) QMUITableView* tableView;

@property (strong, nonatomic) UIView *toolView;

@property(strong, nonatomic) QMUITextField *inputField;
@end

@implementation VTChatViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	[self setupUI];
	// Do any additional setup after loading the view.
}

- (void) setupUI {
	self.title = self.friend.displayName;

	QMUITableView *tableView = [[QMUITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
	[self.view addSubview:tableView];
	self.tableView = tableView;
	[self.view setBackgroundColor:[UIColor whiteColor]];
	[tableView setBackgroundColor:[UIColor whiteColor]];

	[tableView mas_makeConstraints:^(MASConstraintMaker *make) {
	         make.top.mas_equalTo(self.view.mas_top);
	         make.left.mas_equalTo(self.view.mas_left);
	         make.right.mas_equalTo(self.view.mas_right);
	         make.bottom.mas_equalTo(self.view.mas_bottom).mas_offset(-50);
	 }];

	UIView *toolView = [[UIView alloc] init];
	[self.view addSubview:toolView];
	[toolView setBackgroundColor:[Common lightGray]];
	[toolView mas_makeConstraints:^(MASConstraintMaker *make) {
	         make.left.mas_equalTo(self.view.mas_left);
	         make.right.mas_equalTo(self.view.mas_right);
	         make.height.mas_equalTo(50);
	         make.bottom.mas_equalTo(self.view.mas_bottom).mas_offset(-50);
	 }];


	QMUIButton *sendButton = [[QMUIButton alloc] init];
	[sendButton setTitle:@"Send" forState:UIControlStateNormal];
	[sendButton addTarget:self action:@selector(sendButtonClicked) forControlEvents:UIControlEventTouchUpInside];
	[toolView addSubview:sendButton];

	[sendButton mas_makeConstraints:^(MASConstraintMaker *make) {
	         make.right.mas_equalTo(toolView.mas_right).mas_offset(-16);
	         make.centerY.mas_equalTo(toolView.mas_centerY);
	         make.width.mas_equalTo(60);
	         make.height.mas_equalTo(20);
	 }];


	QMUITextField *inputText = [[QMUITextField alloc] init];
	[inputText setBackgroundColor:[UIColor whiteColor]];
	inputText.textInsets = UIEdgeInsetsMake(0, 8, 0, 8);
	inputText.layer.cornerRadius = 6;
	inputText.layer.borderWidth = 1;
	inputText.layer.borderColor = [Common fieldBorderColor].CGColor;
	[inputText.layer masksToBounds];
	self.inputField = inputText;
	[toolView addSubview:inputText];
	inputText.placeholder = kString(@"send_a_message");
	[inputText mas_makeConstraints:^(MASConstraintMaker *make) {
	         make.height.mas_equalTo(30);
	         make.right.mas_equalTo(sendButton.mas_left).mas_offset(-8);
	         make.centerY.mas_equalTo(toolView.mas_centerY);
	         make.width.mas_equalTo(toolView.mas_width).mas_offset(-100);
	 }];


	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.tableView.estimatedRowHeight = 0;
	self.tableView.estimatedSectionFooterHeight = 0;
	self.tableView.estimatedSectionHeaderHeight = 0;
	self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

	[[VTXMPPTool shareTool] startXMPP];
	[[VTXMPPTool shareTool].xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];

	//创建消息保存策略（规则，规定）
	XMPPMessageArchivingCoreDataStorage* messageStorage = [XMPPMessageArchivingCoreDataStorage sharedInstance];
	//用消息保存策略创建消息保存组件
	XMPPMessageArchiving* xmppMessageArchiving = [[XMPPMessageArchiving alloc]initWithMessageArchivingStorage:messageStorage];
	//使组件生效
	[xmppMessageArchiving activate:[VTXMPPTool shareTool].xmppStream];
	//提取消息保存组件的coreData上下文
	self.xmppManagedObjectContext = messageStorage.mainThreadManagedObjectContext;

	//通过实体获取request()
	NSFetchRequest * request = [[NSFetchRequest alloc]initWithEntityName:NSStringFromClass([XMPPMessageArchiving_Message_CoreDataObject class])];
	NSSortDescriptor * sortD = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES];
	[request setSortDescriptors:@[sortD]];

	NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"bareJidStr=='%@'",self.friend.jidStr]];
	[request setPredicate:predicate];


	self.fetchedResultsController = [[NSFetchedResultsController alloc]initWithFetchRequest:request managedObjectContext:self.xmppManagedObjectContext sectionNameKeyPath:nil cacheName:nil];

	self.fetchedResultsController.delegate = self;

	NSError * error;

	if (![self.fetchedResultsController performFetch:&error])
	{
		WLog(@"chat error %s  %@",__FUNCTION__,[error localizedDescription]);
	}

}

-(void)sendButtonClicked {
	XMPPMessage *message = [XMPPMessage messageWithType:@"chat" to:self.friend.jid];
	[message addBody:self.inputField.text];
	[[VTXMPPTool shareTool].xmppStream sendElement:message];
}

#pragma mark - XMPPStreamDelegate

// 消息发送成功
- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message {

	WLog(@"===========>消息发送成功");
}

// 消息发送失败
- (void)xmppStream:(XMPPStream *)sender didFailToSendMessage:(XMPPMessage *)message error:(NSError *)error {

	WLog(@"===========>消息发送失败：%@", error);
}

// 接收消息成功
- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message {

	WLog(@"===========>接收消息成功：%@", message);
	[self.tableView reloadData];
}

#pragma mark - tableview
-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 40;
//    return [tableView fd_heightForCellWithIdentifier:@"reuse identifer" configuration:^(id cell) {
	// Configure this cell with data, same as what you've done in "-tableView:cellForRowAtIndexPath:"
	// Like:
	//    cell.entity = self.feedEntities[indexPath.row];
//      }];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	NSArray *secotions = [self.fetchedResultsController sections];
	return secotions.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

	NSArray *sectoins = [self.fetchedResultsController sections];
	id<NSFetchedResultsSectionInfo> sectionInfo = sectoins[section];

	return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	XMPPMessageArchiving_Message_CoreDataObject * message = [self.fetchedResultsController objectAtIndexPath:indexPath];
	WLog(@"message = %@",message);

	NSString * bodyStr = message.body;
	NSData * bodyData = [bodyStr dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary * dic = [NSJSONSerialization JSONObjectWithData:bodyData options:NSJSONReadingAllowFragments error:nil];

	WLog(@"dict = %@",dic);

	UITableViewCell *cell;
	return cell;
}

@end
