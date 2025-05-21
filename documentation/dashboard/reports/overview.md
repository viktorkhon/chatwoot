# Dashboard: Reports Overview

The Reports section in the Chatwoot dashboard provides analytics and insights into various aspects of customer support operations. These reports help administrators and team leads monitor performance, identify trends, and make data-driven decisions.

## Overview

Chatwoot offers a range of reports covering conversations, agent performance, inbox activity, label usage, team performance, and customer satisfaction (CSAT). Data can often be filtered by time period, inbox, agent, or team.

## Access and Main Layout

-   **Main Route**: `/app/accounts/{account_id}/reports`
-   **Layout Component**: `app/javascript/dashboard/routes/dashboard/reports/Index.vue` (or `ReportsLayout.vue`). This component typically provides a sub-navigation or tabs to switch between different report types.
-   **Key UI Elements**:
    -   **Report Navigation**: Tabs or a sidebar to select the type of report (Agent, Conversation, CSAT, Inbox, Label, Team, Live).
    -   **Filters**: Common filters include:
        -   Date Range Picker: To select the period for the report.
        -   Inbox Selector: To filter by specific inboxes.
        -   Agent Selector: For agent-specific reports.
        -   Team Selector: For team-specific reports.
        -   Label Selector: For label reports.
    -   **Data Visualization**: Charts (bar, line, pie), tables, and key metric summaries are used to present the data. Libraries like Chart.js (via `vue-chartjs`) are often used.
    -   **Data Export**: Option to download report data (e.g., as CSV).

## Available Report Types (and Key Metrics)

1.  **Agent Reports** (`/reports/agent`):
    -   Focus: Performance of individual agents.
    -   Metrics: Conversations handled, First Response Time (FRT), Average Resolution Time (ART), Resolution Count, CSAT score per agent.
    -   Component: `app/javascript/dashboard/routes/dashboard/reports/AgentReport.vue`.

2.  **Conversation Reports** (`/reports/conversation`):
    -   Focus: Overall conversation trends and volume.
    -   Metrics: Total conversations, Incoming conversations, Resolved conversations, Open conversations, Conversations per status, Busiest times.
    -   Component: `app/javascript/dashboard/routes/dashboard/reports/ConversationReport.vue`.

3.  **CSAT Reports (Customer Satisfaction)** (`/reports/csat`):
    -   Focus: Customer satisfaction levels.
    -   Metrics: Overall CSAT score, CSAT response rate, CSAT scores distribution (e.g., satisfied, dissatisfied), CSAT scores over time, feedback comments.
    -   Component: `app/javascript/dashboard/routes/dashboard/reports/CsatReport.vue`.

4.  **Inbox Reports** (`/reports/inbox`):
    -   Focus: Performance of individual inboxes/channels.
    -   Metrics: Conversations per inbox, FRT per inbox, ART per inbox, Resolution count per inbox.
    -   Component: `app/javascript/dashboard/routes/dashboard/reports/InboxReport.vue`.

5.  **Label Reports** (`/reports/label`):
    -   Focus: Usage and trends of conversation labels.
    -   Metrics: Conversations per label, trends of label usage over time.
    -   Component: `app/javascript/dashboard/routes/dashboard/reports/LabelReport.vue`.

6.  **Team Reports** (`/reports/team`):
    -   Focus: Performance of agent teams.
    -   Metrics: Conversations handled per team, FRT per team, ART per team, Resolution count per team.
    -   Component: `app/javascript/dashboard/routes/dashboard/reports/TeamReport.vue`.

7.  **Live Reports / Overview** (`/reports/live` or `/reports/overview`):
    -   Focus: Real-time or near real-time snapshot of current activity.
    -   Metrics: Active conversations, Agents online, Conversations waiting, Queue size.
    -   Component: `app/javascript/dashboard/routes/dashboard/reports/LiveReport.vue`.

## General Frontend Structure for Reports

-   **Vue Components**: Located in `app/javascript/dashboard/routes/dashboard/reports/`. Each report type has its own main Vue component.
    -   Shared components for filters (`DateRangePicker.vue`), charts (`WootHorizontalBar.vue`), and tables are used.
-   **Vuex Store Modules**:
    -   A general `reports` module (`app/javascript/dashboard/store/modules/reports.js`) might handle common state like filters and loading flags.
    -   Or, each report type might have its own Vuex module if its data fetching and state are sufficiently complex.
-   **API Communication**:
    -   API client: `app/javascript/dashboard/api/reports.js`.
    -   This client has methods for fetching data for each report type (e.g., `ReportsAPI.getAgentReports()`, `ReportsAPI.getConversationReports()`).
    -   Endpoints typically accept parameters like `since` (start date), `until` (end date), `type` (daily, monthly, yearly grouping), `user_id`, `inbox_id`, `team_id`, `labels[]`, `status`, `group_by`.

## Backend Structure for Reports

-   **Controllers**: `app/controllers/api/v1/accounts/reports_controller.rb`.
    -   This controller has actions for each report type: `agent`, `conversation`, `csat`, `inbox`, `label`, `team`, `summary` (for live/overview).
    -   These actions receive filter parameters, query the database (often using complex ActiveRecord queries and grouping), and format the data for the frontend.
-   **Data Aggregation**:
    -   The backend performs data aggregation (sum, average, count) based on the requested filters and grouping.
    -   Metrics like FRT and ART are calculated based on timestamps in `Message` and `Conversation` records.
    -   CSAT scores are pulled from `CsatSurveyResponse` records.
-   **Models Involved**: `Conversation`, `Message`, `User`, `Inbox`, `Team`, `Label`, `CsatSurveyResponse`, `Account`.
-   **Services**: Potentially, service objects under `app/services/reports/` could encapsulate the logic for generating specific reports if the controller actions become too complex. (e.g. `Reports::AgentSummaryBuilder`).
-   **Presenters**: `app/presenters/reports/` contains presenter classes (e.g., `AgentReportPresenter`, `ConversationReportPresenter`) that are responsible for building the data structure required by the frontend from the raw query results. They often handle time conversions and metric calculations.

Reports are crucial for understanding support efficiency, agent workload, customer satisfaction, and identifying areas for improvement. Chatwoot provides a good range of built-in reports to cover these needs.