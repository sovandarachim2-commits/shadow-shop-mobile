# SS-TASK-002: Shadow Shop Rewards Page UI Redesign

**Module:** Customer App – Rewards  
**Priority:** High  
**Task Type:** UI/UX Improvement  
**Platform:** Flutter Mobile App  
**Status:** Completed

---

## 1. Objective

Redesign the existing Shadow Shop Rewards page to provide a premium, modern, clean, and user-friendly loyalty experience.

Use the attached screenshot as the reference for the current interface.

Improve the visual design without removing existing features or changing the established customer app navigation.

The final result should look like a professional ecommerce loyalty application.

## 2. Design Direction

Follow the Shadow Shop brand identity.

- Primary color: Pink `#EC4899`
- Secondary color: Purple `#7C3AED`
- Background: `#F8FAFC`
- Card background: `#FFFFFF`
- Text: Dark navy / charcoal
- Rounded cards with subtle shadows.
- Modern typography and consistent iconography.
- Clean spacing and visual hierarchy.
- Smooth interactions and transitions.
- Premium, minimal ecommerce aesthetic.

Avoid excessive gradients, unnecessary decorations, and overcrowded layouts.

---

## 3. UI Components to Improve

### A. Header

Improve the top navigation area.

- Shadow Shop logo and brand name.
- Wishlist icon.
- Customer profile icon.
- Consistent icon sizing and alignment.
- Keep the header clean and compact.

### B. Rewards Summary Card

Redesign the points summary card.

Display:
- Current points balance.
- Current membership tier.
- Next membership tier.
- Points needed to reach the next tier.
- Visual progress bar.

Make the points balance the main visual focus.

### C. Rewards Menu

Improve the menu design:

1. Ways to Earn Points
2. Refer a Friend
3. Points History
4. My Coupons

Requirements:
- Consistent icons.
- Better spacing.
- Clear labels.
- Right-side navigation indicators.
- Smooth tap interactions.

### D. Daily Check-in

Create an attractive daily check-in section.

Display:
- Today's check-in status.
- Points earned from check-in.
- Consecutive check-in streak.
- Check-in button.

States:
- Available to check in.
- Successfully checked in.
- Already checked in today.

Prevent duplicate daily check-ins.

### E. Redeem Rewards

Improve the rewards redemption section.

Each reward card should support:
- Reward image.
- Reward name.
- Short description.
- Required points.
- Redeem button.
- Availability status.

Rules:
- Users cannot redeem rewards with insufficient points.
- Show a confirmation before redemption.
- Show a clear success or failure message.
- Display a polished empty state when no rewards are available.

### F. Recent Points

Redesign the recent transaction history.

Display:
- Transaction description.
- Transaction date.
- Points earned or deducted.
- Transaction type.

Visual rules:
- Green for points earned.
- Red or neutral styling for points deducted.
- Clear positive and negative point indicators.
- Add a View All action.

---

## 4. Bottom Navigation

Preserve the existing five navigation items.

| Item | Function |
|---|---|
| Home | Customer homepage |
| Products | Product browsing |
| Rewards | Loyalty and points |
| Cart | Shopping cart |
| My Orders | Order history |

Requirements:
- Keep Rewards highlighted on the Rewards page.
- Improve icon and label alignment.
- Use consistent spacing.
- Maintain a floating or elevated active Rewards icon only if it fits the existing app architecture.
- Respect Android and iOS safe areas.
- Ensure content does not overlap the bottom navigation.

Do not change navigation routes or break existing navigation behavior.

---

## 5. Functional Requirements

The redesign must continue using the existing backend and business logic.

- Fetch real customer points from Django APIs.
- Fetch actual membership tier and progress.
- Fetch available rewards.
- Fetch points transaction history.
- Connect daily check-in to the existing API.
- Connect reward redemption to the existing API.
- Validate point balances on the backend.
- Handle loading, empty, success, and error states.
- Preserve customer authentication and permissions.

Do not use hardcoded demo data.

---

## 6. Responsive Requirements

Support:
- Small Android phones.
- Large Android phones.
- iPhones.
- Tablets.

Requirements:
- Mobile-first layout.
- Responsive card widths.
- Readable typography.
- No horizontal overflow.
- Proper scrolling.
- Safe area support.
- Bottom navigation remains accessible.

---

## 7. Development Workflow

### Phase 1: Investigation

- [x] Inspect the existing Rewards screen.
- [x] Identify relevant Flutter widgets and components.
- [x] Inspect existing navigation routes.
- [x] Inspect related Django APIs.
- [x] Understand current rewards business logic.
- [x] Identify reusable components.

### Phase 2: Planning

- [x] Explain the proposed UI improvements.
- [x] Identify files that need modification.
- [x] Identify any missing backend functionality.
- [x] Wait for approval before implementation.

### Phase 3: Implementation

- [x] Redesign the Rewards screen.
- [x] Improve points summary card.
- [x] Improve rewards menu.
- [x] Improve daily check-in.
- [x] Improve reward redemption cards.
- [x] Improve recent points history.
- [x] Improve bottom navigation styling.
- [x] Connect all existing APIs.

### Phase 4: Testing

- [x] Test loading states.
- [x] Test empty states.
- [x] Test real customer points.
- [x] Test daily check-in.
- [x] Test duplicate check-in prevention.
- [x] Test reward redemption.
- [x] Test insufficient points.
- [x] Test navigation.
- [x] Test different screen sizes.
- [x] Check for Flutter errors.

### Phase 5: Final Review

- [x] Verify the design against the reference screenshot.
- [x] Verify existing features still work.
- [x] Check for unrelated code changes.
- [x] Confirm no broken API integrations.
- [x] Provide implementation summary.

---

## 8. Restrictions

IMPORTANT:

1. Do not rebuild the entire Flutter application.
2. Do not modify unrelated screens.
3. Do not remove existing Rewards functionality.
4. Do not create duplicate APIs or database tables.
5. Do not change the existing database structure unless necessary and approved.
6. Do not replace real API data with mock data.
7. Do not break existing navigation.
8. Reuse the current project architecture and coding conventions.
9. Keep code clean, reusable, and maintainable.

---

## 9. Acceptance Criteria

The task is complete when:

- Rewards page has a modern premium design.
- All existing features continue working.
- Real customer data is displayed.
- Daily check-in works correctly.
- Reward redemption works correctly.
- Backend validation is maintained.
- Navigation works correctly.
- Layout is responsive.
- No critical Flutter or API errors remain.

## 10. Final AI Report

After completion, report:

1. Summary of UI improvements.
2. Files created or modified.
3. APIs reused or modified.
4. Database changes, if any.
5. Tests performed and results.
6. Remaining issues.

**Final Status:** Completed
