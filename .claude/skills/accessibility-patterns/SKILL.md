---
name: accessibility-patterns
description: Use when implementing or auditing accessibility features. Covers WCAG 2.1 AA/AAA compliance, ARIA roles and attributes, keyboard navigation, screen reader support, color contrast, focus management, and accessible component patterns.
user-invocable: false
allowed-tools: ["Read", "Write", "Edit", "Grep", "Glob", "Bash"]
---

# Accessibility Patterns -- WCAG 2.1 Compliant UI Development

## 1. WCAG 2.1 Principles Overview

### POUR Framework

| Principle | Summary | Key Success Criteria |
|-----------|---------|---------------------|
| **Perceivable** | Users can perceive all content | Text alternatives, captions, contrast, resize |
| **Operable** | Users can operate all controls | Keyboard access, enough time, no seizures, navigable |
| **Understandable** | Users can understand content and UI | Readable, predictable, input assistance |
| **Robust** | Content works across assistive technologies | Valid HTML, name/role/value, status messages |

### Conformance Levels

| Level | Target | Examples |
|-------|--------|----------|
| A | Minimum (required) | Alt text, keyboard access, no keyboard traps |
| AA | Standard (our target) | Color contrast 4.5:1, resize to 200%, focus visible |
| AAA | Enhanced (aspirational) | Contrast 7:1, sign language, no timing |

---

## 2. Semantic HTML

Always use semantic elements before reaching for ARIA. The first rule of ARIA is: do not use ARIA if a native HTML element provides the behavior.

### Correct Element Choices

```html
<!-- Page structure -->
<header>Site header, branding, global nav</header>
<nav aria-label="Main navigation">Primary navigation</nav>
<main>Primary page content (one per page)</main>
<aside>Sidebar, complementary content</aside>
<footer>Site footer, legal, links</footer>

<!-- Content sections -->
<article>Self-contained content (invoice detail, blog post)</article>
<section aria-labelledby="section-heading">Thematic grouping</section>
<h1>-<h6> for heading hierarchy (never skip levels)

<!-- Interactive elements -->
<button>For actions (submit, toggle, open modal)</button>
<a href="/path">For navigation to another page/section</a>
<input>, <select>, <textarea> for form inputs
<details><summary>Collapsible content</summary></details>

<!-- Data -->
<table> for tabular data (never for layout)
<ul>/<ol> for lists
<dl> for key-value pairs (definition lists)
<time datetime="2026-03-06">March 6, 2026</time>
```

### Anti-Patterns to Avoid

```html
<!-- BAD: div/span as interactive elements -->
<div onclick="handleClick()">Click me</div>
<span class="link" onclick="navigate()">Go to page</span>

<!-- GOOD: use native elements -->
<button type="button" @click="handleClick">Click me</button>
<a href="/page">Go to page</a>

<!-- BAD: heading levels skipped -->
<h1>Page Title</h1>
<h3>Section</h3>  <!-- skipped h2 -->

<!-- GOOD: sequential heading levels -->
<h1>Page Title</h1>
<h2>Section</h2>
<h3>Subsection</h3>
```

---

## 3. ARIA Roles, States, and Properties

### Landmark Roles

```html
<nav aria-label="Main navigation">...</nav>
<nav aria-label="Breadcrumb">...</nav>
<main>...</main>
<aside aria-label="Filters">...</aside>
<form aria-label="Invoice creation">...</form>
<region aria-label="Search results">...</region>
```

When multiple landmarks of the same type exist, use `aria-label` to differentiate them.

### Widget Roles and States

```html
<!-- Tabs -->
<div role="tablist" aria-label="Invoice sections">
  <button role="tab" id="tab-details" aria-selected="true" aria-controls="panel-details">
    Details
  </button>
  <button role="tab" id="tab-payments" aria-selected="false" aria-controls="panel-payments">
    Payments
  </button>
</div>
<div role="tabpanel" id="panel-details" aria-labelledby="tab-details">
  ...content...
</div>
<div role="tabpanel" id="panel-payments" aria-labelledby="tab-payments" hidden>
  ...content...
</div>

<!-- Accordion -->
<h3>
  <button aria-expanded="false" aria-controls="section-1-content">
    Section 1
  </button>
</h3>
<div id="section-1-content" role="region" aria-labelledby="section-1-heading" hidden>
  ...content...
</div>

<!-- Toggle / Switch -->
<button role="switch" aria-checked="false" @click="toggle">
  Enable notifications
</button>

<!-- Combobox (autocomplete) -->
<div role="combobox" aria-expanded="false" aria-haspopup="listbox">
  <input type="text" aria-autocomplete="list" aria-controls="suggestions-list"
         aria-activedescendant="" />
  <ul id="suggestions-list" role="listbox" hidden>
    <li role="option" id="opt-1">Option 1</li>
    <li role="option" id="opt-2">Option 2</li>
  </ul>
</div>
```

### Live Regions

```html
<!-- Polite: announced when the user is idle (status updates, saved confirmations) -->
<div aria-live="polite" aria-atomic="true">
  Invoice saved successfully.
</div>

<!-- Assertive: announced immediately (errors, critical alerts) -->
<div role="alert" aria-live="assertive">
  Payment failed. Please check your card details.
</div>

<!-- Status: implicit polite live region -->
<div role="status">
  Showing 25 of 142 results
</div>

<!-- Log: for chat messages, activity feeds -->
<div role="log" aria-live="polite">
  <p>10:42 - John approved Invoice #42</p>
  <p>10:45 - Payment received for Invoice #42</p>
</div>
```

---

## 4. Keyboard Navigation

### Tab Order and Focus Management

```typescript
// Focus management for page navigation (Vue Router)
router.afterEach(() => {
  nextTick(() => {
    const heading = document.querySelector('h1');
    if (heading) {
      heading.setAttribute('tabindex', '-1');
      heading.focus();
    }
  });
});
```

### Skip Link

```html
<!-- First element in the body -->
<a href="#main-content" class="skip-link">Skip to main content</a>

<!-- Target -->
<main id="main-content" tabindex="-1">...</main>
```

```css
.skip-link {
  position: absolute;
  top: -40px;
  left: 0;
  padding: 8px 16px;
  background: var(--color-primary);
  color: white;
  z-index: 100;
  transition: top 0.2s;
}
.skip-link:focus {
  top: 0;
}
```

### Focus Trapping in Modals

```typescript
// composables/useFocusTrap.ts
import { onMounted, onUnmounted, type Ref } from 'vue';

export function useFocusTrap(containerRef: Ref<HTMLElement | null>) {
  const FOCUSABLE_SELECTORS = [
    'a[href]',
    'button:not([disabled])',
    'input:not([disabled])',
    'select:not([disabled])',
    'textarea:not([disabled])',
    '[tabindex]:not([tabindex="-1"])',
  ].join(', ');

  let previouslyFocused: HTMLElement | null = null;

  function getFocusableElements(): HTMLElement[] {
    if (!containerRef.value) return [];
    return Array.from(containerRef.value.querySelectorAll(FOCUSABLE_SELECTORS));
  }

  function handleKeyDown(event: KeyboardEvent) {
    if (event.key !== 'Tab') return;

    const focusable = getFocusableElements();
    if (focusable.length === 0) return;

    const first = focusable[0];
    const last = focusable[focusable.length - 1];

    if (event.shiftKey && document.activeElement === first) {
      event.preventDefault();
      last.focus();
    } else if (!event.shiftKey && document.activeElement === last) {
      event.preventDefault();
      first.focus();
    }
  }

  function activate() {
    previouslyFocused = document.activeElement as HTMLElement;
    document.addEventListener('keydown', handleKeyDown);
    const focusable = getFocusableElements();
    if (focusable.length > 0) focusable[0].focus();
  }

  function deactivate() {
    document.removeEventListener('keydown', handleKeyDown);
    if (previouslyFocused) previouslyFocused.focus();
  }

  onMounted(activate);
  onUnmounted(deactivate);

  return { activate, deactivate };
}
```

### Roving Tabindex (For Grouped Controls)

```typescript
// composables/useRovingTabindex.ts
import { ref, type Ref } from 'vue';

export function useRovingTabindex(items: Ref<HTMLElement[]>) {
  const activeIndex = ref(0);

  function handleKeyDown(event: KeyboardEvent) {
    const len = items.value.length;
    let newIndex = activeIndex.value;

    switch (event.key) {
      case 'ArrowDown':
      case 'ArrowRight':
        event.preventDefault();
        newIndex = (activeIndex.value + 1) % len;
        break;
      case 'ArrowUp':
      case 'ArrowLeft':
        event.preventDefault();
        newIndex = (activeIndex.value - 1 + len) % len;
        break;
      case 'Home':
        event.preventDefault();
        newIndex = 0;
        break;
      case 'End':
        event.preventDefault();
        newIndex = len - 1;
        break;
      default:
        return;
    }

    activeIndex.value = newIndex;
    items.value[newIndex]?.focus();
  }

  function getTabindex(index: number): 0 | -1 {
    return index === activeIndex.value ? 0 : -1;
  }

  return { activeIndex, handleKeyDown, getTabindex };
}
```

### Keyboard Shortcuts Reference

| Pattern | Keys | Action |
|---------|------|--------|
| Modal | `Escape` | Close modal |
| Dropdown | `Escape` | Close dropdown |
| Dropdown | `Arrow Up/Down` | Navigate options |
| Dropdown | `Enter/Space` | Select option |
| Tabs | `Arrow Left/Right` | Switch tabs |
| Data table | `Arrow Up/Down` | Navigate rows |
| Search | `/` | Focus search field (optional) |
| Save | `Ctrl+S` | Save form (optional) |

---

## 5. Color Contrast

### WCAG Contrast Requirements

| Element | Level AA | Level AAA |
|---------|----------|-----------|
| Normal text (< 18px) | 4.5:1 | 7:1 |
| Large text (>= 18px or 14px bold) | 3:1 | 4.5:1 |
| UI components & graphics | 3:1 | Not defined |
| Focus indicators | 3:1 | Not defined |

### Verified Color Combinations

```css
/* High contrast text combinations (all pass AA) */
/* Dark text on light backgrounds */
--text-on-white: #111827;    /* gray-900 on white = 17.4:1 */
--text-on-gray50: #374151;   /* gray-700 on gray-50 = 9.7:1 */
--text-secondary: #4B5563;   /* gray-600 on white = 7.0:1 */

/* Light text on dark backgrounds */
--text-on-primary: #FFFFFF;  /* white on blue-600 = 5.1:1 */
--text-on-dark: #F9FAFB;     /* gray-50 on gray-900 = 17.1:1 */

/* Status colors with accessible text */
--success-text: #065F46;     /* green-800 on green-50 = 7.3:1 */
--warning-text: #92400E;     /* amber-800 on amber-50 = 6.2:1 */
--error-text: #991B1B;       /* red-800 on red-50 = 7.8:1 */
--info-text: #1E40AF;        /* blue-800 on blue-50 = 6.5:1 */
```

### Never Rely on Color Alone

```html
<!-- BAD: status conveyed only by color -->
<span class="text-red-500">Overdue</span>

<!-- GOOD: color + text + icon -->
<span class="text-red-700 flex items-center gap-1">
  <svg aria-hidden="true" class="w-4 h-4"><!-- warning icon --></svg>
  Overdue
</span>

<!-- GOOD: form error with icon and text -->
<div class="flex items-center gap-1.5 text-red-600 text-sm mt-1" role="alert">
  <svg aria-hidden="true" class="w-4 h-4 flex-shrink-0"><!-- error icon --></svg>
  <span>Customer is required</span>
</div>
```

---

## 6. Accessible Form Patterns

### Form Field with Label, Description, and Error

```vue
<!-- components/forms/FormInput.vue -->
<script setup lang="ts">
import { computed } from 'vue';

const props = defineProps<{
  id: string;
  label: string;
  modelValue: string;
  type?: string;
  required?: boolean;
  error?: string;
  description?: string;
  disabled?: boolean;
}>();

defineEmits<{ (e: 'update:modelValue', value: string): void }>();

const descriptionId = computed(() => props.description ? `${props.id}-desc` : undefined);
const errorId = computed(() => props.error ? `${props.id}-error` : undefined);
const ariaDescribedBy = computed(() =>
  [descriptionId.value, errorId.value].filter(Boolean).join(' ') || undefined
);
</script>

<template>
  <div class="space-y-1.5">
    <label :for="id" class="block text-sm font-medium text-gray-700">
      {{ label }}
      <span v-if="required" class="text-red-500 ml-0.5" aria-hidden="true">*</span>
      <span v-if="required" class="sr-only">(required)</span>
    </label>

    <p v-if="description" :id="descriptionId" class="text-sm text-gray-500">
      {{ description }}
    </p>

    <input
      :id="id"
      :type="type ?? 'text'"
      :value="modelValue"
      :required="required"
      :disabled="disabled"
      :aria-invalid="error ? 'true' : undefined"
      :aria-describedby="ariaDescribedBy"
      :class="[
        'block w-full rounded-input border px-3 py-2 text-sm',
        'focus:outline-none focus:ring-2 focus:ring-offset-0',
        error
          ? 'border-red-500 focus:border-red-500 focus:ring-red-500/30'
          : 'border-gray-300 focus:border-blue-500 focus:ring-blue-500/30',
        disabled ? 'bg-gray-100 text-gray-500 cursor-not-allowed' : 'bg-white',
      ]"
      @input="$emit('update:modelValue', ($event.target as HTMLInputElement).value)"
    />

    <p v-if="error" :id="errorId" class="flex items-center gap-1.5 text-sm text-red-600" role="alert">
      <svg class="w-4 h-4 flex-shrink-0" aria-hidden="true" viewBox="0 0 20 20" fill="currentColor">
        <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
      </svg>
      {{ error }}
    </p>
  </div>
</template>
```

### Accessible Select / Dropdown

```html
<div class="space-y-1.5">
  <label for="status-filter" class="block text-sm font-medium text-gray-700">
    Status
  </label>
  <select id="status-filter"
          class="block w-full rounded-input border border-gray-300 px-3 py-2 text-sm"
          aria-describedby="status-filter-desc">
    <option value="">All statuses</option>
    <option value="draft">Draft</option>
    <option value="sent">Sent</option>
    <option value="paid">Paid</option>
    <option value="overdue">Overdue</option>
  </select>
  <p id="status-filter-desc" class="text-xs text-gray-500">
    Filter invoices by their current status
  </p>
</div>
```

### Form Group (Fieldset + Legend)

```html
<fieldset>
  <legend class="text-sm font-medium text-gray-700 mb-3">Payment Method</legend>
  <div class="space-y-2">
    <label class="flex items-center gap-2 cursor-pointer">
      <input type="radio" name="payment" value="bank" class="text-blue-600 focus:ring-blue-500" />
      <span class="text-sm text-gray-700">Bank Transfer</span>
    </label>
    <label class="flex items-center gap-2 cursor-pointer">
      <input type="radio" name="payment" value="cash" class="text-blue-600 focus:ring-blue-500" />
      <span class="text-sm text-gray-700">Cash</span>
    </label>
    <label class="flex items-center gap-2 cursor-pointer">
      <input type="radio" name="payment" value="cheque" class="text-blue-600 focus:ring-blue-500" />
      <span class="text-sm text-gray-700">Cheque</span>
    </label>
  </div>
</fieldset>
```

---

## 7. Accessible Data Tables

```html
<div role="region" aria-label="Invoice list" tabindex="0" class="overflow-x-auto">
  <table class="min-w-full">
    <caption class="sr-only">List of invoices with status and amount</caption>
    <thead>
      <tr>
        <th scope="col">
          <span class="sr-only">Select</span>
          <input type="checkbox" aria-label="Select all invoices" />
        </th>
        <th scope="col">
          <button aria-sort="ascending" class="flex items-center gap-1">
            Invoice #
            <svg aria-hidden="true" class="w-4 h-4"><!-- sort icon --></svg>
          </button>
        </th>
        <th scope="col">Customer</th>
        <th scope="col">Date</th>
        <th scope="col" class="text-right">Amount</th>
        <th scope="col">Status</th>
        <th scope="col"><span class="sr-only">Actions</span></th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td><input type="checkbox" aria-label="Select invoice INV-042" /></td>
        <td>INV-042</td>
        <td>Acme Corp</td>
        <td><time datetime="2026-03-05">Mar 5, 2026</time></td>
        <td class="text-right">$1,200.00</td>
        <td>
          <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-green-50 text-green-700">
            <span class="w-1.5 h-1.5 rounded-full bg-green-500" aria-hidden="true"></span>
            Paid
          </span>
        </td>
        <td>
          <button aria-label="Actions for invoice INV-042" aria-haspopup="menu">
            <svg aria-hidden="true"><!-- dots icon --></svg>
          </button>
        </td>
      </tr>
    </tbody>
  </table>
</div>

<!-- Pagination with accessibility -->
<nav aria-label="Invoice list pagination">
  <ul class="flex items-center gap-1">
    <li><button aria-label="Previous page" :disabled="page === 1">Prev</button></li>
    <li><button aria-label="Page 1" aria-current="page">1</button></li>
    <li><button aria-label="Page 2">2</button></li>
    <li><button aria-label="Page 3">3</button></li>
    <li><button aria-label="Next page" :disabled="page === lastPage">Next</button></li>
  </ul>
  <p class="text-sm text-gray-600" role="status">
    Showing 1 to 25 of 142 invoices
  </p>
</nav>
```

---

## 8. Accessible Modal / Dialog

```vue
<!-- components/common/AppModal.vue -->
<script setup lang="ts">
import { ref, watch, nextTick } from 'vue';
import { useFocusTrap } from '@/composables/useFocusTrap';

const props = defineProps<{
  open: boolean;
  title: string;
  description?: string;
}>();

const emit = defineEmits<{ (e: 'close'): void }>();
const dialogRef = ref<HTMLElement | null>(null);

watch(() => props.open, (isOpen) => {
  if (isOpen) {
    nextTick(() => { useFocusTrap(dialogRef); });
    document.body.style.overflow = 'hidden';
  } else {
    document.body.style.overflow = '';
  }
});

function handleBackdropClick(event: MouseEvent) {
  if (event.target === event.currentTarget) emit('close');
}

function handleKeyDown(event: KeyboardEvent) {
  if (event.key === 'Escape') emit('close');
}
</script>

<template>
  <Teleport to="body">
    <div v-if="open" class="fixed inset-0 z-50 flex items-center justify-center"
         @keydown="handleKeyDown">
      <!-- Backdrop -->
      <div class="fixed inset-0 bg-black/50" aria-hidden="true" @click="handleBackdropClick" />

      <!-- Dialog -->
      <div ref="dialogRef" role="dialog" aria-modal="true"
           :aria-labelledby="`modal-title-${$.uid}`"
           :aria-describedby="description ? `modal-desc-${$.uid}` : undefined"
           class="relative z-10 bg-white rounded-lg shadow-xl max-w-lg w-full mx-4 p-6">
        <h2 :id="`modal-title-${$.uid}`" class="text-lg font-semibold text-gray-900">
          {{ title }}
        </h2>
        <p v-if="description" :id="`modal-desc-${$.uid}`" class="mt-1 text-sm text-gray-500">
          {{ description }}
        </p>

        <div class="mt-4">
          <slot />
        </div>

        <div class="mt-6 flex justify-end gap-3">
          <slot name="actions">
            <button type="button" @click="emit('close')"
                    class="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 rounded hover:bg-gray-200">
              Close
            </button>
          </slot>
        </div>

        <!-- Close button -->
        <button type="button" @click="emit('close')"
                class="absolute top-4 right-4 text-gray-400 hover:text-gray-600"
                aria-label="Close dialog">
          <svg class="w-5 h-5" aria-hidden="true" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
          </svg>
        </button>
      </div>
    </div>
  </Teleport>
</template>
```

---

## 9. Screen Reader Utilities

```css
/* Visually hidden but accessible to screen readers */
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border-width: 0;
}

/* Visible focus indicator (critical for keyboard users) */
.focus-visible:focus-visible {
  outline: 2px solid var(--color-primary);
  outline-offset: 2px;
}

/* Reduced motion for users who prefer it */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

### Screen Reader Best Practices

- Use `aria-label` for icon-only buttons: `<button aria-label="Delete invoice">`
- Use `aria-live="polite"` for status updates (search results count, save confirmations)
- Use `role="alert"` for error messages that need immediate attention
- Use `aria-current="page"` for active navigation items
- Use `aria-expanded` on toggles that show/hide content
- Use `aria-busy="true"` on regions being updated asynchronously
- Always provide text alternatives for images: `<img alt="Company logo" />`
- Use `alt=""` (empty alt) for purely decorative images

---

## 10. Testing Accessibility

### Automated Testing with axe-core

```typescript
// tests/accessibility/a11y.spec.ts
import { describe, it, expect } from 'vitest';
import { mount } from '@vue/test-utils';
import { axe, toHaveNoViolations } from 'jest-axe';
import InvoiceList from '@/modules/accounting/InvoiceList.vue';

expect.extend(toHaveNoViolations);

describe('InvoiceList accessibility', () => {
  it('has no accessibility violations', async () => {
    const wrapper = mount(InvoiceList, {
      global: { /* plugins, stubs */ },
    });
    const results = await axe(wrapper.element);
    expect(results).toHaveNoViolations();
  });
});
```

### Accessibility Test Checklist (Manual)

```markdown
## Manual Accessibility Test

### Keyboard Navigation
- [ ] All interactive elements reachable via Tab
- [ ] Tab order follows visual/logical order
- [ ] Focus indicator visible on every focused element
- [ ] Modals trap focus and return focus on close
- [ ] Escape closes modals and dropdowns
- [ ] Enter/Space activates buttons and links
- [ ] Arrow keys navigate within groups (tabs, menus, radio buttons)
- [ ] No keyboard traps (user can always Tab away)

### Screen Reader
- [ ] Page has a descriptive <title>
- [ ] Headings form a logical hierarchy (h1 -> h2 -> h3)
- [ ] Images have meaningful alt text (or empty alt for decorative)
- [ ] Form fields have visible labels linked via for/id
- [ ] Error messages are announced (aria-live or role="alert")
- [ ] Status changes are announced (aria-live="polite")
- [ ] Tables have proper headers (th with scope)
- [ ] Links and buttons have descriptive text (not "click here")

### Visual
- [ ] Text contrast meets 4.5:1 minimum (AA)
- [ ] UI component contrast meets 3:1 minimum
- [ ] Information not conveyed by color alone
- [ ] Page usable at 200% zoom
- [ ] No horizontal scrolling at 320px viewport width
- [ ] Focus indicator has 3:1 contrast against background
- [ ] Touch targets at least 44x44px on mobile

### Content
- [ ] Language set on html element: <html lang="en">
- [ ] Form fields have visible labels (not placeholder-only)
- [ ] Error messages are specific and next to the field
- [ ] Required fields indicated (not by color alone)
- [ ] Timeouts warn user and allow extension
```

### CI Integration with Lighthouse

```yaml
# .github/workflows/a11y.yml
name: Accessibility Audit
on: [pull_request]

jobs:
  lighthouse:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm ci
      - run: npm run build
      - name: Run Lighthouse
        uses: treosh/lighthouse-ci-action@v11
        with:
          configPath: ./lighthouserc.json
          uploadArtifacts: true
```

```json
// lighthouserc.json
{
  "ci": {
    "assert": {
      "assertions": {
        "categories:accessibility": ["error", { "minScore": 0.9 }],
        "color-contrast": "error",
        "label": "error",
        "image-alt": "error",
        "button-name": "error",
        "link-name": "error"
      }
    }
  }
}
```

---

## 11. Accessibility Audit Checklist by Component

| Component | Key Requirements |
|-----------|-----------------|
| Button | Descriptive text or aria-label, focus visible, disabled state announced |
| Link | Descriptive text, distinguishable from surrounding text (not by color alone) |
| Input | Visible label, error description, aria-invalid on error, aria-required |
| Select | Label, option group labels if applicable |
| Checkbox/Radio | Label per option, fieldset + legend for groups |
| Modal | role="dialog", aria-modal, focus trap, Escape to close |
| Tabs | role="tablist/tab/tabpanel", aria-selected, keyboard arrows |
| Data Table | caption, th with scope, sortable headers with aria-sort |
| Accordion | aria-expanded, aria-controls, heading + button pattern |
| Toast/Alert | role="alert" or aria-live, auto-dismiss has sufficient time |
| Dropdown Menu | aria-haspopup, aria-expanded, keyboard navigation |
| Pagination | nav with aria-label, aria-current="page" |
| Breadcrumb | nav with aria-label="Breadcrumb", aria-current="page" on last |
| Search | label (visible or sr-only), role="search" on container |
| Loading | aria-busy="true" on region, aria-live for completion message |
