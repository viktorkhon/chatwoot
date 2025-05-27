# Architecture: Background Jobs

Chatwoot relies heavily on background job processing to handle time-consuming tasks asynchronously, ensuring the main application remains responsive. This document details the background job architecture, key job types, and how they're implemented.

## Background Job Architecture

### Core Technology Stack

1. **ActiveJob**: Rails' job framework to provide a consistent interface
2. **Sidekiq**: Primary background processing system that executes the jobs
3. **Redis**: Storage backend for Sidekiq's job queues and status information

### Directory Structure

Background jobs are organized in `app/jobs/` with subdirectories for logical grouping:

```
app/jobs/
├── account/                # Account-related jobs
│   ├── contacts/           # Contact processing jobs
│   └── data_import_job.rb  # Data import jobs
├── campaigns/              # Campaign execution jobs
├── conversations/          # Conversation processing jobs
├── inboxes/                # Inbox-related jobs
├── notification/           # Notification dispatch jobs
├── webhooks/               # Webhook delivery jobs
└── migration/              # Data migration jobs
```

### Job Configuration

Core Sidekiq and ActiveJob configuration is defined in:
- `config/sidekiq.yml`: Queue definitions and concurrency settings
- `config/initializers/sidekiq.rb`: Redis connection and middleware setup
- `config/application.rb`: ActiveJob configuration

## Key Job Categories

### 1. Message Processing Jobs

**Purpose**: Handle message creation, routing, and notification across channels

**Key Jobs**:
- `Messages::DispatchEventJob` (`app/jobs/messages/dispatch_event_job.rb`)
  - Dispatches message events to appropriate channels
  - Called after message creation
  - Parameters: `message_id`

- `Conversations::ReplyBotJob` (`app/jobs/conversations/reply_bot_job.rb`)
  - Processes bot replies for automated responses
  - Parameters: `conversation_id`, potentially additional context

### 2. Notification Jobs

**Purpose**: Send email, push, and in-app notifications to users

**Key Jobs**:
- `Notification::PushNotificationJob` (`app/jobs/notification/push_notification_job.rb`) 
  - Sends push notifications to agents' devices
  - Parameters: `notification_id`, `fcm_token`

- `Notification::EmailNotificationJob` (`app/jobs/notification/email_notification_job.rb`)
  - Sends email notifications using ActionMailer
  - Parameters: `mailer_class`, `mailer_method`, `args`

- `Notification::WebhookNotificationJob` (`app/jobs/notification/webhook_notification_job.rb`)
  - Dispatches notifications to external webhooks
  - Parameters: `webhook_url`, `payload`

### 3. Webhook Processing Jobs

**Purpose**: Deliver event data to configured webhooks reliably

**Key Jobs**:
- `Webhooks::AccountWebhookJob` (`app/jobs/webhooks/account_webhook_job.rb`)
  - Delivers webhook payloads to configured endpoints
  - Handles retry logic and signing
  - Parameters: `url`, `payload`, `webhook_type`, `account_id`, etc.

### 4. Campaign Execution Jobs

**Purpose**: Process and deliver marketing campaigns to contacts

**Key Jobs**:
- `Campaigns::OneOffMessageJob` (`app/jobs/campaigns/one_off_message_job.rb`)
  - Sends one-time campaign messages to contacts
  - Parameters: `campaign_id`, `account_id`, batch parameters

### 5. Maintenance Jobs

**Purpose**: Handle routine maintenance tasks

**Key Jobs**:
- `Conversations::ResolutionJob` (`app/jobs/conversations/resolution_job.rb`)
  - Auto-resolves conversations after inactivity period
  - Scheduled to run periodically

- `Inboxes::AvailabilityStatusJob` (`app/jobs/inboxes/availability_status_job.rb`)
  - Updates inbox availability based on business hours
  - Scheduled to run at specific times

## Job Queue Configuration

Chatwoot uses multiple queues to prioritize different types of jobs:

- **Low Priority**: `low`
  - Data exports, imports, bulk operations
  - Example: `Account::ContactExportJob`

- **Medium Priority**: `default`, `medium`
  - Most background operations like webhook delivery
  - Example: `Webhooks::AccountWebhookJob`

- **High Priority**: `high`, `critical`
  - User-facing operations needing quick execution
  - Example: `Notification::PushNotificationJob`

- **Scheduled**: `scheduled`
  - Jobs that run on a schedule
  - Example: `Conversations::ResolutionJob`

Queue configuration in `config/sidekiq.yml`:
```yaml
:concurrency: <%= ENV.fetch('SIDEKIQ_CONCURRENCY', 5) %>
:queues:
  - [critical, 4]
  - [high, 3]
  - [default, 2]
  - [low, 1]
  - [scheduled, 1]
```

## Job Implementation Patterns

### 1. Job Declaration

```ruby
class SampleJob < ApplicationJob
  queue_as :default
  
  # Retry settings
  retry_on StandardError, wait: :exponentially_longer, attempts: 3
  
  # Uniqueness to prevent duplicate jobs (if using sidekiq-unique-jobs)
  sidekiq_options unique: :until_executed, unique_args: ->(args) { args.first }

  def perform(entity_id, options = {})
    # Job logic here
  end
end
```

### 2. Job Enqueueing Patterns

From application code:

```ruby
# Basic enqueuing
SampleJob.perform_later(entity_id)

# With delay
SampleJob.set(wait: 5.minutes).perform_later(entity_id)

# With specific queue
SampleJob.set(queue: 'high').perform_later(entity_id)
```

### 3. Error Handling

Jobs implement error handling through:
- `retry_on` and `discard_on` ActiveJob directives
- Custom error handling in `rescue` blocks
- Reporting to error monitoring services

Example:
```ruby
def perform(entity_id)
  entity = Entity.find(entity_id)
  process_entity(entity)
rescue ActiveRecord::RecordNotFound => e
  # Entity was deleted before job ran, can be discarded
  logger.info "Entity #{entity_id} not found, discarding job"
rescue StandardError => e
  # Log error and let job retry based on retry_on setting
  logger.error "Error processing entity #{entity_id}: #{e.message}"
  raise
end
```

## Managing Background Jobs

### Monitoring and Administration

- **Sidekiq Web UI**: Available at `/sidekiq` for administrators
  - View queue lengths, job statuses, retry queues
  - Implementation in `config/routes.rb` with authentication
  
- **Logging**: Job execution is logged to:
  - Standard Rails log with job-specific context
  - Sidekiq log with detailed execution information

### Deployment Considerations

- **Redis Configuration**: 
  - Required configuration: `notify-keyspace-events Ex` for expirations
  - Redis persistence recommended to prevent job loss
  
- **Worker Scaling**:
  - Independent scaling of web and worker processes
  - In Heroku/similar: `Procfile` defines `worker: bundle exec sidekiq`
  - In Kubernetes: Separate worker deployments with resource allocations

### Testing Background Jobs

Chatwoot tests background jobs using:
- `ActiveJob::TestHelper` for unit testing
- `Sidekiq::Testing` for integration testing
- Test examples in `spec/jobs/`

## Critical Background Job Workflows

### 1. New Message Processing

When a new message is created:
1. `Message` model `after_create_commit` triggers various callbacks
2. `Messages::DispatchEventJob` processes notification requirements
3. Additional jobs for webhooks, email notifications, etc. are enqueued

### 2. Campaign Execution

For one-off campaigns:
1. Campaign is scheduled via dashboard
2. At specified time, `Campaigns::OneOffMessageJob` is triggered
3. Job processes contacts in batches to avoid memory issues
4. Messages are created and sent to each eligible contact

### 3. Auto-Resolution

For conversation auto-resolution:
1. `Conversations::ResolutionJob` runs on schedule
2. Identifies conversations with no activity past threshold
3. Auto-resolves eligible conversations
4. Generates system messages indicating auto-resolution

Background jobs are a critical part of Chatwoot's architecture, handling everything from routine maintenance to essential user-facing features like notifications and message delivery. 