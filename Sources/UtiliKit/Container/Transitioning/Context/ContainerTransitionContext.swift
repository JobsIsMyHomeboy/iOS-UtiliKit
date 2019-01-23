//
//  ContainerTransitionContext.swift
//  UtiliKit-iOS
//
//  Created by Will McGinty on 1/22/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

class ContainerTransitionContext: NSObject {
    
    // MARK: Properties
    var containerView: UIView
    var percentComplete: CGFloat = 0
    var presentationStyle: UIModalPresentationStyle
    var transitionWasCancelled: Bool = false
    var targetTransform: CGAffineTransform = CGAffineTransform.identity
    var isAnimated: Bool = true
    var isInteractive: Bool = false
    
    private var viewControllers: [UITransitionContextViewControllerKey: UIViewController]
    private var views: [UITransitionContextViewKey: UIView]
    
    var completion: ((_ finished: Bool) -> Void)?
    
    // MARK: Initializers
    init(containerView: UIView, fromViewController: UIViewController, toViewController: UIViewController) {
        self.containerView = containerView
        self.presentationStyle = toViewController.modalPresentationStyle
        self.viewControllers = [.from: fromViewController, .to: toViewController]
        self.views = [.from: fromViewController.view, .to: toViewController.view ]
        super.init()
    }
}

// MARK: UIViewControllerContextTransitioning
extension ContainerTransitionContext: UIViewControllerContextTransitioning {
    
    /// The frame's are set to .null when they are not known or otherwise undefined.  For example the finalFrame of the fromViewController will be .null if and only if the fromView will be removed from the window at the end of the transition. On the other hand, if the finalFrame is not .null then it must be respected at the end of the transition.
    func initialFrame(for vc: UIViewController) -> CGRect {
        guard vc == viewController(forKey: .from) else { return .null }
        return containerView.bounds
    }
    
    func finalFrame(for vc: UIViewController) -> CGRect {
        guard vc == viewController(forKey: .to) else { return .null }
        return containerView.bounds
    }
    
    func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController? {
        return viewControllers[key]
    }
    
    func view(forKey key: UITransitionContextViewKey) -> UIView? {
        return views[key]
    }
    
    func completeTransition(_ didComplete: Bool) {
        completion?(didComplete)
    }
    
    func updateInteractiveTransition(_ complete: CGFloat) {
        percentComplete = complete
    }
    
    func finishInteractiveTransition() {
        transitionWasCancelled = false
    }
    
    func cancelInteractiveTransition() {
        transitionWasCancelled = true
    }
    
    func pauseInteractiveTransition() { /* No op */ }
}
