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

@interface VTChatViewController ()<UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate,NSFetchedResultsControllerDelegate,XMPPStreamDelegate>

//从数据库中获取发送内容的xmppManagedObjectContext
@property(nonatomic,strong) NSManagedObjectContext *xmppManagedObjectContext;

//显示在tableView上
@property(nonatomic,strong) NSFetchedResultsController *fetchedResultsController;

//XMPPSteam流
@property (strong, nonatomic) XMPPStream * xmppStream;
@end

@implementation VTChatViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	[self setupUI];
	// Do any additional setup after loading the view.
}

- (void) setupUI {
	self.title = self.friend.displayName;
	self.tableView.delegate = self;
	self.tableView.dataSource = self;

	[[VTXMPPTool shareTool] startXMPP];
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
		WLog(@"%s  %@",__FUNCTION__,[error localizedDescription]);
	}

}

#pragma mark - tableview
-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 40;
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

}

@end
