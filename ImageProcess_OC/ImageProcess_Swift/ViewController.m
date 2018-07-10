//
//  ViewController.m
//  ImageProcess_Swift
//
//  Created by  bochb on 2018/7/10.
//  Copyright © 2018年 com.heron. All rights reserved.
//

/**
 图像处理的基本原理: 将图像转化成二进制数据, 处理二进制数据, 二进制数据还原成图像
 */
#import "ViewController.h"
#import <CoreGraphics/CoreGraphics.h>

//图像处理的宏定义
#define MaskB(x) ((x) & 0xFF)
#define R(x) (MaskB(x))
#define G(x) (MaskB(x >> 8))
#define B(x) (MaskB(x >> 16))
#define A(x) (MaskB(x >> 24))
#define RGBA(r,g,b,a) (MaskB(r) | MaskB(g)<<8 | MaskB(b) << 16 | MaskB(a) << 24)

@interface ViewController ()
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray <UIImageView *>*imageViews;
@end

static NSString *imageName = @"9-160P4202242";

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self textConversion];
    [self textGrayImage];
    [self textColorReverseImage];
    [self textSampleBeautyImage];

}
- (void)textSampleBeautyImage{
    UIImage *image = [UIImage imageNamed:imageName];
    
    unsigned char *data = [self dataFromImage:image];
    
    UInt32 *processedData = [self sampleBeautyWithImageData:data width:CGImageGetWidth(image.CGImage) height:CGImageGetHeight(image.CGImage)];
    
    //宽高要去cgimage的宽高
    UIImage *convertedImage = [self imageFromData:(unsigned char *)processedData width:CGImageGetWidth(image.CGImage) height:CGImageGetHeight(image.CGImage)];
    
    self.imageViews[3].image = convertedImage;
}
- (void)textColorReverseImage{
    UIImage *image = [UIImage imageNamed:imageName];
    
    unsigned char *data = [self dataFromImage:image];
    
    unsigned char *processedData = [self colorReverseWithImageData:data width:CGImageGetWidth(image.CGImage) height:CGImageGetHeight(image.CGImage)];
    
    //宽高要去cgimage的宽高
    UIImage *convertedImage = [self imageFromData:processedData width:CGImageGetWidth(image.CGImage) height:CGImageGetHeight(image.CGImage)];
    
    self.imageViews[2].image = convertedImage;
}
- (void)textGrayImage{
    UIImage *image = [UIImage imageNamed:imageName];
    
    unsigned char *data = [self dataFromImage:image];
    
   unsigned char *processedData = [self grayImageWithImageData:data width:CGImageGetWidth(image.CGImage) height:CGImageGetHeight(image.CGImage)];
    
    //宽高要去cgimage的宽高
    UIImage *convertedImage = [self imageFromData:processedData width:CGImageGetWidth(image.CGImage) height:CGImageGetHeight(image.CGImage)];
    
    self.imageViews[1].image = convertedImage;
}
- (void)textConversion{
    UIImage *image = [UIImage imageNamed:imageName];
    
    unsigned char *data = [self dataFromImage:image];
    
    //宽高要去cgimage的宽高
    UIImage *convertedImage = [self imageFromData:data width:CGImageGetWidth(image.CGImage) height:CGImageGetHeight(image.CGImage)];
    
    self.imageViews[0].image = convertedImage;
}


/**
 图片转成data
 
 @param image <#image description#>
 @return <#return value description#>
 */
- (unsigned char *)dataFromImage:(UIImage *)image{
    CGImageRef cgImage = image.CGImage;
    //图片宽高
    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);
    //分配图片内存
    unsigned char *data = malloc(width * height * 4);
    //RGBA每个单位的位数
    size_t bitsPerComponent = 8;
    //每一个行像素的比特数
    size_t bytesPerRow = width * 4;
    //颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    //位图上下文
    CGContextRef context = CGBitmapContextCreate(data, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    //绘制图片到上下文中
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);
    //处理善后工作
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    return data;
}

/**
 data未经处理直接转成uiimage, 图片为原图
 
 @param data <#data description#>
 @param width <#width description#>
 @param height <#height description#>
 @return <#return value description#>
 */
- (UIImage *)imageFromData:(unsigned char *)data width:(size_t)width height:(size_t)height{
    
    size_t bitsPerComponent = 8;
    size_t bytesPerRow = width * 4;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGBitmapInfo bitMapInfo = kCGBitmapByteOrderDefault;
    
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, data, width * height * 4, NULL);
    
    CGColorRenderingIntent renderIntent = kCGRenderingIntentDefault;
    
    CGImageRef imageRef = CGImageCreate(width, height, 8, bitsPerComponent * 4, bytesPerRow, colorSpace, bitMapInfo, dataProvider, NULL, NO, renderIntent);
    
    UIImage *image = [UIImage imageWithCGImage:imageRef];
    
    CGColorSpaceRelease(colorSpace);
    CGDataProviderRelease(dataProvider);
    CGImageRelease(imageRef);
    
    return image;
}

/**
 图像灰度处理
 公式一(推荐算法):
 Gray = R*0.299 + G*0.587 + B*0.114
 公式二(快捷算法):
 GRAY = (R+B+G)/3

 @param data <#data description#>
 @param width <#width description#>
 @param height <#height description#>
 @return <#return value description#>
 */
- (unsigned char *)grayImageWithImageData:(unsigned char *)data width:(size_t)width height:(size_t)height{
    //分配一片新的内存, 用来存放处理后的数据
    unsigned char *resultData = malloc(width * height * 4);
    //初始化内存空间, 全部填充0
    memset(resultData, 0, width * height * 4);
    
    unsigned int pixelIndex = 0;
    for (int i = 0; i < width; i++) {//行
        for (int j = 0; j < height; j++) {//列
            pixelIndex = (int)width * j + i;
            //每个像素由RGBA组成 大小为4B
            unsigned char red = *(data + pixelIndex * 4);
            unsigned char green = *(data + pixelIndex * 4 + 1);
            unsigned char blue = *(data + pixelIndex * 4 + 2);
            unsigned char alpha = *(data + pixelIndex * 4 + 3);
            //计算灰度公式一(推荐):
            int bitMap = red * 0.299 + green * 0.587 + blue * 0.114;
            //计算灰度公司二:
//            int bitMap = (red + green + blue) / 3;
            unsigned char bitMapNew = bitMap > 255 ? 255 : bitMap;
            
            //在相应的内存中写入对应的数据
            memset(resultData + pixelIndex * 4, bitMapNew, 1);
            memset(resultData + pixelIndex * 4 + 1, bitMapNew, 1);
            memset(resultData + pixelIndex * 4 + 2, bitMapNew, 1);
            memchr(resultData + pixelIndex * 4 + 3, alpha, 1);
        }
    }
    return resultData;
}


/**
 彩色反转
 算法:
 newValue = 255 - oldValue

 @param data <#data description#>
 @param width <#width description#>
 @param height <#height description#>
 @return <#return value description#>
 */
- (unsigned char *)colorReverseWithImageData:(unsigned char *)data width:(size_t)width height:(size_t)height{
    unsigned char *resultData = malloc(width * height * 4);
    memset(resultData, 0, width * height * 4);
    unsigned int pixelIndex = 0;
    for (int i = 0; i < width; i++) {//行
        for (int j = 0; j < height; j++) {//列
            pixelIndex = (int)width * j + i;
            //每个像素由RGBA组成 大小为4B, 根据指针地址取出色值, 并反转
            unsigned char red = 255 - *(data + pixelIndex * 4);
            unsigned char green = 255 - *(data + pixelIndex * 4 + 1);
            unsigned char blue = 255 - *(data + pixelIndex * 4 + 2);
            unsigned char alpha = *(data + pixelIndex * 4 + 3);
            
            memset(resultData + pixelIndex * 4, red, 1);
            memset(resultData + pixelIndex * 4 + 1, green, 1);
            memset(resultData + pixelIndex * 4 + 2, blue, 1);
             memchr(resultData + pixelIndex * 4 + 3, alpha, 1);
        }
    }
    return resultData;
}

/**
 简单的美白算法: 亮度提高50
 不分配内存, 直接操作地址中的数据
 @param data <#data description#>
 @param width <#width description#>
 @param height <#height description#>
 @return <#return value description#>
 */
- (UInt32 *)sampleBeautyWithImageData:(unsigned char *)data1 width:(size_t)width height:(size_t)height{
    
    //将unsigned char * 转成 UInt32 *
    UInt32 *data = (UInt32 *)data1;
    UInt32 red, green, blue;
    for (int i = 0; i < width; i++) {//行
        for (int j = 0; j < height; j++) {//列
           UInt32 *pixelIndex = data + width * j + i;
            UInt32 color = *pixelIndex;
            //每个像素由RGBA组成 大小为4B, 根据指针地址取出色值, 每个值增加50
            red = R(color);
            red = red + 50;
            red = red > 255 ? 255 : red;
//
            green = G(color);
            green = green + 50;
            green = green > 255 ? 255 : green;
            
            blue = B(color);
            blue = blue + 50;
            blue = blue > 255 ? 255 : blue;
            
            *pixelIndex = RGBA(red, green, blue, A(color));
        }
    }
    return data;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
