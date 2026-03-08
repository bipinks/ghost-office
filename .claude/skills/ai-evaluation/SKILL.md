---
name: ai-evaluation
description: Use when evaluating AI/LLM systems — benchmark design, automated evaluation pipelines, human evaluation protocols, A/B testing, hallucination detection, factuality checking, bias testing, safety evaluation (red teaming), latency/cost metrics, eval datasets, regression testing for prompts, and model comparison frameworks.
user-invocable: true
allowed-tools: ["Read", "Write", "Edit", "Grep", "Glob", "Bash"]
---

# AI/LLM Evaluation Methodologies

Patterns for evaluating AI/LLM systems across accuracy, safety, cost, and latency dimensions.

---

## 1. Evaluation Dimensions

| Dimension | Measures | Method |
|-----------|----------|--------|
| Accuracy | Factual correctness | Ground truth comparison |
| Relevance | Answer fits the question | Semantic similarity + human review |
| Coherence | Logical, well-structured | LLM-as-judge scoring |
| Completeness | Covers all required points | Rubric checklist |
| Safety | No harmful/biased output | Red team + classifier |
| Latency | Time to first token, total | Instrumented timing |
| Cost | Tokens in/out, $/request | Token counting |
| Consistency | Same input yields similar output | Multi-run variance |

## 2. Automated Evaluation Pipeline

```python
@dataclass
class EvalCase:
    input: str
    expected: str  # ground truth or rubric
    tags: list[str] = field(default_factory=list)  # e.g., ["factual", "multi-step"]

class EvalRunner:
    def __init__(self, model_fn, judge_fn, cases: list[EvalCase]):
        self.model_fn = model_fn
        self.judge_fn = judge_fn
        self.cases = cases

    def run(self) -> dict:
        results = []
        for case in self.cases:
            output = self.model_fn(case.input)
            score = self.judge_fn(case.input, case.expected, output)
            results.append({"input": case.input, "score": score, "tags": case.tags})
        return self._aggregate(results)

    def _aggregate(self, results):
        scores = [r["score"] for r in results]
        by_tag = defaultdict(list)
        for r in results:
            for tag in r["tags"]:
                by_tag[tag].append(r["score"])
        return {
            "overall": {"mean": mean(scores), "p50": median(scores), "n": len(scores)},
            "by_tag": {tag: mean(s) for tag, s in by_tag.items()},
        }
```

## 3. LLM-as-Judge Pattern

Use a stronger model to grade a weaker model's output against a rubric.

```python
JUDGE_PROMPT = """Score the RESPONSE on a 1-5 scale for each criterion.

INPUT: {input}
EXPECTED: {expected}
RESPONSE: {response}

Criteria:
- Accuracy (1-5): Factually correct vs expected answer
- Completeness (1-5): Covers all required points
- Clarity (1-5): Well-structured and easy to understand

Return JSON: {"accuracy": N, "completeness": N, "clarity": N, "reasoning": "..."}
"""
```

**When to use LLM-as-judge vs programmatic scoring:**
- Programmatic: exact match, regex, JSON schema validation, keyword presence
- LLM-as-judge: open-ended quality, style, nuance, multi-criteria rubrics
- Human review: high-stakes decisions, ambiguous cases, calibrating LLM judges

## 4. Hallucination Detection

**Categories:** factual errors, fabricated citations, invented entities, contradicting the source.

```python
def check_hallucination(response: str, source_docs: list[str]) -> dict:
    claims = extract_claims(response)  # LLM call to decompose into atomic claims
    results = []
    for claim in claims:
        supported = any(is_entailed(claim, doc) for doc in source_docs)
        results.append({"claim": claim, "supported": supported})
    hallucination_rate = sum(1 for r in results if not r["supported"]) / len(results)
    return {"claims": results, "hallucination_rate": hallucination_rate}
```

**Mitigation strategies:** provide source docs in context, instruct "only use provided information", use citation extraction, apply retrieval-augmented generation.

## 5. Bias and Safety Testing

### Bias Evaluation Axes
- **Demographic**: gender, race, age, religion, nationality
- **Stereotype**: occupational stereotypes, cultural assumptions
- **Sentiment**: differential sentiment toward groups
- **Representation**: over/under-representation in generated content

### Red Team Framework
1. Define threat model (what harm could the system cause?)
2. Build adversarial prompt set: jailbreaks, prompt injection, edge cases
3. Run automated sweep + manual creative probing
4. Score severity: Critical (immediate harm) / High / Medium / Low
5. Fix and re-test; add to regression suite

```python
RED_TEAM_CATEGORIES = [
    "harmful_instructions",    # How to cause harm
    "personal_data_extraction",# Leaking PII from training data
    "prompt_injection",        # Overriding system instructions
    "bias_amplification",      # Reinforcing stereotypes
    "misinformation",          # Generating false claims confidently
    "policy_violation",        # Violating content policy
]
```

## 6. Eval Dataset Construction

**Principles:**
- Minimum 100 examples per category; 500+ for statistical significance
- Include easy, medium, hard difficulty levels
- Include adversarial/edge cases (10-20% of dataset)
- Version-control datasets alongside prompts
- Never train on eval data

**Dataset structure:**
```json
{
  "id": "eval-001",
  "input": "What is the capital of France?",
  "expected": "Paris",
  "category": "factual",
  "difficulty": "easy",
  "tags": ["geography"],
  "metadata": {"source": "manual", "created": "2026-03-01"}
}
```

**Sources:** manual curation (highest quality), real user queries (anonymized), synthetic generation (LLM-generated with human review), public benchmarks (MMLU, HumanEval, TruthfulQA).

## 7. Regression Testing

Run eval suite on every prompt or model change. Fail the deploy if scores drop below thresholds.

```yaml
# eval-config.yaml
eval_suite: "production-v2"
thresholds:
  accuracy: 0.92
  hallucination_rate_max: 0.05
  safety_pass_rate: 0.99
  latency_p95_ms: 3000
  cost_per_request_max: 0.08
on_failure: block_deploy
compare_to: last_passing_run
```

**CI integration:** run evals in CI on prompt/model changes, store results in versioned database, generate comparison reports against baseline, block merge if regression detected.

## 8. A/B Testing in Production

| Concern | Approach |
|---------|----------|
| Traffic split | Hash user_id for deterministic assignment |
| Metrics | Primary: task completion. Secondary: satisfaction, latency |
| Duration | Until statistical significance (p < 0.05, power > 0.8) |
| Guardrails | Monitor safety scores, error rates, cost per request |
| Rollback | Automated if error rate > 2x baseline or safety score drops |

## 9. Performance Metrics

```python
@dataclass
class LLMMetrics:
    time_to_first_token_ms: float   # Perceived responsiveness
    total_latency_ms: float         # End-to-end time
    input_tokens: int
    output_tokens: int
    cost_usd: float                 # Based on provider pricing

    @property
    def tokens_per_second(self) -> float:
        return self.output_tokens / (self.total_latency_ms / 1000)
```

**Targets (conversational):** TTFT < 500ms, total < 5s, cost < $0.05/request.
**Targets (batch):** throughput > 100 req/min, cost < $0.02/request.

## 10. Model Comparison Framework

| Factor | Weight | How to Score |
|--------|--------|-------------|
| Accuracy on eval suite | 30% | Automated eval score |
| Latency (p95) | 20% | Benchmarked under load |
| Cost per request | 20% | Token pricing calculation |
| Safety pass rate | 15% | Red team + classifier |
| Instruction following | 15% | Structured output compliance |

**Decision process:** run identical eval suite across candidate models, normalize scores 0-1, compute weighted score, select highest. Re-evaluate quarterly or on major model releases.

## 11. Production Monitoring

Track continuously in production:
- Response quality score (sample-based LLM judge)
- Hallucination rate (claim verification on sample)
- User feedback signals (thumbs up/down, regeneration rate)
- Latency percentiles (p50, p95, p99)
- Cost per request and daily spend
- Safety classifier trigger rate
- Token usage trends (input growing = context bloat)

**Alert thresholds:** quality score drop > 5% over 24h, hallucination rate > 2x baseline, latency p95 > 2x target, safety trigger rate > 1%.
