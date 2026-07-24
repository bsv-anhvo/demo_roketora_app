//
//  CameraQualities.m
//  camerawesome
//
//  Created by Dimitri Dessus on 24/07/2020.
//

#import "CameraQualities.h"

// TODO: rework how qualities are working to be more easy
@implementation CameraQualities

+ (AVCaptureSessionPreset)selectVideoCapturePreset:(CGSize)size session:(AVCaptureSession *)session device:(AVCaptureDevice *)device {
  if (!CGSizeEqualToSize(CGSizeZero, size)) {
    AVCaptureSessionPreset bestPreset = [CameraQualities selectPresetForSize:size session:session];
    if ([session canSetSessionPreset:bestPreset]) {
      return bestPreset;
    }
  }
  
  return [self computeBestPresetWithSession:session device:device];
}

+ (NSString *)selectVideoCapturePreset:(AVCaptureSession *)session device:(AVCaptureDevice *)device {
  return [self computeBestPresetWithSession:session device:device];
}

+ (CGSize)getSizeForPreset:(NSString *)preset {
  if (preset == AVCaptureSessionPreset3840x2160) {
    return CGSizeMake(3840, 2160);
  } else if (preset == AVCaptureSessionPreset1920x1080) {
    return CGSizeMake(1920, 1080);
  } else if (preset == AVCaptureSessionPreset1280x720) {
    return CGSizeMake(1280, 720);
  } else if (preset == AVCaptureSessionPreset640x480) {
    return CGSizeMake(640, 480);
  } else if (preset == AVCaptureSessionPreset352x288) {
    return CGSizeMake(352, 288);
  } else {
    // Default to HD
    return CGSizeMake(1280, 720);
  }
}

// custom code
+ (CGSize)sizeFromQuality:(VideoRecordingQuality)quality {
  switch (quality) {
    case VideoRecordingQualityUhd:
    case VideoRecordingQualityHighest:
      return CGSizeMake(3840, 2160);
    case VideoRecordingQualityFhd:
      return CGSizeMake(1920, 1080);
    case VideoRecordingQualityHd:
      return CGSizeMake(1280, 720);
    case VideoRecordingQualitySd:
    case VideoRecordingQualityLowest:
      return CGSizeMake(640, 480);
  }
}

+ (AVCaptureSessionPreset)computeBestPresetWithSession:(AVCaptureSession *)session device:(AVCaptureDevice *)device {
  // custom code - prefer highest supported preset instead of first small device format
  NSArray *presets = @[
    AVCaptureSessionPreset3840x2160,
    AVCaptureSessionPreset1920x1080,
    AVCaptureSessionPreset1280x720,
    AVCaptureSessionPreset640x480,
  ];
  for (AVCaptureSessionPreset preset in presets) {
    if ([session canSetSessionPreset:preset]) {
      return preset;
    }
  }

  // Default to HD
  return AVCaptureSessionPreset1280x720;
}

+ (NSString *)selectPresetForSize:(CGSize)size session:(AVCaptureSession *)session {
  // custom code - match both landscape and portrait sizes
  CGFloat longer = MAX(size.width, size.height);
  CGFloat shorter = MIN(size.width, size.height);

  if (longer >= 3840 || shorter >= 2160) {
    if (@available(iOS 9.0, *)) {
      if ([session canSetSessionPreset:AVCaptureSessionPreset3840x2160]) {
        return AVCaptureSessionPreset3840x2160;
      }
      return AVCaptureSessionPreset1920x1080;
    } else {
      return AVCaptureSessionPreset1920x1080;
    }
  } else if (longer >= 1920 || shorter >= 1080) {
    return AVCaptureSessionPreset1920x1080;
  } else if (longer >= 1280 || shorter >= 720) {
    return AVCaptureSessionPreset1280x720;
  } else if (longer >= 640 || shorter >= 480) {
    return AVCaptureSessionPreset640x480;
  } else if (longer >= 352 || shorter >= 288) {
    return AVCaptureSessionPreset352x288;
  } else {
    // Default to HD
    return AVCaptureSessionPreset1280x720;
  }
}

+ (NSArray *)captureFormatsForDevice:(AVCaptureDevice *)device  {
  NSMutableArray *qualities = [[NSMutableArray alloc] init];
  NSArray<AVCaptureDeviceFormat *>* formats = [device formats];
  for(int i = 0; i < formats.count; i++) {
    AVCaptureDeviceFormat *format = formats[i];
    [qualities addObject:
       [PreviewSize makeWithWidth:[NSNumber numberWithDouble:CMVideoFormatDescriptionGetDimensions(format.formatDescription).width] height:[NSNumber numberWithDouble:CMVideoFormatDescriptionGetDimensions(format.formatDescription).height]]
    ];
  }
  return qualities;
}

@end
