---
name: design-ui
description: Create wireframes, design components, run accessibility audits, or build design systems
argument-hint: "[task: wireframe|component|accessibility|design-system] description of what you need"
---

## Design UI

Plan and execute UI/UX design tasks using the UI/UX designer. Request: $ARGUMENTS

### Agents Involved
- **ui-ux-designer** — Wireframes, component design, accessibility, design systems
- **frontend-engineer** — Technical feasibility and implementation guidance
- **qa-agent** — Accessibility testing and cross-browser validation

### Steps

1. **Understand the Request**
   - Parse the design task type (wireframe, component, accessibility audit, design system)
   - Identify the target users and use cases
   - Review existing design patterns and brand guidelines in the project

2. **Wireframing** (if wireframe task)
   - Define the user flow and screen hierarchy
   - Create low-fidelity wireframe descriptions for each screen
   - Annotate interactive elements, navigation, and data display areas
   - Specify responsive breakpoints (mobile, tablet, desktop)
   - Document user interactions (clicks, hover states, transitions)

3. **Component Design** (if component task)
   - Define the component API (props, events, slots)
   - Specify visual states (default, hover, focus, active, disabled, error, loading)
   - Document spacing, typography, and color usage
   - Provide code structure using project conventions (Vue/React)
   - Ensure the component follows atomic design principles (atom, molecule, organism)

4. **Accessibility Audit** (if accessibility task)
   - Check WCAG 2.1 AA compliance across the target area
   - Verify keyboard navigation and focus management
   - Review color contrast ratios (minimum 4.5:1 for text)
   - Check screen reader compatibility (ARIA labels, roles, live regions)
   - Validate form labels, error messages, and focus indicators
   - Generate a prioritized list of accessibility issues with fixes

5. **Design System** (if design-system task)
   - Define or extend the design token set (colors, typography, spacing, shadows)
   - Document component library with usage guidelines
   - Create pattern documentation (forms, tables, navigation, modals)
   - Establish naming conventions and file organization
   - Define contribution guidelines for adding new components

6. **Deliver Results**
   - Document all design decisions with rationale
   - Include visual specifications (sizes, spacing, colors as tokens)
   - Provide implementation notes for the frontend engineer
   - Save design documentation to the appropriate project location

### Output
UI/UX deliverables matching the requested task type, including annotated wireframes, component specifications, accessibility audit reports, or design system documentation.
