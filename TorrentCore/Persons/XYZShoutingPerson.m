//
//  XYZShoutingPerson.m
//  TorrentCore
//
//  Created by sboerner on 13.08.13.
//  Copyright (c) 2013 sboerner. All rights reserved.
//

#import "XYZShoutingPerson.h"

@implementation XYZShoutingPerson

-(void)saySomething:(NSString *) greeting{
    NSString *uppercaseGreeting = [greeting uppercaseString];
    [super saySomething:uppercaseGreeting];
}

@end
