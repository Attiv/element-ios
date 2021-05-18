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

#import "Common.h"

@implementation Common

+ (UIColor *)text66Color {
    return WRGBHex(0x666666);
}

+ (UIColor *)text33Color {
    return WRGBHex(0x333333);
}

+ (UIColor *)text99Color {
    return WRGBHex(0x999999);
}

+ (UIColor *)textLightBlueColor {
    return WRGBHex(0x00D1FF);
}

+ (UIColor *)fieldBorderColor {
    return WRGBHex(0xDCDCDC);
}

+ (UIColor *)onlineColor {
    return WRGBHex(0x52C22C);
}

+ (UIColor *)lightGray {
    return WRGBHex(0xF2F0F7);
}

+(void)initLanguage{
    NSString *language=[self currentLanguage];
    if (language.length>0) {
        WLog(@"自设置语言:%@",language);
    }else{
        [self systemLanguage];
    }
}

+(NSString *)currentLanguage{
    NSString *language=[[NSUserDefaults standardUserDefaults]objectForKey:Language_Key];
    return language;
}

/// 设置多语言
/// @param language 语言
+ (void)setNewLanguage:(NSString *)language
{
    NSString * setLanguage = [[NSUserDefaults standardUserDefaults] objectForKey:Language_Key];
    if ([language isEqualToString:setLanguage]) {
        return;
    }
    // 简体中文
    else if ([language isEqualToString:Chinese_Simple]) {
        [[NSUserDefaults standardUserDefaults] setObject:Chinese_Simple forKey:Language_Key];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    // 英文
    else if ([language isEqualToString:English_US]) {
        [[NSUserDefaults standardUserDefaults] setObject:English_US forKey:Language_Key];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    [NSBundle setLanguage:language];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kChangeLanguageNotify object:nil];

}

+ (void)systemLanguage{
    NSString *languageCode = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"][0];
    WLog(@"系统语言:%@",languageCode);
    if([languageCode hasPrefix:@"zh-Han"]){
        languageCode = Chinese_Simple;//简体中文
    }else if([languageCode hasPrefix:@"en"]){
        languageCode = English_US;//英语
    }
    [self setNewLanguage:languageCode];
}


@end
