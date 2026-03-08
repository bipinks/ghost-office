---
name: accessibility-patterns
description: Use when implementing or auditing accessibility features. Covers WCAG 2.1 AA/AAA compliance, ARIA roles and attributes, keyboard navigation, screen reader support, color contrast, focus management, and accessible component patterns.
user-invocable: false
allowed-tools: ["Read", "Write", "Edit", "Grep", "Glob", "Bash"]
---

# Accessibility Patterns -- WCAG 2.1 Compliant UI Development

## 1. WCAG 2.1 Overview

**POUR**: Perceivable, Operable, Understandable, Robust.

| Level | Target | Key Criteria |
|-------|--------|-------------|
| A | Minimum | Alt text, keyboard access, no keyboard traps |
| AA | **Our target** | Contrast 4.5:1, resize to 200%, visible focus |
| AAA | Enhanced | Contrast 7:1, sign language, no timing |

First rule of ARIA: do not use ARIA if a native HTML element provides the behavior.

## 2. Semantic HTML

```html
<!-- Page structure -->
<header>Site header</header>
<nav aria-label="Main navigation">Primary nav</nav>
<main>Primary content (one per page)</main>
<aside>Sidebar</aside>
<footer>Site footer</footer>

<!-- Interactive: use native elements, not div/span with onclick -->
<button type="button">For actions</button>
<a href="/path">For navigation</a>
<details><summary>Collapsible content</summary></details>

<!-- Never skip heading levels: h1 -> h2 -> h3 -->
<!-- Use <table> for data only, never layout -->
```

## 3. ARIA Roles and Live Regions

```html
<!-- Tabs -->
<div role="tablist" aria-label="Invoice sections">
  <button role="tab" aria-selected="true" aria-controls="panel-details">Details</button>
  <button role="tab" aria-selected="false" aria-controls="panel-payments">Payments</button>
</div>
<div role="tabpanel" id="panel-details" aria-labelledby="tab-details">...</div>

<!-- Accordion -->
<h3><button aria-expanded="false" aria-controls="section-content">Section</button></h3>
<div id="section-content" role="region" hidden>...</div>

<!-- Toggle -->
<button role="switch" aria-checked="false">Enable notifications</button>

<!-- Live regions -->
<div aria-live="polite" aria-atomic="true">Status updates (announced when idle)</div>
<div role="alert" aria-live="assertive">Errors (announced immediately)</div>
<div role="status">Showing 25 of 142 results</div>
```

When multiple landmarks of the same type exist, differentiate with `aria-label`.

## 4. Keyboard Navigation

### Focus Management (Vue Router)
```typescript
router.afterEach(() => {
  nextTick(() => {
    const heading = document.querySelector('h1');
    if (heading) { heading.setAttribute('tabindex', '-1'); heading.focus(); }
  });
});
```

### Skip Link
```html
<a href="#main-content" class="skip-link">Skip to main content</a>
<main id="main-content" tabindex="-1">...</main>
```

### Focus Trapping (Modals)
```typescript
// composables/useFocusTrap.ts
export function useFocusTrap(containerRef: Ref<HTMLElement | null>) {
  const FOCUSABLE = 'a[href],button:not([disabled]),input:not([disabled]),select:not([disabled]),textarea:not([disabled]),[tabindex]:not([tabindex="-1"])';
  let previouslyFocused: HTMLElement | null = null;

  function handleKeyDown(e: KeyboardEvent) {
    if (e.key !== 'Tab') return;
    const els = Array.from(containerRef.value!.querySelectorAll<HTMLElement>(FOCUSABLE));
    if (!els.length) return;
    const first = els[0], last = els[els.length - 1];
    if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last.focus(); }
    else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first.focus(); }
  }

  function activate() {
    previouslyFocused = document.activeElement as HTMLElement;
    document.addEventListener('keydown', handleKeyDown);
    const els = Array.from(containerRef.value!.querySelectorAll<HTMLElement>(FOCUSABLE));
    if (els.length) els[0].focus();
  }
  function deactivate() {
    document.removeEventListener('keydown', handleKeyDown);
    previouslyFocused?.focus();
  }
  onMounted(activate); onUnmounted(deactivate);
  return { activate, deactivate };
}
```

### Keyboard Shortcuts Reference
| Pattern | Keys | Action |
|---------|------|--------|
| Modal/Dropdown | `Escape` | Close |
| Dropdown/Tabs | `Arrow keys` | Navigate options |
| Dropdown | `Enter/Space` | Select |
| Data table | `Arrow Up/Down` | Navigate rows |

## 5. Color Contrast

| Element | AA | AAA |
|---------|-----|-----|
| Normal text (<18px) | 4.5:1 | 7:1 |
| Large text (>=18px or 14px bold) | 3:1 | 4.5:1 |
| UI components & focus indicators | 3:1 | -- |

```html
<!-- Never convey information by color alone -->
<!-- BAD -->
<span class="text-red-500">Overdue</span>
<!-- GOOD: color + icon + text -->
<span class="text-red-700 flex items-center gap-1">
  <svg aria-hidden="true" class="w-4 h-4"><!-- warning icon --></svg>
  Overdue
</span>
```

## 6. Accessible Form Pattern

```vue
<script setup lang="ts">
const props = defineProps<{
  id: string; label: string; modelValue: string;
  required?: boolean; error?: string; description?: string;
}>();
const descId = computed(() => props.description ? `${props.id}-desc` : undefined);
const errorId = computed(() => props.error ? `${props.id}-error` : undefined);
const ariaDescribedBy = computed(() =>
  [descId.value, errorId.value].filter(Boolean).join(' ') || undefined
);
</script>
<template>
  <div class="space-y-1.5">
    <label :for="id" class="block text-sm font-medium text-gray-700">
      {{ label }}
      <span v-if="required" class="text-red-500" aria-hidden="true">*</span>
      <span v-if="required" class="sr-only">(required)</span>
    </label>
    <p v-if="description" :id="descId" class="text-sm text-gray-500">{{ description }}</p>
    <input :id="id" :value="modelValue" :required="required"
      :aria-invalid="error ? 'true' : undefined" :aria-describedby="ariaDescribedBy"
      @input="$emit('update:modelValue', ($event.target as HTMLInputElement).value)" />
    <p v-if="error" :id="errorId" class="text-sm text-red-600" role="alert">{{ error }}</p>
  </div>
</template>
```

Use `<fieldset>` + `<legend>` for radio/checkbox groups.

## 7. Accessible Data Table

```html
<div role="region" aria-label="Invoice list" tabindex="0" class="overflow-x-auto">
  <table>
    <caption class="sr-only">List of invoices with status and amount</caption>
    <thead>
      <tr>
        <th scope="col"><input type="checkbox" aria-label="Select all invoices" /></th>
        <th scope="col"><button aria-sort="ascending">Invoice #</button></th>
        <th scope="col">Customer</th>
        <th scope="col" class="text-right">Amount</th>
        <th scope="col">Status</th>
        <th scope="col"><span class="sr-only">Actions</span></th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td><input type="checkbox" aria-label="Select invoice INV-042" /></td>
        <td>INV-042</td><td>Acme Corp</td>
        <td class="text-right">$1,200.00</td><td>Paid</td>
        <td><button aria-label="Actions for INV-042" aria-haspopup="menu">...</button></td>
      </tr>
    </tbody>
  </table>
</div>
<nav aria-label="Pagination">
  <button aria-label="Previous page">Prev</button>
  <button aria-current="page">1</button>
  <button aria-label="Next page">Next</button>
  <p role="status">Showing 1 to 25 of 142 invoices</p>
</nav>
```

## 8. Screen Reader Utilities

```css
.sr-only {
  position: absolute; width: 1px; height: 1px; padding: 0; margin: -1px;
  overflow: hidden; clip: rect(0,0,0,0); white-space: nowrap; border: 0;
}
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important; transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

**Best practices**: `aria-label` on icon-only buttons. `aria-live="polite"` for status updates. `role="alert"` for errors. `aria-current="page"` for active nav. `aria-expanded` on toggles. `alt=""` for decorative images.

## 9. Testing

### Automated (axe-core)
```typescript
import { axe, toHaveNoViolations } from 'jest-axe';
expect.extend(toHaveNoViolations);
it('has no a11y violations', async () => {
  const wrapper = mount(InvoiceList);
  expect(await axe(wrapper.element)).toHaveNoViolations();
});
```

### CI (Lighthouse)
```json
{ "ci": { "assert": { "assertions": {
  "categories:accessibility": ["error", { "minScore": 0.9 }],
  "color-contrast": "error", "label": "error",
  "image-alt": "error", "button-name": "error"
}}}}
```

### Manual Checklist
**Keyboard**: All elements reachable via Tab. Visible focus. Modals trap focus. Escape closes. No traps.
**Screen reader**: Descriptive title. Logical heading hierarchy. Labels linked via for/id. Errors announced. Status changes announced.
**Visual**: Text contrast 4.5:1. UI components 3:1. No color-only info. Usable at 200% zoom. Touch targets 44x44px.

## 10. Component Accessibility Requirements

| Component | Key Requirements |
|-----------|-----------------|
| Button | Descriptive text or aria-label, visible focus, disabled state announced |
| Input | Visible label, error with aria-invalid, aria-describedby |
| Modal | role="dialog", aria-modal, focus trap, Escape closes |
| Tabs | role="tablist/tab/tabpanel", aria-selected, arrow keys |
| Data Table | caption, th with scope, aria-sort on sortable headers |
| Dropdown | aria-haspopup, aria-expanded, keyboard nav |
| Toast/Alert | role="alert" or aria-live, sufficient auto-dismiss time |
| Pagination | nav with aria-label, aria-current="page" |
