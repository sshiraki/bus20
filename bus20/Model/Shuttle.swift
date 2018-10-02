//
//  Shuttle.swift
//  bus20
//
//  Created by SATOSHI NAKAJIMA on 8/27/18.
//  Copyright © 2018 SATOSHI NAKAJIMA. All rights reserved.
//

import UIKit

// A Shuttle represents a shuttle bus who can carry multiple riders.
class Shuttle {
    static var verbose = false
    private let hue:CGFloat
    private var capacity = Metrics.shuttleCapacity
    private var routes:[Route]
    private var baseTime = CGFloat(0)
    private var riders = [Rider]()
    private var location = CGPoint.zero
    private var edge:Edge {
        return self.routes[0].edges[0]
    }
    var isBusy:Bool { return !riders.isEmpty }
    var depth:Int { return routes.count }
    var ocupancy:CGFloat { return CGFloat(riders.filter({ $0.state == .riding }).count) / CGFloat(capacity) }
    
    init(hue:CGFloat, graph:Graph) {
        self.hue = hue
        self.routes = [graph.randamRoute()]
    }
    
    // for debugging
    deinit {
        //print("Shuttle:deinit")
    }
    
    func reset() {
        capacity = Metrics.shuttleCapacity
        baseTime = CGFloat(0)
        riders = [Rider]()
    }
    
    // Update the status of a shuttle based on the time.
    func update(graph:Graph, time:CGFloat) {
        while (time - baseTime) > self.edge.length {
            let delta = (time - baseTime) - self.edge.length
            baseTime += self.edge.length

            // Check if we are at the end of a route section, which incidates
            // that we are likely to pick up or drop some riders
            if routes[0].edges.count == 1 {
                let node = routes[0].to
                // Drop riders whose destination is the current node
                riders.filter({$0.state == .riding && $0.to == node}).forEach {
                    $0.dropTime = time - delta
                    $0.state = .done
                }
                riders = riders.filter({$0.state != .done})
                
                self.routes.removeFirst()
                if !self.routes.isEmpty {
                    // Pick riders who are waiting at the current node
                    riders.filter({routes[0].pickups.contains($0.id)}).forEach {
                        assert($0.state == .waiting)
                        assert($0.from == node)
                        $0.pickupTime = time - delta
                        $0.state = .riding
                    }
                    routes[0].pickups.removeAll()
                    
                    assert(riders.filter({$0.state == .riding}).count <= capacity)
                } else {
                    // All done. Start a random walk.
                    assert(riders.isEmpty)
                    self.routes = [graph.randamRoute(from: node)]
                }
            } else {
                // Just move to the next edge
                var edges = routes[0].edges
                edges.removeFirst()
                self.routes[0] = Route(edges: edges)
            }
        }

        // Update the locations of this shuttle and riders
        let locationFrom = graph.location(at: self.edge.from)
        let locationTo = graph.location(at: self.edge.to)
        let ratio = (time - baseTime) / self.edge.length
        location.x = locationFrom.x + (locationTo.x - locationFrom.x) * ratio
        location.y = locationFrom.y + (locationTo.y - locationFrom.y) * ratio
        var offset = 0
        riders.filter({$0.state == .riding}).forEach {
            $0.location = location
            $0.offset = offset
            offset += 1
        }
    }
    
    // Renders the shuttle itself, and the scheduled route (only when it has riders)
    func render(ctx:CGContext, graph:Graph, scale:CGFloat, time:CGFloat) {
        // Render the shuttle
        let rc = CGRect(x: location.x * scale - Metrics.shuttleRadius, y: location.y * scale - Metrics.shuttleRadius, width: Metrics.shuttleRadius * 2, height: Metrics.shuttleRadius * 2)
        UIColor(hue: hue, saturation: 1.0, brightness: 1.0, alpha: Metrics.shuttleAlpha).setFill()
        ctx.fillEllipse(in: rc)

        // Render the scheduled routes
        if riders.count > 0 {
            ctx.setLineWidth(Metrics.routeWidth)
            ctx.setLineCap(.round)
            ctx.setLineJoin(.round)
            for route in routes {
                UIColor(hue: hue, saturation: 1.0, brightness: 1.0, alpha: Metrics.routeAlpha).setStroke()
                route.render(ctx:ctx, graph:graph, scale:scale)
            }
        }
    }
    
    // Returns the list of possible route plans to carry one additional rider,
    // along with their relative costs.
    // Notice that this code takes a full advantage of Swift, which allows
    // value oriented programming.
    func plans(rider:Rider, graph:Graph, time:CGFloat) -> [RoutePlan] {
        let routesBase:[Route] =  { () -> [Route] in
            var routes = self.routes
            // Make it sure that the first route is a single-edge route,
            // so that we can change the route if necessary.
            if let route = routes.first, route.edges.count > 1 {
                let edge = route.edges[0]
                routes[0] = graph.route(from: edge.from, to: edge.to)
                if riders.count > 0 {
                    routes.insert(graph.route(from: edge.to, to: route.to), at: 1)
                } else {
                    // This case happens if there is an extra route
                    routes = [routes[0]]
                }
            }
            return routes
        }()

        let costBasis = evaluate(routes: routesBase, time:time, rider: nil)
        
        // All possible insertion cases
        var plansArray = Array(repeating: [RoutePlan](), count:routesBase.count - 1)
        //for index0 in 1..<routesBase.count {
        DispatchQueue.concurrentPerform(iterations: routesBase.count-1) { (index00) in
            let index0 = index00+1
            var routes0 = routesBase // notice that we make another copy (for each)
            let route = routes0[index0]
            
            // Process insertion
            if route.from == rider.from {
                routes0[index0] = graph.route(from: route.from, to: route.to, rider:rider, pickups:route.pickups)
            } else if route.to == rider.from {
                if index0+1 < routes0.count {
                    let routeNext = routes0[index0+1]
                    routes0[index0+1] = graph.route(from: routeNext.from, to: routeNext.to, rider:rider, pickups:routeNext.pickups)
                } else {
                    routes0.append(graph.route(from: rider.from, to: rider.to, rider:rider))
                }
            } else {
                routes0[index0] = graph.route(from: route.from, to: rider.from, rider:nil, pickups:route.pickups)
                routes0.insert(graph.route(from: rider.from, to: route.to, rider:rider), at: index0+1)
            }
            // Debug Only: Validation
            for index in 0..<routes0.count-1 {
                assert(routes0[index].to == routes0[index+1].from)
            }

            plansArray[index0-1] = (index0+1..<routes0.count).map { (index1) -> RoutePlan in
                var routes1 = routes0 // notice that we make yet another copy
                let route = routes1[index1]
                if route.from != rider.to && route.to != rider.to {
                    routes1[index1] = graph.route(from: route.from, to: rider.to, rider:nil, pickups:route.pickups)
                    routes1.insert(graph.route(from: rider.to, to: route.to), at: index1+1)
                } // else { print("optimized") }
                let cost = evaluate(routes: routes1, time:time, rider: rider)
                return RoutePlan(shuttle:self, cost:cost - costBasis, routes:routes1)
            }
        }
        var plans = plansArray.flatMap { $0 }
        
        // Append case
        var routes0 = routesBase
        if (riders.count == 0) {
            routes0 = [routes0[0]]
        }
        if let last = routes0.last?.to, last != rider.from {
            routes0.append(graph.route(from: last, to: rider.from))
        }
        routes0.append(graph.route(from:rider.from, to:rider.to, rider:rider))
        let cost = evaluate(routes: routes0, time:time, rider: rider)
        plans.append(RoutePlan(shuttle:self, cost:cost - costBasis, routes:routes0))
        
        return plans
    }

    // Calcurate the cost of the specified route, optinally with one additional rider.
    private func evaluate(routes:[Route], time:CGFloat, rider:Rider?) -> CGFloat {
        let ridersPlus = riders + [rider].compactMap { $0 }
        let evaluator = Evaluator(routes: routes, capacity:capacity, riders: ridersPlus, time:time);
        return evaluator.cost()
    }
    
    private func evaluator(time:CGFloat) -> Evaluator {
        return Evaluator(routes: routes, capacity:capacity, riders: riders, time:time);
    }
    
    func debugDump(time:CGFloat) {
        let evaluator = self.evaluator(time:time)
        print(evaluator)
        print(self)
    }
    
    // Adapt the specified route along with an additional rider
    func adapt(routes:[Route], rider:Rider) {
        if Shuttle.verbose {
            var indeces = routes.map { (route) -> Int in
                route.from
            }
            indeces.append(routes.last!.to)
            print("SH", rider.id, ":", [rider.from, rider.to], "→", indeces)
            routes.forEach { (route) in
                print(" ", route)
            }
        }

        self.routes = routes
        rider.hue = self.hue
        self.riders.append(rider)
    }
    
    static func bestPlan(shuttles:[Shuttle], graph:Graph, rider:Rider, time:CGFloat) -> RoutePlan {
        let plans = shuttles
            .flatMap({ $0.plans(rider:rider, graph:graph, time:time) })
            .sorted { $0.cost < $1.cost }
        return plans[0]
    }
}

extension Shuttle: CustomStringConvertible {
    var description: String {
        let array:[[String]] = [
            ["[Edge]" + edge.description],
            ["[Routes]"],
            routes.map {" " + $0.description},
            ["[Riders]"],
            riders.map {" " + $0.description}
        ]
        return array.flatMap({$0}).joined(separator:"\n")
    }
}


