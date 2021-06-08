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
#import "VTChatTableViewCell.h"
#import <UIScrollView+QMUI.h>

const NSString *reusedCellId = @"chatCellId";

@interface VTChatViewController ()<UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate,NSFetchedResultsControllerDelegate,XMPPStreamDelegate>



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
//	self.navigationController.navigationBar.backgroundColor = [Common themeColor];
	self.navigationController.navigationBar.barTintColor = [Common themeColor];


	QMUITableView *tableView = [[QMUITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
	[self.view addSubview:tableView];
	self.tableView = tableView;
	[self.view setBackgroundColor:[UIColor whiteColor]];
	[tableView setBackgroundColor:[UIColor whiteColor]];


	UIView *toolView = [[UIView alloc] init];
	[self.view addSubview:toolView];
	[toolView setBackgroundColor:[Common lightGray]];
	[toolView mas_makeConstraints:^(MASConstraintMaker *make) {
	         make.left.mas_equalTo(self.view.mas_left);
	         make.right.mas_equalTo(self.view.mas_right);
	         make.height.mas_equalTo(50);
	         make.bottom.mas_equalTo(self.view.mas_bottom);
	 }];

	[tableView mas_makeConstraints:^(MASConstraintMaker *make) {
	         make.top.mas_equalTo(self.view.mas_top);
	         make.left.mas_equalTo(self.view.mas_left);
	         make.right.mas_equalTo(self.view.mas_right);
	         make.bottom.mas_equalTo(toolView.mas_top);
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
	self.tableView.separatorStyle = UITableViewCellSelectionStyleNone;
	self.tableView.estimatedRowHeight = 0;
	self.tableView.estimatedSectionFooterHeight = 0;
	self.tableView.estimatedSectionHeaderHeight = 0;
	self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
	[self.tableView registerClass:[VTChatTableViewCell class] forCellReuseIdentifier:reusedCellId];

//	[[VTXMPPTool shareTool] startXMPP];
	[[VTXMPPTool shareTool].xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];

	[self initData];


}


-(void)initData {


	//通过实体获取request()
	NSFetchRequest * request = [[NSFetchRequest alloc]initWithEntityName:NSStringFromClass([XMPPMessageArchiving_Message_CoreDataObject class])];
	NSSortDescriptor * sortD = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES];
	[request setSortDescriptors:@[sortD]];

	NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"bareJidStr=='%@'",self.friend.jidStr]];
	[request setPredicate:predicate];


	self.fetchedResultsController = [[NSFetchedResultsController alloc]initWithFetchRequest:request managedObjectContext:[VTXMPPTool shareTool].xmppMessageManagedObjectContext sectionNameKeyPath:nil cacheName:nil];

	self.fetchedResultsController.delegate = self;

	NSError * error;

	if (![self.fetchedResultsController performFetch:&error])
	{
		WLog(@"chat error %s  %@",__FUNCTION__,[error localizedDescription]);
	}

}

-(void)sendButtonClicked {
	[self.inputField resignFirstResponder];
	XMPPMessage *message = [XMPPMessage messageWithType:@"chat" to:self.friend.jid];
	[message addBody:self.inputField.text];
	[[VTXMPPTool shareTool].xmppStream sendElement:message];
}

#pragma mark - XMPPStreamDelegate

// 消息发送成功
- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message {

	WLog(@"===========>消息发送成功");
	self.inputField.text = @"";

}

// 消息发送失败
- (void)xmppStream:(XMPPStream *)sender didFailToSendMessage:(XMPPMessage *)message error:(NSError *)error {

	WLog(@"===========>消息发送失败：%@", error);
}

// 接收消息成功
- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message {

	WLog(@"===========>接收消息成功：%@", message);
}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(NSXMLElement *)error {
	WLog(@"===========>接收失败: %@", error);
}


#pragma mark - tableview
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	XMPPMessageArchiving_Message_CoreDataObject * message = [self.fetchedResultsController objectAtIndexPath:indexPath];

	NSString * bodyStr = message.body;
	return [tableView fd_heightForCellWithIdentifier:reusedCellId configuration:^(VTChatTableViewCell* cell) {
	                cell.chatLabel.text = bodyStr;
	                cell.timeLabel.hidden = YES;
		}];
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

- (VTChatTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	XMPPMessageArchiving_Message_CoreDataObject * message = [self.fetchedResultsController objectAtIndexPath:indexPath];

	WLog(@"message === %@", message);
	NSString * bodyStr = message.body;

	VTChatTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reusedCellId forIndexPath:indexPath];
	cell.userInteractionEnabled = NO;
	cell.chatLabel.text = bodyStr;
	cell.timeLabel.hidden = YES;
	return cell;
}

//-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
//	[tableView qmui_scrollToBottomAnimated:YES];
//}

#pragma mark - NSFetchedResultsController

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
	[self.tableView qmui_scrollToBottomAnimated:YES];
}

@end
