---
name: testing-patterns
description: Use when writing or designing tests. Covers test architecture, PHPUnit/Pest for backend, Vitest for frontend, Cypress/Playwright for E2E, test factories, mocking strategies, multi-tenant isolation testing, and CI integration.
user-invocable: false
allowed-tools: ["Read", "Write", "Bash", "Grep", "Glob"]
---

# Testing Patterns

## 1. Test Architecture

### Test Pyramid

```
           /\
          / E2E \            10% — Critical user flows (Cypress/Playwright)
         /--------\
        /Integration\        30% — API endpoints, DB queries, multi-service
       /--------------\
      /   Unit Tests    \    60% — Services, models, helpers, composables
     /--------------------\
```

### Test Categories

| Category | Scope | Tools | Speed |
|----------|-------|-------|-------|
| Unit | Single class/function | Pest, Vitest | < 10ms each |
| Integration | API endpoint + DB | Pest Feature, Supertest | < 500ms each |
| E2E | Full browser flow | Cypress, Playwright | < 30s each |
| Contract | API schema compliance | Pact, Spectral | < 100ms each |
| Performance | Load and latency | k6 | Minutes |

### Directory Structure

```
tests/
├── Unit/
│   ├── Services/           — Business logic tests
│   ├── Models/             — Model scope, accessor, mutator tests
│   └── Helpers/            — Utility function tests
├── Feature/
│   ├── Api/                — HTTP endpoint tests
│   ├── MultiTenant/        — Cross-branch isolation tests
│   └── Workflows/          — Multi-step business process tests
├── E2E/
│   ├── cypress/e2e/        — Cypress specs
│   └── playwright/         — Playwright specs
├── Factories/              — Shared factory definitions
├── Fixtures/               — Static test data (JSON, CSV)
└── Pest.php                — Global test configuration
```

### Naming Conventions

```php
// Test files: {Subject}Test.php
InvoiceServiceTest.php
CustomerApiTest.php

// Pest describe blocks: class or feature name
describe('InvoiceService', function () { ... });

// Test names: "it {does expected behavior}"
it('creates an invoice with correct totals');
it('prevents cross-branch data access');
it('returns 422 when required fields are missing');

// Bug regressions: include ticket reference
it('calculates tax for exempt items correctly (fixes #167)');
```

## 2. PHPUnit/Pest Patterns

### Describe/It Blocks with Pest

```php
// tests/Unit/Services/PayrollServiceTest.php
use App\Services\PayrollService;
use App\Models\{Employee, Branch, SalaryComponent};

describe('PayrollService', function () {
    beforeEach(function () {
        $this->branch = Branch::factory()->create();
        $this->user = User::factory()->for($this->branch)->create();
        $this->actingAs($this->user);
        $this->service = app(PayrollService::class);
    });

    describe('calculateSalary', function () {
        it('sums basic pay and allowances', function () {
            $employee = Employee::factory()
                ->has(SalaryComponent::factory()->state(['type' => 'basic', 'amount' => 5000]))
                ->has(SalaryComponent::factory()->state(['type' => 'housing', 'amount' => 1500]))
                ->create(['branch_id' => $this->branch->id]);

            $result = $this->service->calculateSalary($employee, '2026-03');

            expect($result->gross)->toBe(6500.0);
        });

        it('applies deductions correctly', function () {
            $employee = Employee::factory()
                ->has(SalaryComponent::factory()->state(['type' => 'basic', 'amount' => 5000]))
                ->has(SalaryComponent::factory()->state(['type' => 'tax', 'amount' => -500]))
                ->create(['branch_id' => $this->branch->id]);

            $result = $this->service->calculateSalary($employee, '2026-03');

            expect($result)
                ->gross->toBe(5000.0)
                ->deductions->toBe(500.0)
                ->net->toBe(4500.0);
        });
    });
});
```

### Datasets (Parameterized Tests)

```php
it('validates invoice status transitions', function (string $from, string $to, bool $allowed) {
    $invoice = Invoice::factory()->create(['status' => $from, 'branch_id' => $this->branch->id]);

    if ($allowed) {
        expect(fn () => $invoice->transitionTo($to))->not->toThrow(Exception::class);
        expect($invoice->fresh()->status)->toBe($to);
    } else {
        expect(fn () => $invoice->transitionTo($to))->toThrow(InvalidStatusTransition::class);
    }
})->with([
    'draft to sent'       => ['draft', 'sent', true],
    'sent to paid'        => ['sent', 'paid', true],
    'draft to paid'       => ['draft', 'paid', false],
    'paid to draft'       => ['paid', 'draft', false],
    'sent to cancelled'   => ['sent', 'cancelled', true],
    'paid to cancelled'   => ['paid', 'cancelled', false],
]);
```

### Custom Expectations

```php
// tests/Pest.php
expect()->extend('toBeValidMoney', function () {
    return $this
        ->toBeFloat()
        ->toBeGreaterThanOrEqual(0)
        ->and(round($this->value, 2))->toBe($this->value);
});

// Usage
expect($invoice->total)->toBeValidMoney();
```

## 3. Feature Tests (API)

### HTTP Test Helpers

```php
describe('POST /api/v1/invoices', function () {
    beforeEach(function () {
        $this->branch = Branch::factory()->create();
        $this->user = User::factory()->for($this->branch)->create();
        $this->actingAs($this->user);
    });

    it('creates an invoice and returns 201', function () {
        $customer = Customer::factory()->create(['branch_id' => $this->branch->id]);
        $product = Product::factory()->create(['branch_id' => $this->branch->id, 'price' => 100]);

        $response = $this->postJson('/api/v1/invoices', [
            'customer_id' => $customer->id,
            'date' => '2026-03-06',
            'due_date' => '2026-04-05',
            'items' => [
                ['product_id' => $product->id, 'quantity' => 3, 'price' => 100],
            ],
        ]);

        $response
            ->assertCreated()
            ->assertJsonStructure(['data' => ['id', 'invoice_number', 'total', 'status']])
            ->assertJsonPath('data.total', 315.0)  // 300 + 5% tax
            ->assertJsonPath('data.status', 'draft');
    });

    it('returns 422 with validation errors', function () {
        $response = $this->postJson('/api/v1/invoices', []);

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['customer_id', 'date', 'due_date', 'items']);
    });

    it('returns 401 for unauthenticated requests', function () {
        $this->withoutMiddleware([]); // reset auth
        $this->postJson('/api/v1/invoices', [])->assertUnauthorized();
    });

    it('returns 403 for users without create permission', function () {
        $viewer = User::factory()->for($this->branch)->create();
        $viewer->assignRole('viewer');
        $this->actingAs($viewer);

        $this->postJson('/api/v1/invoices', [])->assertForbidden();
    });
});
```

### File Upload Testing

```php
it('attaches a document to an invoice', function () {
    Storage::fake('s3');
    $invoice = Invoice::factory()->create(['branch_id' => $this->branch->id]);
    $file = UploadedFile::fake()->create('receipt.pdf', 500, 'application/pdf');

    $response = $this->postJson("/api/v1/invoices/{$invoice->id}/attachments", [
        'file' => $file,
    ]);

    $response->assertCreated();
    Storage::disk('s3')->assertExists("invoices/{$invoice->id}/receipt.pdf");
});
```

## 4. Model Factories

### Factory with States and Sequences

```php
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
            'subtotal' => 0,
            'tax' => 0,
            'total' => 0,
        ];
    }

    public function paid(): static
    {
        return $this->state(fn () => [
            'status' => 'paid',
            'paid_at' => now(),
        ]);
    }

    public function overdue(): static
    {
        return $this->state(fn () => [
            'status' => 'unpaid',
            'due_date' => now()->subDays(30),
        ]);
    }

    public function withItems(int $count = 3): static
    {
        return $this->afterCreating(function (Invoice $invoice) use ($count) {
            InvoiceItem::factory()->count($count)->create([
                'invoice_id' => $invoice->id,
            ]);
            $invoice->recalculateTotals();
        });
    }

    public function forBranch(Branch $branch): static
    {
        return $this->state(fn () => ['branch_id' => $branch->id])
            ->for(Customer::factory()->state(['branch_id' => $branch->id]), 'customer');
    }
}
```

### Relationship Chaining

```php
// Create a fully populated invoice in one call
$invoice = Invoice::factory()
    ->forBranch($branch)
    ->withItems(5)
    ->paid()
    ->create();

// Create multiple invoices with shared customer
$customer = Customer::factory()->create(['branch_id' => $branch->id]);
Invoice::factory()
    ->count(10)
    ->for($customer)
    ->sequence(
        ['status' => 'paid'],
        ['status' => 'unpaid'],
    )
    ->create(['branch_id' => $branch->id]);
```

## 5. Mocking

### Mocking External Services

```php
it('sends invoice via email using mail service', function () {
    Mail::fake();
    $invoice = Invoice::factory()->create(['branch_id' => $this->branch->id]);

    $this->postJson("/api/v1/invoices/{$invoice->id}/send");

    Mail::assertSent(InvoiceMail::class, function ($mail) use ($invoice) {
        return $mail->hasTo($invoice->customer->email)
            && $mail->invoice->id === $invoice->id;
    });
});

it('dispatches PDF generation job', function () {
    Queue::fake();
    $invoice = Invoice::factory()->create(['branch_id' => $this->branch->id]);

    $this->postJson("/api/v1/invoices/{$invoice->id}/generate-pdf");

    Queue::assertPushed(GenerateInvoicePdf::class, fn ($job) =>
        $job->invoice->id === $invoice->id
    );
});
```

### Faking Third-Party APIs

```php
it('fetches exchange rate from provider', function () {
    Http::fake([
        'api.exchangerate.com/*' => Http::response([
            'rates' => ['AED' => 3.67, 'EUR' => 0.92],
        ], 200),
    ]);

    $rate = app(CurrencyService::class)->getRate('USD', 'AED');

    expect($rate)->toBe(3.67);
    Http::assertSent(fn ($request) =>
        str_contains($request->url(), 'api.exchangerate.com')
    );
});
```

### Spies for Side-Effect Verification

```php
it('logs audit trail on invoice deletion', function () {
    $spy = Mockery::spy(AuditLogger::class);
    $this->app->instance(AuditLogger::class, $spy);

    $invoice = Invoice::factory()->create(['branch_id' => $this->branch->id]);
    $this->deleteJson("/api/v1/invoices/{$invoice->id}");

    $spy->shouldHaveReceived('log')
        ->with('invoice.deleted', Mockery::on(fn ($data) =>
            $data['invoice_id'] === $invoice->id
        ))
        ->once();
});
```

## 6. Database Testing

### RefreshDatabase and Transactions

```php
// tests/Pest.php — global configuration
uses(Tests\TestCase::class, RefreshDatabase::class)->in('Feature');
uses(Tests\TestCase::class)->in('Unit');
```

### Database Assertions

```php
it('soft-deletes an invoice', function () {
    $invoice = Invoice::factory()->create(['branch_id' => $this->branch->id]);

    $this->deleteJson("/api/v1/invoices/{$invoice->id}")->assertNoContent();

    $this->assertSoftDeleted('invoices', ['id' => $invoice->id]);
    $this->assertDatabaseHas('invoices', [
        'id' => $invoice->id,
        'branch_id' => $this->branch->id,
    ]);
});

it('cascades deletion to invoice items', function () {
    $invoice = Invoice::factory()->withItems(3)->create(['branch_id' => $this->branch->id]);
    $itemIds = $invoice->items->pluck('id');

    $invoice->forceDelete();

    $itemIds->each(fn ($id) =>
        $this->assertDatabaseMissing('invoice_items', ['id' => $id])
    );
});
```

### Migration Testing

```php
it('runs up and down for add_tax_exempt_column migration', function () {
    Artisan::call('migrate', ['--path' => 'database/migrations/2026_03_06_add_tax_exempt_to_products.php']);
    expect(Schema::hasColumn('products', 'tax_exempt'))->toBeTrue();

    Artisan::call('migrate:rollback', ['--step' => 1]);
    expect(Schema::hasColumn('products', 'tax_exempt'))->toBeFalse();
});
```

## 7. Multi-Tenant Test Isolation

### Cross-Branch Prevention (Required for Every Feature)

```php
describe('Multi-Tenant Isolation', function () {
    beforeEach(function () {
        $this->branchA = Branch::factory()->create();
        $this->branchB = Branch::factory()->create();
        $this->userA = User::factory()->for($this->branchA)->create();
        $this->userB = User::factory()->for($this->branchB)->create();
    });

    it('scopes index to current branch', function () {
        Invoice::factory()->count(5)->create(['branch_id' => $this->branchA->id]);
        Invoice::factory()->count(3)->create(['branch_id' => $this->branchB->id]);

        $this->actingAs($this->userA);
        $response = $this->getJson('/api/v1/invoices');
        $response->assertJsonCount(5, 'data');

        $this->actingAs($this->userB);
        $response = $this->getJson('/api/v1/invoices');
        $response->assertJsonCount(3, 'data');
    });

    it('returns 404 when accessing another branch resource', function () {
        $invoiceA = Invoice::factory()->create(['branch_id' => $this->branchA->id]);

        $this->actingAs($this->userB);
        $this->getJson("/api/v1/invoices/{$invoiceA->id}")->assertNotFound();
        $this->putJson("/api/v1/invoices/{$invoiceA->id}", [])->assertNotFound();
        $this->deleteJson("/api/v1/invoices/{$invoiceA->id}")->assertNotFound();
    });

    it('cannot reassign a record to another branch', function () {
        $this->actingAs($this->userA);
        $invoice = Invoice::factory()->create(['branch_id' => $this->branchA->id]);

        $response = $this->putJson("/api/v1/invoices/{$invoice->id}", [
            'branch_id' => $this->branchB->id,
        ]);

        // branch_id should be immutable or ignored in update
        expect($invoice->fresh()->branch_id)->toBe($this->branchA->id);
    });

    it('scopes relationship queries to current branch', function () {
        $customerA = Customer::factory()->create(['branch_id' => $this->branchA->id]);
        $customerB = Customer::factory()->create(['branch_id' => $this->branchB->id]);

        $this->actingAs($this->userA);
        $response = $this->getJson('/api/v1/customers');
        $ids = collect($response->json('data'))->pluck('id');

        expect($ids)->toContain($customerA->id)->not->toContain($customerB->id);
    });
});
```

### Reusable Isolation Trait

```php
// tests/Traits/TestsMultiTenantIsolation.php
trait TestsMultiTenantIsolation
{
    protected function assertBranchIsolation(string $endpoint, string $factoryClass): void
    {
        $branchA = Branch::factory()->create();
        $branchB = Branch::factory()->create();
        $recordA = $factoryClass::factory()->create(['branch_id' => $branchA->id]);

        $this->actingAs(User::factory()->for($branchB)->create());
        $this->getJson("{$endpoint}/{$recordA->id}")->assertNotFound();
    }
}
```

## 8. Vitest (Frontend)

### Component Testing

```typescript
// tests/components/InvoiceForm.test.ts
import { mount } from '@vue/test-utils';
import { describe, it, expect, vi } from 'vitest';
import InvoiceForm from '@/components/InvoiceForm.vue';
import { createTestingPinia } from '@pinia/testing';

describe('InvoiceForm', () => {
  const mountForm = (props = {}) => mount(InvoiceForm, {
    props: { customerId: 1, ...props },
    global: {
      plugins: [createTestingPinia({ createSpy: vi.fn })],
    },
  });

  it('renders empty form with add-item button', () => {
    const wrapper = mountForm();
    expect(wrapper.find('[data-testid="add-item"]').exists()).toBe(true);
    expect(wrapper.findAll('[data-testid="line-item"]')).toHaveLength(0);
  });

  it('adds a line item when button is clicked', async () => {
    const wrapper = mountForm();
    await wrapper.find('[data-testid="add-item"]').trigger('click');
    expect(wrapper.findAll('[data-testid="line-item"]')).toHaveLength(1);
  });

  it('computes totals reactively', async () => {
    const wrapper = mountForm();
    await wrapper.find('[data-testid="add-item"]').trigger('click');
    await wrapper.find('[data-testid="quantity-0"]').setValue(3);
    await wrapper.find('[data-testid="price-0"]').setValue(100);

    expect(wrapper.find('[data-testid="subtotal"]').text()).toContain('300.00');
  });

  it('emits submit event with form data', async () => {
    const wrapper = mountForm();
    await wrapper.find('[data-testid="add-item"]').trigger('click');
    await wrapper.find('[data-testid="quantity-0"]').setValue(1);
    await wrapper.find('[data-testid="price-0"]').setValue(50);
    await wrapper.find('form').trigger('submit');

    expect(wrapper.emitted('submit')).toHaveLength(1);
    expect(wrapper.emitted('submit')[0][0].items).toHaveLength(1);
  });
});
```

### Composable Testing

```typescript
// tests/composables/usePagination.test.ts
import { describe, it, expect } from 'vitest';
import { usePagination } from '@/composables/usePagination';

describe('usePagination', () => {
  it('starts at page 1', () => {
    const { currentPage } = usePagination({ perPage: 10 });
    expect(currentPage.value).toBe(1);
  });

  it('calculates total pages', () => {
    const { totalPages, setTotal } = usePagination({ perPage: 10 });
    setTotal(45);
    expect(totalPages.value).toBe(5);
  });

  it('clamps page within bounds', () => {
    const { currentPage, setTotal, goToPage } = usePagination({ perPage: 10 });
    setTotal(30);
    goToPage(99);
    expect(currentPage.value).toBe(3);
  });
});
```

### Mocking API Calls in Vitest

```typescript
import { vi } from 'vitest';
import { api } from '@/services/api';

vi.mock('@/services/api', () => ({
  api: {
    get: vi.fn(),
    post: vi.fn(),
  },
}));

it('fetches invoices on mount', async () => {
  vi.mocked(api.get).mockResolvedValue({
    data: { data: [{ id: 1, total: 100 }], meta: { total: 1 } },
  });

  const wrapper = mount(InvoiceList);
  await flushPromises();

  expect(api.get).toHaveBeenCalledWith('/api/v1/invoices', expect.any(Object));
  expect(wrapper.findAll('[data-testid="invoice-row"]')).toHaveLength(1);
});
```

## 9. Cypress E2E

### Page Object Pattern

```typescript
// cypress/support/pages/InvoicePage.ts
export class InvoicePage {
  visit()            { cy.visit('/invoices'); }
  clickNew()         { cy.get('[data-cy="new-invoice"]').click(); }
  selectCustomer(n: string) {
    cy.get('[data-cy="customer-select"]').click();
    cy.get('[data-cy="customer-option"]').contains(n).click();
  }
  addItem(product: string, qty: number) {
    cy.get('[data-cy="add-item"]').click();
    cy.get('[data-cy="product-search"]').last().type(product);
    cy.get('[data-cy="product-option"]').first().click();
    cy.get('[data-cy="quantity"]').last().clear().type(String(qty));
  }
  save()             { cy.get('[data-cy="save-btn"]').click(); }
  getTotal()         { return cy.get('[data-cy="total"]'); }
  getStatus()        { return cy.get('[data-cy="status-badge"]'); }
}
```

### Custom Commands

```typescript
// cypress/support/commands.ts
Cypress.Commands.add('login', (email: string, password = 'password') => {
  cy.session(email, () => {
    cy.request('POST', '/api/v1/login', { email, password }).then((resp) => {
      window.localStorage.setItem('token', resp.body.token);
    });
  });
});

Cypress.Commands.add('createInvoice', (overrides = {}) => {
  return cy.request({
    method: 'POST',
    url: '/api/v1/invoices',
    body: { customer_id: 1, date: '2026-03-06', due_date: '2026-04-05', items: [], ...overrides },
    headers: { Authorization: `Bearer ${localStorage.getItem('token')}` },
  });
});
```

### API Stubbing for Isolation

```typescript
it('displays empty state when no invoices exist', () => {
  cy.intercept('GET', '/api/v1/invoices*', { data: [], meta: { total: 0 } }).as('getInvoices');
  cy.visit('/invoices');
  cy.wait('@getInvoices');
  cy.get('[data-cy="empty-state"]').should('be.visible');
});
```

## 10. Playwright E2E

### Fixtures and Locators

```typescript
// tests/e2e/fixtures.ts
import { test as base, expect } from '@playwright/test';

type Fixtures = { invoicePage: InvoicePage };

export const test = base.extend<Fixtures>({
  invoicePage: async ({ page }, use) => {
    await use(new InvoicePage(page));
  },
});

class InvoicePage {
  constructor(private page: Page) {}

  readonly customerSelect = this.page.getByTestId('customer-select');
  readonly addItemBtn     = this.page.getByTestId('add-item');
  readonly saveBtn        = this.page.getByTestId('save-btn');
  readonly total          = this.page.getByTestId('total');

  async goto() { await this.page.goto('/invoices'); }
  async create(customer: string) {
    await this.page.getByTestId('new-invoice').click();
    await this.customerSelect.click();
    await this.page.getByText(customer).click();
  }
}
```

### Parallel Execution and Trace

```typescript
// playwright.config.ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  workers: process.env.CI ? 2 : 4,
  retries: process.env.CI ? 2 : 0,
  use: {
    baseURL: 'http://localhost:8000',
    trace: 'on-first-retry',         // capture trace on failure
    screenshot: 'only-on-failure',
  },
  projects: [
    { name: 'chromium', use: { browserName: 'chromium' } },
    { name: 'firefox',  use: { browserName: 'firefox' } },
  ],
});
```

## 11. Test Data Management

### Factory-First Principle

Never hardcode IDs or rely on seeders in tests. Every test creates its own data.

```php
// WRONG
$this->getJson('/api/v1/invoices/1')->assertOk();

// CORRECT
$invoice = Invoice::factory()->create(['branch_id' => $this->branch->id]);
$this->getJson("/api/v1/invoices/{$invoice->id}")->assertOk();
```

### Database Snapshots for Slow Setup

```php
// tests/TestCase.php — for suites with expensive setup
protected static bool $seeded = false;

protected function setUp(): void
{
    parent::setUp();
    if (! static::$seeded) {
        $this->artisan('db:seed', ['--class' => 'TestDatabaseSeeder']);
        static::$seeded = true;
    }
}
```

### Isolation Checklist

- Each test is independent; no shared mutable state.
- `RefreshDatabase` or transactions roll back after each test.
- Faked services (Mail, Queue, Storage, Http) reset per test.
- Time-dependent tests use `Carbon::setTestNow()` and reset in `tearDown`.

## 12. CI Integration

### Parallel Test Execution (GitHub Actions)

```yaml
# .github/workflows/tests.yml
name: Tests
on: [push, pull_request]

jobs:
  backend:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_DB: testing
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
        ports: ['5432:5432']
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    steps:
      - uses: actions/checkout@v4
      - uses: shivammathur/setup-php@v2
        with: { php-version: '8.3', coverage: xdebug }
      - run: composer install --no-interaction
      - run: php artisan test --parallel --processes=4 --coverage-clover=coverage.xml
      - uses: codecov/codecov-action@v4
        with: { files: coverage.xml }

  frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci
      - run: npx vitest run --coverage --reporter=junit --outputFile=results.xml

  e2e:
    runs-on: ubuntu-latest
    needs: [backend, frontend]
    steps:
      - uses: actions/checkout@v4
      - run: docker compose -f docker-compose.test.yml up -d
      - uses: cypress-io/github-action@v6
        with:
          wait-on: 'http://localhost:8000/api/health'
          wait-on-timeout: 120
```

### Flaky Test Detection

```yaml
# Add retry with annotation for known flaky tests
- run: php artisan test --parallel --retry=2
- name: Report flaky tests
  if: failure()
  run: |
    echo "::warning::Tests required retries. Check for flaky tests."
    grep -r "@flaky" tests/ || true
```

### Coverage Thresholds

```yaml
# Fail CI if coverage drops below threshold
- run: |
    COVERAGE=$(php artisan test --coverage-min=80 2>&1 | tail -1)
    echo "$COVERAGE"
```

## 13. Performance Testing

### k6 Load Test Script

```javascript
// tests/performance/api-load.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '1m', target: 50 },    // ramp up
    { duration: '3m', target: 50 },    // steady
    { duration: '1m', target: 200 },   // spike
    { duration: '2m', target: 50 },    // recover
    { duration: '30s', target: 0 },    // ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1000'],
    http_req_failed: ['rate<0.01'],
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8000';
const TOKEN = __ENV.API_TOKEN;

export default function () {
  const headers = { Authorization: `Bearer ${TOKEN}`, 'Content-Type': 'application/json' };

  // List invoices
  const list = http.get(`${BASE_URL}/api/v1/invoices?per_page=25`, { headers });
  check(list, {
    'list status 200': (r) => r.status === 200,
    'list latency < 300ms': (r) => r.timings.duration < 300,
    'list has data': (r) => JSON.parse(r.body).data.length > 0,
  });

  sleep(1);

  // Create invoice
  const payload = JSON.stringify({
    customer_id: 1,
    date: '2026-03-06',
    due_date: '2026-04-05',
    items: [{ product_id: 1, quantity: 1, price: 100 }],
  });
  const create = http.post(`${BASE_URL}/api/v1/invoices`, payload, { headers });
  check(create, {
    'create status 201': (r) => r.status === 201,
    'create latency < 1s': (r) => r.timings.duration < 1000,
  });

  sleep(1);
}
```

## 14. Contract Testing

### API Schema Validation

```php
it('conforms to the invoice response contract', function () {
    $invoice = Invoice::factory()->withItems(2)->create(['branch_id' => $this->branch->id]);

    $response = $this->getJson("/api/v1/invoices/{$invoice->id}");

    $response->assertOk()->assertJsonStructure([
        'data' => [
            'id',
            'invoice_number',
            'date',
            'due_date',
            'status',
            'subtotal',
            'tax',
            'total',
            'customer' => ['id', 'name'],
            'items' => [['id', 'product_id', 'quantity', 'price', 'amount']],
            'created_at',
            'updated_at',
        ],
    ]);

    // Type assertions
    $data = $response->json('data');
    expect($data['id'])->toBeInt();
    expect($data['total'])->toBeFloat();
    expect($data['status'])->toBeIn(['draft', 'sent', 'paid', 'cancelled']);
    expect($data['items'])->toBeArray()->not->toBeEmpty();
});
```

### Consumer-Driven Contracts (Pact)

```typescript
// tests/contract/invoice-consumer.pact.ts
import { PactV3, MatchersV3 } from '@pact-foundation/pact';
const { like, eachLike, integer, decimal, string } = MatchersV3;

const provider = new PactV3({ consumer: 'frontend', provider: 'invoice-api' });

describe('Invoice API Contract', () => {
  it('returns a list of invoices', async () => {
    await provider
      .given('invoices exist')
      .uponReceiving('a request for invoices')
      .withRequest({ method: 'GET', path: '/api/v1/invoices' })
      .willRespondWith({
        status: 200,
        body: {
          data: eachLike({
            id: integer(1),
            invoice_number: string('INV-0001'),
            total: decimal(315.0),
            status: string('draft'),
          }),
          meta: like({ total: integer(10) }),
        },
      })
      .executeTest(async (mockServer) => {
        const response = await fetch(`${mockServer.url}/api/v1/invoices`);
        const body = await response.json();
        expect(body.data).toHaveLength(1);
        expect(body.data[0]).toHaveProperty('id');
        expect(body.data[0]).toHaveProperty('total');
      });
  });
});
```

## Quick Reference: Test Commands

```bash
# Backend
php artisan test                              # run all tests
php artisan test --parallel --processes=4      # parallel execution
php artisan test --filter=InvoiceService       # filter by name
php artisan test --coverage --min=80           # with coverage gate

# Frontend
npx vitest run                                # run all vitest tests
npx vitest run --coverage                     # with coverage
npx vitest watch                              # watch mode

# E2E
npx cypress run                               # headless Cypress
npx cypress open                              # interactive Cypress
npx playwright test                           # headless Playwright
npx playwright test --trace on                # with trace capture
npx playwright show-report                    # view HTML report

# Performance
k6 run tests/performance/api-load.js          # run load test
k6 run --env BASE_URL=https://staging.example.com tests/performance/api-load.js
```
