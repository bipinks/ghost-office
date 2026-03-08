---
name: prompt-design
description: "Prompt engineering patterns, system prompt design, and prompt optimization techniques"
user-invocable: true
allowed-tools: ["Read", "Write", "Edit", "Bash", "Grep", "Glob"]
---

# Prompt Design

Patterns for designing, structuring, and optimizing prompts for LLMs.

---

## 1. RCICOFE Framework

Every prompt follows this layered structure:

```
R — Role:        Who the model should act as
C — Context:     Background information
I — Instructions: The task
C — Constraints:  Boundaries and rules
O — Output:       Desired format
F — Few-shot:     Input/output examples
E — Edge cases:   How to handle unusual inputs
```

### Minimal Template

```python
PROMPT_TEMPLATE = """
You are {role}.

## Context
{context}

## Task
{instructions}

## Constraints
{constraints}

## Output Format
{output_format}
""".strip()
```

---

## 2. Few-Shot Patterns

### Diverse Few-Shot

Cover different scenarios, edge cases, and output variations.

```python
FEW_SHOT_CLASSIFICATION = """
Classify the support ticket into exactly one category.
Categories: billing, technical, account, feature_request, other

## Examples
Ticket: "I was charged twice for my subscription this month"
Category: billing
Reasoning: Duplicate charge is a billing issue

Ticket: "The export button throws a 500 error"
Category: technical
Reasoning: Application error is a technical issue

Ticket: "I was charged twice AND the receipt page shows a 404"
Category: billing
Reasoning: When multiple categories apply, choose the primary user concern

## Now classify:
Ticket: "{ticket_text}"
Category:
"""
```

### Negative Examples

Show both good and bad outputs with explanations of why.

### Dynamic Few-Shot Selection

Use embedding similarity to select the most relevant examples for each input. Ensure category diversity in selection to avoid bias.

---

## 3. Chain-of-Thought (CoT)

### Explicit CoT

Guide the model through numbered reasoning steps before the final answer. Define each step (identify pattern, check indexes, analyze volume, identify bottlenecks, propose fixes, write optimized version).

### Zero-Shot CoT

Append "Think through this step by step, considering:" followed by a checklist of dimensions to evaluate.

### Self-Consistency

Run the same prompt N times at temperature 0.7, then majority-vote the answers. Return the winner with confidence = count/N.

---

## 4. System Prompt Design

### Layered System Prompt

```python
SYSTEM_PROMPT = """
# Identity
You are FinanceBot for a multi-branch ERP system.

# Capabilities
- Answer accounting procedure questions
- Help with journal entries
- Explain financial reports
- Cannot: approve transactions, modify data, access other branches

# Behavior Rules
1. Verify branch context before answering
2. Format currency as {currency_symbol}#,###.##
3. Amounts over {approval_threshold} trigger approval reminder
4. Never display full bank account numbers

# Error Handling
- Unsure about policy: say so, suggest contacting finance manager
- Cross-branch request: explain data isolation policy
"""
```

### Role + Guardrails Separation

Define the role/expertise in one block, safety guardrails in another. Combine at runtime. Guardrails cover: no secrets in examples, no disabling security, always include health checks, warn before destructive ops.

### Dynamic Assembly

Build prompts from composable sections (role, capabilities, restrictions, tools, style rules) with runtime variable injection per user context.

---

## 5. Template Engine

Key features for a production prompt template system:
- Auto-detect `{variable}` placeholders
- Validate required variables before rendering
- Sanitize values against prompt injection patterns
- Support preview mode with unfilled placeholders

```python
class PromptTemplate:
    def __init__(self, template: str):
        self.template = template
        self.required_vars = re.findall(r'\{(\w+)\}', template)

    def render(self, **kwargs) -> str:
        missing = [v for v in self.required_vars if v not in kwargs]
        if missing:
            raise ValueError(f"Missing: {missing}")
        result = self.template
        for key, value in kwargs.items():
            result = result.replace(f"{{{key}}}", self._sanitize(str(value)))
        return result

    def _sanitize(self, value: str) -> str:
        injection_patterns = ["ignore previous instructions", "new instructions:", "system prompt:"]
        if any(p in value.lower() for p in injection_patterns):
            raise ValueError("Potential prompt injection detected")
        return value
```

---

## 6. Prompt Versioning and A/B Testing

- Register prompts with name, version, template, and content hash
- Activate versions independently of deployment
- A/B test with deterministic traffic split based on request ID hash
- Track metadata (author, accuracy, created_at) per version
- Maintain a registry that supports `get_for_request(name, request_id)`

---

## 7. Token Optimization

| Technique | Before | After |
|-----------|--------|-------|
| Trim redundancy | "I would like you to please analyze..." | "Summarize the key points:" |
| Structured shorthand | Long paragraph of format rules | Bullet list of format rules |
| Output budgeting | Open-ended response | "VERDICT: [word] / REASON: [sentence] / CONFIDENCE: [H/M/L]" |
| Context compression | Full documents | Key sentences (first + last per paragraph) |

---

## 8. Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| Vague instructions | "Help me with this code" | Specify: review for correctness, performance, readability |
| Contradictory constraints | "Be thorough" + "Under 50 words" | Align scope with length |
| Over-prompting | 40 rigid procedural steps | Clear goal with flexible execution |
| Missing context | "Fix this SQL query" | Include schema, constraints, multi-tenant rules |
| Injection vulnerability | `f"Translate: {user_input}"` | Delimit user content with XML tags |

---

## 9. Prompt Organization

```
prompts/
├── system/          # Persistent behavior prompts
├── tasks/           # Task-specific (classification, extraction, generation, analysis)
├── templates/       # Reusable components (output formats, guardrails, few-shot banks)
├── tests/           # Prompt test cases
├── registry.py      # Version registry
└── config.py
```

Use composable enums for output format (JSON, Markdown, CSV) and guardrails (NO_PII, NO_HALLUCINATION, BRANCH_ISOLATION). Compose prompts from these building blocks.

---

## 10. Checklist

### Structure
- [ ] Clear role, context, task, constraints, output format, edge cases
- [ ] Few-shot examples cover diverse scenarios (positive and negative)

### Safety
- [ ] User input delimited with XML tags
- [ ] Prompt injection defenses in sanitization layer
- [ ] No sensitive data in templates
- [ ] Multi-tenant isolation enforced in context

### Operations
- [ ] Version-controlled with content hash
- [ ] Test cases for each prompt
- [ ] Performance baseline established
- [ ] Rollback plan for prompt changes
