//
//  DIrection.swift
//  bus20
//
//  Created by SUNAO SHIRAKI on 2018/10/08.
//  Copyright © 2018年 SATOSHI NAKAJIMA. All rights reserved.
//

import MapKit

struct Direction {
    func addRoute(view:MKMapView, userLocation:CLLocationCoordinate2D, destLocation:CLLocationCoordinate2D)
    {
        // 始点と終点のMKPlacemarkを生成
        let fromPlacemark = MKPlacemark(coordinate:userLocation, addressDictionary:nil)
        let toPlacemark   = MKPlacemark(coordinate:destLocation, addressDictionary:nil)
        
        // MKPlacemark から MKMapItem を生成
        let fromItem = MKMapItem(placemark:fromPlacemark)
        let toItem   = MKMapItem(placemark:toPlacemark)
        // MKMapItem をセットして MKDirectionsRequest を生成
        let request = MKDirections.Request()
        request.source = fromItem
        request.destination = toItem
        request.requestsAlternateRoutes = false // 単独の経路を検索
        request.transportType = MKDirectionsTransportType.any
        // 経路検索
        let directions = MKDirections(request:request)
        directions.calculate(completionHandler: {
            (response, error) in
            
            if error != nil {
                print("Error :",error.debugDescription)
            } else {
                view.addOverlay((response!.routes[0].polyline))
                print(userLocation,destLocation)
                //showRoute(view, response: response!)
            }
        })
    }

    func showRoute(_ view:MKMapView, response: MKDirections.Response) {
        
        for route in response.routes {
            
            view.addOverlay(route.polyline,
                            level: MKOverlayLevel.aboveRoads)
            for step in route.steps {
                print(step.instructions)
            }
        }
    }
}

