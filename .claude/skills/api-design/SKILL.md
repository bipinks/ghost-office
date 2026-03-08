---
name: api-design
description: Use when designing or implementing REST APIs. Covers RESTful conventions, versioning, pagination, filtering, error handling, rate limiting, HATEOAS, OpenAPI documentation, and API security best practices.
user-invocable: false
allowed-tools: ["Read", "Write", "Bash", "Grep", "Glob"]
---

# API Design Skill

Patterns for REST APIs in Laravel and general backend applications.

## RESTful Resource Design

```
GET    /api/v1/invoices              # List (paginated)
POST   /api/v1/invoices              # Create
GET    /api/v1/invoices/{id}         # Get single
PUT    /api/v1/invoices/{id}         # Full update
PATCH  /api/v1/invoices/{id}         # Partial update
DELETE /api/v1/invoices/{id}         # Soft delete
GET    /api/v1/invoices/{id}/items   # Nested (one level max)
POST   /api/v1/invoices/{id}/send    # Non-CRUD action
```

**Conventions**: Plural nouns, kebab-case for multi-word, no verbs in URLs, max one nesting level.

### HTTP Status Codes
200 OK, 201 Created (+Location), 204 No Content (DELETE), 400 Bad Request, 401 Unauthorized, 403 Forbidden, 404 Not Found, 409 Conflict, 422 Validation (Laravel default), 429 Rate Limited, 500 Server Error, 503 Unavailable.

## Response Envelope

```php
// Laravel API Resource
class InvoiceResource extends JsonResource {
    public function toArray(Request $request): array {
        return [
            'id' => $this->id, 'type' => 'invoice',
            'invoice_number' => $this->invoice_number,
            'customer' => new CustomerResource($this->whenLoaded('customer')),
            'items' => InvoiceItemResource::collection($this->whenLoaded('items')),
            'total' => (float) $this->total, 'status' => $this->status,
            'created_at' => $this->created_at->toIso8601String(),
        ];
    }
}
// Single: { "data": { ... } }
// Collection: { "data": [...], "meta": { total, per_page, current_page }, "links": { first, last, prev, next } }
// Error: { "message": "...", "errors": { "field": ["..."] } }
```

## Pagination

**Cursor-based** (recommended for large datasets): stable under inserts/deletes, no total count overhead.
**Offset-based**: simpler, fine for small datasets with total count.

```php
// Cursor
$invoices = Invoice::orderBy('id')->cursorPaginate($request->input('per_page', 25));
// Offset
$invoices = Invoice::paginate($request->input('per_page', 25));
```

Default `per_page` = 25, max = 100. Always validate: `'per_page' => 'integer|min:1|max:100'`.

## Filtering and Sorting

```
GET /api/v1/invoices?filter[status]=unpaid&filter[customer_id]=42&sort=-date,invoice_number&include=customer,items
```

```php
use Spatie\QueryBuilder\{QueryBuilder, AllowedFilter};

$invoices = QueryBuilder::for(Invoice::class)
    ->allowedFilters([
        AllowedFilter::exact('status'), AllowedFilter::exact('customer_id'),
        AllowedFilter::scope('overdue'), AllowedFilter::partial('invoice_number'),
        AllowedFilter::callback('date_from', fn ($q, $v) => $q->where('date', '>=', $v)),
    ])
    ->allowedSorts(['date', 'total', 'invoice_number', 'created_at'])
    ->allowedIncludes(['customer', 'items', 'payments'])
    ->defaultSort('-created_at')
    ->paginate(request('per_page', 25));
```

Sort: `?sort=date` (asc), `?sort=-date` (desc), `?sort=-date,invoice_number` (multi).

## Error Handling

```php
public function render($request, Throwable $e) {
    if ($e instanceof ModelNotFoundException) {
        return response()->json(['message' => class_basename($e->getModel()) . ' not found.'], 404);
    }
    if ($e instanceof AuthorizationException) {
        return response()->json(['message' => 'Not authorized.'], 403);
    }
    if ($e instanceof ThrottleRequestsException) {
        return response()->json(['message' => 'Too many requests.'], 429);
    }
    return parent::render($request, $e);
}
```

## Versioning

```php
Route::prefix('v1')->group(fn () => Route::apiResource('invoices', V1\InvoiceController::class));
Route::prefix('v2')->group(fn () => Route::apiResource('invoices', V2\InvoiceController::class));

// Deprecation middleware adds: Deprecation, Sunset, Link headers
```

**Rules**: Never break clients without version bump. Support old versions 6+ months. Use `Sunset` header.

## Rate Limiting

```php
RateLimiter::for('api', fn (Request $request) =>
    Limit::perMinute(60)->by($request->user()?->id ?: $request->ip())
);
RateLimiter::for('uploads', fn (Request $request) =>
    Limit::perMinute(10)->by($request->user()->id)
);
// Headers: X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset, Retry-After (429 only)
```

## File Uploads

```php
// Multipart: POST /api/v1/invoices/{id}/attachments
$path = $request->file('file')->store("invoices/{$invoice->id}", 's3');
$attachment = $invoice->attachments()->create([
    'branch_id' => auth()->user()->branch_id,
    'file_path' => $path,
    'file_name' => $request->file('file')->getClientOriginalName(),
    'file_size' => $request->file('file')->getSize(),
    'mime_type' => $request->file('file')->getMimeType(),
]);

// Presigned URL for large files: generate S3 temporaryUrl with 15min expiry
```

## Webhooks

```php
class WebhookService {
    public function dispatch(string $event, array $payload, string $url): void {
        $body = json_encode(['event' => $event, 'data' => $payload, 'timestamp' => now()->toIso8601String()]);
        $signature = hash_hmac('sha256', $body, config('services.webhook.secret'));
        Http::withHeaders(['X-Webhook-Signature' => $signature])->timeout(10)->post($url, $payload);
    }
}
// Receiver: verify with hash_equals(hash_hmac('sha256', $content, $secret), $header)
// Retry: 5 attempts, exponential backoff (10s, 30s, 90s, 270s, 810s)
```

## Bulk Operations

Use `POST /resource/bulk` for batch create/update (return 207 Multi-Status for partial success).
Use `DELETE /resource/bulk` with `{ "ids": [...] }` body (max 100 items).

## Testing Checklist

Every endpoint must test: success, validation (422), auth failure (401), authorization (403), tenant isolation (404 for cross-branch), and rate limiting.

```php
public function test_tenant_isolation(): void {
    $userB = User::factory()->create(['branch_id' => 2]);
    $invoice = Invoice::factory()->create(['branch_id' => 1]);
    $this->actingAs($userB)->getJson("/api/v1/invoices/{$invoice->id}")->assertNotFound();
}
```
