//
//  XYZPerson.m
//  TorrentCore
//
//  Created by sboerner on 13.08.13.
//  Copyright (c) 2013 sboerner. All rights reserved.
//

#import "XYZPerson.h"

@implementation XYZPerson

- (id)init {
    self = [super init];
    if (self) {
        _firstName=@"NoName";
        _lastName=@"NoName";
        _yearOfBirth=[_yearOfBirth initWithInt:1988];
        _dateOfBirth=[_dateOfBirth initWithString:@"18.08.1988"];
    }
    return self;
}

-(void)sayHello{
    [self saySomething:@"Hello World!"];
}

-(void)sayGoodBye:(NSString *) greteesName{
    NSString *buffer = @"Good Bye!";
    if([greteesName length]>0)
    {
        buffer=[buffer stringByReplacingOccurrencesOfString:@"!" withString:@" "];
        
        buffer=[buffer stringByAppendingString:greteesName];
        buffer=[buffer stringByAppendingString:@"!"];
    }
    [self saySomething:buffer];
}

-(void)saySomething:(NSString *) greeting{
    
    NSMutableString  *buffer = [NSMutableString new];
    [buffer setString:greeting];
    
    NSLog(@"Person %@ born on %@ is saying:\"%@\"",[self firstName], [self dateOfBirth] ,buffer);
}
@end
