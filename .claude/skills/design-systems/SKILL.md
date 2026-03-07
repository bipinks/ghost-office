---
name: design-systems
description: Use when building or maintaining design systems, design tokens, component libraries, theming, or visual consistency. Covers token architecture, component variants, spacing/typography scales, color systems, dark/light mode, and design documentation.
user-invocable: false
allowed-tools: ["Read", "Write", "Edit", "Grep", "Glob"]
---

# Design Systems -- Building Consistent, Scalable UI

## 1. Design Token Architecture

Design tokens are the atomic values that define a design system. They encode colors, typography, spacing, shadows, borders, and motion into a format consumable by code.

### Token Hierarchy

```
Global Tokens (primitives)
  -> Alias Tokens (semantic)
    -> Component Tokens (scoped)
```

- **Global tokens**: Raw values with no semantic meaning (`blue-500: #3B82F6`)
- **Alias tokens**: Semantic references (`color-primary: {blue-500}`)
- **Component tokens**: Scoped to a component (`button-bg-primary: {color-primary}`)

### Token Naming Convention

```
{category}-{property}-{variant}-{state}
```

Examples:
- `color-bg-primary`
- `color-text-secondary`
- `color-border-error`
- `spacing-md`
- `font-size-heading-lg`
- `shadow-elevation-2`
- `radius-button`

---

## 2. Token Formats

### JSON Token Definition (W3C Design Tokens Format)

```json
{
  "color": {
    "primitive": {
      "blue": {
        "50":  { "$value": "#EFF6FF", "$type": "color" },
        "100": { "$value": "#DBEAFE", "$type": "color" },
        "200": { "$value": "#BFDBFE", "$type": "color" },
        "300": { "$value": "#93C5FD", "$type": "color" },
        "400": { "$value": "#60A5FA", "$type": "color" },
        "500": { "$value": "#3B82F6", "$type": "color" },
        "600": { "$value": "#2563EB", "$type": "color" },
        "700": { "$value": "#1D4ED8", "$type": "color" },
        "800": { "$value": "#1E40AF", "$type": "color" },
        "900": { "$value": "#1E3A8A", "$type": "color" }
      },
      "gray": {
        "50":  { "$value": "#F9FAFB", "$type": "color" },
        "100": { "$value": "#F3F4F6", "$type": "color" },
        "200": { "$value": "#E5E7EB", "$type": "color" },
        "300": { "$value": "#D1D5DB", "$type": "color" },
        "400": { "$value": "#9CA3AF", "$type": "color" },
        "500": { "$value": "#6B7280", "$type": "color" },
        "600": { "$value": "#4B5563", "$type": "color" },
        "700": { "$value": "#374151", "$type": "color" },
        "800": { "$value": "#1F2937", "$type": "color" },
        "900": { "$value": "#111827", "$type": "color" }
      }
    },
    "semantic": {
      "primary":   { "$value": "{color.primitive.blue.600}", "$type": "color" },
      "secondary": { "$value": "{color.primitive.gray.600}", "$type": "color" },
      "success":   { "$value": "#059669", "$type": "color" },
      "warning":   { "$value": "#D97706", "$type": "color" },
      "error":     { "$value": "#DC2626", "$type": "color" },
      "info":      { "$value": "#2563EB", "$type": "color" }
    }
  }
}
```

### CSS Custom Properties

```css
/* tokens/colors.css */
:root {
  /* Primitives */
  --color-blue-50: #EFF6FF;
  --color-blue-500: #3B82F6;
  --color-blue-600: #2563EB;
  --color-blue-700: #1D4ED8;

  --color-gray-50: #F9FAFB;
  --color-gray-100: #F3F4F6;
  --color-gray-200: #E5E7EB;
  --color-gray-700: #374151;
  --color-gray-800: #1F2937;
  --color-gray-900: #111827;

  /* Semantic */
  --color-primary: var(--color-blue-600);
  --color-primary-hover: var(--color-blue-700);
  --color-primary-light: var(--color-blue-50);

  --color-bg-page: var(--color-gray-50);
  --color-bg-surface: #FFFFFF;
  --color-bg-elevated: #FFFFFF;

  --color-text-primary: var(--color-gray-900);
  --color-text-secondary: var(--color-gray-600);
  --color-text-muted: var(--color-gray-400);
  --color-text-inverse: #FFFFFF;

  --color-border-default: var(--color-gray-200);
  --color-border-strong: var(--color-gray-300);

  --color-state-success: #059669;
  --color-state-warning: #D97706;
  --color-state-error: #DC2626;
  --color-state-info: #2563EB;
}
```

### Tailwind CSS Config Integration

```typescript
// tailwind.config.ts
import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./src/**/*.{vue,ts,tsx,html}'],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: 'var(--color-primary)',
          hover: 'var(--color-primary-hover)',
          light: 'var(--color-primary-light)',
        },
        surface: 'var(--color-bg-surface)',
        page: 'var(--color-bg-page)',
        state: {
          success: 'var(--color-state-success)',
          warning: 'var(--color-state-warning)',
          error: 'var(--color-state-error)',
          info: 'var(--color-state-info)',
        },
      },
      spacing: {
        '4.5': '1.125rem', /* 18px */
        '13': '3.25rem',   /* 52px */
        '15': '3.75rem',   /* 60px */
      },
      fontSize: {
        'heading-xl': ['2rem', { lineHeight: '2.5rem', fontWeight: '700' }],
        'heading-lg': ['1.5rem', { lineHeight: '2rem', fontWeight: '600' }],
        'heading-md': ['1.25rem', { lineHeight: '1.75rem', fontWeight: '600' }],
        'heading-sm': ['1.125rem', { lineHeight: '1.5rem', fontWeight: '600' }],
        'body-lg': ['1rem', { lineHeight: '1.5rem' }],
        'body-md': ['0.875rem', { lineHeight: '1.25rem' }],
        'body-sm': ['0.75rem', { lineHeight: '1rem' }],
        'caption': ['0.6875rem', { lineHeight: '0.875rem' }],
      },
      borderRadius: {
        'card': '0.5rem',
        'button': '0.375rem',
        'input': '0.375rem',
        'badge': '9999px',
      },
      boxShadow: {
        'elevation-1': '0 1px 2px 0 rgba(0,0,0,0.05)',
        'elevation-2': '0 1px 3px 0 rgba(0,0,0,0.1), 0 1px 2px -1px rgba(0,0,0,0.1)',
        'elevation-3': '0 4px 6px -1px rgba(0,0,0,0.1), 0 2px 4px -2px rgba(0,0,0,0.1)',
        'elevation-4': '0 10px 15px -3px rgba(0,0,0,0.1), 0 4px 6px -4px rgba(0,0,0,0.1)',
      },
    },
  },
  plugins: [],
};

export default config;
```

---

## 3. Spacing Scale

Use a base-4/base-8 spacing system for consistent rhythm.

```
--spacing-0:   0
--spacing-px:  1px
--spacing-0.5: 0.125rem  /*  2px */
--spacing-1:   0.25rem   /*  4px */
--spacing-1.5: 0.375rem  /*  6px */
--spacing-2:   0.5rem    /*  8px */
--spacing-3:   0.75rem   /* 12px */
--spacing-4:   1rem      /* 16px */
--spacing-5:   1.25rem   /* 20px */
--spacing-6:   1.5rem    /* 24px */
--spacing-8:   2rem      /* 32px */
--spacing-10:  2.5rem    /* 40px */
--spacing-12:  3rem      /* 48px */
--spacing-16:  4rem      /* 64px */
--spacing-20:  5rem      /* 80px */
--spacing-24:  6rem      /* 96px */
```

### Spacing Usage Guidelines

| Context | Token | Example |
|---------|-------|---------|
| Inline element gap | `spacing-1` to `spacing-2` | Icon + label (4-8px) |
| Form field gap | `spacing-4` to `spacing-5` | Between label and input (16-20px) |
| Section padding | `spacing-6` to `spacing-8` | Card body padding (24-32px) |
| Section gap | `spacing-8` to `spacing-12` | Between page sections (32-48px) |
| Page margin | `spacing-6` to `spacing-8` | Page edge padding (24-32px) |

---

## 4. Typography Scale

```css
:root {
  /* Font families */
  --font-sans: 'Inter', system-ui, -apple-system, sans-serif;
  --font-mono: 'JetBrains Mono', 'Fira Code', monospace;

  /* Font sizes */
  --text-xs:   0.75rem;   /* 12px */
  --text-sm:   0.875rem;  /* 14px */
  --text-base: 1rem;      /* 16px */
  --text-lg:   1.125rem;  /* 18px */
  --text-xl:   1.25rem;   /* 20px */
  --text-2xl:  1.5rem;    /* 24px */
  --text-3xl:  1.875rem;  /* 30px */
  --text-4xl:  2.25rem;   /* 36px */

  /* Line heights */
  --leading-tight:  1.25;
  --leading-snug:   1.375;
  --leading-normal: 1.5;
  --leading-relaxed: 1.625;

  /* Font weights */
  --font-regular:  400;
  --font-medium:   500;
  --font-semibold: 600;
  --font-bold:     700;
}
```

### Typography Roles

| Role | Size | Weight | Line Height | Use Case |
|------|------|--------|-------------|----------|
| Display | `text-4xl` | Bold | Tight | Hero sections, empty states |
| Heading 1 | `text-2xl` | Semibold | Tight | Page titles |
| Heading 2 | `text-xl` | Semibold | Snug | Section titles |
| Heading 3 | `text-lg` | Semibold | Snug | Card titles |
| Body | `text-base` | Regular | Normal | Default text |
| Body small | `text-sm` | Regular | Normal | Secondary text, table cells |
| Caption | `text-xs` | Regular | Normal | Labels, timestamps, badges |
| Code | `text-sm` | Regular (mono) | Normal | Code snippets, IDs |

---

## 5. Color System

### Semantic Color Mapping

```typescript
// tokens/colors.ts
export const semanticColors = {
  // Backgrounds
  bg: {
    page: 'gray-50',
    surface: 'white',
    elevated: 'white',
    muted: 'gray-100',
    inverse: 'gray-900',
  },
  // Text
  text: {
    primary: 'gray-900',
    secondary: 'gray-600',
    muted: 'gray-400',
    inverse: 'white',
    link: 'blue-600',
    linkHover: 'blue-700',
  },
  // Borders
  border: {
    default: 'gray-200',
    strong: 'gray-300',
    focus: 'blue-500',
  },
  // Status/state colors
  status: {
    success: { bg: 'green-50', text: 'green-700', border: 'green-200', icon: 'green-500' },
    warning: { bg: 'amber-50', text: 'amber-700', border: 'amber-200', icon: 'amber-500' },
    error:   { bg: 'red-50',   text: 'red-700',   border: 'red-200',   icon: 'red-500' },
    info:    { bg: 'blue-50',  text: 'blue-700',  border: 'blue-200',  icon: 'blue-500' },
  },
  // Interactive
  interactive: {
    default: 'blue-600',
    hover: 'blue-700',
    active: 'blue-800',
    disabled: 'gray-300',
    focus: 'blue-500',
  },
} as const;
```

### State Colors for Data

```css
/* Document/record status colors */
.status-draft     { --status-color: var(--color-gray-500); }
.status-pending   { --status-color: var(--color-amber-500); }
.status-approved  { --status-color: var(--color-green-500); }
.status-rejected  { --status-color: var(--color-red-500); }
.status-paid      { --status-color: var(--color-blue-500); }
.status-overdue   { --status-color: var(--color-red-600); }
.status-cancelled { --status-color: var(--color-gray-400); }
```

---

## 6. Dark Mode / Theming

### CSS Custom Property Theme Switching

```css
/* tokens/theme-light.css */
:root, [data-theme="light"] {
  --color-bg-page: #F9FAFB;
  --color-bg-surface: #FFFFFF;
  --color-bg-elevated: #FFFFFF;
  --color-bg-muted: #F3F4F6;
  --color-text-primary: #111827;
  --color-text-secondary: #4B5563;
  --color-text-muted: #9CA3AF;
  --color-border-default: #E5E7EB;
  --color-shadow-base: rgba(0, 0, 0, 0.1);
}

/* tokens/theme-dark.css */
[data-theme="dark"] {
  --color-bg-page: #111827;
  --color-bg-surface: #1F2937;
  --color-bg-elevated: #374151;
  --color-bg-muted: #1F2937;
  --color-text-primary: #F9FAFB;
  --color-text-secondary: #D1D5DB;
  --color-text-muted: #6B7280;
  --color-border-default: #374151;
  --color-shadow-base: rgba(0, 0, 0, 0.4);
}
```

### Theme Toggle Composable

```typescript
// composables/useTheme.ts
import { ref, watch, onMounted } from 'vue';

type Theme = 'light' | 'dark' | 'system';

const STORAGE_KEY = 'app-theme';
const currentTheme = ref<Theme>('system');

export function useTheme() {
  function getSystemTheme(): 'light' | 'dark' {
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  }

  function applyTheme(theme: Theme) {
    const resolved = theme === 'system' ? getSystemTheme() : theme;
    document.documentElement.setAttribute('data-theme', resolved);
    if (resolved === 'dark') {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  }

  function setTheme(theme: Theme) {
    currentTheme.value = theme;
    localStorage.setItem(STORAGE_KEY, theme);
    applyTheme(theme);
  }

  onMounted(() => {
    const stored = localStorage.getItem(STORAGE_KEY) as Theme | null;
    currentTheme.value = stored ?? 'system';
    applyTheme(currentTheme.value);

    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
      if (currentTheme.value === 'system') applyTheme('system');
    });
  });

  return { currentTheme, setTheme };
}
```

### Brand Theming (Multi-tenant)

```css
/* Brand overrides per tenant */
[data-brand="acme"] {
  --color-primary: #7C3AED;
  --color-primary-hover: #6D28D9;
  --color-primary-light: #EDE9FE;
}

[data-brand="globex"] {
  --color-primary: #059669;
  --color-primary-hover: #047857;
  --color-primary-light: #ECFDF5;
}
```

---

## 7. Component Variant Patterns

### Button Variants

```vue
<!-- components/common/AppButton.vue -->
<script setup lang="ts">
type Variant = 'primary' | 'secondary' | 'outline' | 'ghost' | 'danger';
type Size = 'sm' | 'md' | 'lg';

interface Props {
  variant?: Variant;
  size?: Size;
  disabled?: boolean;
  loading?: boolean;
  icon?: string;
}

withDefaults(defineProps<Props>(), {
  variant: 'primary',
  size: 'md',
  disabled: false,
  loading: false,
});

const variantClasses: Record<Variant, string> = {
  primary: 'bg-primary text-white hover:bg-primary-hover focus:ring-primary/50',
  secondary: 'bg-gray-100 text-gray-700 hover:bg-gray-200 focus:ring-gray-300',
  outline: 'border border-gray-300 text-gray-700 hover:bg-gray-50 focus:ring-primary/50',
  ghost: 'text-gray-600 hover:bg-gray-100 hover:text-gray-900 focus:ring-gray-300',
  danger: 'bg-red-600 text-white hover:bg-red-700 focus:ring-red-500/50',
};

const sizeClasses: Record<Size, string> = {
  sm: 'px-3 py-1.5 text-sm gap-1.5',
  md: 'px-4 py-2 text-sm gap-2',
  lg: 'px-6 py-3 text-base gap-2.5',
};
</script>

<template>
  <button
    :class="[
      'inline-flex items-center justify-center font-medium rounded-button',
      'focus:outline-none focus:ring-2 focus:ring-offset-2',
      'transition-colors duration-150',
      'disabled:opacity-50 disabled:cursor-not-allowed',
      variantClasses[variant],
      sizeClasses[size],
    ]"
    :disabled="disabled || loading"
    v-bind="$attrs"
  >
    <svg v-if="loading" class="animate-spin -ml-1 h-4 w-4" viewBox="0 0 24 24" aria-hidden="true">
      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" fill="none" />
      <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
    </svg>
    <slot />
  </button>
</template>
```

### Badge Variants

```vue
<!-- components/common/AppBadge.vue -->
<script setup lang="ts">
type BadgeVariant = 'default' | 'success' | 'warning' | 'error' | 'info';

const props = withDefaults(defineProps<{ variant?: BadgeVariant; dot?: boolean }>(), {
  variant: 'default',
  dot: false,
});

const classes: Record<BadgeVariant, string> = {
  default: 'bg-gray-100 text-gray-700',
  success: 'bg-green-50 text-green-700',
  warning: 'bg-amber-50 text-amber-700',
  error: 'bg-red-50 text-red-700',
  info: 'bg-blue-50 text-blue-700',
};
</script>

<template>
  <span :class="['inline-flex items-center gap-1 px-2 py-0.5 rounded-badge text-xs font-medium', classes[variant]]">
    <span v-if="dot" :class="['w-1.5 h-1.5 rounded-full', {
      'bg-gray-500': variant === 'default',
      'bg-green-500': variant === 'success',
      'bg-amber-500': variant === 'warning',
      'bg-red-500': variant === 'error',
      'bg-blue-500': variant === 'info',
    }]" />
    <slot />
  </span>
</template>
```

---

## 8. Icon System

### SVG Icon Component

```vue
<!-- components/common/AppIcon.vue -->
<script setup lang="ts">
import { computed, defineAsyncComponent } from 'vue';

const props = withDefaults(defineProps<{
  name: string;
  size?: 'xs' | 'sm' | 'md' | 'lg' | 'xl';
}>(), { size: 'md' });

const sizeMap = { xs: 'w-3 h-3', sm: 'w-4 h-4', md: 'w-5 h-5', lg: 'w-6 h-6', xl: 'w-8 h-8' };

const iconComponent = computed(() =>
  defineAsyncComponent(() => import(`../../assets/icons/${props.name}.svg`))
);
</script>

<template>
  <component :is="iconComponent" :class="sizeMap[size]" aria-hidden="true" />
</template>
```

### Icon Guidelines

- Use a single icon library consistently (Heroicons, Lucide, Phosphor)
- Always set `aria-hidden="true"` on decorative icons
- Provide `aria-label` on icon-only buttons
- Use 20x20 or 24x24 SVGs as the base size
- Ensure icons have `currentColor` for fill/stroke so they inherit text color

---

## 9. Component Documentation

### Storybook Story Format

```typescript
// components/common/AppButton.stories.ts
import type { Meta, StoryObj } from '@storybook/vue3';
import AppButton from './AppButton.vue';

const meta: Meta<typeof AppButton> = {
  title: 'Common/Button',
  component: AppButton,
  tags: ['autodocs'],
  argTypes: {
    variant: { control: 'select', options: ['primary', 'secondary', 'outline', 'ghost', 'danger'] },
    size: { control: 'select', options: ['sm', 'md', 'lg'] },
    disabled: { control: 'boolean' },
    loading: { control: 'boolean' },
  },
};

export default meta;
type Story = StoryObj<typeof AppButton>;

export const Primary: Story = {
  args: { variant: 'primary' },
  render: (args) => ({
    components: { AppButton },
    setup() { return { args }; },
    template: '<AppButton v-bind="args">Save Invoice</AppButton>',
  }),
};

export const AllVariants: Story = {
  render: () => ({
    components: { AppButton },
    template: `
      <div class="flex gap-4 items-center">
        <AppButton variant="primary">Primary</AppButton>
        <AppButton variant="secondary">Secondary</AppButton>
        <AppButton variant="outline">Outline</AppButton>
        <AppButton variant="ghost">Ghost</AppButton>
        <AppButton variant="danger">Danger</AppButton>
      </div>
    `,
  }),
};
```

---

## 10. Design System Checklist

### Foundation
- [ ] Color palette defined (primitives + semantic tokens)
- [ ] Typography scale defined (sizes, weights, line heights)
- [ ] Spacing scale defined (base-4 or base-8)
- [ ] Border radius tokens defined
- [ ] Shadow/elevation tokens defined
- [ ] Breakpoint tokens defined

### Components
- [ ] Button (all variants, sizes, states)
- [ ] Input / TextField (with label, error, helper text)
- [ ] Select / Dropdown
- [ ] Checkbox / Radio / Toggle
- [ ] Badge / Tag
- [ ] Alert / Notification
- [ ] Modal / Dialog
- [ ] Card
- [ ] Data Table
- [ ] Pagination
- [ ] Breadcrumb
- [ ] Tabs
- [ ] Tooltip
- [ ] Avatar
- [ ] Empty State
- [ ] Skeleton / Loading

### Theming
- [ ] Light theme tokens complete
- [ ] Dark theme tokens complete
- [ ] Theme toggle implemented
- [ ] Brand/tenant override mechanism
- [ ] Consistent use of semantic tokens (no hardcoded colors)

### Documentation
- [ ] Token reference page
- [ ] Component catalog (Storybook or equivalent)
- [ ] Usage guidelines per component
- [ ] Do/Don't examples
- [ ] Accessibility notes per component
