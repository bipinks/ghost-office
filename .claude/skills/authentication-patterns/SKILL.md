---
name: authentication-patterns
description: Use when implementing authentication, authorization, or access control. Covers Laravel Sanctum, OAuth 2.0, RBAC with Spatie Permissions, multi-tenant auth, API token management, MFA, and session security.
user-invocable: false
allowed-tools: ["Read", "Write", "Bash", "Grep", "Glob"]
---

# Authentication Patterns

Comprehensive reference for implementing authentication, authorization, and access control in the platform. All patterns enforce multi-tenant isolation via `branch_id` scoping.

---

## 1. Laravel Sanctum

### SPA Authentication (Cookie-Based)
```php
// config/sanctum.php
'stateful' => explode(',', env('SANCTUM_STATEFUL_DOMAINS', 'localhost,localhost:3000,127.0.0.1')),
'guard' => ['web'],
'expiration' => 120, // minutes

// config/cors.php
'supports_credentials' => true,
```

```php
// routes/api.php — login endpoint
Route::post('/login', function (Request $request) {
    $request->validate([
        'email' => ['required', 'email'],
        'password' => ['required'],
    ]);

    if (! Auth::attempt($request->only('email', 'password'))) {
        throw ValidationException::withMessages([
            'email' => ['The provided credentials are incorrect.'],
        ]);
    }

    $request->session()->regenerate();
    return response()->json(['data' => new UserResource(Auth::user())]);
});
```

### API Token Authentication
```php
// Issue token with abilities (scopes)
$token = $user->createToken('api-client', [
    'invoices:read',
    'invoices:write',
    'reports:read',
]);

return ['token' => $token->plainTextToken];

// Protect routes
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/invoices', [InvoiceController::class, 'index'])
        ->middleware('ability:invoices:read');
    Route::post('/invoices', [InvoiceController::class, 'store'])
        ->middleware('ability:invoices:write');
});

// Check abilities in controller
if ($request->user()->tokenCan('reports:read')) {
    // authorized
}
```

### Token Expiration and Pruning
```php
// config/sanctum.php
'expiration' => 1440, // 24 hours

// Prune expired tokens (schedule daily)
// app/Console/Kernel.php
$schedule->command('sanctum:prune-expired --hours=48')->daily();
```

---

## 2. OAuth 2.0 / Laravel Passport

### Authorization Code Flow (Third-Party Apps)
```php
// Install and configure
// php artisan passport:install

// routes/web.php — authorization endpoint
Route::get('/oauth/authorize', [AuthorizationController::class, 'authorize'])
    ->middleware(['web', 'auth']);

// Token exchange
Route::post('/oauth/token', [TokenController::class, 'issueToken']);
```

### Client Credentials (Machine-to-Machine)
```php
// Create client
// php artisan passport:client --client

// Request token
$response = Http::asForm()->post('/oauth/token', [
    'grant_type' => 'client_credentials',
    'client_id' => $clientId,
    'client_secret' => $clientSecret,
    'scope' => 'read-reports',
]);

// Protect route
Route::middleware('client:read-reports')->get('/api/reports', ...);
```

### Token Refresh
```php
$response = Http::asForm()->post('/oauth/token', [
    'grant_type' => 'refresh_token',
    'refresh_token' => $refreshToken,
    'client_id' => $clientId,
    'client_secret' => $clientSecret,
]);
```

---

## 3. RBAC (Spatie Permissions)

### Setup
```php
// Seed roles and permissions
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;

// Define permissions by module
$permissions = [
    'invoices.view', 'invoices.create', 'invoices.edit', 'invoices.delete', 'invoices.approve',
    'reports.view', 'reports.export',
    'users.view', 'users.create', 'users.edit', 'users.delete',
    'settings.manage',
];

foreach ($permissions as $permission) {
    Permission::firstOrCreate(['name' => $permission, 'guard_name' => 'web']);
}

// Create roles with permission sets
$admin = Role::firstOrCreate(['name' => 'admin']);
$admin->givePermissionTo(Permission::all());

$accountant = Role::firstOrCreate(['name' => 'accountant']);
$accountant->givePermissionTo(['invoices.view', 'invoices.create', 'invoices.edit', 'reports.view', 'reports.export']);

$viewer = Role::firstOrCreate(['name' => 'viewer']);
$viewer->givePermissionTo(['invoices.view', 'reports.view']);
```

### Middleware Protection
```php
// Route-level
Route::middleware(['auth:sanctum', 'role:admin'])->group(function () {
    Route::resource('users', UserController::class);
});

Route::middleware(['auth:sanctum', 'permission:invoices.create'])->post('/invoices', ...);

// Controller-level
public function __construct()
{
    $this->middleware('permission:invoices.view')->only(['index', 'show']);
    $this->middleware('permission:invoices.create')->only(['store']);
    $this->middleware('permission:invoices.edit')->only(['update']);
    $this->middleware('permission:invoices.delete')->only(['destroy']);
}
```

---

## 4. Laravel Policies

### Policy Pattern
```php
// app/Policies/InvoicePolicy.php
class InvoicePolicy
{
    public function viewAny(User $user): bool
    {
        return $user->hasPermissionTo('invoices.view');
    }

    public function view(User $user, Invoice $invoice): bool
    {
        return $user->hasPermissionTo('invoices.view')
            && $user->branch_id === $invoice->branch_id; // tenant isolation
    }

    public function create(User $user): bool
    {
        return $user->hasPermissionTo('invoices.create');
    }

    public function update(User $user, Invoice $invoice): bool
    {
        return $user->hasPermissionTo('invoices.edit')
            && $user->branch_id === $invoice->branch_id
            && $invoice->status !== 'approved'; // business rule
    }

    public function approve(User $user, Invoice $invoice): bool
    {
        return $user->hasPermissionTo('invoices.approve')
            && $user->branch_id === $invoice->branch_id
            && $user->id !== $invoice->created_by; // segregation of duties
    }
}

// Controller usage
public function update(UpdateInvoiceRequest $request, Invoice $invoice)
{
    $this->authorize('update', $invoice);
    // proceed with update
}
```

---

## 5. Multi-Tenant Authentication

### Branch-Scoped Auth Middleware
```php
// app/Http/Middleware/EnsureBranchScope.php
class EnsureBranchScope
{
    public function handle(Request $request, Closure $next): Response
    {
        if (Auth::check()) {
            $branchId = Auth::user()->branch_id;

            // Set branch context for all queries via global scope
            app()->instance('current_branch_id', $branchId);

            // Validate that any branch_id in the request matches the user
            if ($request->has('branch_id') && (int) $request->branch_id !== $branchId) {
                abort(403, 'Cross-tenant access denied.');
            }
        }

        return $next($request);
    }
}
```

### Tenant Switching (Company Admins)
```php
// Only company-level admins may switch branches
public function switchBranch(Request $request): JsonResponse
{
    $request->validate(['branch_id' => 'required|exists:branches,id']);

    $user = $request->user();
    $branch = Branch::findOrFail($request->branch_id);

    if ($user->company_id !== $branch->company_id) {
        abort(403, 'Branch does not belong to your company.');
    }

    if (! $user->hasRole('company-admin')) {
        abort(403, 'Only company admins can switch branches.');
    }

    $user->update(['branch_id' => $branch->id]);
    $request->session()->regenerate(); // prevent session fixation

    AuditLog::create([
        'user_id' => $user->id,
        'action' => 'branch_switch',
        'details' => ['from' => $user->getOriginal('branch_id'), 'to' => $branch->id],
    ]);

    return response()->json(['data' => new UserResource($user->fresh())]);
}
```

---

## 6. Multi-Factor Authentication

### TOTP Implementation
```php
// Using pragmarx/google2fa-laravel
use PragmaRX\Google2FA\Google2FA;

public function enableMfa(Request $request): JsonResponse
{
    $google2fa = new Google2FA();
    $secret = $google2fa->generateSecretKey();

    $request->user()->update(['mfa_secret' => encrypt($secret), 'mfa_enabled' => false]);

    $qrCodeUrl = $google2fa->getQRCodeUrl(
        config('app.name'),
        $request->user()->email,
        $secret
    );

    return response()->json(['qr_url' => $qrCodeUrl, 'secret' => $secret]);
}

public function confirmMfa(Request $request): JsonResponse
{
    $request->validate(['code' => 'required|digits:6']);

    $google2fa = new Google2FA();
    $valid = $google2fa->verifyKey(
        decrypt($request->user()->mfa_secret),
        $request->code
    );

    if (! $valid) {
        return response()->json(['message' => 'Invalid MFA code.'], 422);
    }

    // Generate backup codes
    $backupCodes = Collection::times(8, fn () => Str::random(8))->toArray();

    $request->user()->update([
        'mfa_enabled' => true,
        'mfa_backup_codes' => encrypt(json_encode($backupCodes)),
    ]);

    return response()->json(['backup_codes' => $backupCodes]);
}
```

### MFA Enforcement Policy
```php
// Middleware: require MFA for admin roles
class RequireMfa
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if ($user->hasRole('admin') && ! $user->mfa_enabled) {
            return response()->json([
                'message' => 'MFA enrollment required for admin accounts.',
            ], 403);
        }

        if ($user->mfa_enabled && ! session('mfa_verified')) {
            return response()->json(['message' => 'MFA verification required.'], 403);
        }

        return $next($request);
    }
}
```

---

## 7. Session Security

```php
// config/session.php
'lifetime' => 120,
'expire_on_close' => false,
'encrypt' => true,
'secure' => env('SESSION_SECURE_COOKIE', true),   // HTTPS only
'http_only' => true,                                // no JS access
'same_site' => 'lax',                               // CSRF mitigation
'domain' => env('SESSION_DOMAIN'),

// Regenerate session on privilege change
$request->session()->regenerate();          // after login
$request->session()->invalidate();          // after logout
$request->session()->regenerateToken();     // rotate CSRF token
```

---

## 8. Password Security

```php
use Illuminate\Validation\Rules\Password;

// In a FormRequest or validation call
'password' => [
    'required',
    'confirmed',
    Password::min(12)
        ->letters()
        ->mixedCase()
        ->numbers()
        ->symbols()
        ->uncompromised(),  // checks HaveIBeenPwned API
],

// Hashing — Laravel uses bcrypt by default; switch to argon2id for higher security
// config/hashing.php
'driver' => 'argon2id',
'argon' => [
    'memory' => 65536,
    'threads' => 1,
    'time' => 4,
],
```

---

## 9. Social Authentication (Laravel Socialite)

```php
// routes/web.php
Route::get('/auth/{provider}/redirect', [SocialAuthController::class, 'redirect']);
Route::get('/auth/{provider}/callback', [SocialAuthController::class, 'callback']);

// Controller
public function callback(string $provider): RedirectResponse
{
    $socialUser = Socialite::driver($provider)->user();

    $user = User::firstOrCreate(
        ['email' => $socialUser->getEmail()],
        [
            'name' => $socialUser->getName(),
            'email_verified_at' => now(),
            'password' => Hash::make(Str::random(32)), // random password for social-only users
        ]
    );

    // Link social account
    $user->socialAccounts()->updateOrCreate(
        ['provider' => $provider, 'provider_id' => $socialUser->getId()],
        ['token' => encrypt($socialUser->token), 'refresh_token' => encrypt($socialUser->refreshToken)],
    );

    Auth::login($user);
    request()->session()->regenerate();

    return redirect()->intended('/dashboard');
}
```

---

## 10. API Key Management

```php
// Generate scoped API key
public function issueApiKey(Request $request): JsonResponse
{
    $request->validate([
        'name' => 'required|string|max:255',
        'scopes' => 'required|array',
        'scopes.*' => 'string|in:read,write,admin',
        'expires_in_days' => 'nullable|integer|min:1|max:365',
    ]);

    $token = $request->user()->createToken(
        $request->name,
        $request->scopes,
        $request->expires_in_days ? now()->addDays($request->expires_in_days) : null
    );

    AuditLog::create([
        'user_id' => $request->user()->id,
        'action' => 'api_key_created',
        'details' => ['name' => $request->name, 'scopes' => $request->scopes],
    ]);

    // Return the plain-text token only once
    return response()->json(['token' => $token->plainTextToken], 201);
}

// Rate limiting per API key
// app/Providers/RouteServiceProvider.php
RateLimiter::for('api', function (Request $request) {
    $key = $request->user()?->currentAccessToken()?->id ?? $request->ip();
    return Limit::perMinute(60)->by($key);
});
```

---

## 11. JWT Patterns

**Use Sanctum for most cases.** Prefer JWT only for stateless cross-service communication.

```php
// When JWT is appropriate:
// - Microservice-to-microservice auth
// - Third-party integrations requiring signed tokens
// - Short-lived tokens for specific operations (e.g., file download links)

// Structure: Header.Payload.Signature
// Payload should contain:
[
    'sub' => $user->id,
    'branch_id' => $user->branch_id,   // tenant context
    'iat' => time(),
    'exp' => time() + 900,             // 15-minute expiry
    'scopes' => ['invoices:read'],
]

// NEVER store sensitive data in JWT payload (it is base64 encoded, not encrypted)
// ALWAYS validate exp, iss, and aud claims on the receiving end
// ALWAYS use asymmetric signing (RS256) for cross-service tokens
```

---

## 12. Frontend Auth Integration (Vue 3 + Pinia)

```typescript
// stores/auth.ts
import { defineStore } from 'pinia';
import api from '@/lib/axios';

interface AuthState {
  user: User | null;
  isAuthenticated: boolean;
}

export const useAuthStore = defineStore('auth', {
  state: (): AuthState => ({
    user: null,
    isAuthenticated: false,
  }),
  actions: {
    async login(email: string, password: string) {
      await api.get('/sanctum/csrf-cookie');
      await api.post('/login', { email, password });
      await this.fetchUser();
    },
    async fetchUser() {
      const { data } = await api.get('/api/user');
      this.user = data.data;
      this.isAuthenticated = true;
    },
    async logout() {
      await api.post('/logout');
      this.user = null;
      this.isAuthenticated = false;
    },
    can(permission: string): boolean {
      return this.user?.permissions?.includes(permission) ?? false;
    },
  },
});

// Router guard
router.beforeEach(async (to, from, next) => {
  const auth = useAuthStore();
  if (to.meta.requiresAuth && !auth.isAuthenticated) {
    return next({ name: 'login', query: { redirect: to.fullPath } });
  }
  if (to.meta.permission && !auth.can(to.meta.permission as string)) {
    return next({ name: 'forbidden' });
  }
  next();
});

// Axios interceptor for 401 handling
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401) {
      const auth = useAuthStore();
      auth.$reset();
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);
```

---

## 13. Security Headers

```php
// app/Http/Middleware/SecurityHeaders.php
class SecurityHeaders
{
    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);

        $response->headers->set('Strict-Transport-Security', 'max-age=31536000; includeSubDomains; preload');
        $response->headers->set('X-Content-Type-Options', 'nosniff');
        $response->headers->set('X-Frame-Options', 'SAMEORIGIN');
        $response->headers->set('X-XSS-Protection', '0'); // disabled in favor of CSP
        $response->headers->set('Referrer-Policy', 'strict-origin-when-cross-origin');
        $response->headers->set('Permissions-Policy', 'camera=(), microphone=(), geolocation=()');
        $response->headers->set('Content-Security-Policy', implode('; ', [
            "default-src 'self'",
            "script-src 'self' 'nonce-" . csp_nonce() . "'",
            "style-src 'self' 'unsafe-inline'",  // required by many UI frameworks
            "img-src 'self' data: https:",
            "font-src 'self'",
            "connect-src 'self'",
            "frame-ancestors 'self'",
            "base-uri 'self'",
            "form-action 'self'",
        ]));

        return $response;
    }
}

// Register in app/Http/Kernel.php
protected $middleware = [
    // ...
    \App\Http\Middleware\SecurityHeaders::class,
];
```

---

## Security Audit Checklist

Before deploying any auth changes, verify:

- [ ] Passwords hashed with bcrypt or argon2id (never MD5/SHA)
- [ ] Session regenerated on login, invalidated on logout
- [ ] CSRF tokens on all state-changing requests
- [ ] Secure, HttpOnly, SameSite flags on session cookies
- [ ] RBAC enforced at API level, not only in the UI
- [ ] Multi-tenant isolation verified in policies (branch_id check)
- [ ] MFA available for admin accounts
- [ ] API tokens scoped to minimum required abilities
- [ ] Rate limiting applied to login and token endpoints
- [ ] Security headers present on all responses
- [ ] No secrets or tokens logged or exposed in error responses
- [ ] Audit trail for authentication events (login, logout, MFA, password reset)
