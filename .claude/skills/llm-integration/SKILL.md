---
name: llm-integration
description: Use when integrating LLMs into applications — API client design, streaming, token management, cost optimization, retry/fallback, model selection, prompt versioning, structured output, function calling, embeddings, RAG, fine-tuning, evaluation, safety guardrails, and rate limiting.
user-invocable: true
allowed-tools: ["Read", "Write", "Edit", "Grep", "Glob", "Bash"]
---

# LLM Integration Patterns for Applications

Comprehensive reference for integrating large language models into production applications. Covers API client design, streaming, token management, cost optimization, retry strategies, structured output, function calling, RAG pipelines, evaluation, and safety.

---

## 1. API Client Design

### Robust Client Architecture

```python
import asyncio
import time
import hashlib
import json
from dataclasses import dataclass, field
from typing import Any, AsyncIterator, Dict, List, Optional
from enum import Enum


class ModelProvider(Enum):
    ANTHROPIC = "anthropic"
    OPENAI = "openai"


@dataclass
class LLMConfig:
    """Configuration for an LLM API client."""
    provider: ModelProvider
    model: str
    api_key: str
    base_url: Optional[str] = None
    max_retries: int = 3
    timeout_seconds: int = 60
    max_tokens: int = 4096
    temperature: float = 0.0
    rate_limit_rpm: int = 60
    rate_limit_tpm: int = 100_000
    default_system_prompt: Optional[str] = None


@dataclass
class LLMResponse:
    """Standardized response from any LLM provider."""
    content: str
    model: str
    input_tokens: int
    output_tokens: int
    total_tokens: int
    latency_ms: float
    finish_reason: str
    raw_response: Optional[Any] = None

    @property
    def cost_estimate(self) -> float:
        """Estimate cost based on known pricing (example rates)."""
        pricing = {
            "claude-sonnet-4-20250514": {"input": 3.0, "output": 15.0},
            "claude-opus-4-20250514": {"input": 15.0, "output": 75.0},
            "claude-haiku-35-20250414": {"input": 0.80, "output": 4.0},
        }
        rates = pricing.get(self.model, {"input": 3.0, "output": 15.0})
        return (
            (self.input_tokens / 1_000_000) * rates["input"]
            + (self.output_tokens / 1_000_000) * rates["output"]
        )


class LLMClient:
    """Production-grade LLM API client with retry, caching, and observability."""

    def __init__(self, config: LLMConfig):
        self.config = config
        self._request_times: List[float] = []
        self._token_usage: List[int] = []
        self._cache: Dict[str, LLMResponse] = {}

    async def complete(
        self,
        messages: List[Dict[str, str]],
        model: Optional[str] = None,
        temperature: Optional[float] = None,
        max_tokens: Optional[int] = None,
        system: Optional[str] = None,
        cache_key: Optional[str] = None,
    ) -> LLMResponse:
        """Send a completion request with retry and rate limiting."""

        # Check cache
        if cache_key and cache_key in self._cache:
            return self._cache[cache_key]

        # Rate limiting
        await self._enforce_rate_limit()

        # Retry loop
        last_error = None
        for attempt in range(self.config.max_retries + 1):
            try:
                start = time.monotonic()
                response = await self._call_provider(
                    messages=messages,
                    model=model or self.config.model,
                    temperature=temperature if temperature is not None else self.config.temperature,
                    max_tokens=max_tokens or self.config.max_tokens,
                    system=system or self.config.default_system_prompt,
                )
                latency = (time.monotonic() - start) * 1000

                result = LLMResponse(
                    content=response["content"],
                    model=response["model"],
                    input_tokens=response["input_tokens"],
                    output_tokens=response["output_tokens"],
                    total_tokens=response["input_tokens"] + response["output_tokens"],
                    latency_ms=latency,
                    finish_reason=response["finish_reason"],
                    raw_response=response.get("raw"),
                )

                # Track usage
                self._token_usage.append(result.total_tokens)
                self._request_times.append(time.monotonic())

                # Cache result
                if cache_key:
                    self._cache[cache_key] = result

                return result

            except RateLimitError:
                wait = min(2 ** attempt * 1.0, 60.0)
                await asyncio.sleep(wait)
                last_error = "Rate limited"

            except TimeoutError:
                wait = min(2 ** attempt * 2.0, 120.0)
                await asyncio.sleep(wait)
                last_error = "Timeout"

            except (ConnectionError, ServerError) as e:
                if attempt == self.config.max_retries:
                    raise
                wait = min(2 ** attempt * 1.0, 30.0)
                await asyncio.sleep(wait)
                last_error = str(e)

        raise RuntimeError(f"All {self.config.max_retries + 1} attempts failed. Last error: {last_error}")

    async def _enforce_rate_limit(self):
        """Enforce requests-per-minute and tokens-per-minute limits."""
        now = time.monotonic()
        # Remove entries older than 60 seconds
        self._request_times = [t for t in self._request_times if now - t < 60]
        if len(self._request_times) >= self.config.rate_limit_rpm:
            oldest = self._request_times[0]
            wait = 60 - (now - oldest) + 0.1
            if wait > 0:
                await asyncio.sleep(wait)

    async def _call_provider(self, **kwargs) -> Dict:
        """Provider-specific API call. Override for each provider."""
        raise NotImplementedError("Subclass must implement _call_provider")

    def generate_cache_key(self, messages: List[Dict], model: str, temperature: float) -> str:
        """Generate a deterministic cache key for a request."""
        payload = json.dumps({"messages": messages, "model": model, "temp": temperature}, sort_keys=True)
        return hashlib.sha256(payload.encode()).hexdigest()[:16]
```

### Provider-Specific Implementations

```python
# Anthropic provider
import anthropic

class AnthropicClient(LLMClient):
    def __init__(self, config: LLMConfig):
        super().__init__(config)
        self._client = anthropic.AsyncAnthropic(api_key=config.api_key)

    async def _call_provider(self, **kwargs) -> Dict:
        message = await self._client.messages.create(
            model=kwargs["model"],
            max_tokens=kwargs["max_tokens"],
            temperature=kwargs["temperature"],
            system=kwargs.get("system") or anthropic.NOT_GIVEN,
            messages=kwargs["messages"],
        )
        return {
            "content": message.content[0].text,
            "model": message.model,
            "input_tokens": message.usage.input_tokens,
            "output_tokens": message.usage.output_tokens,
            "finish_reason": message.stop_reason,
            "raw": message,
        }


# OpenAI-compatible provider
import openai

class OpenAIClient(LLMClient):
    def __init__(self, config: LLMConfig):
        super().__init__(config)
        self._client = openai.AsyncOpenAI(
            api_key=config.api_key,
            base_url=config.base_url,
        )

    async def _call_provider(self, **kwargs) -> Dict:
        messages = kwargs["messages"]
        if kwargs.get("system"):
            messages = [{"role": "system", "content": kwargs["system"]}] + messages

        response = await self._client.chat.completions.create(
            model=kwargs["model"],
            messages=messages,
            max_tokens=kwargs["max_tokens"],
            temperature=kwargs["temperature"],
        )
        choice = response.choices[0]
        return {
            "content": choice.message.content,
            "model": response.model,
            "input_tokens": response.usage.prompt_tokens,
            "output_tokens": response.usage.completion_tokens,
            "finish_reason": choice.finish_reason,
            "raw": response,
        }
```

---

## 2. Streaming Responses

### Server-Sent Events (SSE) Streaming

```python
from typing import AsyncIterator

async def stream_completion(
    client: anthropic.AsyncAnthropic,
    messages: list,
    model: str = "claude-sonnet-4-20250514",
    system: str = "",
) -> AsyncIterator[str]:
    """Stream LLM response tokens as they arrive."""
    async with client.messages.stream(
        model=model,
        max_tokens=4096,
        system=system,
        messages=messages,
    ) as stream:
        async for text in stream.text_stream:
            yield text
```

### FastAPI SSE Endpoint

```python
from fastapi import FastAPI, Request
from fastapi.responses import StreamingResponse
import json

app = FastAPI()

@app.post("/api/v1/chat/stream")
async def chat_stream(request: Request):
    body = await request.json()
    messages = body["messages"]

    async def event_generator():
        full_content = ""
        try:
            async for chunk in stream_completion(client, messages):
                full_content += chunk
                event = {"type": "content_delta", "text": chunk}
                yield f"data: {json.dumps(event)}\n\n"

            # Final event with usage stats
            yield f"data: {json.dumps({'type': 'done', 'content': full_content})}\n\n"

        except Exception as e:
            error_event = {"type": "error", "message": str(e)}
            yield f"data: {json.dumps(error_event)}\n\n"

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )
```

### Frontend Streaming Consumer (TypeScript)

```typescript
async function streamChat(
  messages: ChatMessage[],
  onChunk: (text: string) => void,
  onDone: (fullText: string) => void,
  onError: (error: string) => void,
): Promise<void> {
  const response = await fetch("/api/v1/chat/stream", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ messages }),
  });

  if (!response.ok) {
    onError(`HTTP ${response.status}: ${response.statusText}`);
    return;
  }

  const reader = response.body!.getReader();
  const decoder = new TextDecoder();
  let buffer = "";

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;

    buffer += decoder.decode(value, { stream: true });
    const lines = buffer.split("\n\n");
    buffer = lines.pop() || "";

    for (const line of lines) {
      if (!line.startsWith("data: ")) continue;
      const data = JSON.parse(line.slice(6));

      switch (data.type) {
        case "content_delta":
          onChunk(data.text);
          break;
        case "done":
          onDone(data.content);
          return;
        case "error":
          onError(data.message);
          return;
      }
    }
  }
}
```

---

## 3. Token Management

### Token Counting and Budget Enforcement

```python
from typing import List, Dict

# Using tiktoken for OpenAI models, or provider-specific tokenizers
def estimate_tokens(text: str, model: str = "claude-sonnet-4-20250514") -> int:
    """Estimate token count for a string.

    For production, use the provider's tokenizer library.
    This is a rough estimator for planning purposes.
    """
    # Rough heuristic: 1 token ~ 4 characters for English
    # For precise counts, use anthropic's token counting API
    return max(1, len(text) // 4)


def estimate_message_tokens(messages: List[Dict[str, str]]) -> int:
    """Estimate tokens for a conversation."""
    total = 0
    for msg in messages:
        # Each message has overhead (~4 tokens for role + formatting)
        total += 4
        total += estimate_tokens(msg.get("content", ""))
    return total


class TokenBudget:
    """Manage token budgets for conversations and features."""

    def __init__(self, max_context: int, max_output: int, reserve: int = 500):
        self.max_context = max_context    # Model's context window
        self.max_output = max_output      # Max output tokens to generate
        self.reserve = reserve            # Reserved for system overhead

    @property
    def available_for_input(self) -> int:
        return self.max_context - self.max_output - self.reserve

    def fits(self, messages: List[Dict], system: str = "") -> bool:
        """Check if messages fit within the token budget."""
        total = estimate_tokens(system) + estimate_message_tokens(messages)
        return total <= self.available_for_input

    def trim_history(
        self,
        messages: List[Dict],
        system: str = "",
        keep_first: int = 1,
        keep_last: int = 4,
    ) -> List[Dict]:
        """Trim conversation history to fit token budget.

        Preserves the first N and last M messages, removing from the middle.
        """
        if self.fits(messages, system):
            return messages

        if len(messages) <= keep_first + keep_last:
            return messages

        # Keep first and last, drop middle
        trimmed = messages[:keep_first] + messages[-keep_last:]

        # If still too large, summarize the dropped portion
        if not self.fits(trimmed, system):
            trimmed = messages[-keep_last:]

        return trimmed
```

### Context Window Planning

```
Model Context Windows (as of 2026):
-----------------------------------
claude-opus-4          200K tokens
claude-sonnet-4        200K tokens
claude-haiku-3.5       200K tokens
gpt-4o                 128K tokens
gpt-4o-mini            128K tokens

Token Budget Allocation (example for 200K context):
----------------------------------------------------
System prompt:          2,000 tokens  (1%)
Conversation history:  50,000 tokens  (25%)
RAG context:           80,000 tokens  (40%)
Reserve for output:     8,000 tokens  (4%)
Safety buffer:         60,000 tokens  (30%)
```

---

## 4. Cost Optimization

### Model Selection by Task

```python
from enum import Enum

class TaskComplexity(Enum):
    TRIVIAL = "trivial"      # Classification, extraction, formatting
    SIMPLE = "simple"        # Summarization, translation, Q&A
    MODERATE = "moderate"    # Analysis, code generation, multi-step reasoning
    COMPLEX = "complex"      # Research, architecture design, creative writing
    CRITICAL = "critical"    # Safety-critical, legal, medical advice


MODEL_SELECTION = {
    TaskComplexity.TRIVIAL:  "claude-haiku-35-20250414",
    TaskComplexity.SIMPLE:   "claude-haiku-35-20250414",
    TaskComplexity.MODERATE: "claude-sonnet-4-20250514",
    TaskComplexity.COMPLEX:  "claude-sonnet-4-20250514",
    TaskComplexity.CRITICAL: "claude-opus-4-20250514",
}


def select_model(task: str, complexity: TaskComplexity) -> str:
    """Select the most cost-effective model for the task."""
    return MODEL_SELECTION[complexity]
```

### Cost Tracking and Budgeting

```python
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from typing import Dict, List

@dataclass
class UsageRecord:
    timestamp: datetime
    model: str
    input_tokens: int
    output_tokens: int
    cost_usd: float
    feature: str
    user_id: str

@dataclass
class CostTracker:
    """Track and enforce API cost budgets."""
    daily_budget_usd: float = 100.0
    monthly_budget_usd: float = 2000.0
    records: List[UsageRecord] = field(default_factory=list)
    alert_threshold: float = 0.8  # Alert at 80% of budget

    def record(self, record: UsageRecord):
        self.records.append(record)

    def daily_spend(self, date: datetime = None) -> float:
        date = date or datetime.utcnow()
        start = date.replace(hour=0, minute=0, second=0, microsecond=0)
        return sum(r.cost_usd for r in self.records if r.timestamp >= start)

    def monthly_spend(self, date: datetime = None) -> float:
        date = date or datetime.utcnow()
        start = date.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        return sum(r.cost_usd for r in self.records if r.timestamp >= start)

    def is_over_budget(self) -> bool:
        return (
            self.daily_spend() >= self.daily_budget_usd
            or self.monthly_spend() >= self.monthly_budget_usd
        )

    def should_alert(self) -> bool:
        return (
            self.daily_spend() >= self.daily_budget_usd * self.alert_threshold
            or self.monthly_spend() >= self.monthly_budget_usd * self.alert_threshold
        )

    def cost_by_feature(self) -> Dict[str, float]:
        costs: Dict[str, float] = {}
        for r in self.records:
            costs[r.feature] = costs.get(r.feature, 0) + r.cost_usd
        return costs
```

### Cost Optimization Strategies

```
STRATEGY                         SAVINGS    EFFORT
-----------------------------------------------------------
1. Use smaller models for        60-80%     Low
   simple tasks (Haiku for
   classification/extraction)

2. Cache identical requests      20-50%     Low
   (deterministic prompts,
   temp=0)

3. Prompt compression            10-30%     Medium
   (fewer tokens in/out)

4. Batch requests                10-20%     Medium
   (group similar tasks)

5. Structured output             5-15%      Low
   (less verbose responses)

6. Conversation summarization    20-40%     Medium
   (compress history instead
   of sending full transcript)

7. Prompt caching (Anthropic)    Up to 90%  Low
   (reuse cached system prompt
   prefixes for repeated calls)
```

---

## 5. Retry and Fallback Strategies

### Exponential Backoff with Jitter

```python
import asyncio
import random
from typing import Callable, TypeVar, Optional

T = TypeVar("T")

async def retry_with_backoff(
    func: Callable,
    max_retries: int = 3,
    base_delay: float = 1.0,
    max_delay: float = 60.0,
    jitter: bool = True,
    retryable_errors: tuple = (RateLimitError, TimeoutError, ConnectionError),
) -> T:
    """Retry an async function with exponential backoff and jitter."""
    last_error = None

    for attempt in range(max_retries + 1):
        try:
            return await func()
        except retryable_errors as e:
            last_error = e
            if attempt == max_retries:
                raise

            delay = min(base_delay * (2 ** attempt), max_delay)
            if jitter:
                delay *= 0.5 + random.random()

            await asyncio.sleep(delay)

    raise last_error
```

### Model Fallback Chain

```python
from typing import List, Optional

class ModelFallbackChain:
    """Try progressively simpler models if the preferred model fails."""

    def __init__(self, clients: Dict[str, LLMClient], chain: List[str]):
        self.clients = clients
        self.chain = chain  # e.g., ["claude-opus-4", "claude-sonnet-4", "claude-haiku-3.5"]

    async def complete(self, messages: list, **kwargs) -> LLMResponse:
        errors = []

        for model_name in self.chain:
            try:
                client = self.clients[model_name]
                return await client.complete(messages, **kwargs)
            except (RateLimitError, TimeoutError) as e:
                errors.append(f"{model_name}: {e}")
                continue
            except ContextLengthError:
                # Try a model with a larger context or truncate
                kwargs["max_tokens"] = kwargs.get("max_tokens", 4096) // 2
                continue

        raise RuntimeError(f"All models in fallback chain failed: {errors}")
```

### Graceful Degradation

```python
async def get_ai_response(query: str, context: dict) -> dict:
    """Get AI response with graceful degradation."""

    # Tier 1: Full AI response
    try:
        response = await llm_client.complete(
            messages=[{"role": "user", "content": query}],
            system=build_system_prompt(context),
        )
        return {"source": "ai", "content": response.content, "confidence": "high"}
    except (RateLimitError, TimeoutError):
        pass

    # Tier 2: Cached/similar response
    cached = await find_similar_cached_response(query)
    if cached and cached.similarity > 0.9:
        return {"source": "cache", "content": cached.content, "confidence": "medium"}

    # Tier 3: Template response
    template = get_template_response(query)
    if template:
        return {"source": "template", "content": template, "confidence": "low"}

    # Tier 4: Handoff
    return {
        "source": "fallback",
        "content": "I'm unable to process your request right now. "
                   "A team member will follow up shortly.",
        "confidence": "none",
        "requires_human": True,
    }
```

---

## 6. Structured Output (JSON Mode)

### Schema-Validated Output

```python
import json
from pydantic import BaseModel, ValidationError
from typing import List, Optional

class InvoiceExtraction(BaseModel):
    invoice_number: str
    date: str
    vendor_name: str
    vendor_id: Optional[str] = None
    total_amount: float
    currency: str = "USD"
    line_items: List[dict]
    confidence: float

async def extract_with_schema(
    client: LLMClient,
    document: str,
    schema: type[BaseModel],
    max_retries: int = 2,
) -> BaseModel:
    """Extract structured data from text, validated against a Pydantic schema."""

    schema_json = json.dumps(schema.model_json_schema(), indent=2)

    prompt = f"""Extract the following information from the document.
Return ONLY valid JSON matching this schema:

{schema_json}

Document:
{document}

JSON output:"""

    for attempt in range(max_retries + 1):
        response = await client.complete(
            messages=[{"role": "user", "content": prompt}],
            temperature=0.0,
        )

        # Parse and validate
        try:
            # Strip markdown code fences if present
            content = response.content.strip()
            if content.startswith("```"):
                content = content.split("\n", 1)[1].rsplit("```", 1)[0]

            data = json.loads(content)
            return schema.model_validate(data)

        except (json.JSONDecodeError, ValidationError) as e:
            if attempt == max_retries:
                raise ValueError(f"Failed to extract valid structured output after {max_retries + 1} attempts: {e}")

            # Retry with error feedback
            prompt += f"\n\nYour previous response had an error: {e}\nPlease fix and return valid JSON."

    raise RuntimeError("Unreachable")
```

### Tool Use / Function Calling

```python
# Define tools for the model to call
TOOLS = [
    {
        "name": "lookup_customer",
        "description": "Look up customer information by name or ID",
        "input_schema": {
            "type": "object",
            "properties": {
                "customer_id": {"type": "string", "description": "Customer ID"},
                "name": {"type": "string", "description": "Customer name for search"},
            },
            "required": [],
        },
    },
    {
        "name": "create_invoice",
        "description": "Create a new invoice in the ERP system",
        "input_schema": {
            "type": "object",
            "properties": {
                "customer_id": {"type": "string"},
                "items": {
                    "type": "array",
                    "items": {
                        "type": "object",
                        "properties": {
                            "product_id": {"type": "string"},
                            "quantity": {"type": "number"},
                            "price": {"type": "number"},
                        },
                        "required": ["product_id", "quantity", "price"],
                    },
                },
                "due_date": {"type": "string", "description": "ISO 8601 date"},
            },
            "required": ["customer_id", "items"],
        },
    },
]


async def handle_tool_use(client, messages, tools):
    """Process a conversation with tool use, executing tool calls and feeding results back."""

    response = await client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=4096,
        messages=messages,
        tools=tools,
    )

    while response.stop_reason == "tool_use":
        tool_blocks = [b for b in response.content if b.type == "tool_use"]
        tool_results = []

        for block in tool_blocks:
            result = await execute_tool(block.name, block.input)
            tool_results.append({
                "type": "tool_result",
                "tool_use_id": block.id,
                "content": json.dumps(result),
            })

        messages.append({"role": "assistant", "content": response.content})
        messages.append({"role": "user", "content": tool_results})

        response = await client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=4096,
            messages=messages,
            tools=tools,
        )

    return response


async def execute_tool(name: str, inputs: dict) -> dict:
    """Execute a tool call and return the result."""
    if name == "lookup_customer":
        return await customer_service.lookup(**inputs)
    elif name == "create_invoice":
        return await invoice_service.create(**inputs)
    else:
        return {"error": f"Unknown tool: {name}"}
```

---

## 7. Embedding Pipelines

### Document Embedding and Search

```python
import numpy as np
from typing import List, Tuple
from dataclasses import dataclass

@dataclass
class EmbeddedDocument:
    id: str
    text: str
    embedding: np.ndarray
    metadata: dict

class EmbeddingPipeline:
    """Pipeline for embedding documents and performing semantic search."""

    def __init__(self, embedding_client, vector_store):
        self.client = embedding_client
        self.store = vector_store

    async def embed_text(self, text: str) -> np.ndarray:
        """Generate an embedding vector for text."""
        response = await self.client.embeddings.create(
            model="text-embedding-3-small",
            input=text,
        )
        return np.array(response.data[0].embedding)

    async def index_documents(
        self,
        documents: List[dict],
        chunk_size: int = 512,
        chunk_overlap: int = 50,
    ):
        """Chunk, embed, and index documents."""
        for doc in documents:
            chunks = self.chunk_text(doc["text"], chunk_size, chunk_overlap)
            for i, chunk in enumerate(chunks):
                embedding = await self.embed_text(chunk)
                await self.store.upsert(
                    id=f"{doc['id']}_chunk_{i}",
                    embedding=embedding,
                    metadata={
                        "source_id": doc["id"],
                        "chunk_index": i,
                        "text": chunk,
                        **doc.get("metadata", {}),
                    },
                )

    async def search(
        self,
        query: str,
        top_k: int = 5,
        min_score: float = 0.7,
        filters: dict = None,
    ) -> List[Tuple[dict, float]]:
        """Semantic search for relevant document chunks."""
        query_embedding = await self.embed_text(query)
        results = await self.store.query(
            embedding=query_embedding,
            top_k=top_k,
            filters=filters,
        )
        return [(r.metadata, r.score) for r in results if r.score >= min_score]

    @staticmethod
    def chunk_text(text: str, chunk_size: int, overlap: int) -> List[str]:
        """Split text into overlapping chunks at sentence boundaries."""
        sentences = text.replace("\n", " ").split(". ")
        chunks = []
        current_chunk = []
        current_length = 0

        for sentence in sentences:
            sentence_len = len(sentence.split())
            if current_length + sentence_len > chunk_size and current_chunk:
                chunks.append(". ".join(current_chunk) + ".")
                # Keep overlap
                overlap_sentences = []
                overlap_len = 0
                for s in reversed(current_chunk):
                    overlap_len += len(s.split())
                    if overlap_len > overlap:
                        break
                    overlap_sentences.insert(0, s)
                current_chunk = overlap_sentences
                current_length = sum(len(s.split()) for s in current_chunk)

            current_chunk.append(sentence)
            current_length += sentence_len

        if current_chunk:
            chunks.append(". ".join(current_chunk) + ".")

        return chunks
```

---

## 8. RAG (Retrieval-Augmented Generation)

### Full RAG Pipeline

```python
class RAGPipeline:
    """Retrieval-Augmented Generation pipeline."""

    def __init__(
        self,
        embedding_pipeline: EmbeddingPipeline,
        llm_client: LLMClient,
        system_prompt: str = "",
    ):
        self.embeddings = embedding_pipeline
        self.llm = llm_client
        self.system_prompt = system_prompt

    async def query(
        self,
        question: str,
        top_k: int = 5,
        filters: dict = None,
        include_sources: bool = True,
    ) -> dict:
        """Answer a question using retrieved context."""

        # Step 1: Retrieve relevant documents
        results = await self.embeddings.search(
            query=question,
            top_k=top_k,
            filters=filters,
        )

        if not results:
            return {
                "answer": "I could not find relevant information to answer this question.",
                "sources": [],
                "confidence": "low",
            }

        # Step 2: Build context from retrieved chunks
        context_parts = []
        sources = []
        for metadata, score in results:
            context_parts.append(f"[Source: {metadata.get('source_id', 'unknown')} "
                                 f"(relevance: {score:.2f})]\n{metadata['text']}")
            sources.append({
                "id": metadata.get("source_id"),
                "score": round(score, 3),
                "excerpt": metadata["text"][:200],
            })

        context = "\n\n---\n\n".join(context_parts)

        # Step 3: Generate answer with context
        prompt = f"""Answer the question based on the provided context.
If the context does not contain enough information, say so clearly.
Do not make up information that is not in the context.

## Context
{context}

## Question
{question}

## Instructions
- Answer based only on the provided context
- Cite sources using [Source: ID] notation
- If information is partial or uncertain, state that explicitly
"""

        response = await self.llm.complete(
            messages=[{"role": "user", "content": prompt}],
            system=self.system_prompt,
            temperature=0.0,
        )

        return {
            "answer": response.content,
            "sources": sources if include_sources else [],
            "tokens_used": response.total_tokens,
            "cost": response.cost_estimate,
        }
```

### RAG Quality Checklist

```
RETRIEVAL QUALITY
- [ ] Chunk size tuned (test 256, 512, 1024 tokens)
- [ ] Chunk overlap prevents context splitting (10-20% overlap)
- [ ] Metadata filters scope search correctly (branch_id, doc_type)
- [ ] Top-k tuned for recall vs. precision (start with 5, adjust)
- [ ] Minimum similarity threshold set (0.7 is a reasonable starting point)
- [ ] Re-ranking applied if using a two-stage retrieval approach

GENERATION QUALITY
- [ ] System prompt instructs model to cite sources
- [ ] Model instructed not to hallucinate beyond context
- [ ] Context formatted clearly with source attribution
- [ ] Token budget accounts for context + output
- [ ] Temperature set to 0 for factual Q&A

DATA PIPELINE
- [ ] Documents re-indexed when source data changes
- [ ] Stale embeddings detected and refreshed
- [ ] Chunking preserves semantic boundaries (paragraphs, sections)
- [ ] Special content handled (tables, code blocks, lists)
```

---

## 9. Prompt Versioning

### Version Control for Prompts

```python
import hashlib
from datetime import datetime
from typing import Optional, Dict, List

class PromptVersion:
    """A version-controlled prompt with metadata."""

    def __init__(self, name: str, version: str, template: str, metadata: dict = None):
        self.name = name
        self.version = version
        self.template = template
        self.metadata = metadata or {}
        self.created_at = datetime.utcnow().isoformat()
        self.content_hash = hashlib.sha256(template.encode()).hexdigest()[:12]

class PromptRegistry:
    """Manage prompt versions with rollback support."""

    def __init__(self):
        self._versions: Dict[str, List[PromptVersion]] = {}
        self._active: Dict[str, str] = {}

    def register(self, name: str, version: str, template: str, **metadata) -> PromptVersion:
        pv = PromptVersion(name, version, template, metadata)
        self._versions.setdefault(name, []).append(pv)
        if name not in self._active:
            self._active[name] = version
        return pv

    def get_active(self, name: str) -> PromptVersion:
        version = self._active.get(name)
        if not version:
            raise KeyError(f"No active version for prompt '{name}'")
        return self.get(name, version)

    def get(self, name: str, version: str) -> PromptVersion:
        for pv in self._versions.get(name, []):
            if pv.version == version:
                return pv
        raise KeyError(f"Prompt '{name}' version '{version}' not found")

    def activate(self, name: str, version: str):
        self.get(name, version)  # validate
        self._active[name] = version

    def rollback(self, name: str):
        versions = self._versions.get(name, [])
        if len(versions) < 2:
            raise ValueError("No previous version to rollback to")
        current = self._active[name]
        for pv in reversed(versions):
            if pv.version != current:
                self._active[name] = pv.version
                return pv
        raise ValueError("No previous version found")
```

### Prompt-as-Code Directory Structure

```
prompts/
  system/
    support-agent.v1.md
    support-agent.v2.md
    finance-agent.v1.md
  tasks/
    classify-ticket.v1.md
    classify-ticket.v2.md
    extract-invoice.v1.md
  registry.json          # Maps prompt names to active versions
  tests/
    test_classify.py     # Automated eval for each prompt version
    test_extract.py
```

---

## 10. Fine-Tuning Workflows

### When to Fine-Tune vs. Prompt

```
USE PROMPTING WHEN:                    USE FINE-TUNING WHEN:
-----------------------------------------+------------------------------------------
Task is well-described in instructions    Task is hard to describe but easy to show
Few-shot examples are sufficient          Thousands of examples available
Output format is standard                 Domain-specific style/terminology needed
Accuracy is acceptable with prompting     Need marginal accuracy gains (>5%)
Cost is acceptable                        High-volume, cost-sensitive task
Task changes frequently                   Task is stable and well-defined
```

### Fine-Tuning Data Preparation

```python
import json
from typing import List, Dict

def prepare_training_data(
    examples: List[Dict],
    system_prompt: str,
    output_path: str,
    validation_split: float = 0.1,
):
    """Prepare training data in JSONL format for fine-tuning."""

    # Validate examples
    for i, ex in enumerate(examples):
        assert "input" in ex, f"Example {i} missing 'input'"
        assert "output" in ex, f"Example {i} missing 'output'"
        assert len(ex["output"]) > 0, f"Example {i} has empty output"

    # Convert to chat format
    training_records = []
    for ex in examples:
        record = {
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": ex["input"]},
                {"role": "assistant", "content": ex["output"]},
            ]
        }
        training_records.append(record)

    # Split into train/validation
    split_idx = int(len(training_records) * (1 - validation_split))
    train_data = training_records[:split_idx]
    val_data = training_records[split_idx:]

    # Write JSONL files
    with open(f"{output_path}/train.jsonl", "w") as f:
        for record in train_data:
            f.write(json.dumps(record) + "\n")

    with open(f"{output_path}/validation.jsonl", "w") as f:
        for record in val_data:
            f.write(json.dumps(record) + "\n")

    return {
        "total_examples": len(examples),
        "training": len(train_data),
        "validation": len(val_data),
    }
```

---

## 11. Safety Guardrails

### Input Validation

```python
import re
from typing import List, Optional

class InputGuardrail:
    """Validate and sanitize user inputs before sending to the LLM."""

    MAX_INPUT_LENGTH = 50_000  # characters
    BLOCKED_PATTERNS = [
        r"ignore\s+(all\s+)?previous\s+instructions",
        r"ignore\s+(all\s+)?above",
        r"disregard\s+(all\s+)?(the\s+)?above",
        r"you\s+are\s+now\s+(?:DAN|jailbroken)",
        r"pretend\s+you\s+(?:are|have)\s+no\s+(?:rules|restrictions|limits)",
        r"(?:system|developer)\s+(?:prompt|mode)\s*:",
    ]

    def validate(self, text: str) -> tuple[bool, Optional[str]]:
        """Validate input text. Returns (is_valid, error_message)."""

        if not text or not text.strip():
            return False, "Input is empty"

        if len(text) > self.MAX_INPUT_LENGTH:
            return False, f"Input exceeds maximum length of {self.MAX_INPUT_LENGTH} characters"

        for pattern in self.BLOCKED_PATTERNS:
            if re.search(pattern, text, re.IGNORECASE):
                return False, "Input contains disallowed content"

        return True, None

    def sanitize(self, text: str) -> str:
        """Wrap user input in clear delimiters to prevent injection."""
        return f"<user_input>\n{text}\n</user_input>"
```

### Output Validation

```python
class OutputGuardrail:
    """Validate LLM outputs before presenting to users."""

    PII_PATTERNS = [
        (r"\b\d{3}-\d{2}-\d{4}\b", "SSN"),
        (r"\b\d{16}\b", "credit card"),
        (r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b", "email"),
    ]

    BLOCKED_CONTENT = [
        "api_key",
        "secret_key",
        "password",
        "private_key",
        "-----BEGIN RSA",
        "-----BEGIN PRIVATE",
    ]

    def validate(self, output: str) -> dict:
        """Check output for PII, secrets, and harmful content."""
        issues = []

        # Check for PII
        for pattern, pii_type in self.PII_PATTERNS:
            if re.search(pattern, output):
                issues.append({"type": "pii", "detail": f"Possible {pii_type} detected"})

        # Check for secrets
        for blocked in self.BLOCKED_CONTENT:
            if blocked.lower() in output.lower():
                issues.append({"type": "secret", "detail": f"Possible secret: {blocked}"})

        return {
            "is_safe": len(issues) == 0,
            "issues": issues,
            "output": output if len(issues) == 0 else self._redact(output),
        }

    def _redact(self, text: str) -> str:
        """Redact detected PII from output."""
        for pattern, _ in self.PII_PATTERNS:
            text = re.sub(pattern, "[REDACTED]", text)
        return text
```

### Multi-Tenant Isolation in LLM Calls

```python
def build_tenant_scoped_prompt(
    base_prompt: str,
    branch_id: str,
    user_role: str,
) -> str:
    """Inject tenant isolation rules into the prompt."""
    isolation_rules = f"""
## Data Isolation Rules
- You are operating in the context of branch_id: {branch_id}
- User role: {user_role}
- NEVER reference, access, or reveal data from any other branch
- If the user asks about other branches, explain that data isolation prevents cross-branch access
- All database queries MUST include WHERE branch_id = '{branch_id}'
"""
    return base_prompt + "\n" + isolation_rules
```

---

## 12. Rate Limiting

### Token Bucket Rate Limiter

```python
import time
import asyncio

class TokenBucketLimiter:
    """Rate limiter using the token bucket algorithm."""

    def __init__(self, rate: float, capacity: int):
        """
        Args:
            rate: Tokens added per second (requests per second)
            capacity: Maximum burst size
        """
        self.rate = rate
        self.capacity = capacity
        self.tokens = capacity
        self.last_refill = time.monotonic()
        self._lock = asyncio.Lock()

    async def acquire(self, tokens: int = 1):
        """Wait until tokens are available, then consume them."""
        async with self._lock:
            while True:
                self._refill()
                if self.tokens >= tokens:
                    self.tokens -= tokens
                    return
                # Wait for tokens to refill
                wait_time = (tokens - self.tokens) / self.rate
                await asyncio.sleep(wait_time)

    def _refill(self):
        now = time.monotonic()
        elapsed = now - self.last_refill
        self.tokens = min(self.capacity, self.tokens + elapsed * self.rate)
        self.last_refill = now


# Usage: 1 request per second, burst of 5
limiter = TokenBucketLimiter(rate=1.0, capacity=5)

async def rate_limited_call(client, messages):
    await limiter.acquire()
    return await client.complete(messages)
```

### Per-User and Per-Feature Limits

```python
from collections import defaultdict

class MultiTierRateLimiter:
    """Rate limiting at multiple tiers: global, per-user, per-feature."""

    def __init__(self):
        self.global_limiter = TokenBucketLimiter(rate=10.0, capacity=50)
        self.user_limiters: dict = defaultdict(lambda: TokenBucketLimiter(rate=1.0, capacity=5))
        self.feature_limiters: dict = defaultdict(lambda: TokenBucketLimiter(rate=5.0, capacity=20))

    async def acquire(self, user_id: str, feature: str):
        """Acquire rate limit tokens at all tiers."""
        await asyncio.gather(
            self.global_limiter.acquire(),
            self.user_limiters[user_id].acquire(),
            self.feature_limiters[feature].acquire(),
        )
```

---

## 13. Evaluation Framework

### Automated Evaluation Pipeline

```python
from dataclasses import dataclass
from typing import Callable, List

@dataclass
class EvalCase:
    input: str
    expected_output: str
    category: str
    metadata: dict = None

@dataclass
class EvalResult:
    case: EvalCase
    actual_output: str
    passed: bool
    score: float
    metrics: dict

class PromptEvaluator:
    """Evaluate prompt quality against a test suite."""

    def __init__(self, client: LLMClient, prompt_template: str):
        self.client = client
        self.template = prompt_template

    async def evaluate(
        self,
        test_cases: List[EvalCase],
        scorers: List[Callable],
    ) -> dict:
        results = []
        for case in test_cases:
            response = await self.client.complete(
                messages=[{"role": "user", "content": self.template.format(input=case.input)}],
                temperature=0.0,
            )

            scores = {}
            for scorer in scorers:
                score_name, score_value = scorer(case.expected_output, response.content)
                scores[score_name] = score_value

            avg_score = sum(scores.values()) / len(scores) if scores else 0
            results.append(EvalResult(
                case=case,
                actual_output=response.content,
                passed=avg_score >= 0.8,
                score=avg_score,
                metrics=scores,
            ))

        # Aggregate metrics
        total = len(results)
        passed = sum(1 for r in results if r.passed)
        return {
            "total": total,
            "passed": passed,
            "failed": total - passed,
            "pass_rate": passed / total if total else 0,
            "avg_score": sum(r.score for r in results) / total if total else 0,
            "by_category": self._group_by_category(results),
            "results": results,
        }

    def _group_by_category(self, results: List[EvalResult]) -> dict:
        groups = {}
        for r in results:
            cat = r.case.category
            if cat not in groups:
                groups[cat] = {"total": 0, "passed": 0, "avg_score": 0, "scores": []}
            groups[cat]["total"] += 1
            groups[cat]["passed"] += 1 if r.passed else 0
            groups[cat]["scores"].append(r.score)
        for cat in groups:
            groups[cat]["avg_score"] = sum(groups[cat]["scores"]) / len(groups[cat]["scores"])
            del groups[cat]["scores"]
        return groups
```

---

## 14. Integration Checklist

```
PRE-LAUNCH
- [ ] API client handles retries, timeouts, and rate limits
- [ ] Fallback chain configured (primary model -> backup model -> template)
- [ ] Token budget enforced (input + output within context window)
- [ ] Cost tracking and alerts configured
- [ ] Prompt injection defenses in place (input sanitization, delimiters)
- [ ] Output validation active (PII, secrets, format checking)
- [ ] Multi-tenant data isolation enforced in all prompts
- [ ] Structured output validated against schema
- [ ] Streaming endpoint tested with error handling
- [ ] Rate limiting configured per-user and per-feature
- [ ] Evaluation test suite passing with >80% score

MONITORING
- [ ] Latency tracked per endpoint (p50, p95, p99)
- [ ] Token usage tracked per feature and per user
- [ ] Cost dashboard updated in real time
- [ ] Error rates monitored with alerting
- [ ] Output quality sampled and reviewed regularly
- [ ] Cache hit rate tracked (target >30% for repeated queries)

OPERATIONS
- [ ] Prompt versions tracked in registry
- [ ] Rollback procedure documented and tested
- [ ] A/B testing framework configured for prompt experiments
- [ ] Model migration plan documented (for model upgrades)
- [ ] Incident response plan covers LLM-specific failures
```
