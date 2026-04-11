# Bootstrap Workflow (Greenfield)

This is the default workflow for greenfield projects (building from scratch). When `approach = brownfield`, the workflow switches to `docs/workflow/brownfield.md` instead.

## Steps

1. idea
2. project_info
3. users
4. features
5. tech
6. complexity
7. prd
8. capabilities
9. domain
10. design_workflow
11. skills
12. scripts
13. done

### Generation (`/generate`)

After `/spec` completes, run `/generate` to produce Copilot configuration:

14. generate_instructions
15. generate_dev_skills
16. generate_dev_prompts
17. generate_hooks
18. generate_project_agent

## ADLC Extended Steps

When `project.json → adlc = true` (type is `agent` or `ai-system`), the following steps activate after `done`:

14. constraints
15. kpis
16. human_agent_map
17. agent_pattern
18. cost_model
19. eval_framework
20. pov
21. monitoring
22. governance
23. adlc_done

## Step Descriptions

- **idea**: Capture the initial project idea and pain points from the user
- **project_info**: Collect project name, type, and domain
- **users**: Define user roles and target audience
- **features**: List core features and functionality
- **tech**: Select backend and frontend technologies
- **complexity**: Determine project complexity and autonomy level (for agent/ai-system)
- **prd**: Generate Product Requirements Document
- **capabilities**: Define system capabilities
- **domain**: Define domain model
- **design_workflow**: Generate design workflow
- **skills**: Define required skills and agents
- **scripts**: Generate automation scripts
- **done**: Bootstrap complete (standard workflow ends here)

### ADLC Step Descriptions

- **constraints**: Collect regulatory, error tolerance, and autonomy boundary constraints
- **kpis**: Define business and technical KPIs with measurable thresholds
- **human_agent_map**: Generate human vs agent responsibility matrix
- **agent_pattern**: Define agent architecture pattern, tool inventory, and memory design
- **cost_model**: Estimate token economics, monthly costs, and infrastructure spend
- **eval_framework**: Define evaluation framework, golden dataset spec, and regression strategy
- **pov**: Create Proof of Value plan with go/no-go criteria
- **monitoring**: Define observability dashboards, alert thresholds, and rollback criteria
- **governance**: Define model versioning, feedback loops, drift monitoring, and audit policy
- **adlc_done**: Full ADLC lifecycle complete
