//
//  main.m
//  TorrentCore
//
//  Created by sboerner on 13.08.13.
//  Copyright (c) 2013 sboerner. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "XYZShoutingPerson.h"
#import "TorrentFile.h"
int main(int argc, const char * argv[])
{

    @autoreleasepool {
        

        
        
       
        
        
        NSURL *filePathURL = [NSURL fileURLWithPathComponents:filePathComponents];
        //NSLog(@"URL:|||%@|||\n\n",filePathURL);
        
        TorrentFile *TestFile =[[TorrentFile alloc]initWithFileURL:filePathURL];
        
       
        
        NSURL *folderPathURL = [NSURL fileURLWithPathComponents:folderPathComponents];

        if(![TestFile createFileStructureWithPath:folderPathURL])
        {
           // NSLog(@"\n  Files Created Successfully\n\n");
        }
        else
        {
            //NSLog(@"\n  File Creation Suceeded !!!!!\n\n");
        }

        //[TestFile verifySHA1HashOfData:folderPathURL];
        if(![TestFile
        {
         //   NSLog(@"PieceWrong!");
        }
        else
        {
           // NSLog(@"\nPieceGood!\n\n");
        }
        [TestFile connectToTrackerAnnounce];
        
        
        NSLog(@"ObjectID:|||%@|||",TestFile);
        

    }
    return 0;
}

