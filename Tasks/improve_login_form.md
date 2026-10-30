# Phase: Build Mobile Authentication UI – Shadow Shop Flutter App

## Objective
Build a modern, premium Login and Registration experience for the Shadow Shop mobile application.

The UI must be designed specifically for Android mobile screens, not copied directly from the desktop website.

## 1. Login Screen

Design a clean login screen containing:

- Shadow Shop logo.
- Welcome Back heading.
- Short welcome description.
- Email or phone number input.
- Password input with show/hide functionality.
- Remember Me option.
- Forgot Password link.
- Primary Login button.
- Google Login button.
- Telegram Login button.
- Navigate to Register link.

## 2. Registration Screen

Build a separate registration screen containing:

- Shadow Shop logo.
- Create Account heading.
- Full Name.
- Phone Number.
- Email Address.
- Password.
- Confirm Password.
- Show/hide password.
- Terms & Conditions checkbox.
- Create Account button.
- Google Registration.
- Telegram Registration.
- Navigate to Login link.

Keep the registration form simple and mobile-friendly. Do not request delivery addresses during registration.

## 3. Visual Design System

Use Shadow Shop branding:

- Primary: #7C3AED (Royal Purple)
- Secondary: #EC4899 (Hot Pink)
- Background: #FFFFFF
- Input Background: #F8FAFC
- Text: #1E1B4B
- Secondary Text: #64748B

Design specifications:

- Modern rounded input fields.
- Button radius: 12–14px.
- Card radius: 16–20px.
- Consistent 16–24px spacing.
- Clean typography.
- Subtle shadows.
- Professional icons.
- Smooth page transitions.

Avoid excessive gradients, large illustrations and unnecessary decorations.

## 4. Mobile UI Requirements

- Support different Android screen sizes.
- Responsive layouts.
- SafeArea support.
- Keyboard-aware scrolling.
- Prevent keyboard from covering input fields.
- Support portrait orientation.
- Add loading indicators.
- Show clear validation and error messages.
- Add password visibility toggle.
- Prevent duplicate submissions.

## 5. Navigation Flow

Login → Forgot Password → Reset Password

Login → Register → Verify Email/OTP → Account

Register → Login

Successful Login → Customer Home Screen

Successful Registration → Verification Screen

## 6. Backend Integration

Use the existing Django backend.

- Inspect existing authentication endpoints before implementation.
- Connect real login and registration APIs.
- Preserve existing database authentication.
- Implement secure access and refresh token handling according to the existing backend.
- Integrate email verification.
- Integrate Google authentication if already supported.
- Integrate Telegram authentication if already supported.
- Handle expired sessions and logout.
- Never store plaintext passwords.
- Never use fake authentication or hardcoded successful responses.

## 7. Code Architecture

Create reusable Flutter components:

- CustomTextField
- PasswordTextField
- PrimaryAuthButton
- SocialLoginButton
- AuthHeader
- AuthDivider
- AuthValidator

Keep Login and Register screens separate and maintainable.

## 8. Testing

Test:
- Login with valid credentials.
- Login with invalid credentials.
- Registration validation.
- Password confirmation.
- Email verification.
- Google and Telegram login flows.
- Keyboard behavior.
- Different Android screen sizes.
- Backend connection failures.
- Session expiration.

## Final Goal

Deliver a production-ready Shadow Shop mobile authentication UI with a premium ecommerce appearance, reliable backend integration, and a smooth customer experience.

Important: Implement actual Flutter screens and working navigation, not just screenshots or static UI mockups. Do not break existing Django authentication functionality.