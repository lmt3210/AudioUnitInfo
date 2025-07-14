//
// MasterViewController.m
//
// Copyright (c) 2020-2025 Larry M. Taylor
//
// This software is provided 'as-is', without any express or implied
// warranty. In no event will the authors be held liable for any damages
// arising from the use of this software. Permission is granted to anyone to
// use this software for any purpose, including commercial applications, and to
// to alter it and redistribute it freely, subject to 
// the following restrictions:
//
// 1. The origin of this software must not be misrepresented; you must not
//    claim that you wrote the original software. If you use this software
//    in a product, an acknowledgment in the product documentation would be
//    appreciated but is not required.
// 2. Altered source versions must be plainly marked as such, and must not be
//    misrepresented as being the original software.
// 3. This notice may not be removed or altered from any source
//    distribution.
//

#import <sys/types.h>
#import <pwd.h>
#import <uuid/uuid.h>
#import <sys/utsname.h>

#import "MasterViewController.h"
#import "LTAudioUnitData.h"
#import "NSFileManager+DirectoryLocations.h"

@implementation MasterViewController

@synthesize mAudioUnits;
@synthesize mAudioUnitTableView;
@synthesize mInfoField;

- (id)initWithNibName:(NSString *)nibNameOrNil 
               bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    // Set up logging
    mLog = os_log_create("com.larrymtaylor.AudioUnitInfo", "MasterView");
    NSString *path =
        [[NSFileManager defaultManager] applicationSupportDirectory];
    mLogFile = [[NSString alloc] initWithFormat:@"%@/logFile.txt", path];
    
    return self;
}

- (NSView *)tableView:(NSTableView *)tableView 
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row
{
    // Get a new ViewCell
    NSTableCellView *cellView = 
        [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    LTAudioUnitData *auData = [mAudioUnits objectAtIndex:row];
    NSString *text = @"";
    
    if ([tableColumn.identifier isEqualToString:@"company"] == YES)
    {
        (auData.company == nil) ? (text = @"N/A") : (text = auData.company);
    }
    else if ([tableColumn.identifier isEqualToString:@"name"] == YES)
    {
        (auData.name == nil) ? (text = @"N/A") : (text = auData.name);
    }
    else if ([tableColumn.identifier isEqualToString:@"type"] == YES)
    {
        (auData.type == nil) ? (text = @"N/A") : (text = auData.type);
    }
    else if ([tableColumn.identifier isEqualToString:@"arch"] == YES)
    {
        if (auData.arch != nil)
        {
            if ([auData.arch containsString:@"Arch:"] == YES)
            {
                NSArray *archs =
                    [auData.arch componentsSeparatedByCharactersInSet:
                    [NSCharacterSet characterSetWithCharactersInString:@":,"]];
                NSMutableString *archString =
                    [NSMutableString stringWithString:@""];
            
                for (int i = 0; i < [archs count]; i++)
                {
                    if (([archs[i] isEqualToString:@"I64"]) ||
                        ([archs[i] isEqualToString:@"A64"]) ||
                        ([archs[i] isEqualToString:@"I32"]) ||
                        ([archs[i] isEqualToString:@"PPC"]) ||
                        ([archs[i] isEqualToString:@"N/A"]))
                    {
                        [archString appendFormat:@"%@  ", archs[i]];
                    }
                }

                text = archString;
            }
            else
            {
                text = @"N/A";
            }
        }
    }
    else if ([tableColumn.identifier isEqualToString:@"compType"] == YES)
    {
        (auData.compType == nil) ? (text = @"N/A") : (text = auData.compType);
    }
    else if ([tableColumn.identifier isEqualToString:@"subtype"] == YES)
    {
        (auData.subtype == nil) ? (text = @"N/A") : (text = auData.subtype);
    }
    else if ([tableColumn.identifier isEqualToString:@"manu"] == YES)
    {
        (auData.manu == nil) ? (text = @"N/A") : (text = auData.manu);
    }
    else if ([tableColumn.identifier isEqualToString:@"sandbox"] == YES)
    {
        (auData.sandbox == nil) ? (text = @"N/A") : (text = auData.sandbox);
    }
    else if ([tableColumn.identifier isEqualToString:@"async"] == YES)
    {
        (auData.async == nil) ? (text = @"N/A") : (text = auData.async);
    }
    else if ([tableColumn.identifier isEqualToString:@"inProc"] == YES)
    {
        (auData.inProc == nil) ? (text = @"N/A") : (text = auData.inProc);
    }
    else if ([tableColumn.identifier isEqualToString:@"auVersion"] == YES)
    {
        (auData.auVersion == nil) ? (text = @"N/A") :
            (text = auData.auVersion);
    }
    else if ([tableColumn.identifier isEqualToString:@"version"] == YES)
    {
        (auData.version == nil) ? (text = @"N/A") : (text = auData.version);
    }
    else if ([tableColumn.identifier isEqualToString:@"minOS"] == YES)
    {
        text = @"N/A";
        
        if ([auData.name containsString:@"View"] == NO)
        {
            if ((auData.minOS != nil) &&
                ([auData.minOS isKindOfClass:[NSString class]]) &&
                ([auData.minOS containsString:@","] == NO))
            {
                text = auData.minOS;
            }
        }
    }

    cellView.textField.stringValue = text;

    return cellView;
}

- (void)loadView
{
    [super loadView];
    
    // Initialize variables
    mAudioUnits = [[NSMutableArray alloc] init];
    mText = [[NSString alloc] init];

    // Set column sort descriptors
    NSArray<NSTableColumn*> *columns = [mAudioUnitTableView tableColumns];
    
    for (int i = 0; i < [columns count]; i++)
    {
        NSTableColumn *column = [columns objectAtIndex:i];
        NSSortDescriptor *sortDescriptor =
            [NSSortDescriptor sortDescriptorWithKey:[column identifier]
             ascending:YES selector:@selector(compare:)];
        [column setSortDescriptorPrototype:sortDescriptor];
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    NSInteger rows = [mAudioUnitTableView numberOfSelectedRows];
    
    if (rows > 1)
    {
        [mInfoField setStringValue:
         [NSString stringWithFormat:@"%li audio units selected.", rows]];
    }
    else if (rows > 0)
    {
        [mInfoField setStringValue:
         [NSString stringWithFormat:@"%li audio unit selected.", rows]];
    }
    else
    {
        [mInfoField setStringValue:@""];
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [mAudioUnits count];
}

- (void)tableView:(NSTableView *)aTableView
        sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
    NSArray<NSTableColumn*> *columns = [mAudioUnitTableView tableColumns];
    NSTableColumn *column =
        [columns objectAtIndex:[aTableView selectedColumn]];
    NSSortDescriptor *sd = [column sortDescriptorPrototype];
    NSSortDescriptor *sdr = [sd reversedSortDescriptor];
    [column setSortDescriptorPrototype:sdr];
    NSArray *sortedAUs = [mAudioUnits sortedArrayUsingDescriptors:@[sd]];
    mAudioUnits = [sortedAUs copy];
    [mAudioUnitTableView reloadData];
}

- (void)auListReadyTimer:(NSTimer *)timer
{
    if (mReady == false)
    {
        NSString *text = [NSString stringWithFormat:@"%@.", mText];
        [mInfoField setStringValue:text];
        mText = [text copy];
        return;
    }
    
    [mReadyTimer invalidate];
    mReadyTimer = nil;
    
    NSString *text = [NSString stringWithFormat:
                      @"%@done.  Found %lu audio units.", mText,
                      (unsigned long)[mAudioUnits count]];
    [mInfoField setStringValue:text];
    [mAudioUnitTableView reloadData];
}

- (void)getAUList
{
    mText = @"Gathering list of audio units...";
    [mInfoField setStringValue:mText];

    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperationWithBlock:^{
        AudioComponentDescription desc = { 0 };
        int componentCount = AudioComponentCount(&desc);
        LTLog(self->mLog, self->mLogFile, OS_LOG_TYPE_INFO,
              @"System reported %i audio components", componentCount);
        AudioComponent last = NULL;
   
        // Get list of all installed devices
        for (int i = 0; i < componentCount; ++i)
        {
            AudioComponent comp = AudioComponentFindNext(last, &desc);
            last = comp;
        
            @try
            {
                LTAudioUnitData *auData =
                    [[LTAudioUnitData alloc] initWithComponent:comp];
                [self.mAudioUnits addObject:auData];
                LTLog(self->mLog, self->mLogFile, OS_LOG_TYPE_INFO,
                      @"Found %@ (%@ %@ %@)", auData.name,
                      auData.manu, auData.subtype, auData.compType);
            }
            @catch(NSException *e)
            {
                LTLog(self->mLog, self->mLogFile, OS_LOG_TYPE_ERROR,
                      @"getAUList %@ ", e.name);
                LTLog(self->mLog, self->mLogFile, OS_LOG_TYPE_ERROR,
                      @"getAUList Reason: %@ ", e.reason);
            }
            @finally
            {
            }
        }
    
        // Sort by name
        NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"name"
                                 ascending:YES];
        NSArray *sortedList =
            [self.mAudioUnits sortedArrayUsingDescriptors:@[sd]];
        
        [self.mAudioUnits removeAllObjects];
        
        for (int i = 0; i < [sortedList count]; i++)
        {
            LTAudioUnitData *au = (LTAudioUnitData *)sortedList[i];
            LTAudioUnitData *newAU = [au copy];
            [self.mAudioUnits addObject:newAU];
        }
        
        [self getArch];
        self->mReady = true;
    }];
}

- (IBAction)showDetails:(id)sender
{
    NSUInteger row = mAudioUnitTableView.selectedRow;
    
    if (row < [mAudioUnits count])
    {
        LTAudioUnitData *auData = [mAudioUnits objectAtIndex:row];
        AudioComponent comp = (AudioComponent)[auData.component integerValue];
        CFDictionaryRef confInfoCF;
        AudioComponentCopyConfigurationInfo(comp, &confInfoCF);
        
        // This dictionary's keys are defined in AudioToolbox
        // AudioUnitProperties.h at pragma mark - Configuration Info Keys
        // (~ line 1534)
        NSDictionary *confInfo = (__bridge NSDictionary *)confInfoCF;
        NSString *confInfoDesc = [confInfo description];
        NSMutableString *text = [[NSMutableString alloc] initWithString:@""];
        
        if (confInfoDesc == nil)
        {
            [text appendString:
             @"No configuration information available"];
        }
        else
        {
            [text appendString:confInfoDesc];
        }
        
        LTInfoWindow *infoWindow =
            [[LTInfoWindow alloc] initWithWindowNibName:@"LTInfoWindow"];
        [infoWindow setTitle:auData.name];
        [infoWindow show];
        [infoWindow setText:text];
    }
}

- (IBAction)validate:(id)sender
{
    NSUInteger row = mAudioUnitTableView.selectedRow;
    
    if (row < [mAudioUnits count])
    {
        LTAudioUnitData *auData = [mAudioUnits objectAtIndex:row];
        NSTask *task = [[NSTask alloc] init];
        NSArray *args =
            [NSArray arrayWithObjects:@"-v", auData.compType, auData.subtype,
             auData.manu, nil];
        task.launchPath = @"/usr/bin/auval";
        task.arguments = args;
        NSPipe *pipe = [NSPipe pipe];
        task.standardOutput = pipe;

        pipe.fileHandleForReading.readabilityHandler =
            ^(NSFileHandle *h)
        {
            self->mValidationResult = [h readDataToEndOfFile];
            [h closeFile];
        };
        
        [task launch];
        [task waitUntilExit];
    
        const char *result = (const char *)[mValidationResult bytes];
        
        LTInfoWindow *infoWindow =
            [[LTInfoWindow alloc] initWithWindowNibName:@"LTInfoWindow"];
        [infoWindow setTitle:auData.name];
        [infoWindow show];
        [infoWindow setText:[NSString stringWithUTF8String:result]];
    }
}

- (IBAction)scan:(id)sender
{
    // Clear list
    mAudioUnits = [[NSMutableArray alloc] init];
    [mAudioUnitTableView reloadData];
    
    // Start timer to wait for app list ready
    mReady = false;
    mReadyTimer = [NSTimer scheduledTimerWithTimeInterval:1
                   target:self selector:@selector(auListReadyTimer:)
                   userInfo:nil repeats:YES];
    
    // Start task to get app list
    [self getAUList];
}

- (IBAction)showState:(id)sender
{
    NSUInteger row = mAudioUnitTableView.selectedRow;
    
    if (row < [mAudioUnits count])
    {
        LTAudioUnitData *auData = [mAudioUnits objectAtIndex:row];
        AudioComponentDescription desc = { 0 };
        CFStringRef compType = (__bridge CFStringRef)auData.compType;
        desc.componentType = UTGetOSTypeFromString(compType);
        CFStringRef subType = (__bridge CFStringRef)auData.subtype;
        desc.componentSubType = UTGetOSTypeFromString(subType);
        CFStringRef manu = (__bridge CFStringRef)auData.manu;
        desc.componentManufacturer = UTGetOSTypeFromString(manu);
        NSError *err = nil;
        AUAudioUnit *au = [[AUAudioUnit alloc]
                           initWithComponentDescription:desc error:&err];
        NSDictionary *auState = [[au fullState] copy];
       
        LTInfoWindow *infoWindow =
            [[LTInfoWindow alloc] initWithWindowNibName:@"LTInfoWindow"];
        [infoWindow setTitle:auData.name];
        [infoWindow show];

        if (auState == nil)
        {
            [infoWindow setText:@"No state to show"];
        }
        else
        {
            NSMutableString *stateDesc = [[NSMutableString alloc] init];
            
            for (NSString *key in auState)
            {
                id value = auState[key];
            
                if ([key isEqualToString:@"type"] ||
                    [key isEqualToString:@"subtype"] ||
                    [key isEqualToString:@"manufacturer"])
                {
                    int tmp = [value intValue];
                    [stateDesc appendFormat:@"%@ = %@\n\n", key,
                     statusToString(tmp)];
                }
                else if ([key isEqualToString:@"version"])
                {
                    int tmp = [value intValue];
                    NSString *version = [NSString stringWithFormat:@"%i.%i.%i",
                                         ((tmp >> 16) & 0x0000ffff),
                                         ((tmp >> 8) & 0x000000ff),
                                         (tmp & 0x000000ff)];
                    [stateDesc appendFormat:@"%@ = %@\n\n", key, version];
                }
                else
                {
                    [stateDesc appendFormat:@"%@ = %@\n\n", key, value];
                }
            }
            
            [infoWindow setText:stateDesc];
        }
    }
}

- (void)getArch
{
    // Process components in /Library/Audio/Plug-Ins
    NSURL *dirUrl =
        [[NSURL alloc] initWithString:@"/Library/Audio/Plug-Ins/Components"];
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager]
        enumeratorAtURL:[dirUrl URLByResolvingSymlinksInPath]
        includingPropertiesForKeys:nil
        options:NSDirectoryEnumerationSkipsPackageDescendants
        errorHandler:nil];
    
    int count = 0;
    
    for (NSURL *url in enumerator)
    {
        if ((url != nil) && ([[[url lastPathComponent] pathExtension]
             isEqualToString:@"component"]))
        {
            [self processComponent:url];
            ++count;
        }
    }
    
    LTLog(mLog, mLogFile, OS_LOG_TYPE_INFO,
          @"Looked for arch information in %i system components.", count);
    
    // Process components installed in /User/.../Library/Audio/Plug-Ins
    struct passwd *pw = getpwuid(getuid());
    NSString *realHomeDir = [NSString stringWithUTF8String:pw->pw_dir];
    NSString *homeCompDir =
        [NSString stringWithFormat:@"%@/Library/Audio/Plug-Ins/Components",
         realHomeDir];
    NSURL *homeDirUrl = [[NSURL alloc] initWithString:homeCompDir];
    NSDirectoryEnumerator *homeEnumerator = [[NSFileManager defaultManager]
        enumeratorAtURL:[homeDirUrl URLByResolvingSymlinksInPath]
        includingPropertiesForKeys:nil
        options:NSDirectoryEnumerationSkipsPackageDescendants
        errorHandler:nil];
    
    count = 0;
    
    for (NSURL *url in homeEnumerator)
    {
        if ((url != nil) && ([[[url lastPathComponent] pathExtension]
             isEqualToString:@"component"]))
        {
            [self processComponent:url];
            ++count;
        }
    }
    
    LTLog(mLog, mLogFile, OS_LOG_TYPE_INFO,
          @"Looked for arch information in %i user components.", count);
    
    // Process components installed in /System/Library/Components
    NSString *compDir =
        [NSString stringWithFormat:@"/System/Library/Components"];
    NSURL *compDirUrl = [[NSURL alloc] initWithString:compDir];
    NSDirectoryEnumerator *compEnumerator = [[NSFileManager defaultManager]
        enumeratorAtURL:[compDirUrl URLByResolvingSymlinksInPath]
        includingPropertiesForKeys:nil
        options:NSDirectoryEnumerationSkipsPackageDescendants
        errorHandler:nil];
    
    count = 0;
    
    for (NSURL *url in compEnumerator)
    {
        if ((url != nil) && ([[[url lastPathComponent] pathExtension]
             isEqualToString:@"component"]))
        {
            [self processComponent:url];
            ++count;
        }
    }
    
    LTLog(mLog, mLogFile, OS_LOG_TYPE_INFO,
          @"Looked for arch information in %i /System/Library/Components "
           "components.", count);
}

- (void)processComponent:(NSURL *)url
{
    NSString *pInfoFile =
        [[NSString alloc] initWithFormat:@"%@/Contents/Info.plist",
         [url path]];
    NSDictionary *pInfo =
        [[NSDictionary alloc] initWithContentsOfFile:pInfoFile];
    NSString *minOS = [pInfo objectForKey:@"LSMinimumSystemVersion"];
    NSArray *aCompArray = [pInfo objectForKey:@"AudioComponents"];
    NSDictionary *aComp = nil;
    NSString *manu = nil;
    NSString *subtype = nil;
    NSString *type = nil;
    
    LTLog(mLog, mLogFile, OS_LOG_TYPE_INFO,
          @"Looking for arch info for component at %@", [url path]);

    if (aCompArray == nil)
    {
        LTLog(mLog, mLogFile, OS_LOG_TYPE_INFO,
              @"AudioComponents key not found for component at %@",
              [url path]);
        return;
    }
    else
    {
        for (int j = 0; j < [aCompArray count]; j++)
        {
            aComp = [aCompArray objectAtIndex:j];
            manu = [aComp objectForKey:@"manufacturer"];
            subtype = [aComp objectForKey:@"subtype"];
            type = [aComp objectForKey:@"type"];
            
            if ((manu == nil) || (subtype == nil) || (type == nil))
            {
                LTLog(mLog, mLogFile, OS_LOG_TYPE_INFO,
                      @"Incomplete AudioComponents information for "
                       "component %i at %@", j, [url path]);
                continue;;
            }
            
            LTAudioUnitData *auData = nil;
            bool found = false;
            
            for (int i = 0; i < [mAudioUnits count]; i++)
            {
                auData = [mAudioUnits objectAtIndex:i];
                
                if (([auData.compType isEqualToString:type]) &&
                    ([auData.subtype isEqualToString:subtype]) &&
                    ([auData.manu isEqualToString:manu]))
                {
                    found = true;
                    break;
                }
            }
            
            // Try just the subtype
            int matches = 0;
            int match_idx = -1;
            
            if (found == false)
            {
                for (int i = 0; i < [mAudioUnits count]; i++)
                {
                    auData = [mAudioUnits objectAtIndex:i];
                    
                    if ([auData.subtype isEqualToString:subtype])
                    {
                        match_idx = i;
                        ++matches;
                    }
                }
                
                if ((match_idx != -1) && (matches == 1))
                {
                    auData = [mAudioUnits objectAtIndex:match_idx];
                    found = true;
                }
            }

            // Get architecture if we have a match
            if ((found == true) && (auData != nil))
            {
                NSString *execDir =
                [[NSString alloc] initWithFormat:@"%@/Contents/MacOS",
                 [url path]];
                NSString* execDirEscaped =
                [execDir stringByAddingPercentEncodingWithAllowedCharacters:
                 [NSCharacterSet URLQueryAllowedCharacterSet]];
                NSURL *execUrl = [[NSURL alloc] initWithString:execDirEscaped];
                NSDirectoryEnumerator *execEnum =
                    [[NSFileManager defaultManager]
                     enumeratorAtURL:[execUrl URLByResolvingSymlinksInPath]
                     includingPropertiesForKeys:nil
                     options:NSDirectoryEnumerationSkipsPackageDescendants
                     errorHandler:nil];
                
                NSTask *task = [[NSTask alloc] init];
                NSArray *args =
                [NSArray arrayWithObjects:[[execEnum nextObject] path], nil];
                task.launchPath = @"/usr/bin/file";
                task.arguments = args;
                NSPipe *pipe = [NSPipe pipe];
                task.standardOutput = pipe;
                
                pipe.fileHandleForReading.readabilityHandler =
                    ^(NSFileHandle *h)
                {
                    self->mArchResult = [h readDataToEndOfFile];
                    [h closeFile];
                };
                
                [task launch];
                [task waitUntilExit];
                
                char string[100] = { 0 };
                unsigned char *result = (unsigned char *)[mArchResult bytes];
                
                if (result != nil)
                {
                    NSUInteger data_length = [mArchResult length];
                    result[data_length - 1] = 0;
                    strcat(string, "Arch:");
                    
                    if (strstr((const char *)result, "arm64"))
                    {
                        strcat(string, "A64,");
                    }
                    
                    if (strstr((const char *)result, "x86_64"))
                    {
                        strcat(string, "I64,");
                    }
                    
                    if (strstr((const char *)result, "i386"))
                    {
                        strcat(string, "I32,");
                    }
                    
                    if (strstr((const char *)result, "ppc"))
                    {
                        strcat(string, "PPC,");
                    }
                }
                
                auData.arch = [NSString stringWithCString:string
                               encoding:NSUTF8StringEncoding];
                auData.minOS = [minOS copy];
                
                LTLog(mLog, mLogFile, OS_LOG_TYPE_INFO,
                      @"Found arch info %@ for component %i at %@ (%@ %@ %@)",
                      auData.arch, j, [url path], auData.manu,
                      auData.subtype, auData.compType);
            }
        }
    }
}

@end
