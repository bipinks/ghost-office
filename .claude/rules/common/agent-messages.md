# Agent Messages — Dashboard Communication

## When Notified by Hook

When you see a `===== DASHBOARD MESSAGE =====` notice from the message-check hook:

1. **Read** your message file at `.claude/status/messages/{your-agent-name}.json`
2. **Process** each message where `status` is `"delivered"`:
   - `instruction` → follow the directive, adjust your current work
   - `question` → write your answer in the `response` field
   - `priority` → reprioritize your tasks accordingly
   - `note` → acknowledge and continue
   - `pause` → stop current work, wait for resume
   - `cancel` → stop current task, report status
3. **Update** each processed message:
   - Set `status` to `"acknowledged"`
   - Set `acknowledged_at` to current UTC timestamp (`date -u +"%Y-%m-%dT%H:%M:%SZ"`)
   - Write your response in the `response` field
4. **Write** the updated JSON back to the same file

## Message File Format

```json
{
  "agent": "your-agent-name",
  "messages": [
    {
      "id": "msg_...",
      "type": "instruction",
      "from": "user",
      "content": "...",
      "priority": "normal",
      "status": "delivered",
      "created_at": "...",
      "delivered_at": "...",
      "acknowledged_at": null,
      "response": null
    }
  ]
}
```

## Rules

- Always acknowledge messages promptly — the dashboard user is waiting for a response
- Never ignore messages; even if you cannot act on one, acknowledge it with an explanation
- Keep responses concise but informative
