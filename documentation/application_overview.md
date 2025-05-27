# Chatwoot: Application Overview

Chatwoot is a modern, open-source, and self-hosted customer support platform. It serves as an alternative to solutions like Intercom, Zendesk, and Salesforce Service Cloud. The platform is designed for scalability and flexibility, giving businesses control over their customer data while providing tools to manage customer interactions across various channels.

## Core Pillars

### 1. Omnichannel Support Desk
Chatwoot centralizes customer conversations from multiple sources into a unified inbox. This allows support agents to manage interactions efficiently regardless of how the customer reaches out.
Supported channels include:
- Website Live Chat
- Email
- Facebook Messenger
- Instagram Direct Messages
- Twitter Direct Messages
- WhatsApp
- Telegram
- Line
- SMS

### 2. Captain – AI Agent for Support
Captain is Chatwoot's integrated AI agent designed to enhance support efficiency.
Key capabilities:
- **Automated Responses**: Handles common queries automatically.
- **Reduced Agent Workload**: Frees up human agents to focus on complex issues.
- **Instant Answers**: Provides customers with quick and accurate resolutions for routine questions.
(Further details: [Captain AI Documentation](https://chwt.app/captain-docs))

### 3. Help Center Portal
A built-in portal for publishing self-service content.
- **Knowledge Base**: Host help articles, FAQs, and user guides.
- **Reduced Queries**: Empowers customers to find answers independently.
- **Improved Team Focus**: Allows support teams to concentrate on more complex customer issues.

## Key Feature Areas

### Collaboration & Productivity
Tools designed to improve team efficiency and internal communication:
- **Private Notes & @mentions**: For internal discussions within conversations.
- **Labels**: To categorize and organize conversations and contacts. ([See Label Management](./dashboard/settings_labels.md))
- **Keyboard Shortcuts & Command Bar**: For faster navigation and actions.
- **Canned Responses**: Pre-defined replies for frequently asked questions. ([See Canned Response Management](./dashboard/settings_canned_responses.md))
- **Auto-Assignment**: Automatically routes conversations to available agents based on rules. ([See Automation Rules](./dashboard/settings_automation_rules.md))
- **Multi-lingual Support**: Cater to a global customer base.
- **Custom Views & Filters**: Personalize inbox organization.
- **Business Hours & Auto-Responders**: Manage customer expectations for response times. ([See Inbox Settings](./dashboard/settings_inboxes.md))
- **Teams & Automation Tools**: For scaling support workflows and managing agent groups. ([See Team Management](./dashboard/settings_teams.md) and [Automation Rules](./dashboard/settings_automation_rules.md))
- **Agent Capacity Management**: Balance workload effectively across the team.

### Customer Data & Segmentation
Features for managing and leveraging customer information:
- **Contact Management**: Unified profiles with complete interaction history. ([See Contact Management](./dashboard/contacts.md))
- **Contact Segments & Notes**: Group contacts for targeted communication and add internal notes.
- **Campaigns**: Proactively engage specific customer segments. ([See Campaigns Overview](./campaigns/overview.md))
- **Custom Attributes**: Store additional, specific data points about customers and conversations. ([See Custom Attribute Management](./dashboard/settings_custom_attributes.md))
- **Pre-Chat Forms**: Collect essential user information before initiating a chat. ([See Chat Widget Overview](./widget/overview.md) and [Widget Customization](./widget/widget_customization.md))

### Integrations
Extend Chatwoot's functionality by connecting with other services: ([See Integrations Overview](./dashboard/settings_integrations_overview.md))
- **Slack**: Manage conversations directly from Slack. ([See Slack Integration](./dashboard/settings_integration_slack.md))
- **Dialogflow**: For advanced chatbot automation.
- **Dashboard Apps**: Embed internal tools and dashboards within Chatwoot.
- **Shopify**: View and manage customer orders directly.
- **Google Translate**: Real-time translation of customer messages.
- **Linear**: Create and manage Linear tickets from within Chatwoot.

### Reports & Insights
Monitor performance and gain visibility into support operations:
- **Live View**: Real-time monitoring of ongoing conversations.
- **Comprehensive Reports**:
    - Conversation Reports
    - Agent Reports
    - Inbox Reports
    - Label Reports
    - Team Reports
- **CSAT Reports**: Measure customer satisfaction.
- **Downloadable Reports**: For offline analysis and sharing.

### Webhook Enhancements
Improved webhook functionality for better tracking of visitor page information. Payloads now include `page_url`, `page_title`, and `referer_url` at the root level for all message types. This includes fixes for URL handling and improved parsing of page and browser information. ([See Backend Webhooks](./backend_architecture/webhooks.md) and [Webhook Configuration UI](./dashboard/settings_webhooks_ui.md))

### Technical Aspects
- **Backend**: Ruby on Rails.
- **Frontend**: Vue.js (SPA for dashboard and widget).
- **Database**: Primarily PostgreSQL.
- **Background Jobs**: Sidekiq. ([See Background Jobs Architecture](./architecture/background_jobs.md))
- **Real-time Communication**: ActionCable (WebSockets).
- **Redis Usage**: Chatwoot relies on Redis for caching, background jobs (Sidekiq), and real-time features (ActionCable). It's crucial that the Redis instance has keyspace notifications enabled for expired events (`notify-keyspace-events Ex`). See `docs/redis-configuration.md`.
- **Deployment**: Multiple deployment options are available, including Heroku, Docker, Kubernetes (DigitalOcean 1-Click app), and others documented at [chatwoot.com/deploy](https://chatwoot.com/deploy).
- **Branching Model**: Uses the [git-flow](https://nvie.com/posts/a-successful-git-branching-model/) model with `develop` as the base branch and `master` for stable releases.

## Community & Contribution
- **Translation**: Managed via Crowdin at [translate.chatwoot.com](https://translate.chatwoot.com).
- **Community Support**: Discord server at [discord.gg/cJXdrwS](https://discord.gg/cJXdrwS).
- **Security**: Vulnerability reporting process is detailed in `SECURITY.md`.

This overview provides a high-level understanding of Chatwoot's capabilities and architecture. Subsequent documents will delve into specific features and technical details. 