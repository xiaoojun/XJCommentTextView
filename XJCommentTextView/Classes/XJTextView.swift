//
//  XJTextView.swift
//  XJUITextViewCategory
//
//  Created by 汤小军 on 2019/6/11.
//  Copyright © 2019 tangxiaojun. All rights reserved.
//

import UIKit

public class XJTextView: UITextView {

    /// 占位文本
    var placeHolderText : String = "" {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    /// 占位文本颜色
    var placeHolderTextColor : UIColor = .lightGray{
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    /// 占位文本的内间距
    var placeHolderInsets : UIEdgeInsets = UIEdgeInsets(top: 5, left: 7, bottom: 5, right: 7) {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    /// 高度改变回调
    var heigthChaneCallback : ((CGFloat)->Void)?
    
    
    /// 输入文本的内间距
    override public var textContainerInset: UIEdgeInsets {
        didSet {
            var textC = self.textContainerInset
            textC.left += 3
            placeHolderInsets = textC
        }
    }
    
    
    /// 输入文本
    override public var text: String! {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    
    /// 属性文本
    override public var attributedText: NSAttributedString! {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    /// 字体
    override public var font: UIFont? {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    /// 文本对其方式
    override public var textAlignment: NSTextAlignment {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    //
    var heightConstraint : NSLayoutConstraint?
    var minHeightConstraint : NSLayoutConstraint?
    var maxHeightConstraint : NSLayoutConstraint?
    
    deinit {
         self.removeTextViewNotificationObservers()
    }
    
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
         super.init(frame: frame, textContainer: textContainer)
         self.configureTextView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public var bounds: CGRect {
        didSet {
            if self.contentSize.height <= self.bounds.size.height + 1 {
                self.contentOffset = .zero
            }else if self.isTracking == false {
                var offset = self.contentOffset
                if offset.y > self.contentSize.height - self.bounds.size.height {
                    offset.y = self.contentSize.height - self.bounds.size.height
                    if self.isDecelerating == false && self.isTracking == false && self.isDragging == false {
                        self.contentOffset = offset
                    }
                }
            }
        }
    }
    
    /// 关联约束
    func associateConstraints() {
        for constraint in self.constraints {
            if constraint.firstAttribute == .height {
                if constraint.relation == .equal {
                    self.heightConstraint = constraint
                }
                else if constraint.relation == .lessThanOrEqual {
                    self.maxHeightConstraint = constraint
                } else if constraint.relation == .greaterThanOrEqual {
                    self.minHeightConstraint = constraint
                }
            }
        }
    }
    
    override public func draw(_ rect: CGRect) {
        super.draw(rect)
        
        if self.text.count == 0 && self.placeHolderText.count > 0 {
            self.placeHolderTextColor.set()
            (self.placeHolderText as NSString).draw(in:rect.inset(by: self.placeHolderInsets),
             withAttributes: self.placeholderTextAttributes())
        }
    }

}

public extension XJTextView {
    
    
    /// 设置占位文本的属性值
    ///
    /// - Returns: <#return value description#>
    func placeholderTextAttributes() -> [NSAttributedString.Key : Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingTail
        paragraphStyle.alignment = self.textAlignment
        
        return [NSAttributedString.Key.font : self.font ?? UIFont.systemFont(ofSize: 17),
                NSAttributedString.Key.foregroundColor : self.placeHolderTextColor,
                NSAttributedString.Key.paragraphStyle : paragraphStyle
            ]
    }
    
    func configureTextView() {
        self.scrollsToTop = false
        self.isUserInteractionEnabled = true
        self.contentMode = .redraw
        self.keyboardAppearance = .default
        self.keyboardType = .default
        self.returnKeyType = .default
        self.dataDetectorTypes = UIDataDetectorTypes.phoneNumber //自动检测文本的信息
        
        self.text = ""
        self.placeHolderText = ""
        self.placeHolderTextColor = .lightGray
        
        var textContainerInset = self.textContainerInset
        textContainerInset.left += 3
        placeHolderInsets = textContainerInset
        
        self.addTextViewNotificationObservers()
    }
    
    func addTextViewNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveTextViewNotification), name: UITextView.textDidChangeNotification, object: self)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveTextViewNotification), name: UITextView.textDidBeginEditingNotification, object: self)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveTextViewNotification), name: UITextView.textDidEndEditingNotification, object: self)
       
    }
    
    func removeTextViewNotificationObservers() {
        NotificationCenter.default.removeObserver(self, name: UITextView.textDidEndEditingNotification, object: self)
        NotificationCenter.default.removeObserver(self, name: UITextView.textDidChangeNotification, object: self)
        NotificationCenter.default.removeObserver(self, name: UITextView.textDidBeginEditingNotification, object: self)
    }
    
   @objc func didReceiveTextViewNotification() {
        self.setNeedsDisplay()
        self.autoAdjustContentHeight()
    }
    
    override var canBecomeFirstResponder: Bool {
        return super.canBecomeFirstResponder
    }
    
    override func becomeFirstResponder() -> Bool {
         return super.becomeFirstResponder()
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
         UIMenuController.shared.menuItems = nil
        return super.canPerformAction(action, withSender: sender)
    }
    
    func autoAdjustContentHeight() {
        let sizeThatFits = self.sizeThatFits(self.frame.size)
        var newHeight = sizeThatFits.height
        
        if  let maxConstant = self.maxHeightConstraint {
            newHeight = min(newHeight, maxConstant.constant)
        }
        
        if let minConstant = self.minHeightConstraint {
            newHeight = max(newHeight, minConstant.constant)
        }
        
        if  CGFloat(Int(newHeight) * 1000) != self.heightConstraint!.constant * 1000 {
            self.heightConstraint?.constant = newHeight
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveLinear, animations: {
                self.heigthChaneCallback?(newHeight)
            }, completion: nil)
        }
    }
}
