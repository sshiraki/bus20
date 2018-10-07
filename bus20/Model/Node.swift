//
//  Node.swift
//  bus20
//
//  Created by SATOSHI NAKAJIMA on 8/27/18.
//  Copyright © 2018 SATOSHI NAKAJIMA. All rights reserved.
//

import CoreGraphics
import MapKit

// A Node represents a location where shuttles can pick up or drop riders
struct Node {
    enum NodeType {
        case empty
        case start
        case end
        case used
    }
    
    //let location:CGPoint // The location
    let location:CGPoint // The location
    let edges:[Edge]     // Edges started from this node (one direction)
    let type:NodeType    // Node type. Used only when we are searching a shortest route
    
    init(location:CGPoint, edges:[Edge]) {
        self.location = location
        self.edges = edges
        self.type = .empty
    }
    
    init(node:Node, type:NodeType) {
        self.location = node.location
        self.edges = node.edges
        self.type = type
    }
    
    func distance(to:Node) -> CGFloat {
        let dx = to.location.x - self.location.x
        let dy = to.location.y - self.location.y
        return sqrt(dx * dx + dy * dy)
    }
    
    func render(ctx:CGContext, graph:Graph, scale:CGFloat) {
        let rc = CGRect(x: location.x * scale - 2, y: location.y * scale - 2, width: 4, height: 4)
        ctx.fillEllipse(in: rc)
        
        ctx.beginPath()
        for edge in edges {
            edge.addPath(ctx: ctx, graph: graph, scale: scale)
        }
        ctx.closePath()
        ctx.drawPath(using: .stroke)
    }

    func render(view:MKMapView, graph:Graph) {
        //地図にピンを立てる。
        let an = MKPointAnnotation()
        let co = view.convert(location, toCoordinateFrom: view)
        an.coordinate = CLLocationCoordinate2DMake(co.latitude, co.longitude)
        view.addAnnotation(an)
        
        for edge in edges {
            edge.addPath(view: view, graph: graph)
        }
    }
    
    var dictionary:[String:Any] {
        return [
          "location": [
            "x": self.location.x,
            "y": self.location.y,
          ],
          "edges": edges.map { $0.dictionary }
        ];
    }
}

