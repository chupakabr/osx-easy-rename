//
//  NiceRenameAppDelegate.h
//  NiceRename
//
//  Created by Valeriy Chevtaev on 7/1/11.
//  Copyright 2011 7bit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NiceRenameAppDelegate : NSObject <NSApplicationDelegate> {
@private
    NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

@end
