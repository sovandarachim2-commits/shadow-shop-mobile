# Shadow Shop Rewards System: Architecture, Mechanics & UI Guide

This document explains **how the Shadow Shop Rewards & Loyalty System works** from backend to frontend, and provides the **optimal UI/UX design specifications** for both the mobile app and website, specifically addressing the integration of **Redeemed Rewards** inside **Points History**.

---

## 1. System Overview & Core Mechanics

The loyalty program is a full-cycle gamification system connecting:
- **Earn Engine**: Earn points through purchases, daily check-ins, product reviews, and friend referrals.
- **Tier Progression**: Points accumulate to level up customer membership tiers (*Bronze → Silver → Gold → Platinum*).
- **Exchange & Redemption Engine**: Spend points to acquire coupons, percentage discounts, free shipping, or physical gifts.
- **Checkout Consumption Engine**: Redeemed promo codes automatically apply discounts to customer cart orders.

---

## 2. Should Points History Show "Redeemed Rewards"?

> **Yes, showing redeemed rewards in Points History is a major UX upgrade.**  
> Showing raw negative points (e.g., `-500 pts`) without clear reward context causes customer confusion ("Where did my 500 points go?"). Showing the actual redeemed item, voucher code, and redemption status gives immediate clarity and value reassurance.

### Current vs. Recommended Experience

| Feature | Current Points History | Recommended Upgraded Experience |
| :--- | :--- | :--- |
| **Tab / Category** | Shows "Used" | Rename to **"Redeemed"** (or dual view: *Points Ledger* vs *Redeemed Items*) |
| **Headline** | Generic: *"Points"* or *"Points activity"* | Clear Reward Name: *"Redeemed: $10 Discount Voucher"* or *"Redeemed: Free Delivery"* |
| **Voucher Code** | Hidden / Must switch to another page | Displayed right on the card with a **1-tap Copy** button |
| **Status Badge** | Missing | Live status: `Active Voucher`, `Applied to Order`, `Expired` |
| **Interaction** | Basic dialog | Opens full voucher details with direct *"Use in Checkout"* or *"View Order"* |

---

## 3. Recommended UI Design for Points History & Redemptions

### A. Dual-Perspective Filter Bar
Instead of just `All` / `Earned` / `Used`, use:
1. **All Activity**: Chronological timeline of everything earned and spent.
2. **Earned (+)**: Clean green list of shopping bonuses, daily check-ins, and referrals.
3. **Redeemed (-)**: Rich reward voucher cards displaying what was claimed.

### B. "Redeemed" Transaction Card Wireframe
```text
┌────────────────────────────────────────────────────────┐
│ 🎟️  $10.00 OFF DISCOUNT               -500 pts         │
│     Reward: Summer Sitewide Voucher                    │
│     Oct 30, 2026 · 4:15 PM                             │
│ ┌──────────────────────────────────────┐               │
│ │ Code: SHADOW-X7B92A   [ Copy Icon ]  │  [ Available ]│
│ └──────────────────────────────────────┘               │
└────────────────────────────────────────────────────────┘
```

---

## 4. End-to-End Module Breakdown

### Module 1: Daily Check-in
* **Mechanics**: Users can claim once per calendar day (UTC local bounds).
* **Streak**: Tracks 7-day cadence.
* **UI**: 7 mini day-circles (`D1`–`D7`). An enabled button when ready (*"Check In & Claim (+10 pts)"*); turns into a light-green disabled pill (*"Checked In Today"*) once claimed.

### Module 2: Refer a Friend
* **Mechanics**: Every user receives an 8-character alphanumeric referral code upon account creation.
* **Tracking**: When friends sign up and make their first purchase, both accounts receive referral bonus points.
* **UI**: Prominent gradient card displaying the code, a 1-tap Copy button, pre-formatted invitation message, and friend code binding input.

### Module 3: Ways to Earn
* **Mechanics**: Governed by backend `RewardSettings` (`points_per_dollar`, `daily_checkin_bonus`, `referral_bonus`, `review_bonus`).
* **UI**: Clean activity cards with colored icon badges and direct CTA buttons (e.g. *"Shop Now"*, *"Invite Friends"*).

### Module 4: My Coupons
* **Mechanics**: Stores active, used, and expired vouchers generated through point redemption.
* **UI**: Ticket-notch voucher cards with discount badges (`15% OFF`, `FREE DELIVERY`), minimum spend requirements, expiration date, and copy actions.

---

## 5. Technical Data Flow

| Action | Frontend Method | Django Endpoint | Database Effect |
| :--- | :--- | :--- | :--- |
| **Load Summary** | `service.rewards()` | `GET /api/orders/rewards/` | Fetches points, tier, catalog, and transactions. |
| **Check In** | `service.checkIn()` | `POST /api/orders/rewards/daily_checkin/` | Creates `PointTransaction(type='earn', note='Daily check-in bonus')`. |
| **Redeem Item** | `service.exchangeReward(id)` | `POST /api/orders/rewards/exchange/` | Deducts points, creates `RewardRedemption` and `PromoCode`. |
| **Bind Referral** | `service.updateProfile(data)` | `PATCH /api/auth/profile/` | Sets `user.referred_by` to the code owner. |
| **Apply Coupon** | `service.validateCoupon(code)` | `POST /api/orders/rewards/validate_coupon/` | Verifies discount against subtotal at checkout. |

