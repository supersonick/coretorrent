//
//  NSData_SHA1.h
//  TorrentCore
//
//  Created by sboerner on 18.08.13.
//  Copyright (c) 2013 sboerner. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <CommonCrypto/CommonDigest.h>

@interface NSData (SHA1)

-(NSString *) returnSHA1HashAsString;
-(NSString *) returnSHA1HashAsLowerCaseCapitalsString;
-(NSData *) returnSHA1HashAsNSData;
@end

@implementation NSData (SHA1)

-(NSString *) returnSHA1HashAsString
{
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];

    NSNumber *myLength = [NSNumber numberWithInteger:[self length]];
    
    CC_SHA1(self.bytes, [myLength intValue], digest);

    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];

    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
    {
        [output appendFormat:@"%02X", digest[i]];
    }

return output;

}

-(NSString *) returnSHA1HashAsLowerCaseCapitalsString
{
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    NSNumber *myLength = [NSNumber numberWithInteger:[self length]];
    
    CC_SHA1(self.bytes, [myLength intValue], digest);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
    {
        [output appendFormat:@"%02x", digest[i]];
    }
    
    return output;
    
}


-(NSData *) returnSHA1HashAsNSData
{
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    NSNumber *myLength = [NSNumber numberWithInteger:[self length]];
    
    CC_SHA1(self.bytes, [myLength intValue], digest);
    
    
    NSData *output = [[NSData alloc]initWithBytes:&digest length:CC_SHA1_DIGEST_LENGTH];
    
    return output;
    
}



@end
