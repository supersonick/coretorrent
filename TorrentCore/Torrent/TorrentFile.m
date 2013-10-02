//
//  TorrentFile.m
//  TorrentCore
//
//  Created by sboerner on 13.08.13.
//  Copyright (c) 2013 sboerner. All rights reserved.
//

#import "TorrentFile.h"




@implementation TorrentFile

- (id)initWithFileURL:(NSURL*) theTorrentFileNSURL {
    self = [super init];
    if (self) {
        theFileManager =  [NSFileManager defaultManager];
        
        torrentFileContents = [self getTorrentFileData:theTorrentFileNSURL];
        positionInFile=0;
        
        torrentDictionary= [self parseTorrentData:torrentFileContents];
        
        torrentInfoDictionary = [torrentDictionary valueForKey:@"info"];
        
        sizeOfPiece=[[torrentInfoDictionary valueForKey:@"piece length"]integerValue];
        
        torrentListOfFilePaths = [torrentInfoDictionary valueForKey:@"files"];
        

        totalSizeOfFiles = [self getSumOfAllFileSizes];

        
        arrayOfSHA1Hashes = [self createArrayOfSHA1Hashes];
        
        torrentMapOfBlocksToFilenames=[self partsOfFilesInBlock];        
        
    }
    
    return self;
    
}

-(NSInteger)getSumOfAllFileSizes;
{
    NSInteger sumOfAllFileSizes=0;

    for (NSDictionary *fileMetaInfoDictionary in torrentListOfFilePaths) {
        sumOfAllFileSizes=sumOfAllFileSizes+[[fileMetaInfoDictionary objectForKey:@"length"]integerValue];
        //NSLog(@"\n  SumOfFileSizes:%ld\n\n",sumOfAllFileSizes);
    }
    
    return sumOfAllFileSizes;
}
-(NSData *)getTorrentFileData:(NSURL *)torrentFileLocation
{
  
    NSError *fileReadErrorObjectPointer;
    
    torrentFileContents = [NSData dataWithContentsOfURL:torrentFileLocation options:(NSDataReadingUncached) error:(&fileReadErrorObjectPointer)];

    if(!torrentFileContents)//If READ ERROR
    {
        //NSLog(@"|||%@|||\n\n",fileReadErrorObjectPointer);
    }
    
    if(FALSE)//DEBUG
    {

/*
        NSUInteger fileLength = [torrentFileContents length];
        
        NSUInteger piecesLength = 18020;
        
        NSUInteger start = fileLength  -1 -1 -piecesLength;
        NSUInteger bufferRangeLength = piecesLength;
        
        NSRange lastShaHashRange = {start, bufferRangeLength};

        
        NSData *dataBuffer= [torrentFileContents subdataWithRange:lastShaHashRange];
        
        NSString *dataBufferString = [[NSString alloc] initWithData:dataBuffer encoding:NSASCIIStringEncoding];
        
       NSMutableString *HexString = [dataBuffer hexRepresentationWithSpaces_AS:TRUE];
        */
        //NSLog(@"FileLength:|||%lu|||/n/n",fileLength);
        
        //NSLog(@"LastHash:%@",dataBufferString);
        //NSLog(@"HexString:%@",HexString);
    
    }

    return torrentFileContents;
}
-(NSNumber *) getBencodedIntegerFromData:(NSData *) torrentFileContentsHandle atIndex:(NSUInteger) startPoint
{

    NSNumber * theNumber = [NSNumber new];
    //Finding out how far we can go in searching for the end of the Integer
    NSInteger fileLength = [torrentFileContentsHandle length];
    NSUInteger readWidth=fileLength-1-positionInFile;
    if(readWidth==0)
        return nil;
    else
    {   //Moving to next byte
        positionInFile++;
        //NSLog(@"\nI  ReadWidth:%ld\n  Position:%ld\n\n",readWidth,positionInFile);
    }
    //Reading from Current Position to the End of the File
    NSData *dataBuffer= [torrentFileContentsHandle subdataWithRange:NSMakeRange(positionInFile, readWidth)];
    
    NSString *dataBufferString = [[NSString alloc] initWithData:dataBuffer encoding:NSASCIIStringEncoding];
    
    ////NSLog(@"\n  S)BytesRead:%@\n  Position:%lu\n\n",dataBufferString,positionInFile);
    //Finding out where in the String the first e is
    NSRange integerEndRange= [dataBufferString rangeOfString:@"e"];
    NSInteger positionOfeInInteger = integerEndRange.location;

    //NSLog(@"\nI  EndCharacter:%@\nEndPositionInDataBuffer:%lu\n\n",[dataBufferString substringWithRange:NSMakeRange(positionOfeInInteger, 1)],positionOfeInInteger);
    
    //Finding out how long the Integer is
    NSInteger lengthOfTheInteger = [[dataBufferString substringWithRange:NSMakeRange(0, positionOfeInInteger)]length];
    
    //NSLog(@"\n LengthOfTheInteger:%ld",lengthOfTheInteger);
    
    NSInteger startOfTheIntegerInFile = positionInFile;
    NSInteger endOfTheIntegerInFile = positionInFile + lengthOfTheInteger;
    dataBuffer= [torrentFileContentsHandle subdataWithRange:NSMakeRange(startOfTheIntegerInFile, lengthOfTheInteger)];
    
    dataBufferString = [[NSString alloc] initWithData:dataBuffer encoding:NSASCIIStringEncoding];
    
    //NSLog(@"\nI IntegerString:%@\n  Position:%ld \n\n",dataBufferString,positionInFile);
    
    theNumber = [NSNumber numberWithInteger:[[dataBufferString substringWithRange:NSMakeRange(0, lengthOfTheInteger)]integerValue]];
    
    
    //NSLog(@"\n  TheNumber:%@\n\n",theNumber);
    positionInFile=endOfTheIntegerInFile;
    //NSLog(@"\n  I SettingPositionto:%lu\n\n",positionInFile);
    
    return theNumber;

    
}

-(NSMutableDictionary *)getBencodedDictionaryFromData:(NSData *)torrentFileContentsHandle atIndex:(NSUInteger)startPoint
{
    
    NSMutableDictionary *theDictionary =[[NSMutableDictionary alloc] init];
    
   
    NSUInteger dataLength = [torrentFileContentsHandle length];
    
    NSUInteger readWidth = 1;
    NSRange readHeadRange = {positionInFile, readWidth};
    NSData *dataBuffer= [torrentFileContentsHandle subdataWithRange:readHeadRange];
    
    NSString *dataBufferString = [[NSString alloc] initWithData:dataBuffer encoding:NSASCIIStringEncoding];
    NSString *keyName=@"";
    //NSLog(@"\nD  Position:%ld\n\n",positionInFile);
    positionInFile++; //Moving to next Byte
    if([dataBufferString isEqualToString:@"d"])
    {
        for(positionInFile=positionInFile; positionInFile<=dataLength-1;positionInFile++)

        {

        
            //NSLog(@"\nD  Reading byte for Key at: %lu\n\n",positionInFile);
            //Read one Byte into NSDATA
            dataBuffer= [torrentFileContentsHandle subdataWithRange:NSMakeRange(positionInFile, readWidth)];
            
            //Read NSDATA into NSString
            dataBufferString = [[NSString alloc] initWithData:dataBuffer encoding:NSASCIIStringEncoding];
            
            //NSLog(@"\nD  KeyByteRead:%@\n  Position   :%lu\n\n",dataBufferString,positionInFile);
            
            //Checking if a Key Exists
            if([dataBufferString isEqualToString:@"d"])
            {
                //Directory found aborting
                return nil;
                
            }
            else if ([dataBufferString isEqualToString:@"i"])
            {
                //Integer found aborting
                return nil;
            }
            else if ([dataBufferString isEqualToString:@"l"])
            {
                //List found aborting
                return nil;
            }
            else if([dataBufferString isEqualToString:@"e"])
            {
                if([keyName isEqualToString:@"info"])
                {
                    endPositionOfInfoValueinTorrent=positionInFile-1;
                }
                //NSLog(@"\nd Directory Ended\n\n");
                return theDictionary;
            }
            else //Trying to get a string
            {
            
                keyName = [self getBencodedStringFromData:torrentFileContentsHandle atIndex:positionInFile];
                //NSLog(@"\n  KeyNameFound:%@\n  Position:%lu\n\n",keyName,positionInFile);

               
                positionInFile++;
                if(keyName==nil)
                    break;
            }
            //Reading byte to determine type of Value
                
            //Read one Byte into NSDATA
            dataBuffer= [torrentFileContentsHandle subdataWithRange:NSMakeRange(positionInFile, readWidth)];
            
            //Read NSDATA into NSString
            dataBufferString = [[NSString alloc] initWithData:dataBuffer encoding:NSASCIIStringEncoding];
            
            //NSLog(@"\n D)ByteReadForValue:%@\n  Position:%lu\n\n",dataBufferString,positionInFile);

                
                
            //Checking what type of value we have
            if([keyName isEqualToString:@"peers"])
            {
                NSLog(@"PEEERS");
                NSData *keyValue = [self getRawData:torrentFileContentsHandle atIndex:positionInFile];
                
                [theDictionary setValue:keyValue forKey:keyName];
            }
            else if([dataBufferString isEqualToString:@"d"])
            {
                //Directory found
                //NSLog(@"\nD  Directory found\n\n");
                if([keyName isEqualToString:@"info"])
                {
                    startPositionOfInfoValueinTorrent=positionInFile;
                }
                NSDictionary *keyValue = [self getBencodedDictionaryFromData:torrentFileContentsHandle atIndex:positionInFile];
                [theDictionary setValue:keyValue forKey:keyName];
                
               
                
            }
            else if ([dataBufferString isEqualToString:@"i"])
            {
                //Integer found
                //NSLog(@"\nD Integer found\n\n");
                NSNumber *keyValue=[self getBencodedIntegerFromData:torrentFileContentsHandle atIndex:positionInFile];
                [theDictionary setValue:keyValue forKey:keyName];

                
            }
            else if ([dataBufferString isEqualToString:@"l"])
            {
                //NSLog(@"\nD List found\n\n");
                NSArray *keyValue =[self getBencodedListFromData:torrentFileContentsHandle atIndex:positionInFile];
                [theDictionary setValue:keyValue forKey:keyName];

            }
            else //Trying to get a string as a value
            {
                //NSLog(@"String found");
                
                if([keyName isEqualToString:@"pieces"])
                {
                
                    NSString *keyValue = [self getBencodedHexStringFromData:torrentFileContentsHandle atIndex:positionInFile];
                    //NSLog(@"\n  KeyValueStringFound:%@\n\n",keyValue);
                    [theDictionary setValue:keyValue forKey:keyName];
                    
                }
                else
                {
                    NSString *keyValue = [self getBencodedStringFromData:torrentFileContentsHandle atIndex:positionInFile];
                    //NSLog(@"\n  KeyValueStringFound:%@\n\n",keyValue);
                    [theDictionary setValue:keyValue forKey:keyName];
                }
            }
            
            
        }
        return theDictionary;
    }
    else
    {
        return nil;
    }

}


-(NSString *)getBencodedStringFromData:(NSData *)torrentFileContentsHandle atIndex:(NSUInteger)startPoint
{

    
    
    //Finding out how far we can go in searching for the end of the string length number
    NSInteger fileLength = [torrentFileContentsHandle length];
    NSUInteger readWidth=fileLength-1-positionInFile;
    if(readWidth==0)
        return nil;
    else
    {
    
        //NSLog(@"\nS  ReadWidth:%ld\n  Position:%ld\n\n",readWidth,positionInFile);
    }
    
    
    
    //Integer
    NSData *dataBuffer= [torrentFileContentsHandle subdataWithRange:NSMakeRange(positionInFile, readWidth)];
    
    NSString *dataBufferString = [[NSString alloc] initWithData:dataBuffer encoding:NSASCIIStringEncoding];
    
    //NSLog(@"\nI BytesRead:%@\nPosition:%lu\n\n",dataBufferString,positionInFile);
    NSRange colonRange= [dataBufferString rangeOfString:@":"];
    
    NSInteger colonPosition = colonRange.location;
    
    ////NSLog(@"\nB)BufferString:%@\nColonPosition:%lu\n\n",dataBufferString,colonPosition);
    
    
    NSInteger lenghtOfTheString = [[dataBufferString substringWithRange:NSMakeRange(0, colonPosition)]integerValue];
    
    
    NSInteger startOfTheString = positionInFile + colonPosition+1;
    
    ////NSLog(@"lengthOfTheString:%ld - %@\nStartOfTheString:%ld",lenghtOfTheString,[dataBufferString substringWithRange:NSMakeRange(0, colonPosition)],startOfTheString);
    
    dataBuffer= [torrentFileContentsHandle subdataWithRange:NSMakeRange(startOfTheString, lenghtOfTheString)];
    
    dataBufferString = [[NSString alloc] initWithData:dataBuffer encoding:NSASCIIStringEncoding];
    
    NSString *theString = dataBufferString;
    
    //NSLog(@"TheString:---%@\n\n---",theString);
    positionInFile=startOfTheString+lenghtOfTheString-1;
    
    return theString;
    
}

-(NSString *)getBencodedHexStringFromData:(NSData *)torrentFileContentsHandle atIndex:(NSUInteger)startPoint
{
    
    //Finding out how far we can go in searching for the end of the string length number
    NSInteger fileLength = [torrentFileContentsHandle length];
    NSUInteger readWidth=fileLength-1-positionInFile;
    if(readWidth==0)
        return nil;
    else
    {
        
        //NSLog(@"\nS  ReadWidth:%ld\n  Position:%ld\n\n",readWidth,positionInFile);
    }
    
    
    
    //Integer
    NSData *dataBuffer= [torrentFileContentsHandle subdataWithRange:NSMakeRange(positionInFile, readWidth)];
    
    NSString *dataBufferString = [[NSString alloc] initWithData:dataBuffer encoding:NSASCIIStringEncoding];
    
    //NSLog(@"\nI BytesRead:%@\nPosition:%lu\n\n",dataBufferString,positionInFile);
    NSRange colonRange= [dataBufferString rangeOfString:@":"];
    
    NSInteger colonPosition = colonRange.location;
    
    ////NSLog(@"\nB)BufferString:%@\nColonPosition:%lu\n\n",dataBufferString,colonPosition);
    
    
    NSInteger lenghtOfTheString = [[dataBufferString substringWithRange:NSMakeRange(0, colonPosition)]integerValue];
    
    
    NSInteger startOfTheString = positionInFile + colonPosition+1;
    
    ////NSLog(@"lengthOfTheString:%ld - %@\nStartOfTheString:%ld",lenghtOfTheString,[dataBufferString substringWithRange:NSMakeRange(0, colonPosition)],startOfTheString);
    
    dataBuffer= [torrentFileContentsHandle subdataWithRange:NSMakeRange(startOfTheString, lenghtOfTheString)];
    
    
    NSMutableString *hexString = [dataBuffer hexRepresentationWithSpaces_AS:FALSE];
    
    NSString * theString = hexString;
    
    
    //NSLog(@"TheString:---%@\n\n---",theString);
    positionInFile=startOfTheString+lenghtOfTheString-1;
    
    return theString;
    
}

-(NSData *)getRawData:(NSData *)torrentFileContentsHandle atIndex:(NSUInteger)startPoint;
{
    //NSLog(@"RawDATA");
    //Finding out how far we can go in searching for the end of the file
    //Finding out how far we can go in searching for the end of the string length number
    NSInteger fileLength = [torrentFileContentsHandle length];
    NSUInteger readWidth=fileLength-1-positionInFile;
    if(readWidth==0)
        return nil;
    else
    {
        
        //NSLog(@"\nS  ReadWidth:%ld\n  Position:%ld\n\n",readWidth,positionInFile);
    }
    
    
    
    //Integer
    NSData *dataBuffer= [torrentFileContentsHandle subdataWithRange:NSMakeRange(positionInFile, readWidth)];
    
    NSString *dataBufferString = [[NSString alloc] initWithData:dataBuffer encoding:NSASCIIStringEncoding];
    
    //NSLog(@"\nI BytesRead:%@\nPosition:%lu\n\n",dataBufferString,positionInFile);
    NSRange colonRange= [dataBufferString rangeOfString:@":"];
    
    NSInteger colonPosition = colonRange.location;
    
    ////NSLog(@"\nB)BufferString:%@\nColonPosition:%lu\n\n",dataBufferString,colonPosition);
    
    
    NSInteger lenghtOfTheString = [[dataBufferString substringWithRange:NSMakeRange(0, colonPosition)]integerValue];
    
    
    NSInteger startOfTheString = positionInFile + colonPosition+1;
    
    ////NSLog(@"lengthOfTheString:%ld - %@\nStartOfTheString:%ld",lenghtOfTheString,[dataBufferString substringWithRange:NSMakeRange(0, colonPosition)],startOfTheString);
    
    dataBuffer= [torrentFileContentsHandle subdataWithRange:NSMakeRange(startOfTheString, lenghtOfTheString)];
    
    
    
    
    
    
    //NSLog(@"TheString:---%@\n\n---",theString);
    positionInFile=startOfTheString+lenghtOfTheString-1;
    return dataBuffer;
}


-(NSMutableArray *)getBencodedListFromData:(NSData *)torrentFileContentsHandle atIndex:(NSUInteger)startPoint
{
    NSMutableArray * theArray =[[NSMutableArray alloc]init];
    
    
    NSUInteger dataLength = [torrentFileContentsHandle length];
    
    NSUInteger readWidth = 1;
    NSRange readHeadRange = {positionInFile, readWidth};
    NSData *dataBuffer= [torrentFileContentsHandle subdataWithRange:readHeadRange];
    
    NSString *dataBufferString = [[NSString alloc] initWithData:dataBuffer encoding:NSASCIIStringEncoding];
    positionInFile++; //Moving to next byte
    if([dataBufferString isEqualToString:@"l"])
    {
        for(positionInFile=positionInFile; positionInFile<=dataLength-1;positionInFile++)
            
        {
            
            
            //NSLog(@"\n  Reading byte for ListEntry at: %lu\n\n",positionInFile);
            //Read one Byte into NSDATA
            dataBuffer= [torrentFileContentsHandle subdataWithRange:NSMakeRange(positionInFile, readWidth)];
            
            //Read NSDATA into NSString
            dataBufferString = [[NSString alloc] initWithData:dataBuffer encoding:NSASCIIStringEncoding];
            
            //NSLog(@"\n  L1)ByteRead:%@\n  Position:%lu\n\n",dataBufferString,positionInFile);
            
                    
            //Checking what type of value we have
            if([dataBufferString isEqualToString:@"d"])
            {
                //Dictionary found
                //NSLog(@"\n  L Directory found");
                [theArray insertObject:[self getBencodedDictionaryFromData:torrentFileContentsHandle atIndex:positionInFile] atIndex:[theArray count]];
                
            }
            else if ([dataBufferString isEqualToString:@"i"])
            {
                //Integer found
                //NSLog(@"\n  L Integer found");
                [theArray insertObject:[self getBencodedStringFromData:torrentFileContentsHandle atIndex:positionInFile] atIndex:[theArray count]];
                
            }
            else if ([dataBufferString isEqualToString:@"l"])
            {
                
                //NSLog(@"\n  L List found");
                [theArray insertObject:[self getBencodedListFromData:torrentFileContentsHandle atIndex:positionInFile] atIndex:[theArray count]];
                 
                 
                
            }
            else if ([dataBufferString isEqualToString:@"e"])
            {
                //NSLog(@"\n  List ended");
                return theArray;
            }
            else //Trying to get a string as a value
            {
                
                [theArray insertObject:[self getBencodedStringFromData:torrentFileContentsHandle atIndex:positionInFile] atIndex:[theArray count]];
                //NSLog(@"\n  L StringFound:%@\n\n",keyValue);
                
            }
            
        }
        return theArray;
    }
    else
    {
        return nil;
    }
    
}

-(NSDictionary *)parseTorrentData:(NSData *)torrentFileContentsHandle;
{
    NSUInteger dataLength = [torrentFileContentsHandle length];    
    NSUInteger readWidth = 1;
    NSRange readHeadRange = {positionInFile, readWidth};
    NSData *dataBuffer= [torrentFileContentsHandle subdataWithRange:readHeadRange];
    
    NSString *dataBufferString = [[NSString alloc] initWithData:dataBuffer encoding:NSASCIIStringEncoding];

    
    for(positionInFile=0; positionInFile<=dataLength-1;positionInFile++)
    {

        
        //Read one Byte into NSDATA
        dataBuffer= [torrentFileContentsHandle subdataWithRange:NSMakeRange(positionInFile, readWidth)];

        //Read NSDATA into NSString
        dataBufferString = [[NSString alloc] initWithData:dataBuffer encoding:NSASCIIStringEncoding];
        
        //NSLog(@"\nTorDir-Read:%@\nPosition   :%lu\n\n",dataBufferString,positionInFile);
        


        
            if([dataBufferString isEqualToString:@"d"])
            {
           
                torrentDictionary=[self getBencodedDictionaryFromData:torrentFileContentsHandle atIndex:positionInFile];
                
                
                if(torrentDictionary==nil)
                    break;
                else
                {
                    //NSLog(@"%@",[torrentDictionary description]);
                    NSLog(@"\nPT Finished Parsing\nPT EndPosition:%lu\n\n",positionInFile);
                    
                }
                return torrentDictionary;
            }
            else if ([dataBufferString isEqualToString:@"i"])
            {
                //Integer is happening
                break;
            }
            else if ([dataBufferString isEqualToString:@"l"])
            {
                //List must be happening
                break;
            }
            else //string must be happening
            {
                break;
            }
        
    }

    return nil;
}
-(NSDictionary *)parseTrackerResponse:(NSData *)trackerResponse
{
    
    NSUInteger dataLength = [trackerResponse length];
    NSUInteger readWidth = 1;
    NSRange readHeadRange = {positionInFile, readWidth};
    NSData *dataBuffer= [trackerResponse subdataWithRange:readHeadRange];
    
    NSString *dataBufferString = [[NSString alloc] initWithData:dataBuffer encoding:NSASCIIStringEncoding];
    
    
    for(positionInFile=0; positionInFile<=dataLength-1;positionInFile++)
    {
        
        
        //Read one Byte into NSDATA
        dataBuffer= [trackerResponse subdataWithRange:NSMakeRange(positionInFile, readWidth)];
        
        //Read NSDATA into NSString
        dataBufferString = [[NSString alloc] initWithData:dataBuffer encoding:NSASCIIStringEncoding];
        
        //NSLog(@"\nTorDir-Read:%@\nPosition   :%lu\n\n",dataBufferString,positionInFile);
        
        
        
        
        if([dataBufferString isEqualToString:@"d"])
        {
            
            torrentDictionary=[self getBencodedDictionaryFromData:trackerResponse atIndex:positionInFile];
            
            
            if(torrentDictionary==nil)
                break;
            else
            {
                //NSLog(@"%@",[torrentDictionary description]);
                NSLog(@"\nPT Finished Parsing Tracker Response\nPT EndPosition:%lu\n\n",positionInFile);
                
            }
            return torrentDictionary;
        }
        else if ([dataBufferString isEqualToString:@"i"])
        {
            //Integer is happening
            break;
        }
        else if ([dataBufferString isEqualToString:@"l"])
        {
            //List must be happening
            break;
        }
        else //string must be happening
        {
            break;
        }
        
    }

    return nil;
}

-(BOOL) verifyFileStructureWithPath:(NSURL*) folderToPlaceFilesIn
{

    BOOL isDirectory=FALSE;
    BOOL directoryExists = [theFileManager fileExistsAtPath:[folderToPlaceFilesIn path] isDirectory:&isDirectory];
    
    if(directoryExists&&isDirectory)
    {
        NSLog(@"\n  Path Exists and is a Directory!\n  %@\n\n",[folderToPlaceFilesIn path]);
    }
    
    
    
    
    //NSLog(@"Lofp%@",[torrentListOfFilePaths description]);
    NSDictionary *currentFilePathDict =[NSDictionary new];
    NSUInteger lengthOfFileToCreate=0;
    NSArray *currentPathArray =[NSArray new];
    NSURL *currentPathWithFile =[NSURL new];
    NSURL *currentPathExcludingFile =[NSURL new];
    
    for (NSUInteger filePathIndex=0;filePathIndex<[torrentListOfFilePaths count];filePathIndex++)
    {
        
        currentFilePathDict = [torrentListOfFilePaths objectAtIndex:filePathIndex];
        //NSLog(@"%@",[currentFilePathDict description]);
        lengthOfFileToCreate = [[currentFilePathDict objectForKey:@"length"]integerValue];
        //NSLog(@"%ld",lengthOfFileToCreate);
        currentPathArray=[currentFilePathDict objectForKey:@"path"];
       
        //NSLog(@"\n  CPL%@\n\n",[currentPathArray description]);
        
        currentPathWithFile=folderToPlaceFilesIn;
        currentPathExcludingFile=folderToPlaceFilesIn;
        for(NSUInteger currentPathComponent=0; currentPathComponent<[currentPathArray count];currentPathComponent++)
        {
            currentPathWithFile=[currentPathWithFile URLByAppendingPathComponent:[currentPathArray objectAtIndex:currentPathComponent]];
            //NSLog(@"\n  CPL:%@",[currentPathArray description]);
          //  NSLog(@"\n  CPC:%@",[[currentPathArray objectAtIndex:currentPathComponent]description]);
            if(([currentPathArray count]>1)&&(currentPathComponent<([currentPathArray count]-1)))
                
            {
                currentPathExcludingFile=[currentPathExcludingFile URLByAppendingPathComponent:[currentPathArray objectAtIndex:currentPathComponent]];
            }
        }
        //NSLog(@"\nCurrentPath:%@  \n\n",currentPathWithFile);
        if([theFileManager fileExistsAtPath:[currentPathWithFile path]])
        {
            //NSLog(@"\n  FileExists:%@\n\n",[currentPathWithFile path]);
        }
        else
        {
            NSError *directoryCreationError=nil;
            //NSLog(@"  Creating Path:%@\n\n",[currentPathExcludingFile path]);
            [theFileManager createDirectoryAtURL:currentPathExcludingFile withIntermediateDirectories:YES attributes:nil error:&directoryCreationError];
            if(directoryCreationError)NSLog(@"Error? %@",[directoryCreationError description]);
            
            //NSLog(@"\n  Creating File:%@\n\n",[currentPathWithFile path]);
            [theFileManager createFileAtPath:[currentPathWithFile path] contents:[NSMutableData dataWithLength:lengthOfFileToCreate] attributes:nil];
        }
    }
    

    return true;
}
-(int) createFileStructureWithPath:(NSURL*) folderToPlaceFilesIn;
{
    
    
    BOOL isDirectory=FALSE;
    BOOL directoryExists = [theFileManager fileExistsAtPath:[folderToPlaceFilesIn path] isDirectory:&isDirectory];
    
    if(directoryExists&&isDirectory)
    {
        NSLog(@"\n  Path Exists and is a Directory!\n  %@\n\n",[folderToPlaceFilesIn path]);
    }
    
    
    
    
    //NSLog(@"Lofp%@",[torrentListOfFilePaths description]);
    NSDictionary *currentFilePathDict =[NSDictionary new];
    NSUInteger lengthOfFileToCreate=0;
    NSArray *currentPathArray =[NSArray new];
    NSURL *currentPathWithFile =[NSURL new];
    NSURL *currentPathExcludingFile =[NSURL new];

    for (NSUInteger filePathIndex=0;filePathIndex<[torrentListOfFilePaths count];filePathIndex++)
    {
    
        currentFilePathDict = [torrentListOfFilePaths objectAtIndex:filePathIndex];
        //NSLog(@"%@",[currentFilePathDict description]);
        lengthOfFileToCreate = [[currentFilePathDict objectForKey:@"length"]integerValue];
        //NSLog(@"%ld",lengthOfFileToCreate);
        currentPathArray=[currentFilePathDict objectForKey:@"path"];
       // NSLog(@"\n  CPL%@\n\n",[currentPathArray description]);
        currentPathWithFile=folderToPlaceFilesIn;
        currentPathExcludingFile=folderToPlaceFilesIn;
        for(NSUInteger currentPathComponent=0; currentPathComponent<[currentPathArray count];currentPathComponent++)
        {
            currentPathWithFile=[currentPathWithFile URLByAppendingPathComponent:[currentPathArray objectAtIndex:currentPathComponent]];
            //NSLog(@"\n  CPL:%@",[currentPathArray description]);
           // NSLog(@"\n  CPC:%@",[[currentPathArray objectAtIndex:currentPathComponent]description]);
            if(([currentPathArray count]>1)&&(currentPathComponent<([currentPathArray count]-1)))
                
            {
                currentPathExcludingFile=[currentPathExcludingFile URLByAppendingPathComponent:[currentPathArray objectAtIndex:currentPathComponent]];
            }
        }
        //NSLog(@"\nCurrentPath:%@  \n\n",currentPathWithFile);
        if([theFileManager fileExistsAtPath:[currentPathWithFile path]])
        {
            //NSLog(@"\n  FileExists:%@\n\n",[currentPathWithFile path]);
        }
        else
        {
            NSError *directoryCreationError=nil;
            //NSLog(@"  Creating Path:%@\n\n",[currentPathExcludingFile path]);
            [theFileManager createDirectoryAtURL:currentPathExcludingFile withIntermediateDirectories:YES attributes:nil error:&directoryCreationError];
            if(directoryCreationError)NSLog(@"Error? %@",[directoryCreationError description]);

            NSLog(@"\n  Creating File:%@\n\n",[currentPathWithFile path]);
            [theFileManager createFileAtPath:[currentPathWithFile path] contents:[NSMutableData dataWithLength:lengthOfFileToCreate] attributes:nil];
        }
    }
    
    return 1; //Something happened
}

-(NSArray *) createArrayOfSHA1Hashes
{
    
    NSString *hashesOfPiecesString = [torrentInfoDictionary objectForKey:@"pieces"];

    numberOfPiecesInTorrent = ([hashesOfPiecesString length]/2/20);
    
   //NSLog(@"\nNumberOfPiecesInTorrent: %ld\nHashesOfPiecesString:%@\n\n",numberOfPiecesInTorrent,hashesOfPiecesString);
    //Calculating the sum of the size of files

    
    NSLog(@"\n  SizeOfPiece:%ld\n\n",sizeOfPiece);
    
    NSMutableArray *theSHA1HashArray =[[NSMutableArray alloc]initWithCapacity:numberOfPiecesInTorrent];
    NSInteger positionInHashesString=0;

    for (NSInteger indexInTheShaHashArray=0;indexInTheShaHashArray<numberOfPiecesInTorrent;indexInTheShaHashArray++) {

        positionInHashesString=((indexInTheShaHashArray)*40);
        
        
        NSString * currentHash = [[torrentInfoDictionary objectForKey:@"pieces"]substringWithRange:NSMakeRange(positionInHashesString, 40)];
        
  //NSLog(@"\nPLA Position:%ld CurrentHash:%@\n\n",positionInHashesString,currentHash);
        [theSHA1HashArray addObject:currentHash];
         
        
    }
    
    return theSHA1HashArray;
}
-(NSDictionary *)partsOfFilesInBlock
{
    NSMutableDictionary *blocksToFilePartsDictionary = [NSMutableDictionary new];
    NSArray *currentPathArray =[NSArray new];

    
    
    //Going through pieces - piece by piece
    NSInteger currentFileNumber=0;
    NSInteger bytesLeftInFile=0;
    NSInteger bytesUsedInFile=0;
    NSInteger fileOffset =0;
    NSInteger bytesUsedInTotal=0;
    for(NSInteger currentPieceNumber=0; currentPieceNumber<numberOfPiecesInTorrent;currentPieceNumber++)
    {
        NSDictionary *filePathAndRangeDict = [NSDictionary new];
        NSMutableArray *blockToFilesArray = [NSMutableArray new];


        NSInteger bytesLeftInPiece=sizeOfPiece;
//        NSInteger bytesUsedInPiece=0;
        
        //going through files in the metadirectory file by file
        while(currentFileNumber < [torrentListOfFilePaths count])

        {
            NSDictionary *fileMetaInfoDictionary = [torrentListOfFilePaths objectAtIndex:currentFileNumber];
            
            currentPathArray=[fileMetaInfoDictionary objectForKey:@"path"];
            //NSLog(@"\n  CPL%@\n\n",[currentPathArray description]);
            
            NSURL *currentPathWithFile = [NSURL fileURLWithPathComponents:currentPathArray];
            
            if(bytesLeftInFile==0)
            {
                NSInteger lengthOfCurrentFile=[[fileMetaInfoDictionary objectForKey:@"length"]integerValue];
                bytesLeftInFile = lengthOfCurrentFile;
                //NSLog(@"\n  BytesLeftInPiece %ld  BytesLeftAtStart:%ld\n%@\n\n",bytesLeftInPiece,bytesLeftInFile,[currentPathWithFile relativePath]);
            }
            
//            NSLog(@"\n BytesUsedInTotal:%ld  BytesLeftInPiece %ld  BytesInFile:%ld Difference:%ld\n   %@\n\n",bytesUsedInTotal,bytesLeftInPiece,bytesLeftInFile,bytesLeftInPiece-bytesLeftInFile,[currentPathWithFile relativePath]);

            //A
            if((fileOffset==0)&&(bytesLeftInFile < bytesLeftInPiece))
            {
                bytesUsedInFile  = bytesLeftInFile;
                bytesUsedInTotal=bytesUsedInTotal+bytesUsedInFile;

                filePathAndRangeDict=[NSDictionary dictionaryWithObject:[NSValue valueWithRange:NSMakeRange(fileOffset, bytesUsedInFile)] forKey:[currentPathWithFile relativePath]];
                [blockToFilesArray addObject:filePathAndRangeDict];
                
                bytesLeftInPiece = bytesLeftInPiece - bytesUsedInFile;
                bytesLeftInFile  = 0;
                fileOffset       = 0;
                currentFileNumber++;
                continue;
            }
            //B
            if((fileOffset == 0)&&(bytesLeftInFile > bytesLeftInPiece))
            {
            
                bytesUsedInFile  = bytesLeftInPiece;
                bytesUsedInTotal=bytesUsedInTotal+bytesUsedInFile;
                
                filePathAndRangeDict=
                [NSDictionary dictionaryWithObject:
                    [NSValue valueWithRange:
                        NSMakeRange(fileOffset, bytesUsedInFile)]
                             forKey:[currentPathWithFile relativePath]];
                
                [blockToFilesArray addObject:filePathAndRangeDict];
                
                bytesLeftInFile  = bytesLeftInFile-bytesUsedInFile;
                bytesLeftInPiece = 0;
                fileOffset       = bytesUsedInFile;
                
                break;
            }
            //C
            if((fileOffset > 0) && (bytesLeftInFile < bytesLeftInPiece))
            {
            
                bytesUsedInFile  = bytesLeftInFile;
                bytesUsedInTotal=bytesUsedInTotal+bytesUsedInFile;
                
                filePathAndRangeDict=
                [NSDictionary dictionaryWithObject:
                 [NSValue valueWithRange:
                  NSMakeRange(fileOffset, bytesUsedInFile)]
                                            forKey:[currentPathWithFile relativePath]];
                
                [blockToFilesArray addObject:filePathAndRangeDict];
                
                bytesLeftInPiece = bytesLeftInPiece - bytesLeftInFile;
                bytesLeftInFile  = 0;
                fileOffset = 0;
                currentFileNumber++;
                continue;
                
            }
            //D
            if((fileOffset == 0) && (bytesLeftInFile > bytesLeftInPiece))
            {
            
                bytesUsedInFile = bytesLeftInPiece;
                bytesUsedInTotal=bytesUsedInTotal+bytesUsedInFile;
                
                filePathAndRangeDict=
                [NSDictionary dictionaryWithObject:
                 [NSValue valueWithRange:
                  NSMakeRange(fileOffset, bytesUsedInFile)]
                                            forKey:[currentPathWithFile relativePath]];
                
                [blockToFilesArray addObject:filePathAndRangeDict];
                
                
                bytesLeftInFile = bytesLeftInFile - bytesUsedInFile;
                fileOffset = fileOffset + bytesUsedInFile ;
                bytesLeftInPiece = 0;
                
                break;
            }
            //E
            if((fileOffset > 0) && (bytesLeftInFile > bytesLeftInPiece))
            {
                bytesUsedInFile = bytesLeftInPiece;
                bytesUsedInTotal=bytesUsedInTotal+bytesUsedInFile;
                
                filePathAndRangeDict=
                [NSDictionary dictionaryWithObject:
                 [NSValue valueWithRange:
                  NSMakeRange(fileOffset, bytesUsedInFile)]
                                            forKey:[currentPathWithFile relativePath]];
                
                [blockToFilesArray addObject:filePathAndRangeDict];
                
                bytesLeftInPiece=0;
                bytesLeftInFile = bytesLeftInFile - bytesUsedInFile;
                fileOffset = fileOffset +  bytesUsedInFile ;
                break;
            }
            //F
            if((fileOffset == 0) && (bytesLeftInFile < bytesLeftInPiece))
            {
            
                bytesUsedInFile=bytesLeftInFile;
                bytesUsedInTotal=bytesUsedInTotal+bytesUsedInFile;
                
                filePathAndRangeDict=[NSDictionary dictionaryWithObject:[NSValue valueWithRange:NSMakeRange(fileOffset, bytesUsedInFile)] forKey:[currentPathWithFile relativePath]];
                [blockToFilesArray addObject:filePathAndRangeDict];
                
                bytesLeftInPiece=bytesLeftInPiece - bytesLeftInFile;
                bytesLeftInFile=0;
                fileOffset = 0;
                currentFileNumber++;
                continue;
            }
           
        }
        //Adding SHA Has of Block As IdentifierKey
        [blocksToFilePartsDictionary setObject:blockToFilesArray forKey:[arrayOfSHA1Hashes objectAtIndex:currentPieceNumber]];

       // NSLog(@"\nCP:%ld\nCurrentHash:%@\nArray:%@\n\n",currentPieceNumber+1,[arrayOfSHA1Hashes objectAtIndex:currentPieceNumber], [blockToFilesArray description]);
        
    }
//    NSLog(@"\n BytesUsedInTotal: %ld . TotalSizeOfFiles:%ld Difference:%ld\n\n",bytesUsedInTotal,totalSizeOfFiles,bytesUsedInTotal-totalSizeOfFiles);
    
//    NSLog(@"\n BlocksToFileParts:%@ \n\n", [blocksToFilePartsDictionary description]);
    

    return blocksToFilePartsDictionary;
}
-(BOOL)verifySHA1HashOfOnePiece:(NSString *)hashOfOnePiece forLocation:(NSURL*) folderToPlaceFilesIn;
{

        NSString *currentHash = hashOfOnePiece;  
        BOOL resultOfVerification=TRUE;
    
        NSMutableData *blockFromFiles = [[NSMutableData alloc]initWithCapacity:sizeOfPiece];
        //NSLog(@"1");
        //Go through array of files
        for (NSDictionary *currentNameToRangeDict in
             [torrentMapOfBlocksToFilenames objectForKey:currentHash])
        {
            //NSLog(@"2");
            //Return range assigned to filename
            for (NSString *currentRelativeFilePath in currentNameToRangeDict)
            {
                //NSLog(@"3");
                NSMutableString *fullFilePath =[NSMutableString new];
                [fullFilePath appendString: [folderToPlaceFilesIn path]];
                [fullFilePath appendString: @"/"];
                [fullFilePath appendString:currentRelativeFilePath];
                
                
                //NSLog(@"\n   fullFilePath:%@ \n   Range:%@  \n\n",fullFilePath,[[currentNameToRangeDict objectForKey:currentRelativeFilePath]description]);
                
                NSValue *rangeValueObject = [currentNameToRangeDict objectForKey:currentRelativeFilePath];
                NSRange currentRange = [rangeValueObject rangeValue];
                
                NSURL *fullPathURL =[NSURL fileURLWithPath:fullFilePath];
                NSError *readError=Nil;
                NSFileHandle * theFileHandle = [NSFileHandle fileHandleForReadingFromURL:fullPathURL error:&readError];
                if(readError)
                {
                    //NSLog(@"%@",readError);
                }
                NSInteger currentLocation = currentRange.location;
                
                [theFileHandle seekToFileOffset:currentLocation];
                
                NSData *interMediateData =[theFileHandle readDataOfLength:currentRange.length];
                [blockFromFiles appendData:interMediateData];
                
                //NSLog(@"\n BytesRead:%ld, BytesExpected:%ld, SizeOfPiece:%ld, LengthOFBlock:%ld, Location:%ld\n\n",[interMediateData length],currentRange.length,sizeOfPiece,[blockFromFiles length],currentLocation);
            
                
                
            }
            
            
        }
        //Fertsch mit DatenLesen
       // NSLog(@"\n  CurrentHash:%@, Index:%ld\nComputedHash :%@  \n\n",currentHash,[arrayOfSHA1Hashes indexOfObjectIdenticalTo:currentHash],[blockFromFiles returnSHA1HashAsString]);
        if([currentHash isEqualToString:[blockFromFiles returnSHA1HashAsString]])
        {
            NSNumber *aMatch =[NSNumber numberWithBool:TRUE];
            [SHA1VerificationState setObject:aMatch forKey:currentHash];
        }
        else
        {
            NSNumber *noMatch =[NSNumber numberWithBool:FALSE];
            
            [SHA1VerificationState setObject:noMatch forKey:currentHash];
             resultOfVerification=FALSE;

        }
        
    
    return resultOfVerification;
}
-(BOOL)verifySHA1HashOfData: (NSURL*) folderToPlaceFilesIn
{
    SHA1VerificationState = [[NSMutableDictionary alloc]initWithCapacity:[arrayOfSHA1Hashes count]];
    //Go through dict of hashes
    BOOL resultOfVerification=TRUE;
                    
    for (NSString *currentHash in arrayOfSHA1Hashes)
    {
        
        NSMutableData *blockFromFiles = [[NSMutableData alloc]initWithCapacity:sizeOfPiece];
        //NSLog(@"1");
        //Go through array of files
        for (NSDictionary *currentNameToRangeDict in
            [torrentMapOfBlocksToFilenames objectForKey:currentHash])
        {
            //NSLog(@"2");
            //Return range assigned to filename
            for (NSString *currentRelativeFilePath in currentNameToRangeDict)
            {
                //NSLog(@"3");
                NSMutableString *fullFilePath =[NSMutableString new];
                [fullFilePath appendString: [folderToPlaceFilesIn path]];
                [fullFilePath appendString: @"/"];
                [fullFilePath appendString:currentRelativeFilePath];

                
                //NSLog(@"\n   fullFilePath:%@ \n   Range:%@  \n\n",fullFilePath,[[currentNameToRangeDict objectForKey:currentRelativeFilePath]description]);
                
                NSValue *rangeValueObject = [currentNameToRangeDict objectForKey:currentRelativeFilePath];
                NSRange currentRange = [rangeValueObject rangeValue];
                
                NSURL *fullPathURL =[NSURL fileURLWithPath:fullFilePath];
                NSError *readError=Nil;
                NSFileHandle * theFileHandle = [NSFileHandle fileHandleForReadingFromURL:fullPathURL error:&readError];
                if(readError)
                {
                    //NSLog(@"%@",readError);
                }
                NSInteger currentLocation = currentRange.location;
                
                [theFileHandle seekToFileOffset:currentLocation];
                
                NSData *interMediateData =[theFileHandle readDataOfLength:currentRange.length];
                [blockFromFiles appendData:interMediateData];
                
                //NSLog(@"\n BytesRead:%ld, BytesExpected:%ld, SizeOfPiece:%ld, LengthOFBlock:%ld, Location:%ld\n\n",[interMediateData length],currentRange.length,sizeOfPiece,[blockFromFiles length],currentLocation);
                


            }
            
            
        }
        //Fertsch mit DatenLesen
        NSLog(@"\n  CurrentHash:%@, Index:%ld\nComputedHash :%@  \n\n",currentHash,[arrayOfSHA1Hashes indexOfObjectIdenticalTo:currentHash],[blockFromFiles returnSHA1HashAsString]);
        if([currentHash isEqualToString:[blockFromFiles returnSHA1HashAsString]])
            {
                NSNumber *aMatch =[NSNumber numberWithBool:TRUE];
                [SHA1VerificationState setObject:aMatch forKey:currentHash];
                
            }
            else
            {
                NSNumber *noMatch =[NSNumber numberWithBool:FALSE];
                
                [SHA1VerificationState setObject:noMatch forKey:currentHash];
                resultOfVerification=FALSE;
            }
            
    }
   // NSLog(@"%@",[torrentListOfFilePaths description]);
           
    return resultOfVerification;
    
}

-(NSDictionary *)connectToTrackerAnnounce
{
    
    //NSLog(@"\n  Start:%ld, End%ld \n\n",startPositionOfInfoValueinTorrent,endPositionOfInfoValueinTorrent);
    
    NSData *infoSection = [torrentFileContents subdataWithRange:NSMakeRange(startPositionOfInfoValueinTorrent, endPositionOfInfoValueinTorrent+1-startPositionOfInfoValueinTorrent)];
    
    NSData *infoSHA1HashData=[infoSection returnSHA1HashAsNSData];

    NSString *infoHashString = [[NSString alloc]initWithData:infoSHA1HashData encoding:NSASCIIStringEncoding];
    NSString *urlReadyInfoHashString = [self infoURLEncode:infoHashString fromData:infoSHA1HashData];
    //NSString *infoHashHumanReadable = [infoSection returnSHA1HashAsLowerCaseCapitalsString];
    
  //  NSLog(@"\nInfhashString::%@:: \n URLReady:%@ \nHumanReadable:%@  \n\n",infoHashString,urlReadyInfoHashString,infoHashHumanReadable);
    
    
    NSString *peerid =@"12345678901234567890";
    NSString *port =@"6881";
    NSString *uploaded=@"0";
    NSString *downloaded=@"0";
    NSString *left=[NSString stringWithFormat:@"%ld",totalSizeOfFiles];
    NSString *compact=@"1";
    NSString *noPeerID=@"1";
    NSString *event=@"";
    
    NSMutableString *getParameters=[NSMutableString new];
    [getParameters appendString:@"?info_hash="];
    [getParameters appendString:urlReadyInfoHashString];
    
    [getParameters appendString:@"&peer_id="];
    [getParameters appendString:peerid];
    
    [getParameters appendString:@"&port="];
    [getParameters appendString:port];
    
    [getParameters appendString:@"&uploaded="];
    [getParameters appendString:uploaded];
    
    [getParameters appendString:@"&uploaded="];
    [getParameters appendString:downloaded];
    
    [getParameters appendString:@"&left="];
    [getParameters appendString:left];
    
    [getParameters appendString:@"&compact="];
    [getParameters appendString:compact];
    
    [getParameters appendString:@"&no_peer_id="];
    [getParameters appendString:noPeerID];
    
    [getParameters appendString:@"&event="];
    [getParameters appendString:event];
    
    
//    NSLog(@"\nInfoHashString:%@",infoHashString);
    
    
    for (NSArray *announceSublist in [torrentDictionary objectForKey:@"announce-list"]) {
        for (NSString* announceURL in announceSublist) {
            //NSLog(@"\n  AnnounceURL:%@\n\n",announceURL);
            NSMutableString *fullURLString =[[NSMutableString alloc]initWithString:announceURL];
            [fullURLString appendString:getParameters];
            NSURL *fullURL =[NSURL URLWithString:fullURLString];

            NSLog(@"\n  FullURL:%@\n\n",fullURL);
        
        }
    }
    
      
  
    
  
    
    return 0;// not finished
}

-(NSString *)infoURLEncode:(NSString *)inputString fromData:(NSData *)inputData

{
    NSString *bufferString = [NSString new];
    NSString *allowedCharacters=@"0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.-_~";
    NSData *bufferData = [NSData new];
    NSRange found = NSMakeRange(0, 0);
    NSMutableString *outputString = [NSMutableString new];
    for(NSUInteger i=0;i<[inputString length];i++)
    {
        
        bufferString = [inputString substringWithRange:NSMakeRange(i, 1)];
        bufferData = [inputData subdataWithRange:NSMakeRange(i,1)];
        found = [allowedCharacters rangeOfString:bufferString];
        if(found.length>0)
        {
           // NSLog(@"Yo!:%@",bufferString);
            [outputString appendString:bufferString];
        }
        else
        {
            
            bufferString= [bufferData hexRepresentationWithSpaces_AS:NO];
           // NSLog(@"No!:%@",bufferString);
            [outputString appendString:@"\%"];
            [outputString appendString:bufferString];

        }
        found = NSMakeRange(0, 0);
    }
    return outputString;
}
-(NSArray *) getPeersFromTrackerResponse:(NSDictionary*) trackerResponse
{
    NSData *peersData =[trackerResponse objectForKey:@"peers"];
   
    NSMutableArray *peerList =[[NSMutableArray alloc]initWithCapacity:([peersData length]/6)];
    NSMutableString *peerAddressPortString = [NSMutableString new];
    unsigned int ipInt1=0;
    unsigned int ipInt2=0;
    unsigned int ipInt3=0;
    unsigned int ipInt4=0;
    
    unsigned int portInt1=0;
    unsigned int portInt2=0;
    
    for(NSUInteger i=0;i<[peersData length];i=i+6)
    {
        [peerAddressPortString setString:@""];
        NSData *ipData1 = [peersData subdataWithRange:NSMakeRange(i, 1)];
        NSData *ipData2 = [peersData subdataWithRange:NSMakeRange(i+1, 1)];
        NSData *ipData3 = [peersData subdataWithRange:NSMakeRange(i+2, 1)];
        NSData *ipData4 = [peersData subdataWithRange:NSMakeRange(i+3, 1)];
        
        NSString *ipString1 = [ipData1 hexRepresentationWithSpaces_AS:NO];
        NSString *ipString2 = [ipData2 hexRepresentationWithSpaces_AS:NO];
        NSString *ipString3 = [ipData3 hexRepresentationWithSpaces_AS:NO];
        NSString *ipString4 = [ipData4 hexRepresentationWithSpaces_AS:NO];
        
        NSScanner *ipHexToInt1 = [NSScanner scannerWithString:ipString1];
        NSScanner *ipHexToInt2 = [NSScanner scannerWithString:ipString2];
        NSScanner *ipHexToInt3 = [NSScanner scannerWithString:ipString3];
        NSScanner *ipHexToInt4 = [NSScanner scannerWithString:ipString4];
        
        [ipHexToInt1 scanHexInt:&ipInt1];
        [ipHexToInt2 scanHexInt:&ipInt2];
        [ipHexToInt3 scanHexInt:&ipInt3];
        [ipHexToInt4 scanHexInt:&ipInt4];
        
        [peerAddressPortString appendFormat:@"%u.%u.%u.%u",ipInt1,ipInt2,ipInt3,ipInt4];
        NSString *currentIP = peerAddressPortString;
        //NSLog(@"\n  peerAddressPortString:%@  \n\n",peerAddressPortString);

        NSData *portData1 = [peersData subdataWithRange:NSMakeRange(i+5, 1)];
        NSData *portData2 = [peersData subdataWithRange:NSMakeRange(i+5, 1)];
        NSString *portString1 = [portData1 hexRepresentationWithSpaces_AS:NO];
        NSString *portString2 = [portData2 hexRepresentationWithSpaces_AS:NO];

        
        NSScanner *portHexToInt1 = [NSScanner scannerWithString:portString1];
        NSScanner *portHexToInt2 = [NSScanner scannerWithString:portString2];
        [portHexToInt1 scanHexInt:&portInt1];
        [portHexToInt2 scanHexInt:&portInt2];
        
        [peerAddressPortString appendFormat:@":%u%u",portInt1,portInt2];
        NSString *portString = [NSString stringWithFormat:@"%u%u",portInt1,portInt2];

        NSInteger currentPort = [portString integerValue];
        
        NSLog(@"\n connecting to peerAddressPortString:%@  \n\n",peerAddressPortString);
        
        [peerList addObject:peerAddressPortString];
        currentIP = [NSString stringWithFormat:@"193.99.144.80"];
        currentPort = 80;
        NSHost *theHost = [NSHost hostWithAddress:currentIP];
        
        NSInputStream *currentInputStream = [NSInputStream new];
        NSOutputStream *currentOutputStream = [NSOutputStream new];
        
        [NSStream getStreamsToHost:theHost port:currentPort inputStream:&currentInputStream outputStream:&currentOutputStream];
        
        [currentInputStream close];
        [currentOutputStream close];
    }
    return peerList;
}


@end
