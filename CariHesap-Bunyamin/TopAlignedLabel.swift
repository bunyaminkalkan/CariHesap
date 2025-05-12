//
//  TopAlignedLabel.swift
//  CariHesap-Bunyamin
//
//  Created by Trakya6 on 12.05.2025.
//

import UIKit

class TopAlignedLabel: UILabel {
    
    var lineSpacing: CGFloat = 5.0
    var firstLineIndent: CGFloat = 24.0

    override func drawText(in rect: CGRect) {
        guard let text = self.text else {
            super.drawText(in: rect)
            return
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = firstLineIndent
        paragraphStyle.lineSpacing = lineSpacing

        let attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: self.font as Any,
                .paragraphStyle: paragraphStyle,
                .foregroundColor: self.textColor as Any
            ])

        let drawingRect = CGRect(x: rect.origin.x,
                                 y: rect.origin.y,
                                 width: rect.width,
                                 height: rect.height)

        attributedText.draw(with: drawingRect, options: .usesLineFragmentOrigin, context: nil)
    }

    override var intrinsicContentSize: CGSize {
        guard let text = self.text else { return super.intrinsicContentSize }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = firstLineIndent
        paragraphStyle.lineSpacing = lineSpacing

        let attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: self.font as Any,
                .paragraphStyle: paragraphStyle
            ])

        let size = attributedText.boundingRect(
            with: CGSize(width: bounds.width, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            context: nil
        ).size

        return CGSize(width: ceil(size.width), height: ceil(size.height))
    }
}





