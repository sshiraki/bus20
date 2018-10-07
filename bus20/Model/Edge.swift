//
//  Edge.swift
//  bus20
//
//  Created by SATOSHI NAKAJIMA on 8/27/18.
//  Copyright © 2018 SATOSHI NAKAJIMA. All rights reserved.
//

import CoreGraphics
import MapKit

// An Edge represents a road (one directional) from one node to another
struct Edge {
    let from:Int
    let to:Int
    let length:CGFloat
    
    init(from:Int, to:Int, length:CGFloat=1.0) {
        self.from = from
        self.to = to
        self.length = length
    }
    
    // For rendering
    func addPath(ctx:CGContext, graph:Graph, scale:CGFloat) {
        let locationFrom = graph.location(at: from)
        let locationTo = graph.location(at: to)

        ctx.move(to: CGPoint(x: locationFrom.x * scale, y: locationFrom.y * scale))
        ctx.addLine(to: CGPoint(x: locationTo.x * scale, y: locationTo.y * scale))
    }

    // For rendering
    func addPath(view:MKMapView, graph:Graph) {
        let locationFrom = graph.location(at: from)
        let locationTo = graph.location(at: to)
        // 地図に線を引く。
        let cofrom = view.convert(locationFrom, toCoordinateFrom: view)
        let coto = view.convert(locationTo, toCoordinateFrom: view)
        var cofromto:[CLLocationCoordinate2D] = [cofrom, coto]
        let pl = MKPolyline(coordinates: &cofromto, count: 2)
        view.addOverlay(pl)
    }
    
    var dictionary:[String:Any] {
        return [
            "from": self.from,
            "to": self.to,
            "length": self.length,
        ];
    }
}

extension Edge: CustomStringConvertible {
    var description: String {
        return String(format: "%d->%d", from, to)
    }
}
