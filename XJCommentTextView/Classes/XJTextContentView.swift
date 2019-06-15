//
//  XJTextContentView.swift
//  SwiftKitDemo
//
//  Created by 汤小军 on 2019/6/12.
//  Copyright © 2019 汤小军. All rights reserved.
//

import UIKit
import SnapKit

public protocol XJTextContentViewDataSource : class {
    func textFontOFTextContentView() -> UIFont //字体
    func defaultHeightOfTextContentView() -> CGFloat //默认高度
    func maxLineOfTextContentView() -> Int // 最大行数
    func edgeInsetsOfTextView() -> UIEdgeInsets
    func sendBtnOfTextView() -> UIButton //发送按钮
}


public class XJTextContentView: UIView {

    weak var dataSource : XJTextContentViewDataSource!
    let textViw = XJTextView()
   
    var heightConstraint : NSLayoutConstraint?
    var bottomConstraint : NSLayoutConstraint?
    var originBottomConstraintConstant : CGFloat = 0
    
    var originCommentID = ""
    var commentID : String?
    var didClickSendBtn : ((String,String) -> Void)?
    var clearTextWhenhHideKeyboard : Bool = false
    
    deinit {
         NotificationCenter.default.removeObserver(self)
    }
    
    func initializeUI(_ dataSource : XJTextContentViewDataSource) {
        self.dataSource = dataSource
        
        self.backgroundColor = UIColor.lightGray
        self.addSubview(self.textViw)
        self.textViw.backgroundColor = UIColor.lightGray
        
        self.textViw.font = self.dataSource.textFontOFTextContentView() //字体
        let lineNumber = self.dataSource.maxLineOfTextContentView() //最大行数
        let singleLineHeight = self.textViewSingleLineTextHeight() //文本单行的高度
        let defaultHeight = self.dataSource.defaultHeightOfTextContentView() //默认高度
        let edgeInsets = self.dataSource.edgeInsetsOfTextView() //textView的内边距
        let maxHeight = singleLineHeight * CGFloat(lineNumber) //最大高度
        let sendBtn = self.dataSource.sendBtnOfTextView() //发送按钮
        
        
        self.textViw.backgroundColor = UIColor.white
        self.textViw.placeHolderText = "喜欢留言的人更讨人喜欢哦！"
        
        let lineView = UIView()
        lineView.backgroundColor = UIColor.lightGray
        self.addSubview(lineView)
        
        lineView.snp.makeConstraints { (make) in
            make.left.equalTo(0)
            make.top.equalTo(0)
            make.right.equalTo(0)
            make.height.equalTo(1)
        }
 
        self.textViw.heigthChaneCallback = {[weak self] in
            print("最新的高度 : \($0)")
            self?.heightConstraint?.constant = $0 + abs(edgeInsets.top) + abs(edgeInsets.bottom)
            self?.layoutIfNeeded()
        }
      
        self.addSubview(sendBtn)
        sendBtn.snp.makeConstraints { (make) in
            make.right.equalTo(0)
            make.centerY.equalTo(self)
            make.width.equalTo(abs(edgeInsets.right))
            make.height.equalTo(30)
        }
        
        self.textViw.snp.makeConstraints { (make) in
            make.left.equalTo(edgeInsets.left)
            make.right.equalTo(edgeInsets.right)
            make.centerY.equalTo(self)
            make.height.equalTo(defaultHeight)
            make.height.greaterThanOrEqualTo(defaultHeight)
            make.height.lessThanOrEqualTo(maxHeight)
        }
        self.textViw.associateConstraints()
        
        sendBtn.addTarget(self, action: #selector(sendBtnAction), for: .touchUpInside)
        
    }
    
    @objc func sendBtnAction() {
        if let commentString = self.textViw.text,commentString.count > 0,
            let commentID = commentID {
            self.didClickSendBtn?(commentString,commentID)
        }
    }
    
    func addkeyboardNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    func popCommentBar() {
        _ = self.textViw.becomeFirstResponder()
    }
    func dismissCommentBar() {
        self.textViw.resignFirstResponder()
        self.textViw.text = ""
        self.commentID = self.originCommentID
    }
}

public extension XJTextContentView {
    
    /// 单行文本的高度
    ///
    /// - Returns: <#return value description#>
    func textViewSingleLineTextHeight() -> CGFloat {
        return self.textViw.font?.lineHeight ?? 0 * 1000.0 / 1000.0
    }
    
    /// 剪切文本后是否包含
    func associateConstraints() {
        let defaultHeight = self.dataSource.defaultHeightOfTextContentView()
        let edgeInsets = self.dataSource.edgeInsetsOfTextView()
        
        self.snp.makeConstraints { (make) in
            make.height.equalTo(defaultHeight + abs(edgeInsets.top) + abs(edgeInsets.bottom))
        }
        
        if let constraints = self.superview?.constraints {
            for constraint in constraints {
                if let _ = constraint.firstItem as? XJTextContentView,
                    constraint.firstAttribute == .bottom,
                    constraint.relation == .equal{
                    self.bottomConstraint = constraint
                    self.originBottomConstraintConstant = constraint.constant
                }
            }
        }
        
        for constraint in self.constraints {
            if constraint.firstAttribute == .height {
                if constraint.relation == .equal {
                    self.heightConstraint = constraint
                }
            }
        }
    }
}

public extension XJTextContentView {
    /// 键盘弹出监听
    ///
    /// - Parameter noti: Notification
    @objc func keyboardWillChangeFrame(_ noti : Notification) {
        let dic : Dictionary = noti.userInfo!
        let endFrame : CGRect = dic[UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
        let duration = dic[UIResponder.keyboardAnimationDurationUserInfoKey]
        
        UIView.animate(withDuration: duration as! TimeInterval) {
            if endFrame.origin.y == UIScreen.main.bounds.size.height { //键盘收起
                self.bottomConstraint?.constant = self.originBottomConstraintConstant
                if self.clearTextWhenhHideKeyboard == true {
                    self.textViw.text = ""
                }
             }else { //键盘弹出
                self.bottomConstraint?.constant = -endFrame.size.height + self.originBottomConstraintConstant
            }
            
            self.superview?.layoutIfNeeded()
        }
    }
}
