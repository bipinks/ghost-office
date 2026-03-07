# Domain Knowledge — E-Commerce

> **Domain**: E-Commerce
> Auto-loaded via `domain.lock` or `/set-domain ecommerce`

## Core Business Concepts

### Product Catalog
- Products with variants (size, color, material)
- Categories and collections (hierarchical, tag-based)
- Product attributes: SKU, price, weight, dimensions, images
- Digital vs physical product handling
- Bundle and grouped products

### Pricing & Promotions
- Base price, sale price, compare-at price
- Tiered pricing (quantity discounts)
- Coupon codes: percentage, fixed amount, free shipping, BOGO
- Automatic discounts based on cart rules
- Flash sales with time-limited pricing

### Customer Lifecycle
- Guest checkout vs registered accounts
- Customer groups (wholesale, VIP, regular)
- Wish lists and saved carts
- Customer reviews and ratings
- Loyalty points and rewards programs

---

## Modules

### 1. Storefront
**Entities**: Page, Collection, Navigation, Theme, Banner
**Key Rules**:
- SEO-optimized URLs (slugs for products and categories)
- Responsive design with mobile-first approach
- Product search with faceted filtering
- Recently viewed and recommended products
- A/B testing for conversion optimization

### 2. Cart & Checkout
**Entities**: Cart, CartItem, Checkout, ShippingMethod, PaymentMethod
**Key Rules**:
- Cart persistence (cookie/session for guests, DB for users)
- Real-time inventory check before checkout
- Shipping calculator based on weight/dimensions/destination
- Tax calculation per jurisdiction (Avalara, TaxJar integration)
- Multiple payment gateways (Stripe, PayPal, etc.)
- Order review step before confirmation
- Abandoned cart recovery (email triggers)

### 3. Order Management
**Entities**: Order, OrderItem, Shipment, Refund, Return
**Key Rules**:
- Order statuses: pending -> processing -> shipped -> delivered -> completed
- Partial fulfillment (ship available items first)
- Split shipments to multiple addresses
- Return/refund workflow with reason codes
- Order notes and internal communication
- Invoice and packing slip generation

### 4. Inventory
**Entities**: Warehouse, StockLocation, StockMovement, Reservation
**Key Rules**:
- Multi-warehouse stock management
- Stock reservation on order placement (release on cancellation)
- Low stock alerts and auto-reorder rules
- Backorder handling (allow oversell or not)
- Inventory sync with POS and marketplaces

### 5. Payments
**Entities**: Payment, Transaction, Refund, PaymentMethod
**Key Rules**:
- PCI DSS compliance (never store raw card data)
- Payment capture: authorize-then-capture vs immediate
- Webhook handling for async payment events
- Refund processing (full, partial, store credit)
- Subscription/recurring billing support

### 6. Shipping & Fulfillment
**Entities**: ShippingZone, ShippingRate, Carrier, Shipment, TrackingEvent
**Key Rules**:
- Shipping zones with rate tables
- Real-time carrier rate calculation (UPS, FedEx, DHL APIs)
- Flat rate, free shipping (above threshold), calculated shipping
- Tracking number generation and status updates
- Fulfillment center integration (3PL)

---

## Cross-Cutting Concerns

### SEO & Marketing
- Meta titles, descriptions, canonical URLs for all pages
- Structured data (JSON-LD) for products, reviews, breadcrumbs
- Sitemap generation (products, categories, pages)
- Email marketing integration (Klaviyo, Mailchimp)
- Social media pixel tracking (Meta, Google, TikTok)

### Analytics
- Conversion funnel tracking (view -> cart -> checkout -> purchase)
- Revenue attribution by channel/campaign
- Product performance metrics (views, cart adds, conversion rate)
- Customer lifetime value (CLV) calculation
- Cohort analysis for retention

### Security
- PCI DSS compliance for payment handling
- Rate limiting on checkout and auth endpoints
- Bot protection for inventory hoarding
- GDPR/CCPA compliance for customer data
- Secure webhook verification (HMAC signatures)

### Performance
- Product listing pages: sub-200ms response
- Search results: sub-300ms with autocomplete
- Image optimization: WebP with lazy loading, CDN delivery
- Cart operations: real-time with optimistic UI updates
- Checkout: minimize steps, pre-fill where possible
