# Reports: Agent Reports

Agent Reports in Chatwoot provide detailed metrics and analytics on individual agent performance. These reports help team leaders and administrators evaluate workload distribution, response efficiency, and quality metrics across the support team.

## Overview

Agent Reports focus on:
- Individual agent workload and productivity
- Response and resolution times per agent
- Conversation handling efficiency
- CSAT scores received by agents
- Agent availability and online hours

## UI Access

Access Agent Reports via:
- `/app/accounts/{account_id}/reports/agent`
- Select "Agent Reports" tab in main Reports page

## Key UI Components

- **Main Component**: `app/javascript/dashboard/routes/dashboard/reports/AgentReport.vue`
  - Contains filters, agent performance metrics, and comparison charts

- **Filters**:
  - Date range selector
  - Inbox filter (specific channels)
  - Agent selector (specific agents or all)
  - Team filter
  - Metric type selector (conversations, response time, etc.)

- **Data Visualizations**:
  - Bar charts: Comparative performance across agents
  - Line charts: Agent metrics over time
  - Tables: Detailed performance data by agent

## Key Metrics Displayed

### Workload Metrics
1. **Conversations Assigned**: Number of conversations assigne