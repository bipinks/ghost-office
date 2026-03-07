---
name: api-design
description: Use when designing or implementing REST APIs. Covers RESTful conventions, versioning, pagination, filtering, error handling, rate limiting, HATEOAS, OpenAPI documentation, and API security best practices.
user-invocable: false
allowed-tools: ["Read", "Write", "Bash", "Grep", "Glob"]
---

# API Design Skill

Comprehensive patterns for designing, implementing, and maintaining REST APIs in Laravel and general backend applications.

---

## 1. RESTful Resource Design

### URL Structure
```
GET    /api/v1/invoices              # List invoices
POST   /api/v1/invoices              # Create invoice
GET    /api/v1/invoices/{id}         # Get single invoice
PUT    /api/v1/invoices/{id}         # Full update
PATCH  /api/v1/invoices/{id}         # Partial update
DELETE /api/v1/invoices/{id}         # Soft delete

# Nested resources (one level deep max)
GET    /api/v1/invoices/{id}/items   # List invoice items
POST   /api/v1/invoices/{id}/items   # Add item to invoice

# Actions that don't map to CRUD
POST   /api/v1/invoices/{id}/send    # Send invoice to customer
POST   /api/v1/invoices/{id}/void    # Void an invoice
```

### Naming Conventions
- Use **plural nouns** for resources: `/invoices`, `/customers`, `/products`
- Use **kebab-case** for multi-word: `/sales-orders`, `/purchase-requests`
- Never use verbs in URLs (use HTTP methods instead)
- Keep nesting to one level: `/invoices/{id}/items` not `/customers/{id}/invoices/{id}/items`

### HTTP Status Codes
```php
// Success
200 OK              // GET, PUT, PATCH success
201 Created          // POST success (include Location header)
204 No Content       // DELETE success

// Client errors
400 Bad Request      // Malformed request syntax
401 Unauthorized     // Missing or invalid authentication
403 Forbidden        // Authenticated but not authorized
404 Not Found        // Resource does not exist
409 Conflict         // Duplicate entry, state conflict
422 Unprocessable    // Validation errors (Laravel default)
429 Too Many Requests // Rate limit exceeded

// Server errors
500 Internal Server  // Unexpected server error
503 Service Unavail  // Maintenance or overload
```

---

## 2. Response Envelope

### Single Resource
```json
{
  "data": {
    "id": 1,
    "type": "invoice",
    "invoice_number": "INV-DXB-2026-00001",
    "customer_id": 42,
    "total": 1500.00,
    "status": "unpaid",
    "created_at": "2026-03-07T10:30:00Z",
    "updated_at": "2026-03-07T10:30:00Z"
  }
}
```

### Collection
```json
{
  "data": [
    { "id": 1, "invoice_number": "INV-DXB-2026-00001" },
    { "id": 2, "invoice_number": "INV-DXB-2026-00002" }
  ],
  "meta": {
    "total": 150,
    "per_page": 25,
    "current_page": 1,
    "last_page": 6
  },
  "links": {
    "first": "/api/v1/invoices?page=1",
    "last": "/api/v1/invoices?page=6",
    "prev": null,
    "next": "/api/v1/invoices?page=2"
  }
}
```

### Laravel API Resource
```php
class InvoiceResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'type' => 'invoice',
            'invoice_number' => $this->invoice_number,
            'customer' => new CustomerResource($this->whenLoaded('customer')),
            'items' => InvoiceItemResource::collection($this->whenLoaded('items')),
            'total' => (float) $this->total,
            'status' => $this->status,
            'created_at' => $this->created_at->toIso8601String(),
            'updated_at' => $this->updated_at->toIso8601String(),
        ];
    }
}
```

---

## 3. Pagination

### Cursor-Based (Recommended for Large Datasets)
```php
// Controller
public function index(Request $request)
{
    $invoices = Invoice::orderBy('id')
        ->cursorPaginate($request->input('per_page', 25));

    return InvoiceResource::collection($invoices);
}

// Response meta
// "meta": { "per_page": 25, "next_cursor": "eyJpZCI6MjV9", "prev_cursor": null }
```

### Offset-Based (Simpler, Fine for Small Datasets)
```php
$invoices = Invoice::paginate($request->input('per_page', 25));
return InvoiceResource::collection($invoices);
```

### Rules
- Default `per_page` = 25, max = 100
- Always validate per_page: `'per_page' => 'integer|min:1|max:100'`
- Cursor pagination prevents skipping and is stable under inserts/deletes
- Include total count only when needed (expensive on large tables)

---

## 4. Filtering and Sorting

### Query Parameter Conventions
```
GET /api/v1/invoices?filter[status]=unpaid&filter[customer_id]=42
GET /api/v1/invoices?sort=-date,invoice_number
GET /api/v1/invoices?include=customer,items
GET /api/v1/invoices?fields[invoices]=id,invoice_number,total
```

### Spatie QueryBuilder Pattern
```php
use Spatie\QueryBuilder\QueryBuilder;
use Spatie\QueryBuilder\AllowedFilter;

public function index()
{
    $invoices = QueryBuilder::for(Invoice::class)
        ->allowedFilters([
            AllowedFilter::exact('status'),
            AllowedFilter::exact('customer_id'),
            AllowedFilter::scope('overdue'),
            AllowedFilter::partial('invoice_number'),
            AllowedFilter::callback('date_from', fn ($query, $value) =>
                $query->where('date', '>=', $value)
            ),
        ])
        ->allowedSorts(['date', 'total', 'invoice_number', 'created_at'])
        ->allowedIncludes(['customer', 'items', 'payments'])
        ->defaultSort('-created_at')
        ->paginate(request('per_page', 25));

    return InvoiceResource::collection($invoices);
}
```

### Sort Prefix Convention
- Ascending: `?sort=date`
- Descending: `?sort=-date` (dash prefix)
- Multiple: `?sort=-date,invoice_number`

---

## 5. Error Handling

### Standard Error Format
```json
{
  "message": "The given data was invalid.",
  "errors": {
    "customer_id": ["The customer id field is required."],
    "items": ["The items field must have at least 1 item."]
  }
}
```

### Single Error (Non-Validation)
```json
{
  "message": "Invoice not found.",
  "error": {
    "code": "INVOICE_NOT_FOUND",
    "detail": "No invoice exists with ID 999."
  }
}
```

### Custom Exception Handler
```php
// app/Exceptions/Handler.php
public function render($request, Throwable $e)
{
    if ($e instanceof ModelNotFoundException) {
        $model = class_basename($e->getModel());
        return response()->json([
            'message' => "{$model} not found.",
        ], 404);
    }

    if ($e instanceof AuthorizationException) {
        return response()->json([
            'message' => 'You are not authorized to perform this action.',
        ], 403);
    }

    if ($e instanceof ThrottleRequestsException) {
        return response()->json([
            'message' => 'Too many requests. Please try again later.',
        ], 429);
    }

    return parent::render($request, $e);
}
```

---

## 6. API Versioning

### URL Prefix Strategy (Recommended)
```php
// routes/api.php
Route::prefix('v1')->group(function () {
    Route::apiResource('invoices', V1\InvoiceController::class);
});

Route::prefix('v2')->group(function () {
    Route::apiResource('invoices', V2\InvoiceController::class);
});
```

### Deprecation Headers
```php
// Middleware for deprecated versions
class DeprecatedApiVersion
{
    public function handle(Request $request, Closure $next, string $sunset)
    {
        $response = $next($request);
        $response->headers->set('Deprecation', 'true');
        $response->headers->set('Sunset', $sunset);
        $response->headers->set('Link', '</api/v2>; rel="successor-version"');
        return $response;
    }
}
```

### Versioning Rules
- Never break existing clients without a version bump
- Support old versions for minimum 6 months after deprecation notice
- Use `Sunset` header to communicate retirement date
- Document all breaking changes in the changelog

---

## 7. Rate Limiting

### Laravel Throttle Configuration
```php
// app/Providers/RouteServiceProvider.php
RateLimiter::for('api', function (Request $request) {
    return Limit::perMinute(60)->by($request->user()?->id ?: $request->ip());
});

RateLimiter::for('uploads', function (Request $request) {
    return Limit::perMinute(10)->by($request->user()->id);
});
```

### Response Headers
```
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1709800000
Retry-After: 30          # Only on 429 responses
```

### Route-Level Throttling
```php
Route::middleware('throttle:uploads')->group(function () {
    Route::post('/invoices/{id}/attachments', [AttachmentController::class, 'store']);
});
```

---

## 8. Authentication

### Bearer Token (Laravel Sanctum)
```php
// Login and issue token
public function login(LoginRequest $request): JsonResponse
{
    $user = User::where('email', $request->email)->first();

    if (!$user || !Hash::check($request->password, $user->password)) {
        return response()->json(['message' => 'Invalid credentials.'], 401);
    }

    $token = $user->createToken('api', ['invoices:read', 'invoices:write']);

    return response()->json([
        'data' => [
            'token' => $token->plainTextToken,
            'expires_at' => now()->addHours(24)->toIso8601String(),
        ],
    ]);
}

// Protect routes
Route::middleware('auth:sanctum')->group(function () {
    Route::apiResource('invoices', InvoiceController::class);
});

// Check abilities in controller
if ($request->user()->tokenCan('invoices:write')) { /* ... */ }
```

### SPA Cookie Authentication (Sanctum)
```php
// Stateful domains in config/sanctum.php
'stateful' => ['spa.example.com', 'localhost:3000'],

// SPA must call /sanctum/csrf-cookie first, then /login
```

---

## 9. CORS Configuration

```php
// config/cors.php
return [
    'paths' => ['api/*', 'sanctum/csrf-cookie'],
    'allowed_methods' => ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    'allowed_origins' => [env('FRONTEND_URL', 'http://localhost:3000')],
    'allowed_headers' => ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept'],
    'exposed_headers' => ['X-RateLimit-Limit', 'X-RateLimit-Remaining'],
    'max_age' => 86400,
    'supports_credentials' => true,
];
```

---

## 10. OpenAPI / Swagger Documentation

### Annotation-Based (L5-Swagger)
```php
/**
 * @OA\Get(
 *     path="/api/v1/invoices",
 *     summary="List invoices",
 *     tags={"Invoices"},
 *     security={{"sanctum":{}}},
 *     @OA\Parameter(name="filter[status]", in="query", @OA\Schema(type="string", enum={"paid","unpaid","overdue"})),
 *     @OA\Parameter(name="per_page", in="query", @OA\Schema(type="integer", default=25)),
 *     @OA\Response(response=200, description="Paginated invoice list",
 *         @OA\JsonContent(ref="#/components/schemas/InvoiceCollection")
 *     ),
 *     @OA\Response(response=401, description="Unauthenticated")
 * )
 */
public function index() { /* ... */ }
```

### Generate Documentation
```bash
php artisan l5-swagger:generate
# Accessible at /api/documentation
```

---

## 11. Bulk Operations

### Batch Create/Update
```php
// POST /api/v1/invoices/bulk
public function bulk(BulkInvoiceRequest $request, InvoiceService $service): JsonResponse
{
    $results = $service->bulkCreate($request->validated('items'));

    return response()->json([
        'data' => InvoiceResource::collection($results['created']),
        'meta' => [
            'total' => count($request->items),
            'created' => count($results['created']),
            'failed' => count($results['errors']),
        ],
        'errors' => $results['errors'],
    ], 207); // 207 Multi-Status for partial success
}
```

### Batch Delete
```php
// DELETE /api/v1/invoices/bulk
// Body: { "ids": [1, 2, 3] }
public function bulkDestroy(Request $request): JsonResponse
{
    $request->validate(['ids' => 'required|array|max:100', 'ids.*' => 'integer']);

    $deleted = Invoice::whereIn('id', $request->ids)->delete();

    return response()->json(['meta' => ['deleted' => $deleted]], 200);
}
```

---

## 12. File Upload API

### Multipart Upload
```php
// POST /api/v1/invoices/{id}/attachments
public function store(Request $request, Invoice $invoice): JsonResponse
{
    $request->validate([
        'file' => 'required|file|mimes:pdf,jpg,png|max:10240', // 10MB
        'description' => 'nullable|string|max:255',
    ]);

    $path = $request->file('file')->store("invoices/{$invoice->id}", 's3');

    $attachment = $invoice->attachments()->create([
        'branch_id' => auth()->user()->branch_id,
        'file_path' => $path,
        'file_name' => $request->file('file')->getClientOriginalName(),
        'file_size' => $request->file('file')->getSize(),
        'mime_type' => $request->file('file')->getMimeType(),
        'description' => $request->description,
    ]);

    return response()->json(['data' => new AttachmentResource($attachment)], 201);
}
```

### Presigned URL (Large Files)
```php
// POST /api/v1/uploads/presign
public function presign(Request $request): JsonResponse
{
    $request->validate(['filename' => 'required|string', 'content_type' => 'required|string']);

    $key = 'uploads/' . Str::uuid() . '/' . $request->filename;
    $url = Storage::disk('s3')->temporaryUrl($key, now()->addMinutes(15), [
        'Content-Type' => $request->content_type,
    ]);

    return response()->json(['data' => ['upload_url' => $url, 'key' => $key]], 200);
}
```

---

## 13. Webhooks

### Event Delivery
```php
class WebhookService
{
    public function dispatch(string $event, array $payload, string $webhookUrl): void
    {
        $body = json_encode(['event' => $event, 'data' => $payload, 'timestamp' => now()->toIso8601String()]);
        $signature = hash_hmac('sha256', $body, config('services.webhook.secret'));

        Http::withHeaders([
            'X-Webhook-Signature' => $signature,
            'X-Webhook-Event' => $event,
            'Content-Type' => 'application/json',
        ])->timeout(10)->post($webhookUrl, $payload);
    }
}
```

### Signature Verification (Receiver Side)
```php
public function handle(Request $request): JsonResponse
{
    $expectedSignature = hash_hmac('sha256', $request->getContent(), config('services.webhook.secret'));

    if (!hash_equals($expectedSignature, $request->header('X-Webhook-Signature', ''))) {
        return response()->json(['message' => 'Invalid signature.'], 401);
    }

    // Process webhook event
    WebhookJob::dispatch($request->input('event'), $request->all());

    return response()->json([], 200);
}
```

### Retry Logic
- Retry up to 5 times with exponential backoff (10s, 30s, 90s, 270s, 810s)
- Mark webhook as failed after all retries exhausted
- Log every attempt for debugging
- Provide a UI or endpoint for manual retry

---

## 14. API Testing

### Laravel Feature Tests
```php
class InvoiceApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_list_invoices_returns_paginated_results(): void
    {
        $user = User::factory()->create();
        Invoice::factory()->count(30)->create(['branch_id' => $user->branch_id]);

        $response = $this->actingAs($user)
            ->getJson('/api/v1/invoices?per_page=10');

        $response->assertOk()
            ->assertJsonCount(10, 'data')
            ->assertJsonStructure([
                'data' => [['id', 'invoice_number', 'total', 'status']],
                'meta' => ['total', 'per_page', 'current_page'],
                'links' => ['first', 'last', 'prev', 'next'],
            ]);
    }

    public function test_create_invoice_returns_201(): void
    {
        $user = User::factory()->create();
        $customer = Customer::factory()->create(['branch_id' => $user->branch_id]);

        $response = $this->actingAs($user)
            ->postJson('/api/v1/invoices', [
                'customer_id' => $customer->id,
                'date' => '2026-03-07',
                'due_date' => '2026-04-07',
                'items' => [
                    ['product_id' => 1, 'quantity' => 2, 'price' => 100.00],
                ],
            ]);

        $response->assertCreated()
            ->assertJsonPath('data.customer_id', $customer->id);
    }

    public function test_tenant_isolation_prevents_cross_branch_access(): void
    {
        $userA = User::factory()->create(['branch_id' => 1]);
        $userB = User::factory()->create(['branch_id' => 2]);
        $invoice = Invoice::factory()->create(['branch_id' => 1]);

        $this->actingAs($userB)
            ->getJson("/api/v1/invoices/{$invoice->id}")
            ->assertNotFound();
    }

    public function test_validation_errors_return_422(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user)
            ->postJson('/api/v1/invoices', [])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['customer_id', 'date', 'items']);
    }

    public function test_unauthenticated_request_returns_401(): void
    {
        $this->getJson('/api/v1/invoices')->assertUnauthorized();
    }
}
```

### Best Practices
- Test every endpoint for success, validation failure, auth failure, and tenant isolation
- Use factories for test data; never rely on database seeds
- Assert response structure, not just status codes
- Test rate limiting with multiple rapid requests
- Test pagination boundary conditions (empty, single page, multi-page)
- Use Postman or Bruno collections for manual exploratory testing
