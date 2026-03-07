---
name: qa-testing-strategy
description: Use when writing tests, designing test plans, or verifying bug fixes for the platform. Covers PHPUnit, Pest, Cypress/Playwright, test data factories, multi-tenant isolation testing, and quality gate criteria.
user-invocable: false
allowed-tools: ["Read", "Write", "Bash", "Grep", "Glob"]
---

# QA Testing Strategy — Platform Testing

## Test Pyramid

```
         ╱╲
        ╱ E2E ╲          — 10% (Cypress/Playwright: critical user flows)
       ╱────────╲
      ╱Integration╲      — 30% (Feature tests: API endpoints, DB queries)
     ╱──────────────╲
    ╱   Unit Tests    ╲   — 60% (PHPUnit/Pest: services, models, helpers)
   ╱────────────────────╲
```

## Unit Test Pattern (Pest/PHPUnit)

```php
// tests/Unit/Services/InvoiceServiceTest.php
use App\Models\Invoice;
use App\Services\InvoiceService;

describe('InvoiceService', function () {
    beforeEach(function () {
        $this->service = app(InvoiceService::class);
        $this->branch = Branch::factory()->create();
        $this->actingAs(User::factory()->for($this->branch)->create());
    });

    it('creates an invoice with line items', function () {
        $customer = Customer::factory()->create(['branch_id' => $this->branch->id]);
        $product = Product::factory()->create(['branch_id' => $this->branch->id, 'price' => 100]);

        $invoice = $this->service->create([
            'customer_id' => $customer->id,
            'date' => '2026-03-06',
            'due_date' => '2026-04-05',
            'items' => [
                ['product_id' => $product->id, 'quantity' => 2, 'price' => 100],
            ],
        ]);

        expect($invoice)
            ->toBeInstanceOf(Invoice::class)
            ->branch_id->toBe($this->branch->id)
            ->total->toBe(200.0)
            ->items->toHaveCount(1);
    });

    it('rejects invoice without items', function () {
        $customer = Customer::factory()->create(['branch_id' => $this->branch->id]);

        expect(fn () => $this->service->create([
            'customer_id' => $customer->id,
            'date' => '2026-03-06',
            'due_date' => '2026-04-05',
            'items' => [],
        ]))->toThrow(ValidationException::class);
    });

    it('rejects due_date before invoice date', function () {
        $customer = Customer::factory()->create(['branch_id' => $this->branch->id]);

        expect(fn () => $this->service->create([
            'customer_id' => $customer->id,
            'date' => '2026-03-06',
            'due_date' => '2026-03-01',
            'items' => [['product_id' => 1, 'quantity' => 1, 'price' => 50]],
        ]))->toThrow(ValidationException::class);
    });
});
```

## Multi-Tenant Isolation Tests

**CRITICAL**: Every feature must verify that Branch A cannot access Branch B data.

```php
// tests/Feature/MultiTenantIsolationTest.php
describe('Multi-Tenant Isolation', function () {
    it('prevents cross-branch data access for invoices', function () {
        $branchA = Branch::factory()->create();
        $branchB = Branch::factory()->create();
        $userA = User::factory()->for($branchA)->create();
        $userB = User::factory()->for($branchB)->create();

        // Create invoice in Branch A
        $this->actingAs($userA);
        $invoice = Invoice::factory()->create(['branch_id' => $branchA->id]);

        // Branch B user cannot see it
        $this->actingAs($userB);
        $response = $this->getJson("/api/v1/invoices/{$invoice->id}");
        $response->assertNotFound();

        // Branch B user cannot list it
        $response = $this->getJson('/api/v1/invoices');
        $response->assertJsonCount(0, 'data');
    });

    it('auto-assigns branch_id on creation', function () {
        $branch = Branch::factory()->create();
        $user = User::factory()->for($branch)->create();
        $this->actingAs($user);

        $customer = Customer::factory()->create(['branch_id' => $branch->id]);
        $response = $this->postJson('/api/v1/invoices', [
            'customer_id' => $customer->id,
            'date' => '2026-03-06',
            'due_date' => '2026-04-05',
            'items' => [['product_id' => 1, 'quantity' => 1, 'price' => 100]],
        ]);

        $response->assertCreated();
        expect(Invoice::first()->branch_id)->toBe($branch->id);
    });
});
```

## API Feature Test Pattern

```php
// tests/Feature/Api/InvoiceApiTest.php
describe('Invoice API', function () {
    beforeEach(function () {
        $this->branch = Branch::factory()->create();
        $this->user = User::factory()->for($this->branch)->create();
        $this->actingAs($this->user);
    });

    describe('GET /api/v1/invoices', function () {
        it('returns paginated invoices for the current branch', function () {
            Invoice::factory()->count(30)->create(['branch_id' => $this->branch->id]);

            $response = $this->getJson('/api/v1/invoices?per_page=10');

            $response
                ->assertOk()
                ->assertJsonCount(10, 'data')
                ->assertJsonPath('meta.total', 30);
        });

        it('filters by status', function () {
            Invoice::factory()->create(['branch_id' => $this->branch->id, 'status' => 'paid']);
            Invoice::factory()->create(['branch_id' => $this->branch->id, 'status' => 'unpaid']);

            $response = $this->getJson('/api/v1/invoices?status=paid');

            $response->assertOk()->assertJsonCount(1, 'data');
        });

        it('returns 401 for unauthenticated requests', function () {
            auth()->logout();
            $this->getJson('/api/v1/invoices')->assertUnauthorized();
        });
    });

    describe('POST /api/v1/invoices', function () {
        it('validates required fields', function () {
            $response = $this->postJson('/api/v1/invoices', []);

            $response->assertUnprocessable()
                ->assertJsonValidationErrors(['customer_id', 'date', 'due_date', 'items']);
        });
    });
});
```

## Factory Pattern

```php
// database/factories/InvoiceFactory.php
class InvoiceFactory extends Factory
{
    public function definition(): array
    {
        return [
            'branch_id' => Branch::factory(),
            'customer_id' => Customer::factory(),
            'invoice_number' => $this->faker->unique()->numerify('INV-####'),
            'date' => $this->faker->date(),
            'due_date' => fn (array $attrs) => Carbon::parse($attrs['date'])->addDays(30),
            'status' => 'draft',
            'subtotal' => $this->faker->randomFloat(2, 100, 10000),
            'tax' => fn (array $attrs) => $attrs['subtotal'] * 0.05,
            'total' => fn (array $attrs) => $attrs['subtotal'] + $attrs['tax'],
        ];
    }

    public function paid(): static
    {
        return $this->state(fn () => ['status' => 'paid', 'paid_at' => now()]);
    }

    public function overdue(): static
    {
        return $this->state(fn () => [
            'status' => 'unpaid',
            'due_date' => now()->subDays(30),
        ]);
    }
}
```

## E2E Test Pattern (Cypress)

```typescript
// cypress/e2e/invoices/create-invoice.cy.ts
describe('Create Invoice', () => {
  beforeEach(() => {
    cy.login('sales@example.com');
    cy.visit('/invoices/new');
  });

  it('creates a new invoice with line items', () => {
    // Select customer
    cy.get('[data-cy=customer-select]').click();
    cy.get('[data-cy=customer-option]').first().click();

    // Set dates
    cy.get('[data-cy=invoice-date]').type('2026-03-06');
    cy.get('[data-cy=due-date]').type('2026-04-05');

    // Add line item
    cy.get('[data-cy=add-item]').click();
    cy.get('[data-cy=product-search]').type('Widget');
    cy.get('[data-cy=product-option]').first().click();
    cy.get('[data-cy=quantity]').clear().type('5');

    // Verify totals
    cy.get('[data-cy=subtotal]').should('contain', '500.00');
    cy.get('[data-cy=total]').should('contain', '525.00');

    // Save
    cy.get('[data-cy=save-btn]').click();
    cy.url().should('match', /\/invoices\/\d+/);
    cy.get('[data-cy=status-badge]').should('contain', 'Draft');
  });

  it('shows validation errors for missing fields', () => {
    cy.get('[data-cy=save-btn]').click();
    cy.get('[data-cy=error-customer]').should('be.visible');
    cy.get('[data-cy=error-items]').should('contain', 'At least one item required');
  });
});
```

## Quality Gate Checklist

Every PR must pass these before merge:

### Automated Gates
- [ ] All unit tests passing (`php artisan test --parallel`)
- [ ] All feature tests passing
- [ ] Code coverage >= 80% for changed files
- [ ] Static analysis passing (`phpstan level 8`)
- [ ] Linting passing (`pint`, `eslint`)
- [ ] No known security vulnerabilities

### Manual Review Checklist
- [ ] Multi-tenant isolation verified (branch_id scoping)
- [ ] Migration has `down()` method
- [ ] API response follows envelope format (`{ data, meta }`)
- [ ] Edge cases tested (empty lists, max values, special chars)
- [ ] Authorization tested (correct roles can/cannot access)
- [ ] Error messages are user-friendly (no stack traces in responses)

## Test Data Principles

1. **Use factories** — Never hardcode test data
2. **Isolate tests** — Each test creates its own data
3. **Use `RefreshDatabase`** — Clean state per test
4. **Name descriptively** — Test names explain the behavior, not the method
5. **One assertion per concept** — Test one behavior, may use multiple `expect()`
6. **Test edge cases**: empty arrays, null values, max lengths, special characters
7. **Test authorization**: verify both allowed and denied access

## Bug Verification Pattern

When fixing a bug:

```php
describe('Bug Fix: #167 — Tax calculation for exempt items', function () {
    it('reproduces the original bug', function () {
        // Setup: Create tax-exempt product
        $product = Product::factory()->create(['tax_exempt' => true, 'price' => 100]);

        // Before fix: This would return 5.00 (incorrect)
        // After fix: This should return 0.00
        $tax = TaxService::calculate($product, quantity: 1);
        expect($tax)->toBe(0.0);
    });

    it('still calculates tax for taxable items', function () {
        // Regression check: normal items still taxed
        $product = Product::factory()->create(['tax_exempt' => false, 'price' => 100]);
        $tax = TaxService::calculate($product, quantity: 1);
        expect($tax)->toBe(5.0);
    });
});
```
