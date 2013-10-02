//
//  TorrentFile.h
//  TorrentCore
//
//  Created by sboerner on 13.08.13.
//  Copyright (c) 2013 sboerner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSData_Hex.h"
#import "NSData_SHA1.h"

@interface TorrentFile : NSObject
{
    int returnvalue;
    NSData *torrentFileContents;
    NSDictionary *torrentDictionary;
    NSDictionary *torrentInfoDictionary;
    NSArray *torrentListOfFilePaths;

    NSInteger positionInFile;
    NSFileManager *theFileManager;
    
    NSDictionary *torrentMapOfBlocksToFilenames;//SHA1 has to fileranges
    NSArray *arrayOfSHA1Hashes; //SHAHashes Only
    NSMutableDictionary *SHA1VerificationState; //Dictionary of true/false if verified
    
    NSInteger numberOfPiecesInTorrent;//Count of arrayOfSHA1Hashes
    NSUInteger totalSizeOfFiles;
    NSUInteger sizeOfPiece;
    NSUInteger startPositionOfInfoValueinTorrent;
    NSUInteger endPositionOfInfoValueinTorrent;

    NSDictionary *trackerResponses;
}
@property NSURL * torrentAnnounce;

- (id)initWithFileURL:(NSURL*) theTorrentFileNSURL;
-(NSData *)getTorrentFileData:(NSURL*)torrentFileLocation;
-(NSMutableDictionary *)getBencodedDictionaryFromData:(NSData* )torrentFileContentsHandle atIndex:(NSUInteger)startPoint;

-(NSString *)getBencodedStringFromData:(NSData *)torrentFileContentsHandle atIndex:(NSUInteger)startPoint;

-(NSString *)getBencodedHexStringFromData:(NSData *)torrentFileContentsHandle atIndex:(NSUInteger)startPoint;

-(NSMutableArray *)getBencodedListFromData:(NSData *)torrentFileContentsHandle atIndex:(NSUInteger)startPoint;

-(NSData *)getRawData:(NSData *)torrentFileContentsHandle atIndex:(NSUInteger)startPoint;


-(NSDictionary *)parseTorrentData:(NSData *)torrentFileContents;

-(NSDictionary *)parseTrackerResponse:(NSData *)trackerResponse;


-(NSInteger)getSumOfAllFileSizes;

-(NSNumber *) getBencodedIntegerFromData:(NSData *) torrentFileContentsHandle atIndex:(NSUInteger) startPoint;
-(NSDictionary *)partsOfFilesInBlock;
-(NSArray *) createArrayOfSHA1Hashes;

-(int) createFileStructureWithPath:(NSURL*) folderToPlaceFilesIn;
-(BOOL) verifyFileStructureWithPath:(NSURL*) folderToPlaceFilesIn;

-(BOOL)verifySHA1HashOfOnePiece:(NSString *)hashOfOnePiece forLocation:(NSURL*) folderToPlaceFilesIn;
-(BOOL)verifySHA1HashOfData: (NSURL*) folderToPlaceFilesIn;

-(NSDictionary *)connectToTrackerAnnounce;
-(NSString *)infoURLEncode:(NSString *)inputString fromData:(NSData *)inputData;
-(NSArray *) getPeersFromTrackerResponse:(NSDictionary*) trackerResponse;

@end
