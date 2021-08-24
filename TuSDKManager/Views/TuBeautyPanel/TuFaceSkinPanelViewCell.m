/********************************************************
 * @file    : TuFaceSkinPanelViewCell.m
 * @project : TuSDKVideoDemo
 * @author  : Copyright © http://tutucloud.com/
 * @date    : 2020-08-01
 * @brief   : 美肤显示项
*********************************************************/

#import "TuFaceSkinPanelViewCell.h"
#import "Constants.h"


@implementation TuFaceSkinPanelViewData
- (instancetype)init
{
    if (self = [super init])
    {
        _code = @"reset";
    }
    return self;
}

- (void)setCode:(NSString *)code
{
    _code = code;
}

@end


@interface TuFaceSkinPanelViewCell()
{
    UILabel *_titleLabel;
    UIImageView *_thumbnailView;
    UIImageView *_selectImageView;
    UIView *_pointView;
    UIColor *_normalColor;
    UIColor *_selectColor;
}
@end


@implementation TuFaceSkinPanelViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self initWithSubViews];
    }
    return self;
}

- (void)initWithSubViews
{
    _normalColor = [UIColor colorWithWhite:1 alpha:0.35];
    _selectColor = [UIColor lsqClorWithHex:@"#FFDE00"];
    
    _thumbnailView = [[UIImageView alloc] init];
    _thumbnailView.contentMode = UIViewContentModeScaleAspectFit;
    _thumbnailView.backgroundColor = [UIColor clearColor];
    _thumbnailView.layer.masksToBounds = YES;
    [self addSubview:_thumbnailView];
    
    _selectImageView = [[UIImageView alloc] init];
    _selectImageView.layer.masksToBounds = YES;
    [self addSubview:_selectImageView];
    _selectImageView.hidden = YES;
    
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = [UIFont systemFontOfSize:10];
    _titleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.35];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_titleLabel];
    
    _pointView = [[UIView alloc] init];
    _pointView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.3];
    _pointView.layer.cornerRadius = 3;
    _pointView.hidden = YES;
    [self addSubview:_pointView];
}

- (void)layoutSubviews
{
    CGSize size = self.bounds.size;
    const CGFloat labelHeight = 22;
    const CGFloat imageWidth = 40;
    
    CGFloat margin = 0;
    CGFloat labelWidth = size.width;
    CGFloat titleMinX = 0;

    _thumbnailView.frame = CGRectMake(size.width / 2 - imageWidth / 2 + margin, 12, imageWidth, imageWidth);
    _titleLabel.frame = CGRectMake(titleMinX, CGRectGetHeight(_thumbnailView.frame) + CGRectGetMinY(_thumbnailView.frame), labelWidth, labelHeight);
    
    _selectImageView.frame = _thumbnailView.frame;
    
    _pointView.frame = CGRectMake(0, 0, 6, 6);
    _pointView.center = _thumbnailView.center;
}

- (void)setData:(TuFaceSkinPanelViewData *)data
{
    _data = data;
    
    _pointView.hidden = _selectImageView.hidden = YES;
    _thumbnailView.hidden = NO;
    
    if ([data.code isEqualToString:@"reset"])
    {
        _titleLabel.text = NSLocalizedStringFromTable(@"tu_无", @"TuSDKConstants", @"无");
        // 缩略图
        NSString *imageName = [NSString stringWithFormat:@"face_ic_%@", data.code];
        _thumbnailView.image = [UIImage imageNamed:imageName];
        
        NSString *selectImageName = [NSString stringWithFormat:@"face_ic_%@_sel", data.code];
        _selectImageView.image = [UIImage imageNamed:selectImageName];
    }
    else if ([data.code isEqualToString:@"point"])
    {
        _titleLabel.text = @"";
        _thumbnailView.hidden = _selectImageView.hidden = YES;
        _pointView.hidden = NO;
        
    }
    else
    {
        // 标题
        NSString *title = [NSString stringWithFormat:@"lsq_filter_set_%@", data.code];
        _titleLabel.text = NSLocalizedStringFromTable(title, @"TuSDKConstants", @"无需国际化");
        // 缩略图
        NSString *imageName = [NSString stringWithFormat:@"face_ic_%@", data.code];
        _thumbnailView.image = [UIImage imageNamed:imageName];
        
        NSString *selectImageName = [NSString stringWithFormat:@"face_ic_%@_sel", data.code];
        _selectImageView.image = [UIImage imageNamed:selectImageName];
    }
    
    if (data.beautySkinSelectType == TuBeautySkinSelectTypeSelected)
    {
        NSArray *shipDataSet = @[TuSkipBeautySkinKeys];
        //只有磨皮、美白、红润、锐化特效需要显示选中状态
        if ([shipDataSet containsObject:data.code])
        {
            _selectImageView.hidden = NO;
            _titleLabel.textColor = _selectColor;
        }
        else
        {
            _titleLabel.textColor = _normalColor;
        }
    }
    else
    {
        _selectImageView.hidden = YES;
        _titleLabel.textColor = _normalColor;
    }
}

@end
