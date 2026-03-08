---
name: conversational-ai
description: Use when designing chatbots, copilots, or conversational assistants — dialogue management, intent recognition, entity extraction, context handling, multi-turn conversations, personality design, escalation flows, error recovery, conversation analytics, architecture patterns, voice interfaces, NLU pipelines, and conversation testing.
user-invocable: true
allowed-tools: ["Read", "Write", "Edit", "Grep", "Glob", "Bash"]
---

# Conversational AI Design

Patterns for building production-grade conversational AI systems.

---

## 1. Architecture

```
User Input -> Input Processing (sanitize, language detect)
           -> Intent Classifier (what do they want?)
           -> Entity Extractor (what details did they provide?)
           -> Dialogue Manager (state machine / LLM router)
           -> Context Retriever (RAG, DB, APIs)
           -> Response Generator (LLM)
           -> Safety Filter (PII, toxicity, policy)
           -> User Response
```

**Architecture decision -- LLM-native vs hybrid**:
- **LLM-native**: System prompt + tools. Best for open-domain, complex reasoning, rapid prototyping. Higher cost, less predictable.
- **Hybrid (intent + LLM)**: Classifier routes to handlers; LLM generates within handler. Best for high-volume, predictable domains. Lower cost, more control.
- **Rule-based with LLM fallback**: Decision trees for known flows, LLM for everything else. Best for regulated domains (healthcare, finance).

## 2. Intent Recognition

```python
# LLM-based intent classification
INTENT_PROMPT = """Classify the user message into exactly one intent.
Intents: {intent_list}
Message: {message}
Return JSON: {"intent": "...", "confidence": 0.0-1.0}"""

# Confidence thresholds
HIGH_CONFIDENCE = 0.85   # Execute directly
MEDIUM_CONFIDENCE = 0.6  # Confirm with user
LOW_CONFIDENCE = 0.6     # Clarify or fallback
```

**Intent design principles**: Keep intents mutually exclusive. 15-30 intents per domain is manageable. Group related intents hierarchically (e.g., `order.status`, `order.cancel`, `order.return`). Include a `fallback` intent for unrecognized input.

## 3. Entity Extraction

```python
ENTITY_PROMPT = """Extract entities from the user message.
Entity types: {entity_schema}
Message: {message}
Return JSON: {"entities": [{"type": "...", "value": "...", "normalized": "..."}]}"""

# Common entity types for business applications
ENTITIES = {
    "date": {"format": "ISO 8601", "examples": ["tomorrow", "next Friday", "March 15"]},
    "currency": {"format": "amount + code", "examples": ["$500", "100 AED"]},
    "order_id": {"pattern": r"ORD-\d{6}", "examples": ["ORD-123456"]},
    "email": {"pattern": r"[\w.-]+@[\w.-]+\.\w+"},
}
```

**Slot filling**: Track required vs optional entities per intent. Prompt for missing required slots. Confirm ambiguous values. Carry forward entities from prior turns.

## 4. Dialogue Management

### State Machine Pattern (Structured Flows)

```python
FLOWS = {
    "order_status": {
        "slots": {"order_id": {"required": True, "prompt": "What's your order number?"}},
        "handler": "lookup_order_status",
        "confirm": False,
    },
    "cancel_order": {
        "slots": {"order_id": {"required": True}, "reason": {"required": False}},
        "handler": "cancel_order",
        "confirm": True,  # Destructive action -- confirm before executing
    },
}
```

### LLM Router Pattern (Flexible)

```python
ROUTER_PROMPT = """You are a customer support assistant. Based on the conversation,
decide the next action:
- "ask_clarification": Need more info from user (provide the question)
- "execute_tool": Ready to call a tool (provide tool name and args)
- "respond": Have enough info to answer directly
- "escalate": Cannot handle, needs human agent

Conversation: {history}
Available tools: {tool_descriptions}
Return JSON: {"action": "...", "details": {...}}"""
```

**When to use which**: State machine for linear, predictable flows (checkout, onboarding). LLM router for open-ended, multi-path conversations (support, advisory). Combine both: state machine for critical paths, LLM for everything between.

## 5. Multi-Turn Context Management

```python
@dataclass
class ConversationContext:
    session_id: str
    user_id: str
    messages: list[dict]        # Full conversation history
    active_intent: str | None
    collected_entities: dict     # Slot values across turns
    metadata: dict              # User profile, preferences, prior interactions

    def to_prompt_context(self, max_turns: int = 10) -> str:
        """Trim to recent turns for LLM context window."""
        recent = self.messages[-max_turns:]
        return "\n".join(f"{m['role']}: {m['content']}" for m in recent)
```

**Context strategies**:
- **Sliding window**: Last N turns (simple, loses early context)
- **Summary + recent**: Summarize older turns, keep last 5 verbatim
- **Entity carry-forward**: Extract and persist key facts across the session
- **Session storage**: Redis with TTL (30 min default), persist to DB on session end

## 6. Personality and Tone Design

```yaml
personality:
  name: "Alex"
  role: "Customer support specialist"
  tone: "Professional, warm, concise"
  rules:
    - Use the customer's name when known
    - Acknowledge frustration before solving ("I understand that's frustrating")
    - Keep responses under 3 sentences for simple queries
    - Use bullet points for multi-step instructions
    - Never say "I'm just an AI" -- say "Let me help with that"
    - Avoid jargon -- explain technical terms when necessary
  boundaries:
    - Never discuss competitors by name
    - Never make promises about timelines
    - Never share internal policies or pricing logic
    - Escalate legal/compliance questions to human agents
```

## 7. Escalation and Handoff

| Trigger | Action |
|---------|--------|
| User requests human agent | Immediate handoff |
| Confidence < 0.4 for 2+ turns | Offer handoff |
| Sentiment score drops below threshold | Offer handoff |
| Sensitive topic (legal, billing dispute, complaint) | Auto-escalate |
| Max turns exceeded (e.g., 15 turns without resolution) | Offer handoff |

**Handoff protocol**: Summarize conversation for the human agent (intent, entities collected, actions taken, unresolved issues). Transfer context seamlessly -- never make the user repeat themselves. Notify user of expected wait time.

## 8. Error Recovery

| Error Type | Recovery Strategy |
|-----------|------------------|
| Intent unclear | "Could you rephrase? I can help with X, Y, or Z." |
| Missing entity | Prompt specifically: "What's your order number?" |
| API/tool failure | "I'm having trouble looking that up. Let me try again." Retry once, then offer alternative. |
| Contradictory input | "Earlier you mentioned X, but now Y. Which is correct?" |
| Out-of-scope | "I can help with [domain]. For [other topic], please contact [channel]." |
| Repeated failures | "I'm not able to resolve this. Let me connect you with a specialist." |

## 9. Conversation Analytics

**Key metrics**:
- **Resolution rate**: % of conversations resolved without escalation
- **Avg turns to resolution**: Lower is better (target: 3-5 for simple queries)
- **Escalation rate**: Target < 15% for mature systems
- **User satisfaction**: Post-chat survey (CSAT) or thumbs up/down
- **Containment rate**: % handled fully by AI without human intervention
- **Intent coverage**: % of user messages that match a defined intent
- **Fallback rate**: % of messages hitting fallback intent (target < 10%)

**Analytics pipeline**: Log every turn (user input, intent, entities, response, latency, feedback). Aggregate daily. Review fallback/low-confidence turns weekly to identify new intents or training gaps.

## 10. Conversation Testing

```python
# Test case structure
test_cases = [
    {
        "name": "order_status_happy_path",
        "turns": [
            {"user": "Where's my order?", "expect_intent": "order_status"},
            {"user": "ORD-123456", "expect_entities": {"order_id": "ORD-123456"}},
        ],
        "expect_resolution": True,
    },
    {
        "name": "escalation_on_frustration",
        "turns": [
            {"user": "This is ridiculous, nothing works!"},
            {"user": "I want to speak to a manager NOW"},
        ],
        "expect_escalation": True,
    },
]
```

**Testing strategy**:
- **Unit**: Test intent classifier, entity extractor, individual handlers in isolation
- **Integration**: Test full conversation flows end-to-end (happy path + error paths)
- **Regression**: Run eval suite on every prompt/model change -- fail deploy on score drop
- **Adversarial**: Prompt injection, off-topic, profanity, PII extraction attempts
- **Load**: Measure latency under concurrent conversations (target p95 < 3s)

## 11. Voice Interface Considerations

**Speech-to-text**: Use streaming ASR for real-time transcription. Handle partial utterances and corrections. Detect end-of-utterance (silence threshold: 700ms-1.2s depending on context).

**Text-to-speech**: Pre-generate common responses for low latency. Use SSML for pronunciation, pauses, and emphasis. Match voice to personality design.

**Voice-specific patterns**: Shorter responses (1-2 sentences max). Confirmation before destructive actions ("I'll cancel order 123456. Is that correct?"). Barge-in support (user can interrupt). Fallback to text channel for complex information (send SMS/email with details).

## 12. Production Checklist

- [ ] Intent classifier tested with >= 100 examples per intent
- [ ] Entity extraction handles common formats and edge cases
- [ ] Multi-turn context persisted (Redis/DB) with TTL
- [ ] Escalation triggers defined and tested
- [ ] Error recovery for all failure modes (API down, unclear input, out of scope)
- [ ] Personality guidelines documented and enforced in system prompt
- [ ] Safety filters: PII detection, toxicity, prompt injection
- [ ] Conversation logging with PII redaction for analytics
- [ ] Monitoring: resolution rate, escalation rate, latency, satisfaction
- [ ] A/B testing framework for prompt/flow changes
- [ ] Graceful degradation when LLM provider is unavailable
