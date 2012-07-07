/* 
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import "KalTileView.h"
#import "KalDate.h"
#import "KalPrivate.h"
#import "KalViewController.h"
#import "UIImageResizing.h"
#import "CoreText/CTFont.h"


#include "math.h"
static inline double radians (double degrees) {return degrees * M_PI/180;}


extern const CGSize kTileSize;


@implementation KalTileView

@synthesize date;


- (void) drawText: (NSString *) str withCtx: (CGContextRef)ctx atPoint: (CGPoint) point withFont: (UIFont *) font withColor: (UIColor *) color
{
    CGContextSaveGState(ctx);
    CGAffineTransform save = CGContextGetTextMatrix(ctx);

    [color setFill];
    CGContextTranslateCTM(ctx, 0.0f, self.bounds.size.height);
    CGContextScaleCTM(ctx, 1.0f, -1.0f);
    [str drawAtPoint:point withFont:font];
    CGContextSetTextMatrix(ctx, save);
    CGContextRestoreGState(ctx);
}

- (id)initWithFrame:(CGRect)frame delegate:(id<KalViewDelegate>)theDelegate
{
  if ((self = [super initWithFrame:frame])) {
    self.opaque = NO;
    self.backgroundColor = [UIColor clearColor];
    self.clipsToBounds = NO;
    origin = frame.origin;
    delegate = theDelegate;
    [self resetState];
  }
  return self;
}

- (void)drawRect:(CGRect)rect
{
  CGContextRef ctx = UIGraphicsGetCurrentContext();
  CGFloat fontSize = 21.f;
  UIFont *font = [UIFont boldSystemFontOfSize:fontSize];
  UIColor *shadowColor = nil;
  UIColor *textColor = nil;
  UIImage *markerImage = nil;
  CGContextSelectFont(ctx, [font.fontName cStringUsingEncoding:NSUTF8StringEncoding], fontSize, kCGEncodingMacRoman);
      
  CGContextTranslateCTM(ctx, 0, kTileSize.height);
  CGContextScaleCTM(ctx, 1, -1);
  
  if ([self isToday] && self.selected) {
      [[[UIImage imageNamed:@"Kal.bundle/kal_tile_today_selected.png"] stretchableImageWithLeftCapWidth:6 topCapHeight:0] drawInRect:CGRectMake(0, -1, kTileSize.width+1, kTileSize.height+1) blendMode:kCGBlendModeScreen alpha:0.8];
    textColor = [UIColor whiteColor];
    shadowColor = [UIColor blackColor];
    markerImage = [UIImage imageNamed:@"Kal.bundle/kal_marker_today.png"];
  } else if ([self isToday] && !self.selected) {
      [[[UIImage imageNamed:@"Kal.bundle/kal_tile_today.png"] stretchableImageWithLeftCapWidth:6 topCapHeight:0] drawInRect:CGRectMake(0, -1, kTileSize.width+1, kTileSize.height+1) blendMode:kCGBlendModeScreen alpha:0.8];
    textColor = [UIColor whiteColor];
    shadowColor = [UIColor blackColor];
    markerImage = [UIImage imageNamed:@"Kal.bundle/kal_marker_today.png"];
  } else if (self.selected) {
      [[[UIImage imageNamed:@"Kal.bundle/kal_tile_selected.png"] stretchableImageWithLeftCapWidth:1 topCapHeight:0] drawInRect:CGRectMake(0, -1, kTileSize.width+1, kTileSize.height+1) blendMode:kCGBlendModeScreen alpha:0.9];
    textColor = [UIColor whiteColor];
    shadowColor = [UIColor blackColor];
    markerImage = [UIImage imageNamed:@"Kal.bundle/kal_marker_selected.png"];
  } else if (self.belongsToAdjacentMonth) {
    textColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Kal.bundle/kal_tile_dim_text_fill.png"]];
    shadowColor = nil;
    markerImage = [UIImage imageNamed:@"Kal.bundle/kal_marker_dim.png"];
  } else {
    textColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Kal.bundle/kal_tile_text_fill.png"]];
    shadowColor = [UIColor whiteColor];
    markerImage = [UIImage imageNamed:@"Kal.bundle/kal_marker.png"];
  }
  
  if (flags.marked) {
      //    [markerImage drawInRect:CGRectMake(21.f, 5.f, 4.f, 5.f)];
      NSArray *iconlist;
      iconlist = [delegate KalTileDrawDelegate:self
                       getIconDrawInfoWithDate:self.date.NSDate];
      CGFloat count = 0;
      if (iconlist) {
          for (NSDictionary *dict in iconlist) {
              // first check icon draw type, if it's type one, just draw icon
              // if type two,draw with clip to mask.
                
              CGFloat iheight = kTileSize.height / 3;
              CGFloat iwidth = kTileSize.width / 3;
              CGFloat margin = 1;
              CGRect iconRect = CGRectMake(margin + (count * iwidth) , 
                                           kTileSize.height - iheight - (margin * 2), iwidth, iheight);
              // if it was draw color icon directly, use this. 
              CGContextSaveGState(ctx);

              NSNumber *showText      = [dict objectForKey:KAL_TILE_ICON_IS_SHOW_TEXT];
              NSString *text           = [dict objectForKey:KAL_TILE_ICON_TEXT];
              UIColor *iconTextColor      = [dict objectForKey:KAL_TILE_ICON_COLOR_KEY];
                
              (iconTextColor == nil) ? [UIColor blackColor] : iconTextColor;

              
              if (showText && showText.intValue == 1) {
                  // bold can see this...
                  UIFont *fontDrawText = [UIFont boldSystemFontOfSize:13.0];
                  [self drawText:text withCtx:ctx atPoint:CGPointMake(iconRect.origin.x, margin) withFont:fontDrawText withColor:iconTextColor];
              } else {
                  UIImage *img = [dict objectForKey:KAL_TILE_ICON_IMAGE_KEY];
                  [img scaleAndCropToSize:iconRect.size onlyIfNeeded:YES];
                  CGImageRef alphaImage = CGImageRetain(img.CGImage);
                  CGContextDrawImage(ctx, iconRect, alphaImage);
                  CGImageRelease(alphaImage);
              }

              CGContextRestoreGState(ctx);
              count += 1;
          }
      } else {
//            // draw a triangle under the square to make this day.
//            CGContextSaveGState(ctx);
//            CGContextBeginPath(ctx);
//            
//            // left, up conner
//            CGContextMoveToPoint(ctx, 0+1, kTileSize.height - 2);
//            CGContextAddLineToPoint(ctx, kTileSize.width/3, kTileSize.height - 2);
//            CGContextAddLineToPoint(ctx, 0+1, (kTileSize.height/3)*2);
//            
//            CGContextClosePath(ctx);
//            // todo the color should can be choose.
//            if (self.selected)
//                CGContextSetRGBFillColor(ctx, 0.8, 0.65, 0.7 ,1);
//            else
//                CGContextSetRGBFillColor(ctx, 0.55, .4, .55 ,1);
//            
//            CGContextSetBlendMode(ctx, kCGBlendModeScreen);
//            
//            CGContextFillPath(ctx);
//            CGContextRestoreGState(ctx);
        }
    }

  NSUInteger n = [self.date day];
  NSString *dayText = [NSString stringWithFormat:@"%lu", (unsigned long)n];
  const char *day = [dayText cStringUsingEncoding:NSUTF8StringEncoding];
  CGSize textSize = [dayText sizeWithFont:font];
  CGFloat textX, textY;
  textX = roundf(0.5f * (kTileSize.width - textSize.width));
  textY = 0.f + roundf(0.5f * (kTileSize.height - textSize.height));
  if (shadowColor) {
    [shadowColor setFill];
    CGContextShowTextAtPoint(ctx, textX, textY, day, n >= 10 ? 2 : 1);
    textY += 1.f;
  }
  [textColor setFill];
  CGContextShowTextAtPoint(ctx, textX, textY, day, n >= 10 ? 2 : 1);
  
  if (self.highlighted) {
    [[UIColor colorWithWhite:0.25f alpha:0.3f] setFill];
    CGContextFillRect(ctx, CGRectMake(0.f, 0.f, kTileSize.width, kTileSize.height));
  }
    

}

- (void)resetState
{
  // realign to the grid
  CGRect frame = self.frame;
  frame.origin = origin;
  frame.size = kTileSize;
  self.frame = frame;
  
  date = nil;
  flags.type = KalTileTypeRegular;
  flags.highlighted = NO;
  flags.selected = NO;
  flags.marked = NO;
}

- (void)setDate:(KalDate *)aDate
{
  if (date == aDate)
    return;

  date = aDate;

  [self setNeedsDisplay];
}

- (BOOL)isSelected { return flags.selected; }

- (void)setSelected:(BOOL)selected
{
  if (flags.selected == selected)
    return;

  // workaround since I cannot draw outside of the frame in drawRect:
  if (![self isToday]) {
    CGRect rect = self.frame;
    if (selected) {
      rect.origin.x--;
      rect.size.width++;
      rect.size.height++;
    } else {
      rect.origin.x++;
      rect.size.width--;
      rect.size.height--;
    }
    self.frame = rect;
  }
  
  flags.selected = selected;
  [self setNeedsDisplay];
}

- (BOOL)isHighlighted { return flags.highlighted; }

- (void)setHighlighted:(BOOL)highlighted
{
  if (flags.highlighted == highlighted)
    return;
  
  flags.highlighted = highlighted;
  [self setNeedsDisplay];
}

- (BOOL)isMarked { return flags.marked; }

- (void)setMarked:(BOOL)marked
{
  if (flags.marked == marked)
    return;
  
  flags.marked = marked;
  [self setNeedsDisplay];
}

- (KalTileType)type { return flags.type; }

- (void)setType:(KalTileType)tileType
{
  if (flags.type == tileType)
    return;
  
  // workaround since I cannot draw outside of the frame in drawRect:
  CGRect rect = self.frame;
  if (tileType == KalTileTypeToday) {
    rect.origin.x--;
    rect.size.width++;
    rect.size.height++;
  } else if (flags.type == KalTileTypeToday) {
    rect.origin.x++;
    rect.size.width--;
    rect.size.height--;
  }
  self.frame = rect;
  
  flags.type = tileType;
  [self setNeedsDisplay];
}

- (BOOL)isToday { return flags.type == KalTileTypeToday; }

- (BOOL)belongsToAdjacentMonth { return flags.type == KalTileTypeAdjacent; }


@end
