//
//  XYZPerson.h
//  TorrentCore
//
//  Created by sboerner on 13.08.13.
//  Copyright (c) 2013 sboerner. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XYZPerson : NSObject

@property NSString *firstName;
@property NSString *lastName;
@property NSNumber *yearOfBirth;
@property NSDate *dateOfBirth;

//+(id) person;
-(id)init;
-(void) sayHello;
-(void) sayGoodBye:(NSString *)greteesName;
-(void) saySomething:(NSString *) greeting;


@end
