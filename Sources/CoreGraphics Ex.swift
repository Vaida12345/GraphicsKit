//
//  CoreGraphics Extensions.swift
//
//
//  Created by Vaida on 5/23/22.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//

import CoreGraphics
import SwiftUI


public extension CGPoint {
    
    /// Calculate the distance between two points.
    ///
    /// - Parameters:
    ///   - other: the other point.
    @inlinable
    func distance(to other: CGPoint) -> CGFloat {
        (pow((self.x - other.x), 2) + pow((self.y - other.y), 2)).squareRoot()
    }
    
    /// The vector additional of two points.
    ///
    /// > Example:
    /// > ```swift
    /// > let lhs = CGPoint(x: 1, y: 2)
    /// > let rhs = CGPoint(x: 2, y: 1)
    /// >
    /// > lhs + rhs // (3, 3)
    /// > ```
    ///
    /// - Parameters:
    ///   - lhs: The first value to add.
    ///   - rhs: The second value to add.
    @inlinable
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    @inlinable
    static func += (lhs: inout CGPoint, rhs: CGPoint) {
        lhs = lhs + rhs
    }
    
    /// The vector subtraction of two points.
    ///
    /// > Example:
    /// > ```swift
    /// > let lhs = CGPoint(x: 1, y: 2)
    /// > let rhs = CGPoint(x: 2, y: 1)
    /// >
    /// > lhs - rhs // (-1, 1)
    /// > ```
    ///
    /// - Parameters:
    ///   - lhs: A vector value.
    ///   - rhs: The value to subtract from `lhs`.
    @inlinable
    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    @inlinable
    static func -= (lhs: inout CGPoint, rhs: CGPoint) {
        lhs = lhs - rhs
    }
    
    @inlinable
    static prefix func - (x: CGPoint) -> CGPoint {
        CGPoint(x: -x.x, y: -x.y)
    }
    
}


public extension CGRect {
    
    /// A point that specifies the coordinates of the rectangle’s center.
    ///
    /// The `origin` is at its lower-left corner.
    @inlinable
    var center: CGPoint {
        get { CGPoint(x: self.origin.x + self.size.width / 2, y: self.origin.y + self.size.height / 2) }
        set { self = CGRect(center: newValue, size: self.size) }
    }
    
    /// Creates an instance with the center point and the size of `CGRect`.
    ///
    /// - Parameters:
    ///   - center: The center point.
    ///   - size: The size of the `CGRect`.
    @inlinable
    init(center: CGPoint, size: CGSize) {
        self.init(x: center.x - size.width / 2, y: center.y - size.height / 2, width: size.width, height: size.height)
    }
    
}


public extension CGSize {
    
    /// A point that specifies the coordinates of the center.
    @inlinable
    var center: CGPoint {
        CGPoint(x: self.width / 2, y: self.height / 2)
    }
    
    /// A bool determining whether the rectangle is a square.
    @inlinable
    var isSquare: Bool {
        self.width == self.height
    }
    
    /// Returns the length of the longer side
    @inlinable
    var longerSide: CGFloat {
        max(self.width, self.height)
    }
    
    /// Returns the length of the shorter side
    @inlinable
    var shorterSide: CGFloat {
        min(self.width, self.height)
    }
    
    /// Returns the size which `self` fits or fills in `target`.
    ///
    /// In `fit` mode, the result size can be smaller than `target`. In `fill` mode, the result size can be larger than `target`.
    ///
    /// - Parameters:
    ///   - target: The size of the container.
    ///   - contentMode: The mode defines how the content fills the available space.
    ///
    /// - Returns: The size which fits or fills in the container.
    @inlinable
    func aspectRatio(_ contentMode: ContentMode, in target: CGSize) -> CGSize {
        let width: CGFloat
        let height: CGFloat
        
        switch contentMode {
        case .fit:
            // if the `size` is wider than `pixel size`
            if target.width / target.height >= self.width / self.height {
                height = target.height
                width = self.width * target.height / self.height
            } else {
                width = target.width
                height = self.height * target.width / self.width
            }
        case .fill:
            // if the `size` is wider than `pixel size`
            if target.width / target.height >= self.width / self.height {
                width = target.width
                height = self.height * target.width / self.width
            } else {
                height = target.height
                width = self.width * target.height / self.height
            }
        }
        
        return CGSize(width: width, height: height)
    }
    
    /// Extend either `width` or `width` to the target length.
    ///
    /// - parameters:
    ///   - side: The side to extend.
    ///   - target: The length to be set.
    @inlinable
    func aspectRatio(extend side: Side, to target: CGFloat) -> CGSize {
        switch side {
        case .height:
            return CGSize(width: target * self.width / self.height, height: target)
        case .width:
            return CGSize(width: target, height: target * self.height / self.width)
        }
    }
    
    /// Returns the scaled size.
    ///
    /// - Parameters:
    ///   - factor: The factor by which to scale the current size.
    @inlinable
    func scaled(by factor: CGFloat) -> CGSize {
        CGSize(width: width * factor, height: height * factor)
    }
    
    /// Returns a square whose borders are `width`.
    ///
    /// - Parameters:
    ///   - width: The width for the square.
    @inlinable
    static func square(_ width: CGFloat) -> CGSize {
        CGSize(width: width, height: width)
    }
    
    /// The side of the size, either `width` or `height`.
    enum Side {
        
        /// The horizontal side
        case width
        
        /// The vertical side
        case height
    }
    
    @inlinable
    static func + (lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }
    
    @inlinable
    static func += (lhs: inout CGSize, rhs: CGSize) {
        lhs = lhs + rhs
    }
    
    @inlinable
    static func - (lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }
    
    @inlinable
    static func -= (lhs: inout CGSize, rhs: CGSize) {
        lhs = lhs - rhs
    }
    
    @inlinable
    static prefix func - (x: CGSize) -> CGSize {
        CGSize(width: -x.width, height: -x.height)
    }
    
}


extension CGRect {
    
    /// Returns a point at the given position.
    public func point(at position: Position) -> CGPoint {
        switch position {
        case .topLeading:
            self.origin
        case .top:
            self.origin + CGPoint(x: self.width / 2, y: 0)
        case .topTrailing:
            self.origin + CGPoint(x: self.width, y: 0)
        case .leading:
            self.origin + CGPoint(x: 0, y: self.height / 2)
        case .center:
            self.origin + CGPoint(x: self.width / 2, y: self.height / 2)
        case .trailing:
            self.origin + CGPoint(x: self.width, y: self.height / 2)
        case .bottomLeading:
            self.origin + CGPoint(x: 0, y: self.height)
        case .bottom:
            self.origin + CGPoint(x: self.width / 2, y: self.height)
        case .bottomTrailing:
            self.origin + CGPoint(x: self.width, y: self.height)
        }
    }
    
    public enum Position {
        case topLeading
        case top
        case topTrailing
        case leading
        case center
        case trailing
        case bottomLeading
        case bottom
        case bottomTrailing
    }
    
}


extension CGAffineTransform {
    
    /// Initialize a translation from a `CGPoint`.
    public init(translation: CGPoint) {
        self.init(translationX: translation.x, y: translation.y)
    }
    
    /// Initialize a translation from a `CGPoint`.
    public init(scale: CGPoint) {
        self.init(scaleX: scale.x, y: scale.y)
    }
    
}
