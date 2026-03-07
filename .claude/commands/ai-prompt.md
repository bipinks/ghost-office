---
name: ai-prompt
description: Design prompts, evaluate AI features, integrate LLMs, or test conversational flows
argument-hint: "[task: design|evaluate|integrate|test] description of what you need"
---

## AI Prompt Engineering

Plan and execute AI prompt engineering tasks using the prompt engineer. Request: $ARGUMENTS

### Agents Involved
- **prompt-engineer** — Prompt design, LLM integration, evaluation, conversational flow testing
- **backend-engineer** — API integration and backend implementation for AI features
- **qa-agent** — Test coverage for AI-powered features and edge cases

### Steps

1. **Understand the Request**
   - Parse the prompt engineering task type (design, evaluate, integrate, test)
   - Identify the target LLM or AI service (Claude, GPT, open-source models)
   - Determine the use case (content generation, classification, extraction, conversation, agents)

2. **Prompt Design** (if design task)
   - Define the task objective and expected output format
   - Draft system prompts with clear role, context, and constraints
   - Structure few-shot examples for consistent output quality
   - Apply prompt engineering techniques (chain-of-thought, step-by-step, XML tags)
   - Define input/output schemas and edge case handling
   - Create prompt templates with variable substitution for reuse

3. **Evaluation** (if evaluate task)
   - Define evaluation criteria (accuracy, relevance, safety, consistency, latency)
   - Create a test dataset with expected outputs (golden set)
   - Run prompts against test cases and score results
   - Compare prompt variations to identify the best performer
   - Measure token usage and cost per request
   - Document evaluation results with pass/fail thresholds

4. **LLM Integration** (if integrate task)
   - Design the API integration architecture (direct API, SDK, proxy)
   - Define request/response schemas and error handling
   - Implement retry logic, rate limiting, and fallback strategies
   - Set up prompt versioning and A/B testing infrastructure
   - Configure token budgets, temperature, and model parameters
   - Document the integration pattern for the development team

5. **Conversational Flow Testing** (if test task)
   - Map the conversation tree with expected paths
   - Define test scenarios for happy path, edge cases, and adversarial inputs
   - Test multi-turn context retention and coherence
   - Validate safety guardrails and content filtering
   - Check graceful degradation when the model is uncertain
   - Generate a test report with pass rates and failure analysis

6. **Deliver Results**
   - Document all prompts with version history and rationale
   - Include performance benchmarks and evaluation scores
   - Provide implementation guidelines and best practices
   - Save prompt libraries and test suites to the project

### Output
AI prompt engineering deliverables matching the requested task type, including documented prompt templates, evaluation reports, integration architectures, or conversational flow test results.
