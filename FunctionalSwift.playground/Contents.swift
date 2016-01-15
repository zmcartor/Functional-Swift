//: Playground - noun: a place where people can play

import UIKit

var str = "Hello, playground"

// Chapt 2, BattleShip game

typealias Distance = Double

// This is cool - Regions are defined by whether or not a point lies within.
// Region type is any function which takes a Position and returns a Bool. Very cool!
typealias Region = (Position) -> Bool

struct Position {
    var x: Double
    var y: Double
}

// Functions that return Regions.

// Default position is at the origin
func circle(radius:Distance, origin:Position = Position(x:0 , y:0)) -> Region {
    return { point in point.minus(origin).length <= radius }
}

// Move Regions around by adding offsets. (like CGOffset)

func shift(region:Region, offset: Position) -> Region {
    // we wrap the original region function in another func
    // which offsets from the point. Neat!
    return { point in region (point.minus(offset)) }
}

// By wrapping functions, a whole bunch of great primitives can be created!
func invert(region:Region) -> Region {
    return { point in !region(point) }
}

func intersection(first:Region , second:Region) -> Region {
    return { point in first(point) && second(point) }
}

func union(first:Region, second:Region) -> Region {
    return { point in first(point) || second(point) }
}

// Function to create region that are in the first, but NOT in the second. NEAATOO
func difference(one:Region , two:Region) -> Region {
    return intersection(one, second: invert(two))
}

struct Ship {
    var position: Position
    var firingRange: Distance
    
    // dont want to target ships that are too close
    var unsafeRange: Distance
}

extension Ship {
    func canEngageShip(target:Ship) -> Bool {
        let dx = target.position.x - position.x
        let dy = target.position.y - position.y
        let targetDistance = sqrt(dx*dx + dy*dy)
        return targetDistance <= firingRange
    }
    // take into account safe firing range
    func canSafelyEngageShip(target:Ship) -> Bool {
        let dx = target.position.x - position.x
        let dy = target.position.y - position.y
        let targetDistance = sqrt(dx*dx + dy*dy)
        return targetDistance <= firingRange && targetDistance > unsafeRange
    }
    
    // Then it gets complicated ... What about firing if a friendly ship is too close to an enemy?
    // This was previously a huge pain in the ass. Mixed bools and calculations. 
    // With our new Region functions, this is much more declarative. 
    
    func canSafelyEngageShip2(target: Ship, friendly: Ship) -> Bool {
        
        // Fire within the firing range, but NOT the unsafeRange :D
        let rangeRegion = difference(circle(firingRange), two: circle(unsafeRange))
        
        // firing region is our current range adjusted for Ship's position
        let firingRegion = shift(rangeRegion, offset:position)
        
        // Also dont want to fire within unsafe range around friendly ship
        let friendlyRegion = shift(circle(unsafeRange), offset:friendly.position)
        
        // takes into account unsafe region, friendly ship unsafe region, adjusted for positions!!
        let resultRegion = difference(firingRegion , two:friendlyRegion)
        
        return resultRegion(target.position)
    }
}

extension Position {
    // determine if is within circle firing range
    func inRange(range:Distance) -> Bool {
        return sqrt(x*x + y*y) <= range
    }
    
    // Things can be made better with more granular extensions
    // These are vector calculations.
    func minus(p:Position) -> Position {
        return Position(x:x-p.x , y:y-p.y)
    }
    
    // could be called 'distance'
    var length: Double {
        return sqrt(x*x + y*y)
    }
}



// Chapter 3 , wrapping Core Image

typealias Filter = (CIImage) -> CIImage


// Functions take in necessary params, and then generate a 'Filter' type to use.

func blur(radius:Double) -> Filter {
    return { image in
        let parameters = [ kCIInputRadiusKey: radius, kCIInputImageKey: image]
        let filter  = CIFilter(name:"CIGaussianBlur", withInputParameters: parameters)!
        return filter.outputImage!
    }
}

// Generates a constant color. Doesn't apply anything to an image
// Notice that the image arg is ignored.
func colorGenerator(color: UIColor) -> Filter {
    return { _ in
    let parameters = [kCIInputColorKey: color]
    let filter = CIFilter(name: "CIConstantColorGenerator",
        withInputParameters: parameters)!
        return filter.outputImage!
    }
}

// overlays another image on top of another
func compositeSourceOver(overlay: CIImage) -> Filter {
    return { image in
        let parameters = [ kCIInputBackgroundImageKey: image, kCIInputImageKey: overlay]
        let filter = CIFilter(name: "CISourceOverCompositing",withInputParameters: parameters)!
        
        // crop to the size of the input image
        let cropRect = image.extent
        return filter.outputImage!.imageByCroppingToRect(cropRect)
    }
}

// Combine these things to create a color-overlay filter

func coloredOverlay(color:UIColor) -> Filter {
    return { image in
        // This applies the overlay filter to image to produce an image
        let overlayImage = colorGenerator(color)(image)
        
        // use overlay as argument to composite fitler. Return resulting image
        return compositeSourceOver(overlayImage)(image)
    }
}

// Blur a photo and put an overlay on top

let url = NSURL(string: "http://tinyurl.com/m74sldb")
let image = CIImage(contentsOfURL: url!)


// Function to compose filters
// g(f(x))
func composeFilters(one:Filter , two:Filter) -> Filter {
    return { image in two(one(image)) }
}

// create a custom operator to compose filters
// inputs are read from left->right like UNIX pipes
infix operator -|- { associativity left }

func -|- (one:Filter, two:Filter) -> Filter {
    return { image in two(one(image)) }
}

// WOW that's pretty cool!
let blueOverlayFilter = coloredOverlay(UIColor.blueColor()) -|- compositeSourceOver(image!)

// Chapter 4



