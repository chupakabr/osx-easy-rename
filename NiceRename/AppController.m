//
//  AppController.m
//  NiceRename
//
//  Created by Valeriy Chevtaev on 7/1/11.
//  Copyright 2011 7bit. All rights reserved.
//

#import "AppController.h"

#define SUCCESS_NOTIFICATION @"ru.chupakabr.dev.cocoa.NiceRename#EVTSuccess"
#define ERROR_NOTIFICATION @"ru.chupakabr.dev.cocoa.NiceRename#EVTError"

#define ERROR_SOME_FILES_DONE 1
#define ERROR_UNKNOWN 9

#define RENAME_TYPE_FILES 0
#define RENAME_TYPE_FOLDERS 1
#define RENAME_TYPE_BOTH 2

@implementation AppController

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}


///
/// Replace this None checkbox value changed
///
- (IBAction) replaceWithNoneChanged:(NSButton *)sender
{
    if ([sender intValue] == YES) {
        [replaceWithTextField setStringValue:@""];
        [replaceWithTextField setEnabled:NO];
    } else {
        [replaceWithTextField setEnabled:YES];        
    }
}

///
/// Browse button handler
///
- (IBAction) browse:(id)sender
{
    NSOpenPanel *dlg = [NSOpenPanel openPanel];
    [dlg setCanChooseFiles:NO];
    [dlg setCanChooseDirectories:YES];
    [dlg setAllowsMultipleSelection:NO];
    
    if ([dlg runModalForDirectory:nil file:nil] == NSOKButton) {
        // Update text field with selected directory
        NSArray *urls = [dlg URLs];
        if (urls) {
            NSURL *url = [urls objectAtIndex:0];
            if (url) {
                [browseTextField setStringValue:[url path]];
            }
        }
    }

}

///
/// Rename button handler
///
- (IBAction) rename:(id)sender
{
    if ([[browseTextField stringValue] isEqualToString:@""]) {
        [statusTextField setStringValue:NSLocalizedString(@"Directory must be specified", nil)];
        return;
    }
    
    if ([[renameThisTextField stringValue] isEqualToString:@""]) {
        [statusTextField setTextColor:[NSColor redColor]];
        [statusTextField setStringValue:NSLocalizedString(@"Filename text must be set", nil)];
        return;
    }

    // Show progress controls
    [statusTextField setTextColor:[NSColor blackColor]];
    [statusTextField setStringValue:NSLocalizedString(@"Renaming...", nil)];
    [progressIndicator setHidden:NO];
    [progressIndicator startAnimation:self];
    
    // Disable UI controls
    [renameThisTextField setEditable:NO];
    [replaceWithTextField setEditable:NO];
    [browseButton setEnabled:NO];
    [renameButton setEnabled:NO];
    [replaceWithNoneCheckbox setEnabled:NO];

    
    // Bind notification listener
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRenameSuccess:) name:SUCCESS_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRenameError:) name:ERROR_NOTIFICATION object:nil];
    
    // Start renaming thread
    NSDictionary * params = [NSDictionary dictionaryWithObjectsAndKeys:
                                [browseTextField stringValue], @"filePath",
                                [renameThisTextField stringValue], @"renameText",
                                [replaceWithTextField stringValue], @"replaceText",
                                [NSNumber numberWithLong:[fileType selectedColumn]], @"fileType",
                                nil];
    [NSThread detachNewThreadSelector:@selector(doRename:) toTarget:self withObject:params];
}

///
/// OnSuccess renaming event handler
///
- (void) onRenameSuccess:(NSNotification *)note
{
    [self onRenameFinish];
    [statusTextField setStringValue:NSLocalizedString(@"Files were renamed successfully", nil)];
}

///
/// OnError renaming event handler
///
- (void) onRenameError:(NSNotification *)note
{
    [self onRenameFinish];
    [statusTextField setTextColor:[NSColor redColor]];
    
    NSNumber *errorCode = (NSNumber *) [note object]; 
    if ([errorCode intValue] == ERROR_SOME_FILES_DONE) {
        [statusTextField setStringValue:NSLocalizedString(@"Not all files have been renamed", nil)];
    } else {
        [statusTextField setStringValue:NSLocalizedString(@"Cannot rename files", nil)];
    }
}

///
/// Called everytime renaming thread finished execution
///
- (void) onRenameFinish
{
    // Stop notification listener
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SUCCESS_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ERROR_NOTIFICATION object:nil];
    
    // Update UI
    [progressIndicator stopAnimation:self];
    [progressIndicator setHidden:YES];
    [statusTextField setStringValue:NSLocalizedString(@"Files were renamed successfully", nil)];
    
    // Enable UI controler
    [renameThisTextField setEditable:YES];
    [replaceWithTextField setEditable:YES];
    [browseButton setEnabled:YES];
    [renameButton setEnabled:YES];
    [replaceWithNoneCheckbox setEnabled:YES];
    [self replaceWithNoneChanged:replaceWithNoneCheckbox];
}

///
/// Files renaming logic
///
- (void) doRename:(NSDictionary *)params
{
    NSAutoreleasePool *pool;
    pool = [[NSAutoreleasePool alloc] init];
    
    // Rename
    BOOL hasErrors = NO;
    int processedFiles = 0;
    
    int fileTypeVal = [[params objectForKey:@"fileType"] intValue];
    NSError * errors = nil;
    NSFileManager * fileMgr = [NSFileManager defaultManager];
    NSString * filePath = [params objectForKey:@"filePath"];
    NSArray * files = [fileMgr contentsOfDirectoryAtPath:filePath error:&errors];
    
    NSLog(@"FileType: %d", fileTypeVal);
    
    if (files != nil) {
        BOOL isDir;
        BOOL needRename;
        NSString * renameText = [params objectForKey:@"renameText"];
        NSString * replaceText = [params objectForKey:@"replaceText"];
        NSPredicate * filePattern = [NSPredicate predicateWithFormat:@"self CONTAINS[c] %@", renameText];
        
        for (NSString *file in files) {
            if ([filePattern evaluateWithObject:file]) {
                
                NSString * from = [filePath stringByAppendingPathComponent:file];
                [fileMgr fileExistsAtPath:from isDirectory:&isDir];
                
                // Check for file type
                switch (fileTypeVal) {
                    case RENAME_TYPE_FILES:
                        needRename = (isDir == NO);
                        break;
                        
                    case RENAME_TYPE_FOLDERS:
                        needRename = isDir;
                        break;
                        
                    default:
                        needRename = YES;
                        break;
                }
                
                // Do rename if needed
                if (needRename)
                {
                    NSString * to = [filePath stringByAppendingPathComponent:
                                     [file stringByReplacingOccurrencesOfString:renameText withString:replaceText]];
                    
                    // Do rename
                    if ([fileMgr moveItemAtPath:from toPath:to error:&errors]) {
                        processedFiles++;
                    }
                }
            }
        }
    } else {
        hasErrors = YES;
    }
        
    // Notify main thread that processing finished
    if (hasErrors) {
        int error = processedFiles > 0 ? ERROR_SOME_FILES_DONE : ERROR_UNKNOWN;
        NSNotification * note = [NSNotification notificationWithName:ERROR_NOTIFICATION object:[NSNumber numberWithInt:error]];
        [[NSNotificationCenter defaultCenter] postNotification:note];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:SUCCESS_NOTIFICATION object:nil];
    }
    
    [pool release];
}

@end
