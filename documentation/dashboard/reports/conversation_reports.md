# Reports: Conversation Reports

Conversation Reports in Chatwoot provide analytics focused on conversation volumes, resolutions, response times, and other conversation-centric metrics. These reports help businesses understand their support workload, efficiency, and trends over time.

## Overview

Conversation Reports aggregate data about:
- Conversation creation and resolution rates
- Response and resolution times
- Status distribution (open, resolved, pending)
- Conversation volume patterns
- Busiest times and trends

## UI Access

Access Conversation Reports via:
- `/app/accounts/{account_id}/reports/conversation`
- Select "Conversation Reports" tab in main Reports page

## Key UI Components

- **Main Component**: `app/javascript/dashboard/routes/dashboard/reports/ConversationReport.vue`
  - Contains filters, charts, and tabular data for conversation metrics

- **Filters**:
  - Date range selector
  - Inbox filter (specific channels)
  - Team filter
  - Group by option (day, week, month)

- **Data Visualizations**:
  - Trend line chart: Conversation volume over time
  - Status distribution chart: Open, resolved, pending
  - Busiest times chart: Heat map or bar chart of activity hours/days

## Key Metrics Displayed

### Volume Metrics
1. **Total Conversations**: Total count in selected period
2. **New Conversations**: Count of newly created conversations
3. **Resolved Conversations**: Count of resolved conversations
4. **Resolution Rate**: Percentage of created conversations that were resolved
5. **Unresolved Count**: Conversations remaining unresolved

### Time-based Metrics
1. **Average First Response Time**: Average time to first agent response
2. **Average Resolution Time**: Average time from creation to resolution
3. **Median Resolution Time**: Median time from creation to resolution

### Distribution Metrics
1. **Status Breakdown**: Number and percentage of open, resolved, pending conversations
2. **Hourly/Daily Distribution**: Conversation volume by hour/day of week

## Backend Implementation

### Controller

`app/controllers/api/v1/accounts/reports_controller.rb#conversation`:
- Processes request parameters
- Queries conversation data with appropriate filters
- Calculates metrics
- Formats response for frontend rendering

### Key Queries and Calculations

1. **Conversation Volume**:
   ```ruby
   # Simplified example - actual implementation more complex
   conversations = account.conversations
                          .where(created_at: start_time..end_time)
                          .where(inbox_id: inbox_ids)
                          .where(team_id: team_ids)
   ```

2. **First Response Time**:
   ```ruby
   # Simplified example
   conversations.map { |c| c.first_response_time }.average
   ```

3. **Resolution Time**:
   ```ruby
   # Simplified example
   conversations.resolved.map { |c| c.resolution_time }.average
   ```

4. **Status Distribution**:
   ```ruby
   # Simplified example
   {
     open: conversations.open.count,
     resolved: conversations.resolved.count,
     pending: conversations.pending.count
   }
   ```

5. **Time Series Data**:
   ```ruby
   # Group by day example (simplified)
   conversations.group_by_day(:created_at).count
   ```

### Data Presenters

The controller may use dedicated presenter classes to format the response:
- `app/presenters/reports/conversation_report_presenter.rb`
- Methods might include:
  - `volume_metrics`
  - `time_metrics`
  - `status_distribution`
  - `time_series_data`

## Frontend Implementation

### Vuex Store

Conversation report data may be managed in a dedicated Vuex module or within a general reports module:
- `app/javascript/dashboard/store/modules/reports.js`
- Actions like `getConversationReports(params)`
- State for storing report data

### API Calls

API client methods for fetching report data:
- `app/javascript/dashboard/api/reports.js`
- `getConversationMetrics(params)` with filters like date range, inboxes, etc.

### Charts and Visualizations

- **Line Charts**: For time series data (conversations over time)
  - `app/javascript/dashboard/components/widgets/chart/WootLineChart.vue`

- **Bar Charts**: For comparative data (status counts, hourly distribution)
  - `app/javascript/dashboard/components/widgets/chart/WootBarChart.vue`

- **Donut Charts**: For distribution data (status percentages)
  - `app/javascript/dashboard/components/widgets/chart/WootDonutChart.vue`

## Data Export

Conversation reports typically support export functionality:
- **CSV Export**: Button to download tabular data
- **API Access**: Direct API access to raw metrics for integration

## Example API Response

```json
{
  "metrics": {
    "total": 245,
    "new": 150,
    "resolved": 120,
    "resolution_rate": 0.8,
    "avg_first_response_time": 1800, // in seconds
    "avg_resolution_time": 86400, // in seconds
    "status_distribution": {
      "open": 95,
      "resolved": 120,
      "pending": 30
    }
  },
  "trend": {
    "2023-10-01": { "created": 15, "resolved": 10 },
    "2023-10-02": { "created": 18, "resolved": 16 },
    // Additional days...
  },
  "busiest_hours": {
    "0": 5, "1": 2, // ... hours 0-23 with counts
  },
  "busiest_days": {
    "monday": 42, "tuesday": 35, // ... days with counts
  }
}
```

Conversation reports are essential for understanding support volume, efficiency in handling conversations, and identifying patterns that can inform staffing and process improvements.