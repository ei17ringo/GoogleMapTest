//
//  ViewController.m
//  GoogleMapTest
//
//  Created by Eriko Ichinohe on 2014/03/18.
//  Copyright (c) 2014年 Eriko Ichinohe. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

// マップで表示する最大のpolyline数
#define MAX_POLYLINE 10
// 1polylineあたりの最大座標数
#define MAX_COORDINATE_PER_POLYLINE 300

@implementation ViewController
{
    GMSMapView* _mapView;   // MapView
    BOOL _doFollow;         // フォローを行うかどうか
    
    NSMutableArray* _polylineList;  // MapViewに追加しているGMSPolylineオブジェクトを保持
    GMSMutablePath* _targetPath;    // 変更対象のpolylineオブジェクトの座標群を保持
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _polylineList = [[NSMutableArray alloc] init];
    _targetPath = [[GMSMutablePath alloc] init];
    
	// Create a GMSCameraPosition that tells the map to display the
    // coordinate -33.86,151.20 at zoom level 6.
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:10.318093                                                            longitude:123.904403                                                                 zoom:18];
    
    mapView_ = [GMSMapView mapWithFrame:CGRectZero camera:camera];
    mapView_.myLocationEnabled = YES;
    self.view = mapView_;

    // Creates a marker in the center of the map.
    GMSMarker *marker = [[GMSMarker alloc] init];
    marker.position = CLLocationCoordinate2DMake(10.318093, 123.904403);
    marker.title = @"Cebu";
    marker.snippet = @"Philipines";
    marker.map = mapView_;
    
//    GMSMarker *marker3 = [[GMSMarker alloc] init];
//    marker3.position = CLLocationCoordinate2DMake(14.599512, 120.984219);
//    marker3.title = @"Sydney";
//    marker3.snippet = @"Australia";
//    marker3.map = mapView_;

    
    // 地図の中心位置更新のため、KVOで位置情報更新の監視を行う
    [_mapView addObserver:self forKeyPath:@"myLocation" options:NSKeyValueObservingOptionNew context:NULL];
    
    // GCDを使って測位開始をviewDidLoad後に実行させる
    dispatch_async(dispatch_get_main_queue(), ^{
        _mapView.myLocationEnabled = YES;
    });
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//- (IBAction)pushedClose:(UIBarButtonItem *)sender {
//    // このViewControllerを閉じる処理を書く
//    [self dismissViewControllerAnimated:YES];
//}

- (void)viewDidUnload {
    _mapView = NULL;
    //[self setPlaceHolderView:nil];
    [super viewDidUnload];
}

// _targetPathからGMSPolylineオブジェクトを生成する
- (GMSPolyline*)createPolyline:(GMSPath*)path
{
    GMSPolyline* polyline = [GMSPolyline polylineWithPath:path];
    // 線の太さと色は適当(^^;
    polyline.strokeWidth = 5;
    polyline.strokeColor = [UIColor colorWithRed:0.625 green:0.21875 blue:0.125 alpha:1.0];
    return polyline;
}

// CLLocationを追加して軌跡群を更新する
- (void)updatePolylines:(CLLocation*)location
{
    // 誤差が50mより大きければ軌跡に加えない
    NSLog(@"%d",location && location.horizontalAccuracy);
    
    if(location && location.horizontalAccuracy > 150) return;
    
    // 一番後ろのpolylineは再作成するためにMapViewとリストから削除する
    if(_polylineList && _polylineList.count > 0){
        GMSPolyline* lastOne = [_polylineList lastObject];
        lastOne.map = nil; // mapプロパティをnilにすればMapViewから消える
        [_polylineList removeLastObject];
    }
    // 座標をpathに追加して、polylineを作成する
    NSMutableArray* workList = [NSMutableArray array]; // 追加するGMSPolylineを一時的に保持
    [_targetPath addLatitude:location.coordinate.latitude longitude:location.coordinate.longitude];
    if (_targetPath.count >= MAX_COORDINATE_PER_POLYLINE) {
        // 一つのpolylineに保持可能な座標数に達したので、次のpolylineに切り替える
        [workList addObject:[self createPolyline:_targetPath]]; // pathからpolylineを作成し、一時リストに追加
        _targetPath = [GMSMutablePath path]; // pathを切り替え
        // 直前のPolylineの最後の座標と次の座標をつなぐため、最後の座標をこちらにもセットしておく
        [_targetPath addLatitude:location.coordinate.latitude longitude:location.coordinate.longitude];
    }
    [workList addObject:[self createPolyline:_targetPath]]; // pathからpolylineを作成し、一時リストに追加
    
    // 新規作成したpolyline群を上限数以内におさめる
    if (workList.count > MAX_POLYLINE) {
        [workList removeObjectsInRange: NSMakeRange(0, workList.count - MAX_POLYLINE)];
    }
    // 新規+既存のpolyline群を上限数以内におさめるために、既存のpolyline群の数を調整する
    if ((_polylineList.count + workList.count) > MAX_POLYLINE) {
        
        int firstvalue = (int)_polylineList.count + (int)workList.count - MAX_POLYLINE;
        
        for (int left = firstvalue; left > 0; --left) {
            // 先頭のpolylineをMapViewから切り離し、リストからも削除する
            GMSPolyline* polyline = _polylineList[0];
            polyline.map = nil;
            [_polylineList removeObjectAtIndex:0];
        }
    }
    // 新規polylineをMapViewに追加し、既存リストに加える
    for (GMSPolyline* polyline in workList){
        polyline.map = _mapView;
    }
    [_polylineList addObjectsFromArray:workList];
}

#pragma mark - KVO updates

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    
    
    CLLocation *location = [change objectForKey:NSKeyValueChangeNewKey];
    
    [self updatePolylines:location]; // 軌跡更新
    
    NSLog(@"observeValueForKeyPath=%d",_doFollow);
    if(_doFollow){
        // フォローモードなのでマップ中心を現在位置にアニメーションで移動させる
        [_mapView animateToLocation:location.coordinate];
    }
}

#pragma mark - GMSMapViewDelegate

- (void)mapView:(GMSMapView *)mapView willMove:(BOOL)gesture
{
    NSLog(@"willMove=%d",_doFollow);
    // ユーザーが画面を操作したときはフォローモードを解除する
    if (gesture) {
        _doFollow = NO;
    }
}

- (void)mapView:(GMSMapView *)mapView idleAtCameraPosition:(GMSCameraPosition *)position
{
    // アニメーションでのcameraの位置変更が終わったときに呼ばれるので、ここでmyLocationとマップ中心の座標を比較し、
    // フォローモードにするかどうかを判定する
    NSLog(@"idleAtCameraPosition=%d",_doFollow);
    if(mapView.myLocation){
        CLLocationDegrees deltaLat = fabs(mapView.myLocation.coordinate.latitude - position.target.latitude);
        CLLocationDegrees deltaLon = fabs(mapView.myLocation.coordinate.longitude - position.target.longitude);
        _doFollow = (deltaLat < 0.000001 && deltaLon < 0.000001);
    }
}
@end
