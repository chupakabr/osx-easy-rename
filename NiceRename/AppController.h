//
//  AppController.h
//  NiceRename
//
//  Created by Valeriy Chevtaev on 7/1/11.
//  Copyright 2011 7bit. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface AppController : NSObject {

@private
    IBOutlet NSTextField *renameThisTextField;
    IBOutlet NSTextField *replaceWithTextField;
    IBOutlet NSTextField *statusTextField;
    IBOutlet NSTextField *browseTextField;
    IBOutlet NSProgressIndicator *progressIndicator;
    IBOutlet NSButton *browseButton;
    IBOutlet NSButton *renameButton;
    IBOutlet NSButton *replaceWithNoneCheckbox;
    IBOutlet NSMatrix *fileType;
}

- (IBAction) browse:(id)sender;
- (IBAction) rename:(id)sender;
- (IBAction) replaceWithNoneChanged:(NSButton *)sender;

- (void) doRename:(id)sender;
- (void) onRenameSuccess:(NSNotification *)note;
- (void) onRenameError:(NSNotification *)note;
- (void) onRenameFinish;

@end
