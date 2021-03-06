//
//  ViewController.m
//  framed-mac
//
//  Created by Neil McGuiggan on 24/09/2015.
//  Copyright © 2015 Multicoloured Software. All rights reserved.
//

#import "ViewController.h"
#import "DraggingView.h"
#import "DraggingButton.h"
#import "DraggingImageView.h"

@interface ViewController()

@property (weak) IBOutlet NSButton *screenshot;
@property (weak) IBOutlet NSImageView *framedImage;
@property (weak) IBOutlet NSButton *chooseButton;

@end

@implementation ViewController

- (void)loadView {
    [super loadView];
    [self registerDragReceivers];
}

- (void)registerDragReceivers {
    [self.view registerForDraggedTypes:@[NSFilenamesPboardType]];
    if ([self.view isKindOfClass:[DraggingView class]]) {
        ((DraggingView *)self.view).delegate = self;
    }
    
    [self.chooseButton registerForDraggedTypes:@[NSFilenamesPboardType]];
    if ([self.chooseButton isKindOfClass:[DraggingButton class]]) {
        ((DraggingButton *)self.chooseButton).delegate = self;
    }
    
    [self.framedImage registerForDraggedTypes:@[NSFilenamesPboardType]];
    if ([self.framedImage isKindOfClass:[DraggingImageView class]]) {
        ((DraggingImageView *)self.framedImage).delegate = self;
    }
}

- (IBAction)chooseScreenshot:(id)sender {
    NSOpenPanel *imagePanel = [NSOpenPanel openPanel];
    [imagePanel setAllowedFileTypes:[NSImage imageTypes]];
    [imagePanel setDirectoryURL:[NSURL URLWithString:NSHomeDirectory()]];
    [imagePanel setAllowsMultipleSelection:NO];
    [imagePanel setCanChooseDirectories:NO];
    [imagePanel setCanChooseFiles:YES];
    [imagePanel setResolvesAliases:YES];
    [imagePanel setMessage:@"Load your screenshot"];
    
    NSWindow *window = [[self view] window];
    
    [imagePanel beginSheetModalForWindow:window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            // We aren't allowing multiple selection, but NSOpenPanel still returns
            // an array with a single element.
            NSURL *imagePath = [[imagePanel URLs] objectAtIndex:0];
            NSImage *image = [[NSImage alloc] initWithContentsOfURL:imagePath];
            self.screenshot.image = image;
        } else {
            [imagePanel close];
        }
    }];
}

- (IBAction)shareScreenshot:(id)sender {
    NSBitmapImageRep *rep = [self deviceImage];
    NSImage *imageToSave = [[NSImage alloc] init];
    [imageToSave addRepresentation:rep];
  
    NSSharingServicePicker *sharingServicePicker = [[NSSharingServicePicker alloc] initWithItems:@[imageToSave]];
    sharingServicePicker.delegate = self;
    
    [sharingServicePicker showRelativeToRect:[sender bounds]
                                      ofView:sender
                               preferredEdge:NSMinYEdge];
}

- (IBAction)saveScreenshot:(id)sender {
    NSBitmapImageRep *rep = [self deviceImage];
    NSData *data = [rep representationUsingType:NSPNGFileType properties:@{NSImageCompressionFactor:@1.0}];
    
    // create the save panel
    NSSavePanel *panel = [NSSavePanel savePanel];
    
    // set a new file name
    [panel setNameFieldStringValue:@"FramedScreenshot.png"];
    
    // display the panel
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *saveURL = [panel URL];
            [data writeToURL:saveURL atomically:YES];
        }
    }];
}

- (NSBitmapImageRep *)deviceImage {
    NSImageView *framedImage = self.framedImage;
    [framedImage lockFocus];
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:[framedImage bounds]];
    [framedImage unlockFocus];
    
    return rep;
}

- (void)didDropImage:(NSString *)filename {
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:filename];
    self.screenshot.image = image;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.001 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      self.framedImage.image = [NSImage imageNamed:@"frame"];
    });
}

@end
