# Campaigns: Overview

Campaigns in Chatwoot are proactive messaging initiatives that allow businesses to reach out to their contacts or website visitors without waiting for them to initiate a conversation.

## Campaign Types

Chatwoot supports two main types of campaigns:

1. **One-off Campaigns**: Single-time messages sent to a specific segment of contacts.
2. **Ongoing Website Campaigns**: Triggered messages shown to website visitors based on specific behavior or conditions.

## Campaign Architecture

Campaigns are structured around the following core components:

1. **Campaign Definition**:
   - Campaign type, title, and description
   - Associated inbox for sending messages
   - Scheduling parameters (immediate or scheduled for future)
   - Display settings and rules

2. **Audience Targeting**:
   - For one-off campaigns: Contact segments or filters
   - For website campaigns: Trigger rules and audience conditions

3. **Content Configuration**:
   - Message content (text, rich media)
   - Call-to-action buttons or links
   - Personalization variables

## Key Models and Relationships

- **`Campaign` (`app/models/campaign.rb`)**:
  - Core campaign model storing campaign configuration
  - Attributes: `title`, `description`, `account_id`, `inbox_id`, `campaign_type` (enum), `campaign_status` (enum), `scheduled_at`
  - Associations: `belongs_to :account`, `belongs_to :inbox`, `has_many :campaign_displays`

- **`CampaignRule` (likely as JSONB within Campaign)**:
  - Rules for triggering campaign displays
  - Includes conditions like URL matching, time on page, scroll percentage, etc.

- **`CampaignDisplay` (`app/models/campaign_display.rb`)**:
  - Tracks when a campaign is displayed to a contact/visitor
  - Attributes: `campaign_id`, `contact_id` (optional), `inbox_member_id` (optional)

## Campaign Management UI

### Campaign Dashboard
- **Route**: `/app/accounts/{account_id}/campaigns`
- **Main Component**: `app/javascript/dashboard/routes/dashboard/campaigns/Index.vue`
  - Lists existing campaigns with status and metrics
  - Provides actions to create, edit, enable/disable campaigns

### Campaign Creation
- **Route**: `/app/accounts/{account_id}/campaigns/new`
- **Component**: `app/javascript/dashboard/routes/dashboard/campaigns/New.vue`
  - Multi-step form for creating a new campaign
  - Steps include: type selection, audience targeting, content creation, scheduling

### Campaign Editor
- **Route**: `/app/accounts/{account_id}/campaigns/{campaign_id}/edit`
- **Component**: `app/javascript/dashboard/routes/dashboard/campaigns/Edit.vue`
  - Editor for modifying campaign settings and content

## Key Functionalities

### 1. Creating a Campaign

**Frontend Process**:
- Admin selects campaign type
- Configures audience targeting
- Creates message content
- Sets schedule and triggers
- Vuex action: `campaigns/create`
- API: `POST /api/v1/accounts/{account_id}/campaigns`

**Backend Process**:
- Controller: `app/controllers/api/v1/accounts/campaigns_controller.rb#create`
- Creates a new `Campaign` record with specified configuration
- Sets up any required campaign rules or schedules

### 2. Triggering Website Campaigns

- **Website Integration**:
  - Chatwoot widget JavaScript (extended from basic widget)
  - Listens for conditions that match campaign rules

- **Trigger Logic**:
  - When conditions are met (e.g., visitor spends 30 seconds on page)
  - Campaign is displayed via widget interface
  - Display is logged in `CampaignDisplay`
  - If contact responds, a conversation is created

- **Implementation**:
  - `app/javascript/widget/store/modules/campaign.js`
  - `app/javascript/widget/components/Campaign.vue`

### 3. Executing One-off Campaigns

- **Execution Process**:
  - At scheduled time, background job processes campaign
  - Creates outbound messages to targeted contacts
  - Records campaign delivery metrics

- **Background Jobs**:
  - `app/jobs/campaigns/one_off_message_job.rb`
  - Handles batch processing of messages to contacts

### 4. Campaign Analytics

- **Metrics Tracked**:
  - Impressions: Number of times campaign was displayed
  - Clicks/Responses: User engagements with campaign
  - Conversion Rate: Percentage of displays that led to conversations
  - For one-off campaigns: Delivery rates, open rates

## State Management (Vuex)

**`app/javascript/dashboard/store/modules/campaigns.js`**:
- **State**:
  - `records`: Array of campaign objects
  - `uiFlags`: Loading and error states
- **Actions**:
  - `fetch`: Get campaigns for account
  - `create`: Create new campaign
  - `update`: Modify campaign
  - `delete`: Remove campaign
  - `toggleStatus`: Enable/disable campaign
- **Mutations**:
  - `SET_CAMPAIGNS`, `ADD_CAMPAIGN`, `EDIT_CAMPAIGN`, `DELETE_CAMPAIGN`

## Backend API Endpoints

- **List**: `GET /api/v1/accounts/{account_id}/campaigns`
- **Create**: `POST /api/v1/accounts/{account_id}/campaigns`
- **Show**: `GET /api/v1/accounts/{account_id}/campaigns/{campaign_id}`
- **Update**: `PATCH /api/v1/accounts/{account_id}/campaigns/{campaign_id}`
- **Delete**: `DELETE /api/v1/accounts/{account_id}/campaigns/{campaign_id}`

## Campaign Integration with Other Features

1. **Contact Management**: Campaigns use contact segments for targeting
2. **Widget**: Website campaigns display through the widget
3. **Inbox**: Messages from campaigns appear in specified inboxes
4. **Automation**: Campaigns can be part of broader automation workflows

Campaigns provide a powerful way to proactively engage with customers, whether through targeted outreach to existing contacts or contextual messages to website visitors. 