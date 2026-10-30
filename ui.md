# SS-TASK-003: Redesign All Shadow Shop Rewards Subpages

**Module:** Customer Rewards & Loyalty  
**Priority:** High  
**Platform:** Flutter Mobile App  
**Task Type:** UI/UX Redesign + Functional Integration  
**Status:** Completed

## 1. Objective

Redesign all four Rewards subpages to create a consistent, premium, modern ecommerce loyalty experience.

### Pages Included
1. Ways to Earn Points
2. Refer a Friend
3. Points History
4. My Coupons

Use the provided screenshots as references for the existing application.

All four pages must follow the same Shadow Shop design system.

## 2. Global Design Requirements

- Primary color: Pink `#EC4899`
- Secondary color: Purple `#7C3AED`
- Background: `#F8FAFC`
- Cards: White
- Text: Dark navy / charcoal
- Rounded corners.
- Subtle shadows.
- Consistent icons.
- Modern typography.
- Responsive mobile-first layout.
- Smooth page transitions.
- Consistent headers and back navigation.

Avoid overcrowded layouts and unnecessary decorations.

---

# PAGE 1 — Ways to Earn Points

## Objective
Help customers understand all available ways to earn loyalty points.

### UI Components

**A. Header**
- Back button.
- Page title: Ways to Earn Points.
- Current points balance.

**B. Earning Activities**

Display available earning methods as individual cards.

Examples:

1. Daily Check-in
   - Earn points by checking in every day.
   - Display available points.
   - Show check-in status.
   - Check In button.

2. Shopping Rewards
   - Earn points from eligible purchases.
   - Explain earning rules.
   - Display applicable conditions.

3. Refer a Friend
   - Invite friends.
   - Display referral rewards.
   - Invite Friends button.

4. Special Promotions
   - Display available promotional activities.
   - Show points and expiration dates.
   - Provide relevant action buttons.

5. Other Activities
   - Display additional activities configured by administrators.

### Functional Requirements
- Fetch actual earning activities from Django.
- Display real configured reward values.
- Validate eligibility.
- Prevent duplicate reward claims.
- Update points balance after successful transactions.

---

# PAGE 2 — Refer a Friend

## Objective
Create a referral system that encourages customers to invite friends and earn points.

### UI Components

**A. Referral Summary Card**
Display:
- Referral code.
- Total friends invited.
- Successful referrals.
- Points earned from referrals.

**B. Referral Code**
- Display unique customer referral code.
- Copy referral code button.
- Share invitation button.

**C. Referral Link**
- Generate or retrieve the customer's referral link.
- Copy link.
- Share through supported mobile sharing options.

**D. How It Works**

Display a simple three-step explanation:

1. Share your referral link with a friend.
2. Your friend registers using your referral link or code.
3. Receive referral points when the referral conditions are successfully completed.

**E. Referral History**

Display:
- Friend or referral identifier.
- Registration date.
- Referral status.
- Points earned.

Possible statuses:
- Pending
- Completed
- Expired

### Functional Requirements
- Use unique referral codes.
- Track referral relationships.
- Prevent self-referrals.
- Prevent duplicate referral rewards.
- Validate referral eligibility on the backend.
- Only award points when configured referral conditions are met.
- Integrate with the existing Django authentication system.

---

# PAGE 3 — Points History

## Objective
Give customers a clear record of all points earned and used.

### UI Components

**A. Header**
- Back button.
- Page title: Points History.

**B. Points Summary**
Display:
- Total points earned.
- Total points used.
- Current points balance.

**C. Transaction Filters**

Three filter tabs:
- All
- Earned
- Used

Update the transaction list based on the selected filter.

**D. Transaction List**

Each transaction should display:
- Transaction icon.
- Transaction description.
- Transaction date and time.
- Points earned or deducted.
- Transaction status where applicable.

Examples:
- Daily Check-in Bonus
- Purchase Reward
- Referral Bonus
- Special Promotion
- Reward Redemption
- Points Adjustment

**E. Date Formatting**

Never display raw ISO timestamps.

Use readable formatting:

- Today · 4:01 PM
- Yesterday · 11:42 AM
- October 28, 2026 · 6:34 PM

Respect the correct local timezone.

**F. Transaction Details**

When a customer taps a transaction, display:
- Transaction type.
- Description.
- Points earned or used.
- Transaction date.
- Related order or reward reference.
- Transaction status.

### Functional Requirements
- Fetch actual transaction history from Django.
- Filters must work correctly.
- Preserve transaction accuracy.
- Support pagination or load more if available.
- Do not modify historical transaction records.

---

# PAGE 4 — My Coupons

## Objective
Create a professional coupon management page where customers can view and use available discount coupons.

### UI Components

**A. Header**
- Back button.
- Page title: My Coupons.

**B. Coupon Filters**

Create tabs:
- All
- Available
- Used
- Expired

**C. Coupon Cards**

Each coupon should display:
- Coupon name.
- Discount amount or percentage.
- Coupon code.
- Minimum purchase requirement.
- Maximum discount if applicable.
- Valid from date.
- Expiration date.
- Coupon status.

**D. Coupon Actions**
- Copy coupon code.
- View coupon details.
- Use Coupon / Shop Now button when available.

**E. Coupon Details**

When customers select a coupon, display:
- Full description.
- Discount rules.
- Eligible products or categories.
- Minimum order value.
- Maximum discount.
- Expiration date.
- Terms and conditions.

**F. Empty States**

Show attractive empty states when:
- No available coupons.
- No used coupons.
- No expired coupons.

### Functional Requirements
- Fetch real customer coupons from Django.
- Validate coupon availability.
- Validate expiration dates.
- Validate minimum order requirements.
- Prevent unauthorized coupon usage.
- Apply discounts through the existing checkout system.
- Do not hardcode coupon values.

---

## 3. Navigation Flow

Maintain this Rewards navigation structure:

Rewards Dashboard
  ├── Ways to Earn Points
  ├── Refer a Friend
  ├── Points History
  └── My Coupons

Requirements:
- Each page must have working navigation.
- Back button returns to the Rewards Dashboard.
- Preserve existing app navigation.
- Do not create duplicate navigation routes.

## 4. Backend Integration

Technology:
- Flutter frontend.
- Django 5 backend.
- MySQL database.

Before development:
- Inspect existing Django models.
- Inspect existing API endpoints.
- Inspect existing Flutter API services.
- Reuse existing reward and coupon logic.
- Identify missing functionality before proposing database changes.

All points, referral rewards, transaction history, and coupons must use actual backend data.

Never use hardcoded demo data in production.

## 5. Security and Business Rules

- Validate points on the backend.
- Prevent duplicate reward transactions.
- Prevent duplicate referral claims.
- Prevent self-referrals.
- Validate coupon ownership and eligibility.
- Do not trust frontend point balances.
- Preserve authentication and permissions.
- Keep financial and points transaction records accurate.

## 6. Development Workflow

### Phase 1 — Investigation
- [x] Inspect all four existing pages.
- [x] Inspect Flutter widgets and components.
- [x] Inspect navigation and routes.
- [x] Inspect Django APIs and models.
- [x] Identify reusable components.
- [x] Identify missing backend functionality.

### Phase 2 — Planning
- [x] Propose a consistent design for all four pages.
- [x] Explain page layouts.
- [x] List files to modify.
- [x] Identify API changes.
- [x] Identify database changes, if necessary.
- [x] Wait for approval.

### Phase 3 — Implementation
- [x] Implement Ways to Earn Points.
- [x] Implement Refer a Friend.
- [x] Implement Points History.
- [x] Implement My Coupons.
- [x] Connect existing Django APIs.
- [x] Implement loading and empty states.
- [x] Implement error handling.
- [x] Ensure consistent navigation.

### Phase 4 — Testing & Validation
- [x] Test all four pages.
- [x] Test real backend data.
- [x] Test referral functionality.
- [x] Test points transactions.
- [x] Test coupon filters.
- [x] Test coupon redemption.
- [x] Test authentication and permissions.
- [x] Test responsive layouts.
- [x] Fix errors.

### Phase 5 — Final Review & Delivery
- [x] Review all four redesigned pages.
- [x] Verify existing functionality.
- [x] Verify API integrations.
- [x] Check for unrelated code changes.
- [x] Report modified files.
- [x] Report test results.
- [x] Report remaining issues.

## 7. Restrictions

IMPORTANT:

1. Do not rebuild the entire Flutter application.
2. Do not modify unrelated modules.
3. Do not remove existing functionality.
4. Do not create duplicate APIs or database tables.
5. Do not change database structure without approval.
6. Do not replace real data with mock data.
7. Do not break existing navigation.
8. Follow existing project architecture.
9. Reuse existing components and services.
10. Keep code clean and maintainable.

## 8. Acceptance Criteria

The task is complete when:

- All four pages have a consistent premium design.
- All pages connect to the existing Django backend.
- Points and referral calculations are accurate.
- Coupon information is correct.
- All filters and buttons work.
- Navigation works correctly.
- Mobile layouts are responsive.
- No existing Rewards functionality is broken.
- Relevant tests pass.

## 9. Final AI Report

Provide:

1. Summary of improvements for each page.
2. Files created or modified.
3. APIs reused or modified.
4. Database changes, if any.
5. Tests performed and results.
6. Remaining issues.

**Final Status:** Completed
