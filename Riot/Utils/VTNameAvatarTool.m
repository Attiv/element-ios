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

#import "VTNameAvatarTool.h"
#import "PrefixHeader.pch"


@implementation VTNameAvatarTool

+(NSArray *)avatarBGColors {
	static NSArray *avatarBGColors;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		avatarBGColors = @[WRGBHex(0xBC61CF), WRGBHex(0xF26666), WRGBHex(0xF29A52), WRGBHex(0xF4C329), WRGBHex(0xCBD057), WRGBHex(0x289ED3), WRGBHex(0x29B3F0)];
	});
	return avatarBGColors;
}

+ (NSString *)getShortNameWithFullName:(NSString *)fullName {
	if ([self isChinese:fullName]) {
		if (fullName.length > 1) {
			return [fullName substringFromIndex:fullName.length - 2];
		}  else {
			return fullName;
		}
	} else {
		if (fullName.length > 1) {
			return [fullName substringToIndex:2];
		} else {
			return fullName;
		}
	}
}

+ (BOOL)isChinese:(NSString*) name
{
	NSString *match = @"(^[\u4e00-\u9fa5]+$)";
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF matches %@", match];
	return [predicate evaluateWithObject:name];
}

+ (BOOL)includeChinese:(NSString*) name
{
	for(int i=0; i< [name length]; i++)
	{
		int a =[name characterAtIndex:i];
		if( a >0x4e00&& a <0x9fff) {
			return YES;
		}
	}
	return NO;
}

+(UIColor *)getColorFromUserName:(NSString *)userName {
	NSInteger idx = [userName hash] % 7;
	return [[self avatarBGColors] objectAtIndex:idx];
}

@end
