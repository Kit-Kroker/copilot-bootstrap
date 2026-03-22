---
name: review-spec
description: Review the generated spec for consistency — checks that resource names, permissions, events, and state machines all align across the four spec files.
agent: Spec
tools: ['read', 'search/codebase']
---

Read all four spec files:
- `docs/spec/api.md`
- `docs/spec/events.md`
- `docs/spec/permissions.md`
- `docs/spec/state-machines.md`

Also read `docs/domain/model.md` and `docs/domain/rbac.md` for reference.

Check for these issues:

1. **Resource naming** — are resource names identical across api.md, permissions.md, and events.md?
2. **Permission coverage** — does every API endpoint have a matching permission in permissions.md?
3. **Event coverage** — does every state transition in state-machines.md have a corresponding domain event in events.md?
4. **Role consistency** — are the same role names used in api.md and permissions.md as in rbac.md?
5. **State machine completeness** — does every stateful entity from model.md have a state machine defined?

Report findings as:

```
Spec Review
───────────
✅ Resource naming: consistent
❌ Permission coverage: GET /api/v1/tickets missing ticket:read permission
❌ Event coverage: Ticket state "closed" has no TicketClosed event
✅ Role consistency: consistent
⚠️  State machines: Invoice entity has no state machine defined

Issues found: 3
```

List each issue with the file and line reference where possible.
