//
//  ViewController.h
//  GoogleMapTest
//
//  Created by Eriko Ichinohe on 2014/03/18.
//  Copyright (c) 2014年 Eriko Ichinohe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleMaps/GoogleMaps.h>

@interface ViewController : UIViewController<GMSMapViewDelegate> {
    GMSMapView *mapView_;
}

//- (IBAction)pushedClose:(UIBarButtonItem *)sender;

//@property (weak, nonatomic) IBOutlet UIView *placeHolderView;


@end
