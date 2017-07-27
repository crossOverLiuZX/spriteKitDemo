//
//  MyScrene.m
//  SpriteKitDemo
//
//  Created by liuZX on 17/7/27.
//  Copyright © 2017年 LY_LiuZX. All rights reserved.
//

#import "MyScrene.h"

@interface MyScrene()


@property (nonatomic, strong) NSMutableArray *monsters;
@property (nonatomic, strong) NSMutableArray *projectiles;


@end
@implementation MyScrene
- (instancetype)initWithSize:(CGSize)size {
    
    if (self = [super initWithSize:size]) {
        self.backgroundColor = [UIColor whiteColor];
        SKSpriteNode *player = [SKSpriteNode spriteNodeWithImageNamed:@"MLA.jpg"];
        player.size = CGSizeMake(40, 40);
        
        player.position = CGPointMake(player.size.width/2, self.size.height/2);
        
        [self addChild:player];
        
        //添加怪物
        [self addMonster];
    }
    return self;
}
#pragma mark - 创建怪物
- (void)  addMonster {
    __weak typeof(self) weakSelf = self;
    SKAction *actionAddMonster = [SKAction runBlock:^{
        //添加新的怪物
        [weakSelf addNewMonster];
    }];
    //actionAddMonster 是创建怪物 --- actionWaitNextMonster 设置怪物出现间隔
    SKAction *actionWaitNextMonster = [SKAction waitForDuration:1];
    //sequence 设置顺序  类似依赖---下面的方法意思是每隔一秒创建一个怪物出来
    [self runAction:[SKAction repeatActionForever:[SKAction sequence:@[actionAddMonster,actionWaitNextMonster]]]];
}
- (void) addNewMonster {
    SKSpriteNode *monster = [SKSpriteNode spriteNodeWithImageNamed:@"monster"];
    
    //1 让怪物随机出现在某一个位置（y）
    CGSize winSize = self.size;
    int minY = monster.size.height / 2;
    int maxY = winSize.height - monster.size.height/2;
    int rangeY = maxY - minY;
    int actualY = (arc4random() % rangeY) + minY;
    
    monster.position = CGPointMake(winSize.width + monster.size.width/2, actualY);
    [self addChild:monster];
    
    //速度
    int minDuration = 2.0;
    int maxDuration = 4.0;
    int rangeDuration = maxDuration - minDuration;
    int actualDuration = (arc4random() % rangeDuration) + minDuration;
    
    //这里创建一个行为，让怪物跑到最左边，并设置跑的时间
    SKAction *actionMove = [SKAction moveTo:CGPointMake(-monster.size.width/2, actualY)
                                   duration:actualDuration];
    //然后 如果已经跑到了左边 执行移除方法
    SKAction *actionMoveDone = [SKAction runBlock:^{
        [monster removeFromParent];
        [self.monsters removeObject:monster];
        //在这里你可以做一些逻辑 比如怪物没被杀死 跑出屏幕 游戏结束什么的
    }];
    //跑起来
    [monster runAction:[SKAction sequence:@[actionMove,actionMoveDone]]];
    
    [self.monsters addObject:monster];

}
- (NSMutableArray *)monsters {
    if (!_monsters) {
        _monsters = [NSMutableArray new];
    }
    return _monsters;
}
- (NSMutableArray *)projectiles {
    if (!_projectiles) {
        _projectiles = [NSMutableArray new];
    }
    return _projectiles;
}
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    //点击屏幕 就发射飞镖
    for (UITouch *touch in touches) {
        //
        CGSize winSize = self.size;
        SKSpriteNode *projectile = [SKSpriteNode spriteNodeWithImageNamed:@"projectile.png"];
        projectile.position = CGPointMake(projectile.size.width/2, winSize.height/2);
        
        //2 Get the touch location tn the scene and calculate offset
        CGPoint location = [touch locationInNode:self];
        CGPoint offset = CGPointMake(location.x - projectile.position.x, location.y - projectile.position.y);
        
        // 一些基本的判断
        if (offset.x <= 0) return;
        
        [self addChild:projectile];
        
        int realX = winSize.width + (projectile.size.width/2);
        float ratio = (float) offset.y / (float) offset.x;
        int realY = (realX * ratio) + projectile.position.y;
        CGPoint realDest = CGPointMake(realX, realY);
        
        
        int offRealX = realX - projectile.position.x;
        int offRealY = realY - projectile.position.y;
        float length = sqrtf((offRealX*offRealX)+(offRealY*offRealY));
        float velocity = self.size.width/1; // projectile speed.
        float realMoveDuration = length/velocity;
        
        //让子弹飞吧
        SKAction *moveAction = [SKAction moveTo:realDest duration:realMoveDuration];
        SKAction *projectileCastAction = [SKAction group:@[moveAction]];
        [projectile runAction:projectileCastAction completion:^{
            [projectile removeFromParent];
            [self.projectiles removeObject:projectile];
        }];
        
        [self.projectiles addObject:projectile];
    }
}

-(void)update:(CFTimeInterval)currentTime {
    //场景的每一帧渲染时候都会走这么回调---在这里来做飞镖和怪物的碰撞检测吧
    NSMutableArray *projectilesToDelete = [[NSMutableArray alloc] init];
    for (SKSpriteNode *projectile in self.projectiles) {
        
        NSMutableArray *monstersToDelete = [[NSMutableArray alloc] init];
        for (SKSpriteNode *monster in self.monsters) {
            
            if (CGRectIntersectsRect(projectile.frame, monster.frame)) {
                [monstersToDelete addObject:monster];
            }
        }
        
        for (SKSpriteNode *monster in monstersToDelete) {
            [self.monsters removeObject:monster];
            [monster removeFromParent];
            
            //这里可以做一些逻辑 比如通关判定
        }
        
        if (monstersToDelete.count > 0) {
            [projectilesToDelete addObject:projectile];
        }
    }
    
    for (SKSpriteNode *projectile in projectilesToDelete) {
        [self.projectiles removeObject:projectile];
        [projectile removeFromParent];
    }
}
@end
