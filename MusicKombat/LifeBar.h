//
//  LifeBar.h
//  MusicKombat
//
//  Created by Kenneth Ballenegger on 9/11/11.
//  Copyright 2011 Azure Talon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LifeBar : UIView

@property (nonatomic) int value;

- (id)initWithFrame:(CGRect)frame isRight:(BOOL)_isRight;

@end
