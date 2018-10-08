//
//  Route.swift
//  bus20
//
//  Created by SATOSHI NAKAJIMA on 8/27/18.
//  Copyright © 2018 SATOSHI NAKAJIMA. All rights reserved.
//

import CoreGraphics
import MapKit

// A Route represents a section of trip from one node to another consisting of connected edges.
struct Route {
    let edges:[Edge]
    let length:CGFloat
    let extra:CGFloat // used only when finding a shortest route
    var pickups = Set<Int>() // identifiers of riders to be picked up 
    var from:Int { return edges.first!.from }
    var to:Int { return edges.last!.to }

    init(edges:[Edge], extra:CGFloat = 0) {
        self.edges = edges
        self.length = edges.reduce(0) { $0 + $1.length }
        self.extra = extra
    }

    func render(ctx:CGContext, graph:Graph, scale:CGFloat) {
        let locationFrom = graph.location(at: edges[0].from)
        ctx.move(to: CGPoint(x: locationFrom.x * scale, y: locationFrom.y * scale))
        for edge in edges {
            let locationTo = graph.location(at: edge.to)
            ctx.addLine(to: CGPoint(x: locationTo.x * scale, y: locationTo.y * scale))
        }
        ctx.drawPath(using: .stroke)
    }

    // for MapKit
    func render(view:MKMapView, graph:Graph, scale:CGFloat) {
        let locationFrom = graph.location(at: edges[0].from)
        for edge in edges {
            let locationTo = graph.location(at: edge.to)
            // 経路の始点終点を設定。
            let cofrom = view.convert(locationFrom, toCoordinateFrom: view)
            let coto = view.convert(locationTo, toCoordinateFrom: view)
            Metricsmk.maproadcolor = UIColor(red: (0/255.0), green: (0/255.0), blue: (255/255.0), alpha: 1.0)
           // 地図に経路を表示する。
            let dr = Direction()
            dr.addRoute(view: view, userLocation: cofrom, destLocation: coto)
        }
    }
}

extension Route: CustomStringConvertible {
    var description: String {
        return String(format: "%3d->%3d:%@", from, to,
                      pickups.map{String($0)}.joined(separator: ","))
    }
}
