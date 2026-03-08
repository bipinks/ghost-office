---
name: authentication-patterns
description: Use when implementing authentication, authorization, or access control. Covers Laravel Sanctum, OAuth 2.0, RBAC with Spatie Permissions, multi-tenant auth, API token management, MFA, and session security.
user-invocable: false
allowed-tools: ["Read", "Write", "Bash", "Grep", "Glob"]
---

# Authentication Patterns

All patterns enforce multi-tenant isolation via `branch_id` scoping.

## Decision: Sanctum vs Passport vs JWT

| Approach | Use When |
|----------|----------|
| Sanctum (SPA cookies) | First-party SPA on same domain |
| Sanctum (API tokens) | First-party mobile or third-party with simple scopes |
| Passport (OAuth 2.0) | Third-party apps needing authorization code flow |
| JWT (raw) | Stateless cross-service communication only |

## Laravel Sanctum

### SPA Authentication (Cookie-Based)
```php
// config/sanctum.php
'stateful' => explode(',', env('SANCTUM_STATEFUL_DOMAINS', 'localhost,localhost:3000')),
'expiration' => 120,

// Login endpoint
Route::post('/login', function (Request $request) {
    $request->validate(['email' => ['required', 'email'], 'password' => ['required']]);
    if (! Auth::attempt($request->only('email', 'password'))) {
        throw ValidationException::withMessages(['email' => ['Invalid credentials.']]);
    }
    $request->session()->regenerate();
    return response()->json(['data' => new UserResource(Auth::user())]);
});
```

### API Token Authentication
```php
$token = $user->createToken('api-client', ['invoices:read', 'invoices:write', 'reports:read']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/invoices', [InvoiceController::class, 'index'])->middleware('ability:invoices:read');
    Route::post('/invoices', [InvoiceController::class, 'store'])->middleware('ability:invoices:write');
});

// Prune expired tokens daily
$schedule->command('sanctum:prune-expired --hours=48')->daily();
```

## RBAC (Spatie Permissions)

```php
// Seed permissions by module
$permissions = [
    'invoices.view', 'invoices.create', 'invoices.edit', 'invoices.delete', 'invoices.approve',
    'reports.view', 'reports.export', 'users.view', 'users.create', 'users.edit', 'settings.manage',
];
foreach ($permissions as $p) { Permission::firstOrCreate(['name' => $p, 'guard_name' => 'web']); }

$admin = Role::firstOrCreate(['name' => 'admin']);
$admin->givePermissionTo(Permission::all());

$accountant = Role::firstOrCreate(['name' => 'accountant']);
$accountant->givePermissionTo(['invoices.view', 'invoices.create', 'invoices.edit', 'reports.view']);
```

## Laravel Policies (Tenant-Aware)

```php
class InvoicePolicy
{
    public function view(User $user, Invoice $invoice): bool {
        return $user->hasPermissionTo('invoices.view') && $user->branch_id === $invoice->branch_id;
    }
    public function update(User $user, Invoice $invoice): bool {
        return $user->hasPermissionTo('invoices.edit')
            && $user->branch_id === $invoice->branch_id
            && $invoice->status !== 'approved';
    }
    public function approve(User $user, Invoice $invoice): bool {
        return $user->hasPermissionTo('invoices.approve')
            && $user->branch_id === $invoice->branch_id
            && $user->id !== $invoice->created_by; // segregation of duties
    }
}
```

## Multi-Tenant Auth Middleware

```php
class EnsureBranchScope
{
    public function handle(Request $request, Closure $next): Response {
        if (Auth::check()) {
            app()->instance('current_branch_id', Auth::user()->branch_id);
            if ($request->has('branch_id') && (int) $request->branch_id !== Auth::user()->branch_id) {
                abort(403, 'Cross-tenant access denied.');
            }
        }
        return $next($request);
    }
}
```

### Branch Switching (Company Admins)
```php
public function switchBranch(Request $request): JsonResponse {
    $branch = Branch::findOrFail($request->validate(['branch_id' => 'required|exists:branches,id'])['branch_id']);
    abort_unless($request->user()->company_id === $branch->company_id, 403);
    abort_unless($request->user()->hasRole('company-admin'), 403);
    $request->user()->update(['branch_id' => $branch->id]);
    $request->session()->regenerate();
    return response()->json(['data' => new UserResource($request->user()->fresh())]);
}
```

## Multi-Factor Authentication (TOTP)

```php
// Enable: generate secret, return QR URL
public function enableMfa(Request $request): JsonResponse {
    $secret = (new Google2FA())->generateSecretKey();
    $request->user()->update(['mfa_secret' => encrypt($secret), 'mfa_enabled' => false]);
    return response()->json([
        'qr_url' => (new Google2FA())->getQRCodeUrl(config('app.name'), $request->user()->email, $secret),
    ]);
}

// Confirm: verify code, generate backup codes
public function confirmMfa(Request $request): JsonResponse {
    $valid = (new Google2FA())->verifyKey(decrypt($request->user()->mfa_secret), $request->validate(['code' => 'required|digits:6'])['code']);
    abort_unless($valid, 422, 'Invalid MFA code.');
    $backupCodes = Collection::times(8, fn () => Str::random(8))->toArray();
    $request->user()->update(['mfa_enabled' => true, 'mfa_backup_codes' => encrypt(json_encode($backupCodes))]);
    return response()->json(['backup_codes' => $backupCodes]);
}

// Enforcement middleware: require MFA for admin roles
class RequireMfa {
    public function handle(Request $request, Closure $next): Response {
        $user = $request->user();
        if ($user->hasRole('admin') && ! $user->mfa_enabled) return response()->json(['message' => 'MFA required.'], 403);
        if ($user->mfa_enabled && ! session('mfa_verified')) return response()->json(['message' => 'MFA verification required.'], 403);
        return $next($request);
    }
}
```

## Password and Session Security

```php
// Password rules
'password' => ['required', 'confirmed', Password::min(12)->letters()->mixedCase()->numbers()->symbols()->uncompromised()],

// Session config essentials
'lifetime' => 120, 'encrypt' => true, 'secure' => true, 'http_only' => true, 'same_site' => 'lax',
// Regenerate on login, invalidate on logout, regenerateToken for CSRF rotation
```

## Frontend Auth (Vue 3 + Pinia)

```typescript
export const useAuthStore = defineStore('auth', {
  state: (): { user: User | null; isAuthenticated: boolean } => ({ user: null, isAuthenticated: false }),
  actions: {
    async login(email: string, password: string) {
      await api.get('/sanctum/csrf-cookie');
      await api.post('/login', { email, password });
      await this.fetchUser();
    },
    async fetchUser() { this.user = (await api.get('/api/user')).data; this.isAuthenticated = true; },
    can(permission: string): boolean { return this.user?.permissions?.includes(permission) ?? false; },
  },
});

// Router guard
router.beforeEach(async (to, from, next) => {
  const auth = useAuthStore();
  if (to.meta.requiresAuth && !auth.isAuthenticated) return next({ name: 'login', query: { redirect: to.fullPath } });
  if (to.meta.permission && !auth.can(to.meta.permission as string)) return next({ name: 'forbidden' });
  next();
});
```

## Security Headers Middleware

```php
class SecurityHeaders {
    public function handle(Request $request, Closure $next): Response {
        $response = $next($request);
        $response->headers->set('Strict-Transport-Security', 'max-age=31536000; includeSubDomains; preload');
        $response->headers->set('X-Content-Type-Options', 'nosniff');
        $response->headers->set('X-Frame-Options', 'SAMEORIGIN');
        $response->headers->set('Referrer-Policy', 'strict-origin-when-cross-origin');
        $response->headers->set('Permissions-Policy', 'camera=(), microphone=(), geolocation=()');
        return $response;
    }
}
```

## Security Audit Checklist

- [ ] Passwords hashed with bcrypt or argon2id
- [ ] Session regenerated on login, invalidated on logout
- [ ] CSRF tokens on all state-changing requests
- [ ] Secure, HttpOnly, SameSite flags on session cookies
- [ ] RBAC enforced at API level, not only in the UI
- [ ] Multi-tenant isolation verified in policies (branch_id check)
- [ ] MFA available for admin accounts
- [ ] API tokens scoped to minimum required abilities
- [ ] Rate limiting on login and token endpoints
- [ ] Security headers on all responses
- [ ] No secrets or tokens in logs or error responses
- [ ] Audit trail for auth events (login, logout, MFA, password reset)
