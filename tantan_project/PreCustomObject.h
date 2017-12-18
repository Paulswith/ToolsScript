//
//  PreCustomObject.h
//  putong
//
//  Created by dobby on 2017/12/14.
//  Copyright © 2017年 Dobby. All rights reserved.
//

#ifndef PreCustomObject_h
#define PreCustomObject_h
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@class UserObject;

@interface MessageObject
@property(retain, nonatomic) NSString *value;
@property(readonly, nonatomic) NSString *message;
@property(retain, nonatomic) UserObject *owner;
@end


@interface MessageCollection
@property(readonly, nonatomic) MessageObject *latestNormalMessage;

@end



@interface ConversationObject
@property(retain, nonatomic) MessageCollection *messageCollection;
@property(retain, nonatomic) NSDate *latestTime; 
@property(retain, nonatomic) NSDate *latestReceivedTime;
@property(retain, nonatomic) NSDate *clearedUntil; // @dynamic clearedUntil;
@property(retain, nonatomic) NSDate *createdTime; // @dynamic createdTime;
@property(nonatomic) _Bool isRead; // @dynamic isRead;
@property(retain, nonatomic) NSDate *latestReadMessageCreatedTime; // @dynamic latestReadMessageCreatedTime;
@end

@interface P1ConversationTableView
- (void)controller:(id)arg1 didChangeObject:(ConversationObject *)conversation atIndexPath:(id)arg3 forChangeType:(NSUInteger)type newIndexPath:(id)arg5;  //
@end

@interface P1MessagesViewController
- (void)sendMessage:(NSString *)content;
@end

@interface P1MessagesView : UIView
@property(retain, nonatomic) ConversationObject *conversationObject;
- (void)controller:(id)arg1 didChangeObject:(MessageObject *)arg2 atIndexPath:(id)arg3 forChangeType:(NSUInteger)arg4 newIndexPath:(id)arg5;
@end



@interface P1HelpCenterHomeViewController
- (void)tableView:(UITableView *)arg1 didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
@end


@interface P1HomeNearbyViewController
@property(readonly, nonatomic) NSUInteger maximumVisibleUserCardCount;
- (void)viewDidAppear:(BOOL)arg1;
- (void)checkIfShouldShowAlertViewForDismissTopUserWithLike:(BOOL)arg1 dragVelocity:(struct CGPoint)arg2 cancelDragAction:(id)arg3;
- (UIButton *)dislikeButton;
- (UIButton *)likeButton;
- (id)topUserCard;
@end


@interface P1HomeLookingViewController
@property(retain, nonatomic) CLLocation *userLocation;
@end



@interface StudiesInfo
@property(retain, nonatomic) NSString *major;
@property(retain, nonatomic) NSString *school;
@property(nonatomic) BOOL verified;
@property(readonly, nonatomic) NSString *studentString;
- (NSDictionary *)toDictionary;
@end


@interface WorkInfo
@property(retain, nonatomic) NSString *company;
@property(retain, nonatomic) NSString *department;
@property(retain, nonatomic) NSString *industry;
- (NSDictionary *)toDictionary;
@end


@interface ProfileInfo : NSObject
@property(retain, nonatomic) NSArray *answers;
@property(readonly, nonatomic) NSString *displayableZodiac;
@property(retain, nonatomic) NSString *hangouts;
@property(retain, nonatomic) NSString *hometown;
@property(readonly, nonatomic) BOOL isStudent;
@property(retain, nonatomic) NSArray *momentIds;
@property(retain, nonatomic) NSArray *scenarioReferences;
@property(readonly, nonatomic) NSArray *scenarios;
@property(retain, nonatomic) NSArray *social;
@property(retain, nonatomic) StudiesInfo *studies;
@property(retain, nonatomic) NSArray *tags;
@property(retain, nonatomic) WorkInfo *work;
@property(nonatomic) long long zodiacType;
- (NSDictionary *)toDictionary;
@end


@interface UserObject
@property (readonly,nonatomic) BOOL isCurrentUser;
@property(readonly, nonatomic) NSArray *pictures;
@property(readonly, nonatomic) ProfileInfo *profile;
@property(nonatomic) int age;
@property(retain, nonatomic) NSDate *createdTime;
@property(nonatomic) int gender;
@property(nonatomic) BOOL isHidden;   // hook它 , 不想见的都能见了?
@property(retain, nonatomic) NSDictionary *locationDictionary;
@property(retain, nonatomic) NSString *name;
@property(retain, nonatomic) NSArray *pictureDictionaries;
@property(retain, nonatomic) NSDictionary *profileDictionary;
@property(retain, nonatomic) NSString *userDescription;
@end

#endif /* PreCustomObject_h */
