---
name: prompt-design
description: "Prompt engineering patterns, system prompt design, and prompt optimization techniques"
user-invocable: true
allowed-tools: ["Read", "Write", "Edit", "Bash", "Grep", "Glob"]
---

# Prompt Design

Comprehensive reference for designing, structuring, and optimizing prompts for large language models. Covers prompt architecture, few-shot patterns, chain-of-thought reasoning, system prompt design, template management, and production optimization.

---

## 1. Prompt Structure Framework

Every effective prompt follows a layered structure. Use this framework as your starting point for any prompt design task.

### The RCICOFE Framework

```
R — Role:        Who the model should act as
C — Context:     Background information and situation
I — Instructions: What the model should do (the task)
C — Constraints:  Boundaries, limitations, rules
O — Output:       Desired format and structure
F — Few-shot:     Examples of input/output pairs
E — Edge cases:   How to handle unusual inputs
```

### Minimal Prompt Template

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

### Full Structured Prompt Example

```python
INVOICE_CLASSIFIER_PROMPT = """
You are a financial document analyst specializing in invoice processing
for multi-branch ERP systems.

## Context
You are processing invoices for a company with {branch_count} branches.
Each invoice must be classified by type, urgency, and department.
The current financial year runs from {fy_start} to {fy_end}.

## Task
Analyze the provided invoice text and extract:
1. Invoice number and date
2. Vendor name and ID (if recognizable)
3. Total amount and currency
4. Line item categories
5. Suggested department assignment
6. Urgency level (routine, priority, urgent)

## Constraints
- All amounts must be in the base currency ({base_currency})
- If vendor is not in the known vendor list, flag as "NEW_VENDOR"
- Do not guess department assignment if confidence is below 80%
- Flag any invoice over {threshold_amount} as requiring manager approval
- Never fabricate invoice numbers or amounts

## Output Format
Return a JSON object:
```json
{{
  "invoice_number": "string",
  "date": "YYYY-MM-DD",
  "vendor": {{"name": "string", "id": "string|null", "is_new": false}},
  "amount": {{"value": 0.00, "currency": "USD"}},
  "line_items": [{{"description": "string", "category": "string", "amount": 0.00}}],
  "department": {{"name": "string|null", "confidence": 0.0}},
  "urgency": "routine|priority|urgent",
  "flags": ["string"]
}}
```

## Examples
Input: "Invoice #INV-2026-0042 from Acme Corp, dated 2026-03-01, for $5,250.00 —
office supplies (paper $1,200, toner $3,050, desk organizers $1,000)"

Output:
```json
{{
  "invoice_number": "INV-2026-0042",
  "date": "2026-03-01",
  "vendor": {{"name": "Acme Corp", "id": "VND-001", "is_new": false}},
  "amount": {{"value": 5250.00, "currency": "USD"}},
  "line_items": [
    {{"description": "Paper", "category": "office_supplies", "amount": 1200.00}},
    {{"description": "Toner", "category": "office_supplies", "amount": 3050.00}},
    {{"description": "Desk organizers", "category": "office_supplies", "amount": 1000.00}}
  ],
  "department": {{"name": "Administration", "confidence": 0.92}},
  "urgency": "routine",
  "flags": []
}}
```

Now analyze this invoice:
{invoice_text}
"""
```

---

## 2. Few-Shot Prompting Patterns

Few-shot prompting provides examples that demonstrate the expected behavior. The quality and diversity of examples directly impacts output quality.

### Pattern: Diverse Few-Shot

Provide examples that cover different scenarios, edge cases, and output variations.

```python
FEW_SHOT_CLASSIFICATION = """
Classify the support ticket into exactly one category.

Categories: billing, technical, account, feature_request, other

## Examples

Ticket: "I was charged twice for my subscription this month"
Category: billing
Reasoning: Duplicate charge is a billing issue

Ticket: "The export button throws a 500 error when I click it"
Category: technical
Reasoning: Application error is a technical issue

Ticket: "Can you add dark mode to the dashboard?"
Category: feature_request
Reasoning: Request for new functionality

Ticket: "I need to change the email on my account"
Category: account
Reasoning: Account profile modification

Ticket: "I was charged twice AND the receipt page shows a 404"
Category: billing
Reasoning: When multiple categories apply, choose the primary user concern (billing)

## Now classify this ticket:
Ticket: "{ticket_text}"
Category:
"""
```

### Pattern: Structured Few-Shot with Explanations

```python
CODE_REVIEW_PROMPT = """
Review the code change and provide feedback.

## Example 1 — Security Issue
```php
$query = "SELECT * FROM users WHERE id = " . $_GET['id'];
```
Review:
- Severity: CRITICAL
- Category: Security (SQL Injection)
- Issue: User input is concatenated directly into SQL query
- Fix: Use parameterized queries: `User::find($request->input('id'))`
- Reference: OWASP A03:2021 Injection

## Example 2 — Performance Issue
```php
$users = User::all();
$activeUsers = $users->filter(fn($u) => $u->isActive());
```
Review:
- Severity: WARNING
- Category: Performance (N+1 / unnecessary data load)
- Issue: Loads all users into memory, then filters in PHP
- Fix: Use database query: `User::where('is_active', true)->get()`
- Reference: Eloquent query optimization

## Example 3 — No Issues
```php
$invoice = Invoice::with(['items', 'customer'])
    ->where('branch_id', auth()->user()->branch_id)
    ->findOrFail($id);
```
Review:
- Severity: PASS
- Category: N/A
- Notes: Good use of eager loading, proper branch scoping, fail-fast on missing

## Now review this code:
```{language}
{code}
```
Review:
"""
```

### Pattern: Negative Examples (What NOT to Do)

```python
WRITING_STYLE_PROMPT = """
Write a user-facing error message for the given error code.

## Good Examples
Error: PAYMENT_DECLINED
Message: "Your payment could not be processed. Please check your card details or try a different payment method."

Error: SESSION_EXPIRED
Message: "Your session has expired for security reasons. Please sign in again to continue."

## Bad Examples (DO NOT write like this)
Error: PAYMENT_DECLINED
Bad: "Error 402: Payment gateway returned decline code 05. Transaction failed."
Why bad: Exposes technical details, not actionable for the user

Error: SESSION_EXPIRED
Bad: "Session timeout. Login again."
Why bad: Too terse, no explanation, feels robotic

## Now write a message for:
Error: {error_code}
Description: {error_description}
Message:
"""
```

### Few-Shot Selection Strategy

```python
import numpy as np
from typing import List, Dict

class FewShotSelector:
    """Select the most relevant few-shot examples for a given input."""

    def __init__(self, examples: List[Dict], embedding_model):
        self.examples = examples
        self.model = embedding_model
        self.embeddings = self._embed_examples()

    def _embed_examples(self) -> np.ndarray:
        texts = [ex["input"] for ex in self.examples]
        return self.model.encode(texts)

    def select(self, query: str, k: int = 3, diverse: bool = True) -> List[Dict]:
        """Select k examples most relevant to the query.

        Args:
            query: The input to find examples for
            k: Number of examples to return
            diverse: If True, ensure category diversity in selection
        """
        query_embedding = self.model.encode([query])[0]
        similarities = np.dot(self.embeddings, query_embedding)

        if diverse:
            return self._diverse_select(similarities, k)

        top_indices = np.argsort(similarities)[-k:][::-1]
        return [self.examples[i] for i in top_indices]

    def _diverse_select(self, similarities: np.ndarray, k: int) -> List[Dict]:
        """Select examples ensuring category diversity."""
        selected = []
        seen_categories = set()
        sorted_indices = np.argsort(similarities)[::-1]

        for idx in sorted_indices:
            if len(selected) >= k:
                break
            category = self.examples[idx].get("category", "default")
            if category not in seen_categories or len(selected) < k:
                selected.append(self.examples[idx])
                seen_categories.add(category)

        return selected
```

---

## 3. Chain-of-Thought Prompting

Chain-of-thought (CoT) prompting guides the model through step-by-step reasoning before arriving at a final answer.

### Explicit CoT

```python
COT_ANALYSIS_PROMPT = """
Analyze the database query performance issue step by step.

## Query
```sql
{query}
```

## Table Schema
{schema}

## Current Execution Time
{execution_time}

## Step-by-Step Analysis

Step 1 — Identify the query pattern:
Determine if this is a simple lookup, join, aggregation, or subquery pattern.

Step 2 — Check index usage:
For each WHERE clause and JOIN condition, verify if an appropriate index exists.

Step 3 — Analyze data volume:
Estimate rows scanned vs. rows returned. A ratio above 10:1 suggests optimization needed.

Step 4 — Identify bottlenecks:
Look for full table scans, filesorts, temporary tables, or nested loops.

Step 5 — Propose optimizations:
For each bottleneck, suggest a specific fix with the expected improvement.

Step 6 — Provide the optimized query:
Write the optimized version with explanations for each change.

Now perform this analysis:
"""
```

### Zero-Shot CoT

The simplest form: append "Let's think step by step" or "Think through this carefully."

```python
REASONING_PROMPT = """
Determine whether this API change is backward-compatible.

Current endpoint: {current_spec}
Proposed change: {proposed_change}

Think through this step by step, considering:
- Request format changes
- Response format changes
- Status code changes
- Authentication changes
- Rate limit changes

Then provide your verdict: COMPATIBLE or BREAKING, with justification.
"""
```

### Self-Consistency Pattern

Run the same prompt multiple times and use majority voting for higher accuracy.

```python
import asyncio
from collections import Counter
from typing import List

async def self_consistent_classify(
    client,
    prompt: str,
    n_samples: int = 5,
    temperature: float = 0.7
) -> dict:
    """Run classification multiple times and return majority vote."""

    async def single_call():
        response = await client.chat.completions.create(
            model="claude-sonnet-4-20250514",
            messages=[{"role": "user", "content": prompt}],
            temperature=temperature,
            max_tokens=100
        )
        return response.choices[0].message.content.strip()

    results = await asyncio.gather(*[single_call() for _ in range(n_samples)])
    vote_counts = Counter(results)
    winner, count = vote_counts.most_common(1)[0]

    return {
        "answer": winner,
        "confidence": count / n_samples,
        "all_responses": results,
        "vote_distribution": dict(vote_counts)
    }
```

### Structured Reasoning Template

```python
STRUCTURED_REASONING = """
## Problem
{problem_description}

## Available Information
{context}

## Analysis Framework
Apply this reasoning structure:

### 1. Decomposition
Break the problem into sub-problems:
- Sub-problem A: ...
- Sub-problem B: ...

### 2. Evidence Gathering
For each sub-problem, identify relevant evidence from the context:
- Evidence for A: ...
- Evidence for B: ...

### 3. Reasoning
For each sub-problem, reason through the evidence:
- Conclusion for A: ...
- Conclusion for B: ...

### 4. Synthesis
Combine sub-conclusions into a final answer:
- Final answer: ...
- Confidence level: HIGH / MEDIUM / LOW
- Key assumptions: ...
- Limitations: ...
"""
```

---

## 4. System Prompt Design Patterns

System prompts define the model's persistent behavior, personality, and constraints across an entire conversation.

### Pattern: Layered System Prompt

```python
SYSTEM_PROMPT = """
# Identity
You are FinanceBot, an AI assistant for the accounting department
at a multi-branch retail company using an ERP system.

# Capabilities
You can:
- Answer questions about accounting procedures
- Help with journal entry creation
- Explain financial report data
- Guide users through month-end closing
- Look up transaction history via function calls

You cannot:
- Approve transactions or journal entries
- Modify financial data directly
- Access branches the user is not assigned to
- Provide tax advice (direct to the tax department)

# Behavior Rules
1. Always verify the user's branch context before answering
2. Use double-entry bookkeeping terminology consistently
3. When amounts exceed {approval_threshold}, remind about approval workflow
4. Format all currency as {currency_symbol}#,###.##
5. Dates use {date_format} format
6. Never display full bank account numbers — mask all but last 4 digits

# Response Style
- Professional but approachable
- Use bullet points for multi-step procedures
- Include relevant account codes when discussing transactions
- Warn about common mistakes proactively

# Error Handling
- If unsure about a policy, say so and suggest contacting the finance manager
- If the user asks about another branch's data, explain the data isolation policy
- If asked to perform an unauthorized action, explain why and suggest the correct process
"""
```

### Pattern: Role + Guardrails Separation

```python
# Separate the role definition from the safety guardrails

ROLE_PROMPT = """
You are a senior DevOps engineer helping a team migrate from
monolithic deployments to containerized microservices on Kubernetes.

You have deep expertise in:
- Docker multi-stage builds and optimization
- Kubernetes deployment strategies (rolling, blue-green, canary)
- Helm chart design and templating
- CI/CD pipeline architecture (GitHub Actions, GitLab CI)
- Infrastructure as Code (Terraform, Pulumi)
- Monitoring and observability (Prometheus, Grafana, ELK)

When advising, you:
- Start with the simplest solution that meets requirements
- Explain trade-offs between approaches
- Provide working code examples, not pseudocode
- Flag security concerns proactively
- Consider cost implications
"""

GUARDRAILS_PROMPT = """
# Safety Guardrails

## Never
- Provide credentials, API keys, or secrets in examples (use placeholders)
- Suggest disabling security features for convenience
- Recommend running containers as root without justification
- Skip error handling in code examples

## Always
- Include health checks in Dockerfile and Kubernetes manifests
- Use specific image tags, never :latest in production examples
- Include resource limits in Kubernetes pod specs
- Add comments explaining non-obvious configuration choices
- Warn before any destructive operation (delete, destroy, drop)

## When Uncertain
- State your uncertainty explicitly
- Provide multiple options with trade-offs
- Suggest testing in a non-production environment first
"""

FULL_SYSTEM_PROMPT = f"{ROLE_PROMPT}\n\n{GUARDRAILS_PROMPT}"
```

### Pattern: Dynamic System Prompt Assembly

```python
from dataclasses import dataclass, field
from typing import List, Optional

@dataclass
class SystemPromptBuilder:
    """Build system prompts dynamically based on user context."""

    role: str = ""
    capabilities: List[str] = field(default_factory=list)
    restrictions: List[str] = field(default_factory=list)
    style_rules: List[str] = field(default_factory=list)
    context_variables: dict = field(default_factory=dict)
    tools_available: List[str] = field(default_factory=list)

    def build(self) -> str:
        sections = []

        if self.role:
            sections.append(f"# Role\n{self.role}")

        if self.capabilities:
            cap_list = "\n".join(f"- {c}" for c in self.capabilities)
            sections.append(f"# Capabilities\n{cap_list}")

        if self.restrictions:
            res_list = "\n".join(f"- {r}" for r in self.restrictions)
            sections.append(f"# Restrictions\n{res_list}")

        if self.tools_available:
            tool_list = "\n".join(f"- `{t}`" for t in self.tools_available)
            sections.append(f"# Available Tools\n{tool_list}")

        if self.style_rules:
            style_list = "\n".join(f"- {s}" for s in self.style_rules)
            sections.append(f"# Response Style\n{style_list}")

        prompt = "\n\n".join(sections)

        for key, value in self.context_variables.items():
            prompt = prompt.replace(f"{{{key}}}", str(value))

        return prompt


# Usage
builder = SystemPromptBuilder(
    role="You are an ERP support agent for {company_name}.",
    capabilities=[
        "Answer questions about invoice processing",
        "Guide users through purchase order workflows",
        "Explain report data and financial summaries",
    ],
    restrictions=[
        "Never modify data directly",
        "Only access data for branch: {branch_name}",
        "Escalate security-related queries to IT",
    ],
    style_rules=[
        "Be concise — maximum 3 paragraphs per response",
        "Use the company's terminology from the glossary",
        "Include step numbers for procedural answers",
    ],
    context_variables={
        "company_name": "Acme Corp",
        "branch_name": "Dubai HQ",
    },
)

system_prompt = builder.build()
```

---

## 5. Prompt Templates with Variable Injection

### Safe Template Engine

```python
import re
from typing import Any, Dict, Optional

class PromptTemplate:
    """Safe prompt template with variable injection and validation."""

    def __init__(self, template: str, required_vars: Optional[list] = None):
        self.template = template
        self.required_vars = required_vars or self._detect_variables()

    def _detect_variables(self) -> list:
        """Auto-detect {variable} placeholders in template."""
        return re.findall(r'\{(\w+)\}', self.template)

    def render(self, **kwargs) -> str:
        """Render the template with provided variables.

        Raises ValueError if required variables are missing.
        """
        missing = [v for v in self.required_vars if v not in kwargs]
        if missing:
            raise ValueError(f"Missing required variables: {missing}")

        result = self.template
        for key, value in kwargs.items():
            # Sanitize values to prevent injection
            safe_value = self._sanitize(str(value))
            result = result.replace(f"{{{key}}}", safe_value)

        return result

    def _sanitize(self, value: str) -> str:
        """Basic sanitization — extend for your use case."""
        # Prevent prompt injection via variable values
        injection_patterns = [
            "ignore previous instructions",
            "ignore all instructions",
            "disregard the above",
            "new instructions:",
            "system prompt:",
        ]
        lower_value = value.lower()
        for pattern in injection_patterns:
            if pattern in lower_value:
                raise ValueError(f"Potential prompt injection detected in variable value")
        return value

    def preview(self, **kwargs) -> str:
        """Render with placeholders for missing variables."""
        result = self.template
        for key, value in kwargs.items():
            result = result.replace(f"{{{key}}}", str(value))
        return result


# Usage
template = PromptTemplate("""
Summarize this {document_type} for {audience}.

Document:
{content}

Requirements:
- Maximum {max_words} words
- Reading level: {reading_level}
- Focus on: {focus_areas}
""")

prompt = template.render(
    document_type="quarterly financial report",
    audience="the board of directors",
    content="[report content here]",
    max_words="300",
    reading_level="executive",
    focus_areas="revenue growth, cost reduction, key risks",
)
```

### TypeScript Template System

```typescript
interface TemplateConfig {
  template: string;
  requiredVars: string[];
  defaults?: Record<string, string>;
  validators?: Record<string, (value: string) => boolean>;
}

class PromptTemplate {
  private config: TemplateConfig;

  constructor(config: TemplateConfig) {
    this.config = config;
  }

  render(variables: Record<string, string>): string {
    const merged = { ...this.config.defaults, ...variables };

    // Check required variables
    const missing = this.config.requiredVars.filter((v) => !(v in merged));
    if (missing.length > 0) {
      throw new Error(`Missing required variables: ${missing.join(", ")}`);
    }

    // Validate values
    if (this.config.validators) {
      for (const [key, validator] of Object.entries(this.config.validators)) {
        if (key in merged && !validator(merged[key])) {
          throw new Error(`Validation failed for variable: ${key}`);
        }
      }
    }

    // Render
    let result = this.config.template;
    for (const [key, value] of Object.entries(merged)) {
      result = result.replaceAll(`{${key}}`, value);
    }
    return result;
  }
}

// Usage
const summarizer = new PromptTemplate({
  template: `Summarize the following {doc_type} in {max_words} words or fewer.
Focus on: {focus}

Content:
{content}`,
  requiredVars: ["doc_type", "content"],
  defaults: { max_words: "200", focus: "key findings and action items" },
  validators: {
    max_words: (v) => !isNaN(Number(v)) && Number(v) > 0 && Number(v) <= 2000,
  },
});
```

---

## 6. Prompt Versioning and A/B Testing

### Version Registry

```python
from dataclasses import dataclass
from datetime import datetime
from typing import Dict, List, Optional
import hashlib
import json

@dataclass
class PromptVersion:
    id: str
    name: str
    version: str
    template: str
    variables: List[str]
    metadata: Dict
    created_at: str
    content_hash: str

class PromptRegistry:
    """Version-controlled prompt registry with A/B testing support."""

    def __init__(self):
        self._prompts: Dict[str, List[PromptVersion]] = {}
        self._active: Dict[str, str] = {}  # name -> version
        self._ab_tests: Dict[str, dict] = {}

    def register(self, name: str, version: str, template: str,
                 metadata: Optional[Dict] = None) -> PromptVersion:
        """Register a new prompt version."""
        content_hash = hashlib.sha256(template.encode()).hexdigest()[:12]
        prompt = PromptVersion(
            id=f"{name}@{version}",
            name=name,
            version=version,
            template=template,
            variables=self._extract_vars(template),
            metadata=metadata or {},
            created_at=datetime.utcnow().isoformat(),
            content_hash=content_hash,
        )

        if name not in self._prompts:
            self._prompts[name] = []
            self._active[name] = version

        self._prompts[name].append(prompt)
        return prompt

    def get(self, name: str, version: Optional[str] = None) -> PromptVersion:
        """Get a specific version or the active version of a prompt."""
        if name not in self._prompts:
            raise KeyError(f"Prompt '{name}' not found")

        target_version = version or self._active[name]
        for p in self._prompts[name]:
            if p.version == target_version:
                return p
        raise KeyError(f"Version '{target_version}' not found for '{name}'")

    def activate(self, name: str, version: str):
        """Set the active version for a prompt."""
        self.get(name, version)  # Validate existence
        self._active[name] = version

    def setup_ab_test(self, name: str, variants: Dict[str, float]):
        """Set up an A/B test with traffic split.

        Args:
            variants: {version: weight} e.g., {"v1": 0.5, "v2": 0.5}
        """
        total = sum(variants.values())
        if abs(total - 1.0) > 0.001:
            raise ValueError(f"Weights must sum to 1.0, got {total}")
        self._ab_tests[name] = variants

    def get_for_request(self, name: str, request_id: str) -> PromptVersion:
        """Get the prompt version for a request, respecting A/B test config."""
        if name in self._ab_tests:
            # Deterministic assignment based on request_id
            hash_val = int(hashlib.md5(request_id.encode()).hexdigest(), 16)
            bucket = (hash_val % 1000) / 1000.0
            cumulative = 0.0
            for version, weight in self._ab_tests[name].items():
                cumulative += weight
                if bucket < cumulative:
                    return self.get(name, version)
        return self.get(name)

    def _extract_vars(self, template: str) -> List[str]:
        import re
        return list(set(re.findall(r'\{(\w+)\}', template)))

    def list_versions(self, name: str) -> List[Dict]:
        """List all versions of a prompt with metadata."""
        if name not in self._prompts:
            return []
        return [
            {
                "version": p.version,
                "hash": p.content_hash,
                "created_at": p.created_at,
                "is_active": p.version == self._active[name],
                "metadata": p.metadata,
            }
            for p in self._prompts[name]
        ]


# Usage
registry = PromptRegistry()

registry.register("ticket_classifier", "v1", """
Classify this support ticket: {ticket}
Categories: billing, technical, account, other
""", metadata={"author": "team-ai", "accuracy": 0.82})

registry.register("ticket_classifier", "v2", """
You are a support ticket classifier. Analyze the ticket below and
assign exactly one category. If uncertain, choose the most likely.

Categories:
- billing: payment, charges, subscription, refund issues
- technical: bugs, errors, performance, feature not working
- account: profile, password, access, permissions
- other: anything that doesn't fit above

Ticket: {ticket}

Category (one word):
""", metadata={"author": "team-ai", "accuracy": 0.91})

# A/B test the two versions
registry.setup_ab_test("ticket_classifier", {"v1": 0.2, "v2": 0.8})
```

---

## 7. Token Optimization Techniques

### Technique 1: Trim Redundancy

```python
# BEFORE: 142 tokens
VERBOSE_PROMPT = """
I would like you to please analyze the following piece of text
and then provide me with a summary of the main points. The summary
should be concise and to the point. Please make sure to include all
the important information while keeping it brief. The text is as follows:
"""

# AFTER: 28 tokens
CONCISE_PROMPT = """
Summarize the key points from this text concisely:
"""
```

### Technique 2: Structured Compression

```python
# BEFORE: Long natural language constraints
"""
When you write the response, please make sure that you use proper
grammar and punctuation. Also, please use markdown formatting with
headers for different sections. Each section should have a clear
heading. Use bullet points for lists. Keep paragraphs short,
ideally 2-3 sentences each. Use code blocks for any code examples.
"""

# AFTER: Structured shorthand
"""
Format rules:
- Markdown with ## headers per section
- Bullet points for lists
- 2-3 sentence paragraphs
- Code in fenced blocks
"""
```

### Technique 3: Reference Compression for Context

```python
def compress_context(documents: list, max_tokens: int = 2000) -> str:
    """Compress document context to fit token budget."""
    compressed = []
    token_count = 0

    for doc in documents:
        # Extract key sentences (first + last of each paragraph)
        paragraphs = doc.split("\n\n")
        key_sentences = []
        for para in paragraphs:
            sentences = para.split(". ")
            if sentences:
                key_sentences.append(sentences[0])
                if len(sentences) > 2:
                    key_sentences.append(sentences[-1])

        summary = ". ".join(key_sentences)
        estimated_tokens = len(summary.split()) * 1.3  # rough estimate

        if token_count + estimated_tokens > max_tokens:
            break
        compressed.append(summary)
        token_count += estimated_tokens

    return "\n---\n".join(compressed)
```

### Technique 4: Output Token Budgeting

```python
# Be explicit about output length expectations
SHORT_ANSWER = """
Answer in one sentence: {question}
"""

MEDIUM_ANSWER = """
Answer in 2-3 paragraphs: {question}
"""

STRUCTURED_ANSWER = """
Answer using exactly this structure (no additional text):

VERDICT: [one word]
REASON: [one sentence]
CONFIDENCE: [HIGH/MEDIUM/LOW]
"""
```

---

## 8. Common Anti-Patterns to Avoid

### Anti-Pattern 1: Vague Instructions

```python
# BAD — vague, no structure
bad = "Help me with this code"

# GOOD — specific task, clear format
good = """
Review this Python function for:
1. Correctness (does it handle edge cases?)
2. Performance (any obvious inefficiencies?)
3. Readability (naming, structure, comments)

Function:
```python
{code}
```

For each issue found, provide:
- Line number
- Issue description
- Suggested fix
"""
```

### Anti-Pattern 2: Contradictory Constraints

```python
# BAD — contradicts itself
bad = """
Be extremely thorough and detailed in your analysis.
Keep your response under 50 words.
"""

# GOOD — consistent constraints
good = """
Provide a brief assessment (50 words max) identifying the single
most critical issue in this code.
"""
```

### Anti-Pattern 3: Over-Prompting

```python
# BAD — over-specified, rigid, fragile
bad = """
Step 1: Read the first line.
Step 2: If the first line contains "error", go to step 5.
Step 3: If the first line contains "warning", go to step 7.
Step 4: Otherwise, read the second line...
[40 more steps]
"""

# GOOD — clear goal with flexible execution
good = """
Parse this log file and extract:
- All ERROR entries with timestamps and messages
- All WARNING entries with timestamps and messages
- A count of each error type

Return as JSON with keys: errors, warnings, summary.
"""
```

### Anti-Pattern 4: Missing Context

```python
# BAD — no context about the system
bad = "Fix this SQL query: SELECT * FROM orders WHERE status = 'pending'"

# GOOD — includes schema and constraints
good = """
Fix this SQL query for our multi-tenant ERP system.

Schema:
- orders(id, branch_id, customer_id, status, total, created_at)
- branch_id is required for all queries (multi-tenant isolation)

Current query:
SELECT * FROM orders WHERE status = 'pending'

Issues to address:
1. Missing branch_id filter (security/isolation requirement)
2. SELECT * should specify needed columns
3. Should include index hints if available
"""
```

### Anti-Pattern 5: Prompt Injection Vulnerability

```python
# BAD — user input directly in prompt with no boundary
bad = f"Translate this text: {user_input}"

# GOOD — clear boundary between instructions and user content
good = f"""
Translate the text between the <user_text> tags to French.
Only output the translation, nothing else.

<user_text>
{user_input}
</user_text>
"""
```

---

## 9. Prompt Libraries and Organization

### Directory Structure

```
prompts/
├── system/                    # System prompts (persistent behavior)
│   ├── base.py               # Base system prompt components
│   ├── finance_agent.py      # Finance-specific system prompt
│   └── support_agent.py      # Support-specific system prompt
├── tasks/                     # Task-specific prompts
│   ├── classification/
│   │   ├── ticket_classifier.py
│   │   └── document_classifier.py
│   ├── extraction/
│   │   ├── invoice_extractor.py
│   │   └── entity_extractor.py
│   ├── generation/
│   │   ├── email_writer.py
│   │   └── report_generator.py
│   └── analysis/
│       ├── code_reviewer.py
│       └── sentiment_analyzer.py
├── templates/                 # Reusable template components
│   ├── output_formats.py     # JSON, markdown, table formats
│   ├── guardrails.py         # Safety and constraint blocks
│   └── few_shot_banks.py     # Example libraries
├── tests/                     # Prompt tests
│   ├── test_classification.py
│   └── test_extraction.py
├── registry.py                # Prompt version registry
└── config.py                  # Prompt configuration
```

### Prompt Composition Pattern

```python
from enum import Enum

class OutputFormat(Enum):
    JSON = "Return your response as valid JSON."
    MARKDOWN = "Format your response in Markdown."
    PLAIN = "Return plain text with no formatting."
    CSV = "Return data as CSV with headers."

class Guardrail(Enum):
    NO_PII = "Never include personal identifiable information in outputs."
    NO_HALLUCINATION = "Only use information provided in the context. If unsure, say so."
    SAFE_CONTENT = "Do not generate harmful, offensive, or misleading content."
    BRANCH_ISOLATION = "Only reference data from the user's current branch."

def compose_prompt(
    task: str,
    context: str = "",
    output_format: OutputFormat = OutputFormat.JSON,
    guardrails: list = None,
    examples: list = None,
    max_tokens_hint: int = None,
) -> str:
    """Compose a prompt from reusable components."""
    sections = []

    if context:
        sections.append(f"## Context\n{context}")

    sections.append(f"## Task\n{task}")

    if guardrails:
        rules = "\n".join(f"- {g.value}" for g in guardrails)
        sections.append(f"## Rules\n{rules}")

    if examples:
        ex_text = "\n\n".join(
            f"Input: {ex['input']}\nOutput: {ex['output']}"
            for ex in examples
        )
        sections.append(f"## Examples\n{ex_text}")

    sections.append(f"## Output Format\n{output_format.value}")

    if max_tokens_hint:
        sections.append(f"Keep your response under approximately {max_tokens_hint} tokens.")

    return "\n\n".join(sections)


# Usage
prompt = compose_prompt(
    task="Classify this support ticket into a category and priority.",
    context="Categories: billing, technical, account. Priority: low, medium, high, critical.",
    output_format=OutputFormat.JSON,
    guardrails=[Guardrail.NO_PII, Guardrail.NO_HALLUCINATION],
    examples=[
        {"input": "I can't log in", "output": '{"category": "account", "priority": "high"}'},
        {"input": "Add dark mode", "output": '{"category": "technical", "priority": "low"}'},
    ],
)
```

---

## 10. Quick Reference Checklist

Use this checklist when designing or reviewing any prompt:

```markdown
## Prompt Design Checklist

### Structure
- [ ] Clear role defined (if applicable)
- [ ] Sufficient context provided
- [ ] Task instructions are specific and unambiguous
- [ ] Constraints are explicit and non-contradictory
- [ ] Output format specified with example
- [ ] Edge cases addressed

### Quality
- [ ] Few-shot examples cover diverse scenarios
- [ ] Examples include both positive and negative cases
- [ ] Token budget is reasonable for the task
- [ ] No redundant or filler text
- [ ] Variable placeholders are clearly named

### Safety
- [ ] User input is clearly delimited (XML tags or similar)
- [ ] Prompt injection defenses in place
- [ ] No sensitive data in prompt templates
- [ ] Guardrails prevent harmful outputs
- [ ] Multi-tenant isolation enforced in context

### Operations
- [ ] Prompt is version-controlled
- [ ] Prompt has associated test cases
- [ ] Performance baseline established
- [ ] Monitoring for output quality in place
- [ ] Rollback plan for prompt changes
```
