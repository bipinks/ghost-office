---
name: design-systems
description: Use when building or maintaining design systems, design tokens, component libraries, theming, or visual consistency. Covers token architecture, component variants, spacing/typography scales, color systems, dark/light mode, and design documentation.
user-invocable: false
allowed-tools: ["Read", "Write", "Edit", "Grep", "Glob"]
---

# Design Systems -- Building Consistent, Scalable UI

## 1. Design Token Architecture

```
Global Tokens (primitives: blue-500: #3B82F6)
  -> Alias Tokens (semantic: color-primary: {blue-600})
    -> Component Tokens (scoped: button-bg-primary: {color-primary})
```

**Naming**: `{category}-{property}-{variant}-{state}` -- e.g., `color-bg-primary`, `spacing-md`, `font-size-heading-lg`, `shadow-elevation-2`.

### CSS Custom Properties
```css
:root {
  /* Primitives */
  --color-blue-500: #3B82F6; --color-blue-600: #2563EB; --color-blue-700: #1D4ED8;
  --color-gray-50: #F9FAFB; --color-gray-200: #E5E7EB; --color-gray-600: #4B5563;
  --color-gray-900: #111827;

  /* Semantic */
  --color-primary: var(--color-blue-600);
  --color-primary-hover: var(--color-blue-700);
  --color-bg-page: var(--color-gray-50);
  --color-bg-surface: #FFFFFF;
  --color-text-primary: var(--color-gray-900);
  --color-text-secondary: var(--color-gray-600);
  --color-border-default: var(--color-gray-200);
  --color-state-success: #059669; --color-state-warning: #D97706;
  --color-state-error: #DC2626; --color-state-info: #2563EB;
}
```

### Tailwind Integration
```typescript
// tailwind.config.ts
export default {
  darkMode: 'class',
  theme: { extend: {
    colors: {
      primary: { DEFAULT: 'var(--color-primary)', hover: 'var(--color-primary-hover)' },
      state: { success: 'var(--color-state-success)', warning: 'var(--color-state-warning)',
               error: 'var(--color-state-error)', info: 'var(--color-state-info)' },
    },
    borderRadius: { card: '0.5rem', button: '0.375rem', input: '0.375rem', badge: '9999px' },
    boxShadow: {
      'elevation-1': '0 1px 2px 0 rgba(0,0,0,0.05)',
      'elevation-2': '0 1px 3px 0 rgba(0,0,0,0.1), 0 1px 2px -1px rgba(0,0,0,0.1)',
      'elevation-3': '0 4px 6px -1px rgba(0,0,0,0.1), 0 2px 4px -2px rgba(0,0,0,0.1)',
    },
  }},
};
```

## 2. Spacing Scale (base-4/base-8)

```
0: 0  |  1: 4px  |  2: 8px  |  3: 12px  |  4: 16px  |  6: 24px  |  8: 32px  |  12: 48px  |  16: 64px
```

| Context | Token | Size |
|---------|-------|------|
| Inline gap (icon + label) | `spacing-1` to `spacing-2` | 4-8px |
| Form field gap | `spacing-4` | 16px |
| Card body padding | `spacing-6` to `spacing-8` | 24-32px |
| Section gap | `spacing-8` to `spacing-12` | 32-48px |

## 3. Typography Scale

```css
:root {
  --font-sans: 'Inter', system-ui, sans-serif;
  --font-mono: 'JetBrains Mono', monospace;
}
```

| Role | Size | Weight | Use Case |
|------|------|--------|----------|
| Display | 2.25rem | Bold | Hero sections, empty states |
| Heading 1 | 1.5rem | Semibold | Page titles |
| Heading 2 | 1.25rem | Semibold | Section titles |
| Heading 3 | 1.125rem | Semibold | Card titles |
| Body | 1rem | Regular | Default text |
| Body small | 0.875rem | Regular | Secondary text, table cells |
| Caption | 0.75rem | Regular | Labels, timestamps, badges |

## 4. Color System

### Status Colors
```css
.status-draft     { color: var(--color-gray-500); }
.status-pending   { color: var(--color-amber-500); }
.status-approved  { color: var(--color-green-500); }
.status-rejected  { color: var(--color-red-500); }
.status-overdue   { color: var(--color-red-600); }
```

Each status needs: bg (light tint), text (dark shade), border, icon color. Never convey status by color alone.

## 5. Dark Mode / Theming

```css
:root, [data-theme="light"] {
  --color-bg-page: #F9FAFB; --color-bg-surface: #FFFFFF;
  --color-text-primary: #111827; --color-text-secondary: #4B5563;
  --color-border-default: #E5E7EB; --color-shadow-base: rgba(0,0,0,0.1);
}
[data-theme="dark"] {
  --color-bg-page: #111827; --color-bg-surface: #1F2937;
  --color-text-primary: #F9FAFB; --color-text-secondary: #D1D5DB;
  --color-border-default: #374151; --color-shadow-base: rgba(0,0,0,0.4);
}
```

### Theme Toggle (Vue)
```typescript
export function useTheme() {
  const theme = ref<'light' | 'dark' | 'system'>('system');
  function apply(t: typeof theme.value) {
    const resolved = t === 'system'
      ? (matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light') : t;
    document.documentElement.setAttribute('data-theme', resolved);
    document.documentElement.classList.toggle('dark', resolved === 'dark');
  }
  function set(t: typeof theme.value) { theme.value = t; localStorage.setItem('theme', t); apply(t); }
  onMounted(() => { theme.value = (localStorage.getItem('theme') as any) ?? 'system'; apply(theme.value); });
  return { theme, set };
}
```

### Multi-tenant Brand Override
```css
[data-brand="acme"]   { --color-primary: #7C3AED; --color-primary-hover: #6D28D9; }
[data-brand="globex"] { --color-primary: #059669; --color-primary-hover: #047857; }
```

## 6. Component Variants

### Button
```vue
<script setup lang="ts">
type Variant = 'primary' | 'secondary' | 'outline' | 'ghost' | 'danger';
type Size = 'sm' | 'md' | 'lg';
const props = withDefaults(defineProps<{ variant?: Variant; size?: Size; loading?: boolean; disabled?: boolean }>(),
  { variant: 'primary', size: 'md' });

const variants: Record<Variant, string> = {
  primary: 'bg-primary text-white hover:bg-primary-hover',
  secondary: 'bg-gray-100 text-gray-700 hover:bg-gray-200',
  outline: 'border border-gray-300 text-gray-700 hover:bg-gray-50',
  ghost: 'text-gray-600 hover:bg-gray-100',
  danger: 'bg-red-600 text-white hover:bg-red-700',
};
const sizes: Record<Size, string> = { sm: 'px-3 py-1.5 text-sm', md: 'px-4 py-2 text-sm', lg: 'px-6 py-3 text-base' };
</script>
<template>
  <button :class="['inline-flex items-center justify-center font-medium rounded-button focus:ring-2 focus:ring-offset-2 transition-colors disabled:opacity-50', variants[variant], sizes[size]]"
    :disabled="disabled || loading"><slot /></button>
</template>
```

### Badge
```vue
<script setup lang="ts">
type V = 'default' | 'success' | 'warning' | 'error' | 'info';
const props = withDefaults(defineProps<{ variant?: V; dot?: boolean }>(), { variant: 'default' });
const cls: Record<V, string> = { default: 'bg-gray-100 text-gray-700', success: 'bg-green-50 text-green-700',
  warning: 'bg-amber-50 text-amber-700', error: 'bg-red-50 text-red-700', info: 'bg-blue-50 text-blue-700' };
</script>
<template>
  <span :class="['inline-flex items-center gap-1 px-2 py-0.5 rounded-badge text-xs font-medium', cls[variant]]">
    <span v-if="dot" class="w-1.5 h-1.5 rounded-full bg-current opacity-60" /><slot />
  </span>
</template>
```

## 7. Icon System

Use a single library consistently (Heroicons, Lucide, Phosphor). Always `aria-hidden="true"` on decorative icons. `aria-label` on icon-only buttons. SVGs at 20x20 or 24x24 with `currentColor` fill/stroke.

## 8. Documentation (Storybook)

```typescript
const meta: Meta<typeof AppButton> = {
  title: 'Common/Button', component: AppButton, tags: ['autodocs'],
  argTypes: {
    variant: { control: 'select', options: ['primary', 'secondary', 'outline', 'ghost', 'danger'] },
    size: { control: 'select', options: ['sm', 'md', 'lg'] },
  },
};
export const Primary: Story = {
  args: { variant: 'primary' },
  render: (args) => ({ components: { AppButton }, setup: () => ({ args }),
    template: '<AppButton v-bind="args">Save Invoice</AppButton>' }),
};
```

## 9. Checklist

**Foundation**: Color palette (primitives + semantic), typography scale, spacing scale, border radius, shadows, breakpoints.
**Components**: Button, Input, Select, Checkbox/Radio/Toggle, Badge, Alert, Modal, Card, DataTable, Pagination, Breadcrumb, Tabs, Tooltip, Avatar, Empty State, Skeleton.
**Theming**: Light + dark tokens, toggle, brand/tenant override, no hardcoded colors.
**Docs**: Token reference, component catalog, usage guidelines, do/don't examples, accessibility notes.
