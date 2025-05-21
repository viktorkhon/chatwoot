# API Structure and Endpoints

Chatwoot provides a comprehensive set of RESTful APIs that allow developers to integrate with and extend the platform. The API is versioned to ensure compatibility as the platform evolves.

## API Versions

Chatwoot offers multiple API versions:

1. **API v1**: Primary API for most operations
2. **API v2**: Newer endpoints, particularly for reporting
3. **Platform API**: For platform-level operations (managing accounts, users, etc.)
4. **Public API**: Endpoints exposed to end users/contacts

## API Base URLs

- **Account-scoped APIs**: `/api/v1/accounts/{account_id}/...`
- **Platform APIs**: `/platform/api/v1/...`
- **Public APIs**: `/public/api/v1/...`
- **Enterprise APIs** (if enabled): `/enterprise/api/v1/...`

## Authentication

All API requests (except public endpoints) require authentication:

1. **Bearer Token Authentication**: 
   - Include token in `Authorization: Bearer <token>` header
   - Tokens are obtained through the authentication process

2. **User Context**:
   - APIs operate in the context of the authenticated user
   - Access control is enforced based on user permissions

## Core API Resources (v1)

### Conversations
- **Endpoints**: 
  - `GET /api/v1/accounts/{account_id}/conversations` - List conversations
  - `GET /api/v1/accounts/{account_id}/conversations/{id}` - Get single conversation
  - `POST /api/v1/accounts/{account_id}/conversations/filter` - Filter conversations
  - `PATCH /api/v1/accounts/{account_id}/conversations/{id}` - Update conversation
  - `POST /api/v1/accounts/{account_id}/conversations/{id}/toggle_status` - Toggle status
  - `POST /api/v1/accounts/{account_id}/conversations/{id}/toggle_priority` - Toggle priority

- **Implementation**:
  - Controller: `app/controllers/api/v1/accounts/conversations_controller.rb`
  - Policy: `app/policies/conversation_policy.rb`

### Messages
- **Endpoints**:
  - `GET /api/v1/accounts/{account_id}/conversations/{conversation_id}/messages` - List messages
  - `POST /api/v1/accounts/{account_id}/conversations/{conversation_id}/messages` - Create message
  - `PATCH /api/v1/accounts/{account_id}/conversations/{conversation_id}/messages/{id}` - Update message
  - `DELETE /api/v1/accounts/{account_id}/conversations/{conversation_id}/messages/{id}` - Delete message

- **Implementation**:
  - Controller: `app/controllers/api/v1/accounts/messages_controller.rb`
  - Policy: `app/policies/message_policy.rb`

### Contacts
- **Endpoints**:
  - `GET /api/v1/accounts/{account_id}/contacts` - List contacts
  - `GET /api/v1/accounts/{account_id}/contacts/{id}` - Get single contact
  - `POST /api/v1/accounts/{account_id}/contacts` - Create contact
  - `PATCH /api/v1/accounts/{account_id}/contacts/{id}` - Update contact
  - `DELETE /api/v1/accounts/{account_id}/contacts/{id}` - Delete contact
  - `GET /api/v1/accounts/{account_id}/contacts/{id}/conversations` - Get contact conversations
  - `POST /api/v1/accounts/{account_id}/contacts/search` - Search contacts
  - `POST /api/v1/accounts/{account_id}/contacts/filter` - Filter contacts

- **Implementation**:
  - Controller: `app/controllers/api/v1/accounts/contacts_controller.rb`
  - Policy: `app/policies/contact_policy.rb`

### Inboxes
- **Endpoints**:
  - `GET /api/v1/accounts/{account_id}/inboxes` - List inboxes
  - `GET /api/v1/accounts/{account_id}/inboxes/{id}` - Get single inbox
  - `POST /api/v1/accounts/{account_id}/inboxes` - Create inbox
  - `PATCH /api/v1/accounts/{account_id}/inboxes/{id}` - Update inbox
  - `DELETE /api/v1/accounts/{account_id}/inboxes/{id}` - Delete inbox
  - `GET /api/v1/accounts/{account_id}/inboxes/{id}/assignable_agents` - Get assignable agents
  - `GET /api/v1/accounts/{account_id}/inboxes/{id}/campaigns` - Get campaigns
  - `GET /api/v1/accounts/{account_id}/inboxes/{id}/agent_bot` - Get agent bot
  - `POST /api/v1/accounts/{account_id}/inboxes/{id}/set_agent_bot` - Set agent bot

- **Implementation**:
  - Controller: `app/controllers/api/v1/accounts/inboxes_controller.rb`
  - Policy: `app/policies/inbox_policy.rb`

### Agents
- **Endpoints**:
  - `GET /api/v1/accounts/{account_id}/agents` - List agents
  - `POST /api/v1/accounts/{account_id}/agents` - Create agent
  - `PATCH /api/v1/accounts/{account_id}/agents/{id}` - Update agent
  - `DELETE /api/v1/accounts/{account_id}/agents/{id}` - Delete agent

- **Implementation**:
  - Controller: `app/controllers/api/v1/accounts/agents_controller.rb`
  - Policy: `app/policies/agent_policy.rb`

### Teams
- **Endpoints**:
  - `GET /api/v1/accounts/{account_id}/teams` - List teams
  - `POST /api/v1/accounts/{account_id}/teams` - Create team
  - `PATCH /api/v1/accounts/{account_id}/teams/{id}` - Update team
  - `DELETE /api/v1/accounts/{account_id}/teams/{id}` - Delete team
  - `GET /api/v1/accounts/{account_id}/teams/{team_id}/team_members` - Get team members
  - `POST /api/v1/accounts/{account_id}/teams/{team_id}/team_members` - Add team member
  - `PATCH /api/v1/accounts/{account_id}/teams/{team_id}/team_members` - Update team member
  - `DELETE /api/v1/accounts/{account_id}/teams/{team_id}/team_members` - Remove team member

- **Implementation**:
  - Controller: `app/controllers/api/v1/accounts/teams_controller.rb`
  - Policy: `app/policies/team_policy.rb`

### Automation Rules
- **Endpoints**:
  - `GET /api/v1/accounts/{account_id}/automation_rules` - List rules
  - `GET /api/v1/accounts/{account_id}/automation_rules/{id}` - Get single rule
  - `POST /api/v1/accounts/{account_id}/automation_rules` - Create rule
  - `PATCH /api/v1/accounts/{account_id}/automation_rules/{id}` - Update rule
  - `DELETE /api/v1/accounts/{account_id}/automation_rules/{id}` - Delete rule

- **Implementation**:
  - Controller: `app/controllers/api/v1/accounts/automation_rules_controller.rb`
  - Policy: `app/policies/automation_rule_policy.rb`

## API v2 (Reporting)

API v2 primarily focuses on advanced reporting features:

- **Summary Reports**:
  - `GET /api/v2/accounts/{account_id}/summary_reports/agent` - Agent summary
  - `GET /api/v2/accounts/{account_id}/summary_reports/team` - Team summary
  - `GET /api/v2/accounts/{account_id}/summary_reports/inbox` - Inbox summary

- **Detailed Reports**:
  - `GET /api/v2/accounts/{account_id}/reports/summary` - Summary report
  - `GET /api/v2/accounts/{account_id}/reports/agents` - Agent reports
  - `GET /api/v2/accounts/{account_id}/reports/inboxes` - Inbox reports
  - `GET /api/v2/accounts/{account_id}/reports/labels` - Label reports
  - `GET /api/v2/accounts/{account_id}/reports/teams` - Team reports
  - `GET /api/v2/accounts/{account_id}/reports/conversations` - Conversation reports

- **Implementation**:
  - Controllers in `app/controllers/api/v2/accounts/`
  - Service classes in `app/builders/v2/reports/`

## Platform API

The Platform API is designed for system-level operations:

- **Users**:
  - `POST /platform/api/v1/users` - Create user
  - `GET /platform/api/v1/users/{id}` - Get user
  - `PATCH /platform/api/v1/users/{id}` - Update user
  - `DELETE /platform/api/v1/users/{id}` - Delete user
  - `GET /platform/api/v1/users/{id}/login` - Generate login link

- **Accounts**:
  - `POST /platform/api/v1/accounts` - Create account
  - `GET /platform/api/v1/accounts/{id}` - Get account
  - `PATCH /platform/api/v1/accounts/{id}` - Update account
  - `DELETE /platform/api/v1/accounts/{id}` - Delete account

- **Account Users**:
  - `GET /platform/api/v1/accounts/{account_id}/account_users` - List account users
  - `POST /platform/api/v1/accounts/{account_id}/account_users` - Create account user
  - `DELETE /platform/api/v1/accounts/{account_id}/account_users` - Delete account user

- **Implementation**:
  - Controllers in `app/controllers/platform/api/v1/`

## Public API

The Public API is for end-users (contacts) to interact with Chatwoot:

- **Conversations**:
  - `GET /public/api/v1/inboxes/{inbox_identifier}/contacts/{contact_identifier}/conversations` - List conversations
  - `POST /public/api/v1/inboxes/{inbox_identifier}/contacts/{contact_identifier}/conversations` - Create conversation
  - `GET /public/api/v1/inboxes/{inbox_identifier}/contacts/{contact_identifier}/conversations/{id}` - Get conversation
  - `POST /public/api/v1/inboxes/{inbox_identifier}/contacts/{contact_identifier}/conversations/{id}/toggle_status` - Toggle status
  - `POST /public/api/v1/inboxes/{inbox_identifier}/contacts/{contact_identifier}/conversations/{id}/toggle_typing` - Toggle typing
  - `POST /public/api/v1/inboxes/{inbox_identifier}/contacts/{contact_identifier}/conversations/{id}/update_last_seen` - Update last seen

- **Messages**:
  - `GET /public/api/v1/inboxes/{inbox_identifier}/contacts/{contact_identifier}/conversations/{conversation_id}/messages` - List messages
  - `POST /public/api/v1/inboxes/{inbox_identifier}/contacts/{contact_identifier}/conversations/{conversation_id}/messages` - Create message
  - `PATCH /public/api/v1/inboxes/{inbox_identifier}/contacts/{contact_identifier}/conversations/{conversation_id}/messages/{id}` - Update message

- **Implementation**:
  - Controllers in `app/controllers/public/api/v1/`

## API Client Implementation

For frontend applications, Chatwoot provides a JavaScript API client:

```javascript
// File: app/javascript/dashboard/api/ApiClient.js
class ApiClient {
  constructor(resource, options = {}) {
    this.apiVersion = `/api/${options.apiVersion || DEFAULT_API_VERSION}`;
    this.options = options;
    this.resource = resource;
  }

  get url() {
    return `${this.baseUrl()}/${this.resource}`;
  }

  baseUrl() {
    let url = this.apiVersion;

    if (this.options.enterprise) {
      url = `/enterprise${url}`;
    }

    if (this.options.accountScoped && this.accountIdFromRoute) {
      url = `${url}/accounts/${this.accountIdFromRoute}`;
    }

    return url;
  }

  // HTTP methods
  get() {
    return axios.get(this.url);
  }

  show(id) {
    return axios.get(`${this.url}/${id}`);
  }

  create(data) {
    return axios.post(this.url, data);
  }

  update(id, data) {
    return axios.patch(`${this.url}/${id}`, data);
  }

  delete(id) {
    return axios.delete(`${this.url}/${id}`);
  }
}
```

## API Documentation

Chatwoot uses Swagger (OpenAPI) for API documentation:

- **Swagger Files**: Located in `swagger/` directory
- **Endpoint Definitions**: In `swagger/paths/` 
- **Schema Definitions**: In `swagger/definitions/`
- **Parameter Definitions**: In `swagger/parameters/`

The API documentation can be accessed at `{base_url}/swagger` when the application is running in development mode.

## Error Handling

API errors follow a consistent format:

```json
{
  "error": "Error message",
  "message": "Detailed explanation",
  "errors": {
    "field1": ["Error for field1"],
    "field2": ["Error for field2"]
  }
}
```

Common HTTP status codes:
- `200 OK`: Successful operation
- `201 Created`: Resource created successfully
- `401 Unauthorized`: Missing or invalid authentication
- `403 Forbidden`: Authentication valid but permission denied
- `404 Not Found`: Resource not found
- `422 Unprocessable Entity`: Validation errors

## Rate Limiting

API endpoints may be subject to rate limiting to prevent abuse:

- Rate limits set in `config/initializers/rack_attack.rb`
- Rate limit information returned in response headers
- Exceeded limits result in `429 Too Many Requests` response 