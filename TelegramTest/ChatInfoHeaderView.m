//
//  ChatInfoHeaderView.m
//  Messenger for Telegram
//
//  Created by Dmitry Kondratyev on 3/9/14.
//  Copyright (c) 2014 keepcoder. All rights reserved.
//

#import "ChatInfoHeaderView.h"
#import "TMAvatarImageView.h"
#import "UserInfoShortButtonView.h"
#import "ChatInfoNotificationView.h"
#import "ChatAvatarImageView.h"
#import "SelectUserItem.h"
#import "PreviewObject.h"
#import "TMPreviewChatPicture.h"
#import "TMMediaUserPictureController.h"
#import "PhotoHistoryFilter.h"
#import "TMSharedMediaButton.h"
#import "ComposeActionAddGroupMembersBehavior.h"
#import "TGPhotoViewer.h"
#import "MessagesUtils.h"
@implementation LineView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    [NSColorFromRGB(0xe6e6e6) set];
    NSRectFill(NSMakeRect(0, 0, self.bounds.size.width, 1));
}

@end

@interface ChatInfoHeaderView()
@property (nonatomic, strong) TLChatFull *fullChat;
@property (nonatomic,strong) TMTextField *muteUntilTitle;



@end

@implementation ChatInfoHeaderView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        weakify();
        
        
        float offsetRight = self.bounds.size.width - 200;
        
        _avatarImageView = [ChatAvatarImageView standartUserInfoAvatar];
        
        [self.avatarImageView setFrameSize:NSMakeSize(70, 70)];
        
        [self.avatarImageView setFrameOrigin:NSMakePoint(100, self.bounds.size.height - self.avatarImageView.bounds.size.height - 30)];
        
        [self addSubview:self.avatarImageView];
        
        [self.avatarImageView setSourceType:ChatAvatarSourceGroup];
        
        
        [self.avatarImageView setTapBlock:^{
            
            if(strongSelf.avatarImageView.sourceType != ChatAvatarSourceBroadcast) {
                
                if(![strongSelf.fullChat.chat_photo isKindOfClass:[TL_photoEmpty class]]) {
                    
                    TL_photoSize *size = [strongSelf.fullChat.chat_photo.sizes lastObject];
                    
                    PreviewObject *previewObject = [[PreviewObject alloc] initWithMsdId:strongSelf.fullChat.chat_photo.n_id media:size peer_id:strongSelf.fullChat.n_id];
                    
                    previewObject.reservedObject = [TGCache cachedImage:strongSelf.controller.chat.photo.photo_small.cacheKey];
                    
                    [[TGPhotoViewer viewer] show:previewObject];
                }
               
//                
//                TMPreviewChatPicture *picture = [[TMPreviewChatPicture alloc] initWithItem:previewObject];
//                if(picture)
//                    [[TMMediaUserPictureController controller] show:picture];
            }
            
        }];
        
        self.muteUntilTitle = [TMTextField defaultTextField];
        
        self.nameTextField = [[TMNameTextField alloc] init];
        [self.nameTextField setNameDelegate:self];
        [self.nameTextField setSelector:@selector(titleForChatInfo)];
        [self.nameTextField setTextColor:NSColorFromRGB(0x333333)];
        [self.nameTextField setEditable:NO];
        [self.nameTextField setSelectable:YES];
        [[self.nameTextField cell] setFocusRingType:NSFocusRingTypeNone];
        [self.nameTextField setFont:TGSystemFont(15)];
        [self.nameTextField setTarget:self];
        [self.nameTextField setAction:@selector(enter)];
        [self addSubview:self.nameTextField];
        
        _nameLiveView = [[LineView alloc] initWithFrame:NSMakeRect(185, self.bounds.size.height - 80, NSWidth(self.frame) - 310, 1)];
        [self.nameLiveView setHidden:YES];
        [self addSubview:self.nameLiveView];
        
        _statusTextField = [[TMStatusTextField alloc] init];
        
        [_statusTextField setSelector:@selector(statusForMessagesHeaderView)];
        
        
        [self.statusTextField setBordered:NO];
        [self addSubview:self.statusTextField];
        
        _setGroupPhotoButton = [UserInfoShortButtonView buttonWithText:NSLocalizedString(@"Profile.SetGroupPhoto", nil) tapBlock:^{
            [self.avatarImageView showUpdateChatPhotoBox];
        }];
        [self.setGroupPhotoButton setFrameSize:NSMakeSize(offsetRight, 42)];
        [self.setGroupPhotoButton setFrameOrigin:NSMakePoint(100, self.bounds.size.height - 156)];
        [self addSubview:self.setGroupPhotoButton];
        
        
        _addMembersButton = [UserInfoShortButtonView buttonWithText:NSLocalizedString(@"Group.AddMembers", nil) tapBlock:^{
            
            NSMutableArray *filter = [[NSMutableArray alloc] init];
            
            for (TL_chatParticipant *participant in self.fullChat.participants.participants) {
                [filter addObject:@(participant.user_id)];
            }
            
            
            if(self.fullChat.participants.participants.count < maxChatUsers())
                [[Telegram rightViewController] showComposeWithAction:[[ComposeAction alloc]initWithBehaviorClass:[ComposeActionAddGroupMembersBehavior class] filter:filter object:self.fullChat]];
            
            
        }];
        
        [self.addMembersButton setFrameSize:NSMakeSize(self.setGroupPhotoButton.bounds.size.width, 42)];
        [self.addMembersButton setFrameOrigin:NSMakePoint(self.setGroupPhotoButton.frame.origin.x, self.setGroupPhotoButton.frame.origin.y - 42)];
        
       
        [self addSubview:self.addMembersButton];
        
        
        _exportChatInvite = [UserInfoShortButtonView buttonWithText:NSLocalizedString(@"Group.CopyExportChatInvite", nil) tapBlock:^{
            
            
            
            
            dispatch_block_t cblock = ^ {
                
                [[Telegram rightViewController] showChatExportLinkController:_fullChat];

            };
            
            
            if([_fullChat.exported_invite isKindOfClass:[TL_chatInviteExported class]]) {
                
                cblock();
                
            } else {
                
                [TMViewController showModalProgress];
                
                [RPCRequest sendRequest:[TLAPI_messages_exportChatInvite createWithChat_id:_fullChat.n_id] successHandler:^(RPCRequest *request, TL_chatInviteExported *response) {
                    
                    [TMViewController hideModalProgressWithSuccess];
                    
                    _fullChat.exported_invite = response;
                    
                    [[Storage manager] insertFullChat:_fullChat completeHandler:nil];
                    
                    cblock();
                    
                    
                } errorHandler:^(RPCRequest *request, RpcError *error) {
                    [TMViewController hideModalProgress];
                } timeout:10];
                
            }
            
            
            
            
        }];
        
        [_exportChatInvite setFrameSize:NSMakeSize(self.addMembersButton.bounds.size.width, 42)];
        [_exportChatInvite setFrameOrigin:NSMakePoint(self.addMembersButton.frame.origin.x, self.addMembersButton.frame.origin.y - 42)];
        
        
        
        [self addSubview:_exportChatInvite];
        
        
        
        
        self.sharedMediaButton = [TMSharedMediaButton buttonWithText:NSLocalizedString(@"Profile.SharedMedia", nil) tapBlock:^{
            
            [[Telegram rightViewController] showCollectionPage:self.controller.chat.dialog];
            
            [[Telegram rightViewController].collectionViewController showAllMedia];
        }];
        
        [self.sharedMediaButton setFrameSize:NSMakeSize(self.exportChatInvite.bounds.size.width, 42)];
        [self.sharedMediaButton setFrameOrigin:NSMakePoint(self.exportChatInvite.frame.origin.x, self.exportChatInvite.frame.origin.y - 72)];
        
        [self addSubview:self.sharedMediaButton];
        
        self.filesMediaButton = [TMSharedMediaButton buttonWithText:NSLocalizedString(@"Profile.SharedMediaFiles", nil) tapBlock:^{
            
            [[Telegram rightViewController] showCollectionPage:self.controller.chat.dialog];
            
            [[Telegram rightViewController].collectionViewController showFiles];
        }];
        
        self.filesMediaButton.isFiles = YES;
        
        [self.filesMediaButton setFrameSize:NSMakeSize(self.addMembersButton.bounds.size.width, 42)];
        
        [self.filesMediaButton setFrameOrigin:NSMakePoint(self.sharedMediaButton.frame.origin.x, self.sharedMediaButton.frame.origin.y -42)];
        
        [self addSubview:self.filesMediaButton];
                
        _notificationView = [UserInfoShortButtonView buttonWithText:NSLocalizedString(@"Notifications", nil) tapBlock:^{
            
            
            NSMenu *menu = [MessagesViewController notifications:^{
                
                [self buildNotificationsTitle];
                
            } conversation:self.controller.chat.dialog click:^{
                
                
            }];;
            
            TMMenuPopover *menuPopover = [[TMMenuPopover alloc] initWithMenu:menu];
            
            [menuPopover showRelativeToRect:strongSelf.muteUntilTitle.bounds ofView:strongSelf.muteUntilTitle preferredEdge:CGRectMinYEdge];
            
        }];
//        
//        _notificationSwitcher = [[ITSwitch alloc] initWithFrame:NSMakeRect(0, 0, 36, 20)];
//        
//        _notificationView.rightContainer = self.notificationSwitcher;
//        
//        [self.notificationSwitcher setDidChangeHandler:^(BOOL isOn) {
//            
//            TL_conversation *dialog = [[DialogsManager sharedManager] findByChatId:strongSelf.controller.chat.n_id];
//            
//            BOOL isMute =  dialog.isMute;
//            if(isMute == isOn) {
//             //   [dialog muteOrUnmute:nil];
//            }
//
//        }];
        
        [_notificationView setFrame:NSMakeRect(100,  NSMinY(self.filesMediaButton.frame) - 42, NSWidth(self.frame) - 200, 42)];
        

        [self addSubview:self.notificationView];
        
        self.filesMediaButton.textButton.textColor = self.sharedMediaButton.textButton.textColor = self.notificationView.textButton.textColor = DARK_BLACK;
        
        

        
    }
    return self;
}

- (void)rebuild {
    
}

- (void)enter {
    [self.controller save];
}



- (void)setType:(ChatInfoViewControllerType)type {
    self->_type = type;
    
    float duration = 0.08;
    [self.statusTextField prepareForAnimation];
    [self.nameLiveView prepareForAnimation];
    
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [self.statusTextField setHidden:self.statusTextField.layer.opacity == 0];
        [self.nameLiveView setHidden:self.nameLiveView.layer.opacity == 0];
    }];
    switch (self->_type) {
        case ChatInfoViewControllerEdit: {
            [self.nameTextField setEditable:YES];
            if([self.nameTextField becomeFirstResponder]) {
                 [self.nameTextField setCursorToEnd];
            }
           
            [self.statusTextField setAnimation:[TMAnimations fadeWithDuration:duration fromValue:1 toValue:0] forKey:@"opacity"];
            [self.nameLiveView setAnimation:[TMAnimations fadeWithDuration:duration fromValue:0 toValue:1] forKey:@"opacity"];
        }
            break;
            
        case ChatInfoViewControllerNormal: {
            [self.nameTextField setEditable:NO];
            [self.statusTextField setAnimation:[TMAnimations fadeWithDuration:duration fromValue:0 toValue:1] forKey:@"opacity"];
            [self.nameLiveView setAnimation:[TMAnimations fadeWithDuration:duration fromValue:1 toValue:0] forKey:@"opacity"];

        }
            break;
            
        default:
            break;
    }
    [CATransaction commit];
}

- (void)mouseDown:(NSEvent *)theEvent {
    if(self.window.firstResponder != self.nameTextField) {
        if([self.nameTextField becomeFirstResponder])
            [self.nameTextField setCursorToEnd];
    }
}

- (NSString *)title {
    return self.nameTextField.stringValue;
}

- (void) TMNameTextFieldDidChanged:(TMNameTextField *)textField {
    [self.nameTextField sizeToFit];
    [self.nameTextField setFrame:NSMakeRect(185, self.bounds.size.height - 43   - self.nameTextField.bounds.size.height, self.bounds.size.width - 185 - 30, self.nameTextField.bounds.size.height)];
    
    
    [self.statusTextField sizeToFit];
    [self.statusTextField setFrame:NSMakeRect(182, self.nameTextField.frame.origin.y - self.statusTextField.bounds.size.height - 3, MIN(self.bounds.size.width - 310,NSWidth(self.statusTextField.frame)), self.nameTextField.bounds.size.height)];
}

- (void)setController:(ChatInfoViewController *)controller {
    self->_controller = controller;
    
    self.avatarImageView.controller = controller;
}

- (void)reload {
    
    TLChat *chat = self.controller.chat;
    
    [self.statusTextField setChat:chat];
    [self.statusTextField sizeToFit];
    
    self.fullChat = [[FullChatManager sharedManager] find:chat.n_id];
    if(!self.fullChat) {
        DLog(@"full chat is not loading");
        return;
    }
    
    [self.avatarImageView setChat:chat];
    [self.avatarImageView rebuild];
    
   
    
    [_mediaView setConversation:chat.dialog];
    [self.sharedMediaButton setConversation:chat.dialog];
    [self.filesMediaButton setConversation:chat.dialog];
    
    [self.nameTextField setChat:chat];
    
    
    [self buildNotificationsTitle];
    
    [self TMNameTextFieldDidChanged:self.nameTextField];
    
    
    [_exportChatInvite setHidden:self.fullChat.participants.admin_id != [UsersManager currentUserId]];
    
    
    
    [self.sharedMediaButton setFrameOrigin:NSMakePoint(NSMinX(_exportChatInvite.isHidden ? self.addMembersButton.frame : self.exportChatInvite.frame), NSMinY(_exportChatInvite.isHidden ? self.addMembersButton.frame : self.exportChatInvite.frame) - 72)];

  
    [self.filesMediaButton setFrameOrigin:NSMakePoint(self.sharedMediaButton.frame.origin.x, self.sharedMediaButton.frame.origin.y -42)];
    

    [_notificationView setFrame:NSMakeRect(100,  NSMinY(self.filesMediaButton.frame) - 42, NSWidth(self.frame) - 200, 42)];
    

    
}

-(void)buildNotificationsTitle  {
    
    static NSTextAttachment *attach;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        attach = [NSMutableAttributedString textAttachmentByImage:[image_selectPopup() imageWithInsets:NSEdgeInsetsMake(0, 10, 0, 0)]];
    });
    
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
    NSString *str = [MessagesUtils muteUntil:self.controller.chat.dialog.notify_settings.mute_until];
    
    [string appendString:str withColor:NSColorFromRGB(0xa1a1a1)];
    
    [string setFont:[NSFont fontWithName:@"HelveticaNeue-Light" size:15] forRange:NSMakeRange(0, string.length)];
    
    [string appendAttributedString:[NSAttributedString attributedStringWithAttachment:attach]];
    [self.muteUntilTitle setAttributedStringValue:string];
    
    [self.muteUntilTitle sizeToFit];
    
    self.notificationView.rightContainer = self.muteUntilTitle;
    
}


- (void)drawRect:(NSRect)dirtyRect {
	[super drawRect:dirtyRect];
	
    // Drawing code here.
}

@end
