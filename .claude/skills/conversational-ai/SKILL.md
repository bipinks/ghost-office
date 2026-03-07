---
name: conversational-ai
description: Use when designing chatbots, copilots, or conversational assistants — dialogue management, intent recognition, entity extraction, context handling, multi-turn conversations, personality design, escalation flows, error recovery, conversation analytics, architecture patterns, voice interfaces, NLU pipelines, and conversation testing.
user-invocable: true
allowed-tools: ["Read", "Write", "Edit", "Grep", "Glob", "Bash"]
---

# Conversational AI Design

Comprehensive reference for building production-grade conversational AI systems. Covers dialogue management, intent recognition, entity extraction, multi-turn handling, personality design, escalation, error recovery, analytics, testing, and architecture patterns.

---

## 1. Conversational AI Architecture

### High-Level System Design

```
User Input
    |
    v
+-------------------+
| Input Processing  |  -- Sanitize, normalize, language detection
+-------------------+
    |
    v
+-------------------+
| Intent Classifier |  -- What does the user want to do?
+-------------------+
    |
    v
+-------------------+
| Entity Extractor  |  -- What specific details did they provide?
+-------------------+
    |
    v
+-------------------+
| Dialogue Manager  |  -- What state are we in? What next?
+-------------------+
    |
    v
+-------------------+
| Context Retriever |  -- Fetch relevant data (RAG, DB, APIs)
+-------------------+
    |
    v
+-------------------+
| Response Generator|  -- Generate the actual response (LLM)
+-------------------+
    |
    v
+-------------------+
| Safety Filter     |  -- Check for PII, harmful content, policy
+-------------------+
    |
    v
+-------------------+
| Output Formatter  |  -- Format for channel (web, voice, SMS)
+-------------------+
    |
    v
User Response
```

### Architecture Patterns

#### Pattern 1: LLM-Native (Recommended for most cases)

The LLM handles intent recognition, entity extraction, and response generation in a single call with a well-designed system prompt.

```python
class LLMNativeChatbot:
    """LLM handles all NLU + generation in one pass."""

    def __init__(self, client, system_prompt: str, tools: list = None):
        self.client = client
        self.system_prompt = system_prompt
        self.tools = tools or []
        self.conversations: dict = {}  # session_id -> messages

    async def handle_message(
        self,
        session_id: str,
        user_message: str,
        user_context: dict = None,
    ) -> dict:
        # Get or create conversation history
        history = self.conversations.setdefault(session_id, [])

        # Build system prompt with dynamic context
        system = self._build_system(user_context)

        # Add user message
        history.append({"role": "user", "content": user_message})

        # Trim history if needed
        trimmed = self._trim_history(history)

        # Call LLM
        response = await self.client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=2048,
            system=system,
            messages=trimmed,
            tools=self.tools if self.tools else None,
        )

        # Handle tool use if needed
        if response.stop_reason == "tool_use":
            response = await self._handle_tools(response, trimmed)

        # Extract response text
        assistant_text = ""
        for block in response.content:
            if hasattr(block, "text"):
                assistant_text += block.text

        # Save to history
        history.append({"role": "assistant", "content": assistant_text})

        return {
            "response": assistant_text,
            "session_id": session_id,
            "turn_count": len(history) // 2,
        }

    def _build_system(self, user_context: dict = None) -> str:
        prompt = self.system_prompt
        if user_context:
            ctx = "\n".join(f"- {k}: {v}" for k, v in user_context.items())
            prompt += f"\n\n## Current User Context\n{ctx}"
        return prompt

    def _trim_history(self, history: list, max_turns: int = 20) -> list:
        """Keep the most recent turns within the token budget."""
        if len(history) <= max_turns * 2:
            return history
        # Keep first message (may contain important context) and recent turns
        return history[:2] + history[-(max_turns * 2 - 2):]

    async def _handle_tools(self, response, messages):
        """Execute tool calls and get final response."""
        tool_blocks = [b for b in response.content if b.type == "tool_use"]
        tool_results = []

        for block in tool_blocks:
            result = await self._execute_tool(block.name, block.input)
            tool_results.append({
                "type": "tool_result",
                "tool_use_id": block.id,
                "content": str(result),
            })

        messages.append({"role": "assistant", "content": response.content})
        messages.append({"role": "user", "content": tool_results})

        return await self.client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=2048,
            system=self.system_prompt,
            messages=messages,
            tools=self.tools,
        )

    async def _execute_tool(self, name: str, inputs: dict) -> dict:
        """Route tool calls to implementations."""
        raise NotImplementedError("Override with your tool implementations")
```

#### Pattern 2: Hybrid (Intent Router + LLM Generation)

Use a lightweight classifier for routing, with LLM generation for responses.

```python
from enum import Enum
from typing import Optional

class Intent(Enum):
    GREETING = "greeting"
    FAQ = "faq"
    ACCOUNT_QUERY = "account_query"
    TRANSACTION_QUERY = "transaction_query"
    COMPLAINT = "complaint"
    FEATURE_REQUEST = "feature_request"
    ESCALATE = "escalate"
    FAREWELL = "farewell"
    UNKNOWN = "unknown"


class HybridChatbot:
    """Intent classification + LLM response generation."""

    def __init__(self, classifier, generator, knowledge_base):
        self.classifier = classifier
        self.generator = generator
        self.kb = knowledge_base
        self.intent_handlers = {
            Intent.GREETING: self._handle_greeting,
            Intent.FAQ: self._handle_faq,
            Intent.ACCOUNT_QUERY: self._handle_account_query,
            Intent.COMPLAINT: self._handle_complaint,
            Intent.ESCALATE: self._handle_escalation,
            Intent.UNKNOWN: self._handle_unknown,
        }

    async def handle_message(self, session: "Session", message: str) -> dict:
        # Step 1: Classify intent
        intent, confidence = await self.classifier.classify(message)

        # Step 2: Extract entities
        entities = await self.classifier.extract_entities(message)

        # Step 3: Update session state
        session.add_turn(message, intent, entities)

        # Step 4: Route to handler
        handler = self.intent_handlers.get(intent, self._handle_unknown)
        response = await handler(session, message, entities)

        # Step 5: Safety check
        response = await self._safety_check(response)

        session.add_response(response["text"])
        return response

    async def _handle_greeting(self, session, message, entities):
        if session.turn_count == 0:
            return {"text": f"Hello! I'm here to help with your account and transactions. What can I do for you?"}
        return {"text": "How else can I help you?"}

    async def _handle_faq(self, session, message, entities):
        # Retrieve from knowledge base
        results = await self.kb.search(message, top_k=3)
        if results:
            context = "\n".join(r["text"] for r in results)
            response = await self.generator.generate(
                system="Answer the user's question based on the provided knowledge base articles. Be concise.",
                context=context,
                query=message,
            )
            return {"text": response, "sources": [r["id"] for r in results]}
        return {"text": "I don't have a specific answer for that. Let me connect you with our support team.",
                "escalate": True}

    async def _handle_account_query(self, session, message, entities):
        if not session.user_authenticated:
            return {
                "text": "I need to verify your identity first. Could you provide your account email?",
                "awaiting": "authentication",
            }
        # Fetch account data and respond
        account = await self._fetch_account(session.user_id)
        response = await self.generator.generate(
            system="You are an account assistant. Answer based on the account data provided.",
            context=str(account),
            query=message,
        )
        return {"text": response}

    async def _handle_complaint(self, session, message, entities):
        return {
            "text": "I'm sorry to hear about your experience. Let me create a support ticket "
                    "and connect you with a team member who can resolve this. "
                    "Could you describe the issue in more detail?",
            "create_ticket": True,
            "priority": "high",
        }

    async def _handle_escalation(self, session, message, entities):
        return {
            "text": "I'll connect you with a human agent right away. "
                    "Please hold on while I transfer your conversation.",
            "escalate": True,
            "transfer_context": session.summary(),
        }

    async def _handle_unknown(self, session, message, entities):
        return {
            "text": "I'm not sure I understand. I can help with account questions, "
                    "transactions, and general inquiries. Could you rephrase your question?",
        }

    async def _safety_check(self, response: dict) -> dict:
        """Filter response for safety before sending."""
        # Implementation depends on safety requirements
        return response
```

---

## 2. Intent Recognition

### LLM-Based Intent Classification

```python
INTENT_CLASSIFIER_PROMPT = """You are an intent classifier for a customer support chatbot.

Classify the user's message into exactly one intent from the list below.
Return ONLY the intent name, nothing else.

## Intents

- greeting: Hello, hi, good morning, etc.
- account_info: Questions about account details, balance, profile
- transaction_query: Questions about specific transactions, payments, invoices
- report_request: Requesting a report or data export
- complaint: Expressing dissatisfaction or reporting a problem
- feature_request: Suggesting a new feature or improvement
- how_to: Asking how to perform a specific action in the system
- billing: Questions about pricing, plans, charges
- escalate: Explicitly requesting to speak to a human
- farewell: Goodbye, thank you, end of conversation
- other: Does not fit any category above

## Rules
- If the message contains multiple intents, choose the primary one
- If unclear, default to "other"
- Greeting + question should be classified as the question intent, not greeting

## Examples
"Hi there" -> greeting
"What's my account balance?" -> account_info
"I was charged twice" -> complaint
"Can you add dark mode?" -> feature_request
"Let me talk to a real person" -> escalate
"How do I create an invoice?" -> how_to

## Message
{message}

Intent:"""


async def classify_intent(client, message: str) -> tuple:
    """Classify user intent. Returns (intent, confidence)."""
    response = await client.complete(
        messages=[{"role": "user", "content": INTENT_CLASSIFIER_PROMPT.format(message=message)}],
        temperature=0.0,
        max_tokens=20,
    )
    intent = response.content.strip().lower().replace(" ", "_")
    # Use logprobs or self-consistency for confidence
    return intent, 0.9  # Simplified; see evaluation section for proper confidence
```

### Entity Extraction

```python
ENTITY_EXTRACTION_PROMPT = """Extract entities from the user's message.
Return a JSON object with the following possible keys (omit keys with no value):

- customer_name: string
- customer_id: string (format: CUST-XXXX)
- invoice_number: string (format: INV-XXXX-YYYY)
- date: string (ISO 8601)
- date_range_start: string
- date_range_end: string
- amount: number
- currency: string (3-letter code)
- product_name: string
- status: string (one of: pending, paid, overdue, cancelled)
- branch: string

## Examples

Message: "Show me invoice INV-DXB-2026-0042 for Acme Corp"
{{"invoice_number": "INV-DXB-2026-0042", "customer_name": "Acme Corp"}}

Message: "What are the unpaid invoices from last month?"
{{"status": "unpaid", "date_range_start": "2026-02-01", "date_range_end": "2026-02-28"}}

Message: "I need the sales report for Dubai branch"
{{"branch": "Dubai"}}

## Message
{message}

JSON:"""


async def extract_entities(client, message: str) -> dict:
    """Extract structured entities from user message."""
    response = await client.complete(
        messages=[{"role": "user", "content": ENTITY_EXTRACTION_PROMPT.format(message=message)}],
        temperature=0.0,
        max_tokens=200,
    )
    try:
        content = response.content.strip()
        if content.startswith("```"):
            content = content.split("\n", 1)[1].rsplit("```", 1)[0]
        return json.loads(content)
    except json.JSONDecodeError:
        return {}
```

---

## 3. Dialogue Management

### Session State Machine

```python
from enum import Enum, auto
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional
from datetime import datetime

class DialogueState(Enum):
    IDLE = auto()
    GREETING = auto()
    GATHERING_INFO = auto()
    CONFIRMING = auto()
    PROCESSING = auto()
    AWAITING_AUTH = auto()
    ESCALATED = auto()
    COMPLETED = auto()

@dataclass
class SlotDefinition:
    name: str
    required: bool = True
    prompt: str = ""
    validator: Optional[callable] = None

@dataclass
class ConversationSession:
    session_id: str
    user_id: Optional[str] = None
    user_authenticated: bool = False
    state: DialogueState = DialogueState.IDLE
    current_intent: Optional[str] = None
    slots: Dict[str, Any] = field(default_factory=dict)
    history: List[Dict] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)
    created_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())
    last_active: str = field(default_factory=lambda: datetime.utcnow().isoformat())

    @property
    def turn_count(self) -> int:
        return sum(1 for h in self.history if h.get("role") == "user")

    def add_turn(self, message: str, intent: str = None, entities: dict = None):
        self.history.append({
            "role": "user",
            "content": message,
            "intent": intent,
            "entities": entities or {},
            "timestamp": datetime.utcnow().isoformat(),
        })
        self.last_active = datetime.utcnow().isoformat()
        if intent:
            self.current_intent = intent
        if entities:
            self.slots.update(entities)

    def add_response(self, text: str):
        self.history.append({
            "role": "assistant",
            "content": text,
            "timestamp": datetime.utcnow().isoformat(),
        })

    def summary(self) -> str:
        """Generate a concise summary of the conversation for handoff."""
        return (
            f"Session: {self.session_id}\n"
            f"User: {self.user_id or 'unauthenticated'}\n"
            f"Intent: {self.current_intent}\n"
            f"Turns: {self.turn_count}\n"
            f"Slots: {self.slots}\n"
            f"State: {self.state.name}\n"
        )

    def get_missing_slots(self, required_slots: List[SlotDefinition]) -> List[SlotDefinition]:
        """Find required slots that have not been filled yet."""
        return [s for s in required_slots if s.required and s.name not in self.slots]
```

### Slot-Filling Dialogue

```python
class SlotFillingDialogue:
    """Manage multi-turn slot filling for structured tasks."""

    # Define required slots per intent
    INTENT_SLOTS = {
        "create_invoice": [
            SlotDefinition("customer_id", required=True,
                           prompt="Which customer is this invoice for?"),
            SlotDefinition("items", required=True,
                           prompt="What items should be on the invoice?"),
            SlotDefinition("due_date", required=True,
                           prompt="When should the invoice be due?"),
            SlotDefinition("notes", required=False,
                           prompt="Any notes to add to the invoice?"),
        ],
        "look_up_invoice": [
            SlotDefinition("invoice_number", required=True,
                           prompt="What is the invoice number?"),
        ],
    }

    async def process(self, session: ConversationSession, message: str) -> str:
        intent = session.current_intent

        if intent not in self.INTENT_SLOTS:
            return "I can help with creating or looking up invoices. What would you like to do?"

        required = self.INTENT_SLOTS[intent]
        missing = session.get_missing_slots(required)

        if not missing:
            # All slots filled -- proceed with action
            session.state = DialogueState.CONFIRMING
            return self._build_confirmation(session, required)

        # Ask for the next missing slot
        next_slot = missing[0]
        session.state = DialogueState.GATHERING_INFO
        return next_slot.prompt

    def _build_confirmation(self, session: ConversationSession, slots: list) -> str:
        """Build a confirmation message with all collected slot values."""
        lines = ["Here is what I have so far:"]
        for slot in slots:
            value = session.slots.get(slot.name, "not provided")
            lines.append(f"- {slot.name.replace('_', ' ').title()}: {value}")
        lines.append("\nShall I proceed? (yes/no)")
        return "\n".join(lines)
```

---

## 4. Context Handling and Memory

### Short-Term Memory (Conversation)

```python
class ConversationMemory:
    """Manage conversation history within a single session."""

    def __init__(self, max_tokens: int = 8000):
        self.max_tokens = max_tokens
        self.messages: List[Dict] = []
        self.summary: Optional[str] = None

    def add(self, role: str, content: str):
        self.messages.append({"role": role, "content": content})
        if self._estimate_tokens() > self.max_tokens:
            self._compress()

    def get_messages(self) -> List[Dict]:
        result = []
        if self.summary:
            result.append({
                "role": "user",
                "content": f"[Previous conversation summary: {self.summary}]",
            })
        result.extend(self.messages)
        return result

    def _estimate_tokens(self) -> int:
        return sum(len(m["content"]) // 4 for m in self.messages)

    async def _compress(self):
        """Summarize older messages to free up token space."""
        if len(self.messages) <= 4:
            return

        # Keep the most recent 4 messages
        older = self.messages[:-4]
        self.messages = self.messages[-4:]

        # Summarize the older messages
        older_text = "\n".join(f"{m['role']}: {m['content']}" for m in older)
        # In production, call the LLM to generate this summary
        if self.summary:
            self.summary = f"{self.summary}\n\nContinued: {older_text[:500]}"
        else:
            self.summary = older_text[:500]
```

### Long-Term Memory (Cross-Session)

```python
from typing import List, Dict, Optional

class UserMemory:
    """Persistent memory that spans across conversation sessions."""

    def __init__(self, storage):
        self.storage = storage  # Database or key-value store

    async def get_user_profile(self, user_id: str) -> dict:
        """Retrieve stored user preferences and interaction history."""
        return await self.storage.get(f"user:{user_id}:profile") or {
            "preferences": {},
            "past_issues": [],
            "interaction_count": 0,
            "last_interaction": None,
        }

    async def save_interaction_summary(self, user_id: str, summary: dict):
        """Save a summary of the conversation for future context."""
        profile = await self.get_user_profile(user_id)
        profile["past_issues"].append({
            "date": datetime.utcnow().isoformat(),
            "intent": summary.get("intent"),
            "resolution": summary.get("resolution"),
            "satisfaction": summary.get("satisfaction"),
        })
        # Keep only the last 20 interactions
        profile["past_issues"] = profile["past_issues"][-20:]
        profile["interaction_count"] += 1
        profile["last_interaction"] = datetime.utcnow().isoformat()

        await self.storage.set(f"user:{user_id}:profile", profile)

    async def get_context_for_prompt(self, user_id: str) -> str:
        """Build a context string from user memory for the system prompt."""
        profile = await self.get_user_profile(user_id)

        if not profile["past_issues"]:
            return "This is a new user with no prior interaction history."

        recent = profile["past_issues"][-3:]
        history_lines = []
        for issue in recent:
            history_lines.append(
                f"- {issue['date'][:10]}: {issue.get('intent', 'unknown')} "
                f"(resolved: {issue.get('resolution', 'unknown')})"
            )

        return (
            f"User has had {profile['interaction_count']} prior interactions.\n"
            f"Recent history:\n" + "\n".join(history_lines)
        )
```

---

## 5. Personality and Tone Design

### Persona Definition Template

```python
PERSONA_TEMPLATE = """
# Persona: {name}

## Identity
- Name: {name}
- Role: {role}
- Company: {company}

## Voice Attributes
- Tone: {tone}
- Formality: {formality} (1=very casual, 5=very formal)
- Verbosity: {verbosity} (1=terse, 5=detailed)
- Empathy: {empathy} (1=matter-of-fact, 5=highly empathetic)

## Communication Rules
{communication_rules}

## Vocabulary
- USE: {preferred_terms}
- AVOID: {avoided_terms}

## Response Length Guidelines
- Simple acknowledgment: 1 sentence
- Factual answer: 1-2 sentences
- How-to guidance: Numbered steps (3-7 steps)
- Complex explanation: 2-3 paragraphs with examples
- Error/problem: Acknowledge + explain + solution (always offer next steps)
"""

# Example persona
SUPPORT_PERSONA = PERSONA_TEMPLATE.format(
    name="Atlas",
    role="ERP Support Assistant",
    company="the company",
    tone="helpful, professional, patient",
    formality="3",
    verbosity="3",
    empathy="4",
    communication_rules="""
- Address the user by name if known
- Acknowledge the user's frustration before solving the problem
- Use active voice ("I will check that" not "That will be checked")
- End each response with a question or offer to help further
- If you cannot help, explain why and suggest who can
- Never blame the user for errors
- Use "we" when referring to company actions, "I" for personal actions
""",
    preferred_terms="invoice, payment, account, dashboard, team member",
    avoided_terms="ticket number (say 'reference number'), error code (say 'issue'), backend (say 'system')",
)
```

### Tone Adaptation by Context

```python
TONE_MODIFIERS = {
    "complaint": """
The user is frustrated. Prioritize empathy:
1. Acknowledge their frustration sincerely
2. Take responsibility (do not deflect)
3. State the concrete action you will take
4. Provide a timeline if possible
""",
    "urgent": """
The user has an urgent need. Be concise and action-oriented:
1. Skip pleasantries
2. Get to the solution immediately
3. Provide step-by-step instructions
4. Offer escalation proactively
""",
    "new_user": """
The user appears unfamiliar with the system. Be extra helpful:
1. Avoid jargon; explain terms when needed
2. Provide context for each step
3. Offer links to documentation or guides
4. Be encouraging
""",
    "returning_issue": """
The user has raised this issue before. Show awareness:
1. Reference their previous interaction
2. Acknowledge the inconvenience of a recurring issue
3. Explain what is different this time
4. Escalate if this is the third occurrence
""",
}
```

---

## 6. Escalation Flows

### Escalation Decision Framework

```python
class EscalationManager:
    """Manage handoff from AI to human agents."""

    ESCALATION_TRIGGERS = {
        # Explicit triggers
        "explicit_request": {
            "patterns": ["talk to a human", "speak to someone", "real person", "agent", "supervisor"],
            "action": "immediate_transfer",
        },
        # Sentiment-based
        "negative_sentiment": {
            "threshold": -0.7,  # sentiment score
            "consecutive_turns": 2,
            "action": "offer_transfer",
        },
        # Loop detection
        "repetition": {
            "max_similar_turns": 3,  # Same question asked 3 times
            "action": "offer_transfer",
        },
        # Confidence-based
        "low_confidence": {
            "threshold": 0.4,
            "action": "offer_transfer",
        },
        # Policy-based
        "sensitive_topic": {
            "topics": ["legal", "discrimination", "refund_over_1000", "account_closure"],
            "action": "immediate_transfer",
        },
        # Time-based
        "long_conversation": {
            "max_turns": 15,
            "action": "offer_transfer",
        },
    }

    async def should_escalate(self, session: ConversationSession) -> dict:
        """Evaluate whether the conversation should be escalated."""

        reasons = []

        # Check explicit request
        last_msg = session.history[-1]["content"].lower() if session.history else ""
        for pattern in self.ESCALATION_TRIGGERS["explicit_request"]["patterns"]:
            if pattern in last_msg:
                reasons.append("User explicitly requested human agent")
                return {"escalate": True, "action": "immediate_transfer", "reasons": reasons}

        # Check conversation length
        if session.turn_count > self.ESCALATION_TRIGGERS["long_conversation"]["max_turns"]:
            reasons.append(f"Conversation exceeded {session.turn_count} turns")

        # Check for repetition (user asking the same thing)
        if self._detect_repetition(session):
            reasons.append("User appears to be repeating the same question")

        if reasons:
            return {"escalate": True, "action": "offer_transfer", "reasons": reasons}

        return {"escalate": False, "reasons": []}

    def _detect_repetition(self, session: ConversationSession) -> bool:
        """Detect if the user is repeating the same question."""
        user_messages = [h["content"] for h in session.history if h.get("role") == "user"]
        if len(user_messages) < 3:
            return False
        recent = user_messages[-3:]
        # Simple check: if last 3 messages are very similar
        from difflib import SequenceMatcher
        for i in range(len(recent) - 1):
            ratio = SequenceMatcher(None, recent[i].lower(), recent[i + 1].lower()).ratio()
            if ratio < 0.6:
                return False
        return True

    def build_handoff_context(self, session: ConversationSession) -> dict:
        """Build context package for the human agent receiving the handoff."""
        return {
            "session_id": session.session_id,
            "user_id": session.user_id,
            "summary": session.summary(),
            "intent": session.current_intent,
            "collected_info": session.slots,
            "turn_count": session.turn_count,
            "full_history": session.history,
            "escalation_reason": "See session metadata",
        }
```

### Escalation Response Templates

```python
ESCALATION_RESPONSES = {
    "offer_transfer": (
        "It seems like I might not be fully addressing your needs. "
        "Would you like me to connect you with a team member who can help further?"
    ),
    "immediate_transfer": (
        "I'm transferring you to a team member now. "
        "I've shared our conversation summary so you won't need to repeat yourself. "
        "Please hold on for just a moment."
    ),
    "after_hours": (
        "Our team is currently offline (available {hours}). "
        "I've created a reference ({ref_id}) for your issue. "
        "A team member will reach out to you as soon as they're available. "
        "Is there anything else I can help with in the meantime?"
    ),
    "queue_position": (
        "I've added you to the queue. You're currently number {position}. "
        "Estimated wait time: {wait_time}. "
        "I'll stay here if you have any other questions while you wait."
    ),
}
```

---

## 7. Error Recovery

### Error Handling Patterns

```python
class ErrorRecoveryHandler:
    """Handle errors gracefully in conversation flow."""

    ERROR_RESPONSES = {
        "parse_error": (
            "I had trouble understanding that. Could you rephrase your request? "
            "For example, you could say '{example}'."
        ),
        "api_error": (
            "I'm having trouble accessing the system right now. "
            "Let me try again in a moment."
        ),
        "auth_error": (
            "I need to verify your identity to access that information. "
            "Could you provide your account email or ID?"
        ),
        "not_found": (
            "I couldn't find {entity} matching '{query}'. "
            "Could you double-check the details? "
            "Common formats are: {format_hint}."
        ),
        "permission_denied": (
            "Your current role doesn't have access to that feature. "
            "You may need to contact your administrator for access."
        ),
        "llm_error": (
            "I ran into an issue processing your request. "
            "Let me try a different approach."
        ),
    }

    async def handle(self, error_type: str, context: dict = None) -> str:
        """Generate an appropriate error recovery response."""
        template = self.ERROR_RESPONSES.get(error_type, self.ERROR_RESPONSES["llm_error"])
        if context:
            return template.format(**context)
        return template

    async def recover_conversation(
        self,
        session: ConversationSession,
        error_type: str,
        retry_count: int = 0,
    ) -> dict:
        """Attempt to recover the conversation after an error."""

        if retry_count >= 3:
            return {
                "response": "I'm unable to complete this request. Let me connect you with a team member.",
                "escalate": True,
            }

        if error_type == "parse_error":
            return {
                "response": await self.handle("parse_error", {
                    "example": self._get_example_for_intent(session.current_intent),
                }),
                "retry": True,
            }

        if error_type == "api_error":
            return {
                "response": await self.handle("api_error"),
                "retry": True,
                "delay_seconds": 2 ** retry_count,
            }

        return {"response": await self.handle(error_type), "retry": False}

    def _get_example_for_intent(self, intent: str) -> str:
        examples = {
            "transaction_query": "Show me invoices from March 2026",
            "account_info": "What is my current account balance?",
            "report_request": "Generate a sales report for last quarter",
        }
        return examples.get(intent, "How can I help you?")
```

### Disambiguation

```python
DISAMBIGUATION_PROMPT = """The user's message is ambiguous. Generate a clarifying question.

User message: "{message}"
Possible interpretations:
{interpretations}

Generate a single, natural clarifying question that helps determine which interpretation is correct.
Do not list the options mechanically. Ask in a conversational way.

Question:"""


async def disambiguate(client, message: str, interpretations: list) -> str:
    """Generate a natural clarifying question for ambiguous input."""
    formatted = "\n".join(f"- {i}" for i in interpretations)
    response = await client.complete(
        messages=[{"role": "user", "content": DISAMBIGUATION_PROMPT.format(
            message=message,
            interpretations=formatted,
        )}],
        temperature=0.3,
        max_tokens=100,
    )
    return response.content.strip()
```

---

## 8. Conversation Analytics

### Metrics to Track

```python
from dataclasses import dataclass
from datetime import datetime
from typing import Dict, List

@dataclass
class ConversationMetrics:
    """Metrics for a single conversation."""
    session_id: str
    start_time: datetime
    end_time: datetime
    turn_count: int
    resolution: str              # resolved, escalated, abandoned
    intents: List[str]           # sequence of intents
    response_latencies_ms: List[float]
    user_satisfaction: Optional[int] = None  # 1-5 rating
    escalated: bool = False
    error_count: int = 0

    @property
    def duration_seconds(self) -> float:
        return (self.end_time - self.start_time).total_seconds()

    @property
    def avg_latency_ms(self) -> float:
        return sum(self.response_latencies_ms) / len(self.response_latencies_ms) if self.response_latencies_ms else 0


class AnalyticsDashboard:
    """Aggregate conversation metrics."""

    def __init__(self):
        self.conversations: List[ConversationMetrics] = []

    def add(self, metrics: ConversationMetrics):
        self.conversations.append(metrics)

    def summary(self, period_start: datetime = None, period_end: datetime = None) -> dict:
        filtered = self.conversations
        if period_start:
            filtered = [c for c in filtered if c.start_time >= period_start]
        if period_end:
            filtered = [c for c in filtered if c.end_time <= period_end]

        if not filtered:
            return {"message": "No conversations in the specified period"}

        total = len(filtered)
        resolved = sum(1 for c in filtered if c.resolution == "resolved")
        escalated = sum(1 for c in filtered if c.escalated)
        abandoned = sum(1 for c in filtered if c.resolution == "abandoned")

        satisfaction_ratings = [c.user_satisfaction for c in filtered if c.user_satisfaction]

        return {
            "total_conversations": total,
            "resolution_rate": resolved / total,
            "escalation_rate": escalated / total,
            "abandonment_rate": abandoned / total,
            "avg_turns": sum(c.turn_count for c in filtered) / total,
            "avg_duration_seconds": sum(c.duration_seconds for c in filtered) / total,
            "avg_latency_ms": sum(c.avg_latency_ms for c in filtered) / total,
            "avg_satisfaction": (sum(satisfaction_ratings) / len(satisfaction_ratings)
                                if satisfaction_ratings else None),
            "top_intents": self._top_intents(filtered),
            "error_rate": sum(c.error_count for c in filtered) / total,
        }

    def _top_intents(self, conversations: list, top_n: int = 10) -> list:
        from collections import Counter
        all_intents = []
        for c in conversations:
            all_intents.extend(c.intents)
        return Counter(all_intents).most_common(top_n)
```

### Key Performance Indicators

```
OPERATIONAL KPIs
-----------------------------------------------------------
Metric                          Target      Alert Threshold
-----------------------------------------------------------
Resolution rate                 > 80%       < 70%
Escalation rate                 < 15%       > 25%
Avg turns to resolution         < 5         > 8
Avg response latency            < 2s        > 5s
User satisfaction (CSAT)        > 4.0/5     < 3.5/5
Abandonment rate                < 10%       > 20%
Error rate (per conversation)   < 5%        > 10%
First-contact resolution rate   > 70%       < 50%
Containment rate                > 85%       < 75%
(% handled without escalation)

QUALITY KPIs
-----------------------------------------------------------
Factual accuracy                > 95%       < 90%
Intent classification accuracy  > 90%       < 80%
Entity extraction accuracy      > 85%       < 75%
Response relevance              > 90%       < 80%
Tone consistency                > 90%       < 80%
```

---

## 9. Multi-Channel Design

### Channel-Specific Formatting

```python
class ChannelFormatter:
    """Format responses for different output channels."""

    def format(self, response: str, channel: str, metadata: dict = None) -> dict:
        formatters = {
            "web": self._format_web,
            "slack": self._format_slack,
            "sms": self._format_sms,
            "email": self._format_email,
            "voice": self._format_voice,
        }
        formatter = formatters.get(channel, self._format_web)
        return formatter(response, metadata or {})

    def _format_web(self, response: str, metadata: dict) -> dict:
        """Full rich text with markdown, links, and interactive elements."""
        return {
            "text": response,
            "format": "markdown",
            "actions": metadata.get("actions", []),
            "attachments": metadata.get("attachments", []),
        }

    def _format_slack(self, response: str, metadata: dict) -> dict:
        """Slack mrkdwn format with blocks."""
        return {
            "text": response,
            "blocks": [
                {"type": "section", "text": {"type": "mrkdwn", "text": response}},
            ],
        }

    def _format_sms(self, response: str, metadata: dict) -> dict:
        """Plain text, max 160 characters per segment."""
        # Strip markdown formatting
        import re
        plain = re.sub(r'[*_`#\[\]]', '', response)
        # Truncate with continuation indicator
        if len(plain) > 160:
            plain = plain[:157] + "..."
        return {"text": plain, "format": "plain"}

    def _format_voice(self, response: str, metadata: dict) -> dict:
        """Optimized for text-to-speech output."""
        import re
        # Remove markdown and URLs
        voice_text = re.sub(r'\[([^\]]+)\]\([^\)]+\)', r'\1', response)
        voice_text = re.sub(r'[*_`#]', '', voice_text)
        # Replace abbreviations for TTS
        voice_text = voice_text.replace("e.g.", "for example")
        voice_text = voice_text.replace("i.e.", "that is")
        # Add SSML pauses for lists
        voice_text = re.sub(r'\n- ', '\n<break time="300ms"/> ', voice_text)
        return {"text": voice_text, "format": "ssml"}

    def _format_email(self, response: str, metadata: dict) -> dict:
        """HTML email format."""
        import re
        html = response
        html = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', html)
        html = re.sub(r'\*(.+?)\*', r'<em>\1</em>', html)
        html = html.replace('\n', '<br>')
        return {
            "subject": metadata.get("subject", "Response from Support"),
            "body_html": f"<div style='font-family: sans-serif;'>{html}</div>",
            "body_text": response,
        }
```

---

## 10. Conversation Testing

### Test Framework

```python
from dataclasses import dataclass
from typing import List, Optional, Callable

@dataclass
class ConversationTestTurn:
    user_message: str
    expected_intent: Optional[str] = None
    expected_entities: Optional[dict] = None
    response_must_contain: Optional[List[str]] = None
    response_must_not_contain: Optional[List[str]] = None
    expect_escalation: bool = False
    expect_tool_call: Optional[str] = None
    custom_assertion: Optional[Callable] = None

@dataclass
class ConversationTestCase:
    name: str
    description: str
    persona_context: dict  # User context (role, branch, etc.)
    turns: List[ConversationTestTurn]
    tags: List[str] = None


# Example test cases
TEST_CASES = [
    ConversationTestCase(
        name="happy_path_invoice_lookup",
        description="User asks about an invoice and gets a correct answer",
        persona_context={"user_id": "USR-001", "branch": "Dubai", "role": "accountant"},
        turns=[
            ConversationTestTurn(
                user_message="Hi, I need to check invoice INV-DXB-2026-0042",
                expected_intent="transaction_query",
                expected_entities={"invoice_number": "INV-DXB-2026-0042"},
                response_must_contain=["INV-DXB-2026-0042"],
            ),
            ConversationTestTurn(
                user_message="What is the payment status?",
                expected_intent="transaction_query",
                response_must_contain=["status", "paid", "unpaid", "pending"],
            ),
        ],
        tags=["invoice", "happy_path"],
    ),

    ConversationTestCase(
        name="escalation_after_frustration",
        description="User gets frustrated and requests human agent",
        persona_context={"user_id": "USR-002", "branch": "Abu Dhabi", "role": "manager"},
        turns=[
            ConversationTestTurn(
                user_message="This is the third time I'm asking about my refund!",
                expected_intent="complaint",
                response_must_contain=["sorry", "understand"],
                response_must_not_contain=["don't know", "cannot"],
            ),
            ConversationTestTurn(
                user_message="Let me talk to someone real",
                expected_intent="escalate",
                expect_escalation=True,
                response_must_contain=["connect", "team member", "transfer"],
            ),
        ],
        tags=["escalation", "complaint"],
    ),

    ConversationTestCase(
        name="cross_branch_isolation",
        description="User tries to access data from another branch",
        persona_context={"user_id": "USR-003", "branch": "Dubai", "role": "accountant"},
        turns=[
            ConversationTestTurn(
                user_message="Show me Abu Dhabi branch's revenue report",
                response_must_contain=["access", "branch"],
                response_must_not_contain=["revenue", "AED", "$"],
            ),
        ],
        tags=["security", "multi_tenant"],
    ),
]


class ConversationTestRunner:
    """Run conversation test cases against a chatbot."""

    def __init__(self, chatbot):
        self.chatbot = chatbot

    async def run_test(self, test: ConversationTestCase) -> dict:
        """Run a single test case and return results."""
        session_id = f"test_{test.name}_{datetime.utcnow().timestamp()}"
        results = []

        for i, turn in enumerate(test.turns):
            response = await self.chatbot.handle_message(
                session_id=session_id,
                user_message=turn.user_message,
                user_context=test.persona_context,
            )

            turn_result = {"turn": i + 1, "passed": True, "failures": []}
            resp_text = response.get("response", "")

            # Check required content
            if turn.response_must_contain:
                for phrase in turn.response_must_contain:
                    if phrase.lower() not in resp_text.lower():
                        turn_result["passed"] = False
                        turn_result["failures"].append(f"Missing required phrase: '{phrase}'")

            # Check forbidden content
            if turn.response_must_not_contain:
                for phrase in turn.response_must_not_contain:
                    if phrase.lower() in resp_text.lower():
                        turn_result["passed"] = False
                        turn_result["failures"].append(f"Contains forbidden phrase: '{phrase}'")

            # Check escalation
            if turn.expect_escalation and not response.get("escalate"):
                turn_result["passed"] = False
                turn_result["failures"].append("Expected escalation but none triggered")

            # Custom assertion
            if turn.custom_assertion:
                try:
                    turn.custom_assertion(response)
                except AssertionError as e:
                    turn_result["passed"] = False
                    turn_result["failures"].append(str(e))

            turn_result["response"] = resp_text[:200]
            results.append(turn_result)

        all_passed = all(r["passed"] for r in results)
        return {
            "test_name": test.name,
            "passed": all_passed,
            "turns": results,
            "tags": test.tags,
        }

    async def run_suite(self, tests: List[ConversationTestCase]) -> dict:
        """Run all test cases and aggregate results."""
        results = []
        for test in tests:
            result = await self.run_test(test)
            results.append(result)

        total = len(results)
        passed = sum(1 for r in results if r["passed"])
        return {
            "total": total,
            "passed": passed,
            "failed": total - passed,
            "pass_rate": passed / total if total else 0,
            "results": results,
            "failed_tests": [r["test_name"] for r in results if not r["passed"]],
        }
```

---

## 11. System Prompt for Conversational AI

### Complete Support Bot System Prompt

```python
SUPPORT_BOT_SYSTEM_PROMPT = """You are Atlas, the AI support assistant for {company_name}.

## Your Role
You help users with account questions, invoice management, report generation,
and general ERP system navigation. You are part of the {branch_name} branch.

## Capabilities
- Answer questions about invoices, payments, and account balances
- Guide users through ERP workflows (create invoice, submit purchase order, etc.)
- Look up transaction history and generate simple reports
- Explain system features and provide how-to guidance

## Boundaries
- You can ONLY access data for branch: {branch_name} (branch_id: {branch_id})
- You CANNOT modify data — you can look up and explain, but changes require the user to act in the system
- You CANNOT provide tax, legal, or financial advice — direct users to the appropriate department
- You CANNOT access other branches' data — explain this if asked

## Tone
- Professional but warm
- Patient and encouraging, especially with new users
- Concise — get to the point, but be thorough when explaining steps
- Empathetic when users are frustrated

## Response Rules
1. If you do not know the answer, say so honestly — never make up data
2. If the question is outside your scope, explain why and suggest who can help
3. If the user is frustrated (3+ turns without resolution), offer to connect them with a team member
4. Always confirm understanding before taking action
5. End responses with a relevant follow-up question or offer to help further
6. Format responses with bullet points or numbered steps for procedures
7. Include relevant reference numbers (invoice numbers, order IDs) when available

## Data Formatting
- Currency: {currency_format}
- Dates: {date_format}
- Numbers: Use thousands separators (e.g., 1,234.56)

## Current Context
- Date: {current_date}
- User: {user_name} ({user_role})
- Branch: {branch_name}
- Financial year: {fy_start} to {fy_end}
"""
```

---

## 12. Design Checklist

```
ARCHITECTURE
- [ ] Conversation architecture pattern chosen (LLM-native vs. hybrid)
- [ ] Session management implemented (create, resume, timeout, cleanup)
- [ ] Multi-channel support designed (web, mobile, email, voice)
- [ ] Integration points identified (CRM, ERP, knowledge base, ticketing)

DIALOGUE DESIGN
- [ ] Core intents defined and tested
- [ ] Entity extraction schema defined
- [ ] Slot-filling flows designed for structured tasks
- [ ] Error recovery patterns implemented
- [ ] Disambiguation strategy defined
- [ ] Escalation triggers and flows designed

PERSONA
- [ ] Persona name, role, and voice attributes defined
- [ ] Tone guidelines documented with examples
- [ ] Response length guidelines by context type
- [ ] Vocabulary and terminology guidelines set

SAFETY AND COMPLIANCE
- [ ] Input sanitization active (prompt injection defense)
- [ ] Output filtering active (PII, secrets, harmful content)
- [ ] Multi-tenant data isolation enforced in all prompts
- [ ] Audit trail for all conversations
- [ ] Data retention policy defined and enforced
- [ ] GDPR/privacy compliance verified

TESTING
- [ ] Happy path test cases for each intent
- [ ] Edge case test cases (ambiguity, out-of-scope, multi-intent)
- [ ] Escalation test cases
- [ ] Security test cases (data isolation, prompt injection)
- [ ] Load test for concurrent conversations
- [ ] Regression test suite for prompt changes

MONITORING
- [ ] Resolution rate tracked
- [ ] Escalation rate tracked
- [ ] Response latency tracked
- [ ] User satisfaction (CSAT) collected
- [ ] Error rate monitored
- [ ] Intent classification accuracy monitored
- [ ] Conversation length distribution tracked
```
