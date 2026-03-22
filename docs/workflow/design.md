# Design Workflow

## Steps

1. capabilities
2. domain
3. rbac
4. workflow
5. integration
6. metrics
7. ia
8. flows
9. stitch
10. ux
11. design-system
12. spec

## Step Descriptions

- **capabilities**: Define system capabilities and map them to features
- **domain**: Define domain model, entities, and relationships
- **rbac**: Define roles, permissions, and access control rules
- **workflow**: Map core business workflows and state machines
- **integration**: Identify external integrations and API contracts
- **metrics**: Define success metrics, analytics events, and KPIs
- **ia**: Build information architecture — sitemap, navigation, screen ownership
- **flows**: Map user flows and interaction paths per role
- **stitch**: Generate high-fidelity UI screens via Google Stitch MCP (all states: default, empty, error)
- **ux**: Define UX patterns, component behaviour, and interaction rules derived from Stitch output
- **design-system**: Extract design tokens, components, and style guide from Stitch screens
- **spec**: Generate handoff spec for development

## Outputs per Step

| Step | Output File |
|------|-------------|
| capabilities | `docs/analysis/capabilities.md` |
| domain | `docs/domain/model.md` |
| rbac | `docs/domain/rbac.md` |
| workflow | `docs/domain/workflows.md` |
| integration | `docs/domain/integrations.md` |
| metrics | `docs/analysis/metrics.md` |
| ia | `docs/design/ia.md` |
| flows | `docs/design/flows.md` |
| stitch | `docs/design/screens/*.html`, `docs/design/screens/index.md` |
| ux | `docs/design/ux.md` |
| design-system | `docs/design/design-system.md` |
| spec | `docs/spec/design-spec.md` |
