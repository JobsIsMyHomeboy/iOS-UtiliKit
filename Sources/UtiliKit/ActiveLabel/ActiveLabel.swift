//
//  ActiveLabel.swift
//  UtiliKit
//
//  Copyright © 2019 Bottle Rocket Studios. All rights reserved.
//

import UIKit
import GLKit

struct ActiveLabelConfiguration {
    var estimatedNumberOfLines: UInt
    var finalLineTrailingInset: CGFloat
    var finalLineLength: CGFloat
    var loadingViewColor: UIColor
    var loadingLineHeight: CGFloat
    var loadingLineVerticalSpacing: CGFloat
    var loadingAnimationDuration: Double
    var loadingAnimationDelay: Double
    
    /// Default configuration to be used with the ActiveLabel convenience initializer.
    ///
    /// Default values are:
    /// - estimatedNumberOfLines = 1
    /// - finalLineTrailingInset = 0
    /// - finalLineLength = 0
    /// - loadingViewColor = (233,231,237)
    /// - loadingLineHeight = 8
    /// - loadingLineVerticalSpacing = 14
    /// - loadingAnimationDuration = 2.4
    /// - loadingAnimationDelay = 0.4
    static var `default`: ActiveLabelConfiguration {
        return ActiveLabelConfiguration(estimatedNumberOfLines: 1,
                                        finalLineTrailingInset: 0,
                                        finalLineLength: 0,
                                        loadingViewColor: UIColor(red: 233.0/255.0, green: 231.0/255.0, blue: 237.0/255.0, alpha: 1.0),
                                        loadingLineHeight: 8,
                                        loadingLineVerticalSpacing: 14,
                                        loadingAnimationDuration: 2.4,
                                        loadingAnimationDelay: 0.4)
    }
}

/// Used to show loading progress in a UILabel through an animated gradient.
///
/// Setting text to nil will cause the loading indicator to show, non nil will remove the loading indicators.
/// Use lastLineTrailingInset and lastLineLength to control how the last line is displayed. If only 1 line then
/// it is considered the last line. lastLineTrailingInset takes precendence over lastLineLength.
@IBDesignable
class ActiveLabel: UILabel {
    /// The number of activity lines to display. Default is 1.
    @IBInspectable public var estimatedNumberOfLines: UInt = 1
    /// Trailing Inset for the last activity line. Default is 0.
    @IBInspectable public var finalLineTrailingInset: CGFloat = 0
    /// Line Length in points for the last activity line. If finalLineTralingInset is set to greater than 0 this value is not used. Default is 0.
    @IBInspectable public var finalLineLength: CGFloat = 0
    /// This color is the darkest area of the line seen during activity animation. Default is (233,231,237) Gray.
    @IBInspectable public var loadingViewColor: UIColor = UIColor(red: 233.0/255.0, green: 231.0/255.0, blue: 237.0/255.0, alpha: 1.0)
    /// The height of each activity line. Default is 8.
    @IBInspectable public var loadingLineHeight: CGFloat = 8
    /// Vertical spacing between each activity line when 2 or more lines are displayed. Default is 14.
    @IBInspectable public var loadingLineVerticalSpacing: CGFloat = 14
    /// The duration of the gradient animation applied to the activity lines. Default is 2.4.
    @IBInspectable public var loadingAnimationDuration: Double = 2.4
    /// The delay that is applied before each animation begins. Default is 0.4.
    @IBInspectable public var loadingAnimationDelay: Double = 0.4
    /// Shows the loading views in the Storyboard by default since text of a label can't be nil in a Storybaord. Default is true.
    @IBInspectable private var showLoadingViewsInStoryboard: Bool = true
    
    private static let locationKeyPath = "locations"
    
    private var isDisplayingInStoryboard: Bool = false
    private(set) var isLoading: Bool = false {
        didSet {
            guard oldValue != isLoading else { return }
            
            if isLoading {
                text = nil
                if !isHidden {
                    showLoadingViews()
                }
            } else {
                loadingViews.forEach({ $0.removeFromSuperview() })
                loadingViews.removeAll()
            }
        }
    }
    private var loadingViews: [UIView] = []
    private var maskOffset: CGFloat {
        // The offset is enough to make sure that the gradient doesn't originally show on screen.
        return bounds.width * 0.4
    }
    
    /**
     When text is set to nil the loading views will display. When text is non-nill the loading views will be hidden.
     */
    override var text: String? {
        didSet {
            textDidUpdate()
        }
    }
    
    override var isHidden: Bool {
        didSet {
            if isHidden {
                hideLoadingViews()
            } else if !isHidden && isLoading {
                showLoadingViews()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        defer {
            textDidUpdate()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        defer {
            textDidUpdate()
        }
    }
    
    convenience init(frame: CGRect, configuration: ActiveLabelConfiguration) {
        self.init(frame: frame)
        
        self.estimatedNumberOfLines = configuration.estimatedNumberOfLines
        self.finalLineTrailingInset = configuration.finalLineTrailingInset
        self.finalLineLength = configuration.finalLineTrailingInset
        self.loadingViewColor = configuration.loadingViewColor
        self.loadingLineHeight = configuration.loadingLineHeight
        self.loadingLineVerticalSpacing = configuration.loadingLineVerticalSpacing
        self.loadingAnimationDuration = configuration.loadingAnimationDuration
        self.loadingAnimationDelay = configuration.loadingAnimationDelay
        
        configurationChanged()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        loadingViews.forEach { [weak self] (view) in
            guard let self = self else { return }
            if let maskLayer = view.layer.mask {
                maskLayer.bounds = CGRect(x: 0, y: 0, width: self.bounds.width + (maskOffset * 2), height: self.bounds.height)
                maskLayer.frame = CGRect(x: -maskOffset, y: 0, width: self.bounds.width + (maskOffset * 2), height: self.bounds.height)
            }
        }
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        isDisplayingInStoryboard = true
        isLoading = showLoadingViewsInStoryboard
    }
    
    /**
     You must call this function to reset the loading views after you have changed a configuration value.
     */
    func configurationChanged() {
        loadingViews.forEach({ $0.removeFromSuperview() })
        loadingViews.removeAll()
        
        if isLoading {
            showLoadingViews()
        }
    }
}

private extension ActiveLabel {
    func textDidUpdate() {
        isLoading = text == nil
    }
    
    // MARK: - Loading View Functions
    func showLoadingViews() {
        if loadingViews.isEmpty {
            configureLoadingViews()
        }
        loadingViews.forEach({ $0.isHidden = false })
    }
    
    func hideLoadingViews() {
        loadingViews.forEach({ $0.isHidden = true })
    }
    
    func configureLoadingViews() {
        for i in 0..<Int(estimatedNumberOfLines) {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.backgroundColor = loadingViewColor
            
            let maskLayer = createLayerMask()
            maskLayer.add(maskAnimation(), forKey: "maskAnimation")
            view.layer.mask = maskLayer
            loadingViews.append(view)
            
            addSubview(view)
            NSLayoutConstraint.activate([view.leadingAnchor.constraint(equalTo: leadingAnchor),
                                         view.heightAnchor.constraint(greaterThanOrEqualToConstant: loadingLineHeight)])
            
            if i == 0 {
                view.topAnchor.constraint(equalTo: topAnchor).isActive = true
            } else {
                let aboveView = loadingViews[i - 1]
                view.topAnchor.constraint(equalTo: aboveView.bottomAnchor, constant: loadingLineVerticalSpacing).isActive = true
            }
            
            if i + 1 == estimatedNumberOfLines {
                view.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
                if finalLineTrailingInset != 0 {
                    view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -finalLineTrailingInset).isActive = true
                } else if finalLineLength != 0 {
                    view.widthAnchor.constraint(equalToConstant: finalLineLength).isActive = true
                } else {
                    view.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
                }
            } else {
                view.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            }
        }
        
        loadingViews.forEach({ $0.isHidden = isHidden })
    }
    
    // MARK: - CA Helpers
    func createLayerMask() -> CALayer {
        let maskLayer = CAGradientLayer()
        maskLayer.anchorPoint = .zero
        maskLayer.startPoint = CGPoint(x: 0, y: 1)
        maskLayer.endPoint = CGPoint(x: 1, y: 1)
        
        let lightColor = UIColor(white: 1, alpha: 0.5)
        let darkColor = UIColor(white: 1, alpha: 1)
        
        maskLayer.colors = [lightColor.cgColor, darkColor.cgColor, lightColor.cgColor]
        if showLoadingViewsInStoryboard && isDisplayingInStoryboard {
            maskLayer.locations = [NSNumber(value: 0.4), NSNumber(value: 0.5), NSNumber(value: 0.6)]
        } else {
            maskLayer.locations = [NSNumber(value: 0.0), NSNumber(value: 0.1), NSNumber(value: 0.2)]
        }
        maskLayer.bounds = CGRect(x: 0, y: 0, width: frame.width + (maskOffset * 2), height: frame.height)
        maskLayer.frame = CGRect(x: -maskOffset, y: 0, width: frame.width + (maskOffset * 2), height: frame.height)
        
        return maskLayer
    }
    
    func maskAnimation() -> CAAnimationGroup {
        let animationValues = [[NSNumber(value: 0.0), NSNumber(value: 0.1), NSNumber(value: 0.2)],
                               [NSNumber(value: 0.1), NSNumber(value: 0.3), NSNumber(value: 0.5)],
                               [NSNumber(value: 0.6), NSNumber(value: 0.8), NSNumber(value: 1.0)],
                               [NSNumber(value: 0.8), NSNumber(value: 0.9), NSNumber(value: 1.0)]]
        let animationPartDuration = loadingAnimationDuration / Double((animationValues.count - 1))
        
        var beginTime = loadingAnimationDelay
        var animations: [CABasicAnimation] = []
        
        for index in 0..<(animationValues.count - 1) {
            let animation = CABasicAnimation(keyPath: ActiveLabel.locationKeyPath)
            animation.fromValue = animationValues[index]
            animation.toValue = animationValues[index + 1]
            animation.beginTime = beginTime
            animation.duration = animationPartDuration
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
            animations.append(animation)
            
            beginTime = animation.beginTime + animation.duration
        }
        
        let group = CAAnimationGroup()
        group.isRemovedOnCompletion = false
        group.animations = animations
        group.duration = loadingAnimationDelay + loadingAnimationDuration
        group.repeatCount = Float.infinity
        group.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        
        return group
    }
}
