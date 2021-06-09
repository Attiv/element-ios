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

#import "VTXMPPTool.h"
#import "PrefixHeader.pch"

@interface VTXMPPTool () <XMPPStreamDelegate>

@end

@implementation VTXMPPTool

+ (VTXMPPTool *)shareTool {
	static VTXMPPTool *tool;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		tool = [[VTXMPPTool alloc] init];
	});
	return tool;
}


-(void)startXMPP {
	if (nil == self.xmppStream) {
		self.xmppStream = [[XMPPStream alloc] init];
		[self.xmppStream setHostName:@"chat-ext.kelare-demo.com"];
		[self.xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
		XMPPJID *jid = [XMPPJID jidWithUser:@"kelaredemo2" domain:@"chat.kelare-demo.com" resource:@"iOS"];
		[self.xmppStream setMyJID:jid];

		// 创建重连组件
		XMPPReconnect *xmppReconnect = [[XMPPReconnect alloc]init];
		[xmppReconnect activate:[VTXMPPTool shareTool].xmppStream];


		XMPPRosterCoreDataStorage *xmppRosterCoreDataStorage = [[XMPPRosterCoreDataStorage alloc] init];
		XMPPRoster *xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:xmppRosterCoreDataStorage];
		self.xmppRoster = xmppRoster;
		[xmppRoster activate:[VTXMPPTool shareTool].xmppStream];
		// 用户管理上下文
		NSManagedObjectContext* xmppRosterManagedObjectContext = xmppRosterCoreDataStorage.mainThreadManagedObjectContext;
		self.xmppRosterManagedObjectContext = xmppRosterManagedObjectContext;


		//创建消息保存策略（规则，规定）
		XMPPMessageArchivingCoreDataStorage* messageStorage = [XMPPMessageArchivingCoreDataStorage sharedInstance];
		//用消息保存策略创建消息保存组件
		XMPPMessageArchiving* xmppMessageArchiving = [[XMPPMessageArchiving alloc]initWithMessageArchivingStorage:messageStorage];
		//使组件生效
		[xmppMessageArchiving activate:[VTXMPPTool shareTool].xmppStream];
		//提取消息保存组件的coreData上下文
		self.xmppMessageManagedObjectContext = messageStorage.mainThreadManagedObjectContext;

		//连接服务器
		NSError *error2 = nil;
		[[VTXMPPTool shareTool].xmppStream connectWithTimeout:10 error:&error2];
		if (error2) {
			WLog(@"连接出错：%@",[error2 localizedDescription]);
			[QMUITips hideAllTips];
		}
	}
}



#pragma mark - XMPP delegate
//连接后的回调
-(void)xmppStreamDidConnect:(XMPPStream *)sender
{
	//连接成功后认证用户名和密码
	NSError *error = nil;
	[self.xmppStream authenticateWithPassword:@"P@55word1!" error:&error];
	if (error) {
		WLog(@"认证错误：%@",[error localizedDescription]);
	}
}

//认证成功后的回调
-(void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
	// 设置在线状态
	XMPPPresence *pre = [XMPPPresence presence];
	[self.xmppStream sendElement:pre];
	WLog(@"登录成功");
}

//认证失败后的回调
-(void)xmppStream:sender didNotAuthenticate:(DDXMLElement *)error
{
	WLog(@"登录失败");
}

@end
