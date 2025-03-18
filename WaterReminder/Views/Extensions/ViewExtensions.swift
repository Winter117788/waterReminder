import SwiftUI
import UIKit

extension View {
    func dismissKeyboardOnTap() -> some View {
        self.modifier(DismissKeyboardModifier())
    }
    
    func moveTextFieldCursorToEnd() -> some View {
        self.modifier(MoveTextFieldCursorModifier())
    }
}

struct DismissKeyboardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                             to: nil,
                                             from: nil,
                                             for: nil)
            }
    }
}

struct MoveTextFieldCursorModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                DispatchQueue.main.async {
                    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                          let window = scene.windows.first,
                          let textField = window.firstResponder() as? UITextField else {
                        return
                    }
                    
                    if let newPosition = textField.position(from: textField.endOfDocument, offset: 0) {
                        textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
                    }
                }
            }
    }
}

extension UIWindow {
    func firstResponder() -> UIResponder? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { 
            return nil 
        }
        
        var responder: UIResponder? = nil
        window.subviews.forEach { view in
            if let firstResponder = view.firstResponderInView() {
                responder = firstResponder
            }
        }
        return responder
    }
}

extension UIView {
    func firstResponderInView() -> UIResponder? {
        if self.isFirstResponder {
            return self
        }
        
        for subview in self.subviews {
            if let responder = subview.firstResponderInView() {
                return responder
            }
        }
        return nil
    }
} 