# Contact Management

Contacts in Chatwoot represent the customers or users who interact with businesses through the platform. This document outlines how contacts are structured, managed, and utilized within Chatwoot.

## Contact Data Structure

### Core Models and Relationships

1. **Contact Model** (`app/models/contact.rb`)
   - The primary model representing a customer
   - Key attributes:
     - `account_id`: Account the contact belongs to
     - `name`: Display name of the contact
     - `email`: Email address
     - `phone_number`: Phone/mobile number
     - `identifier`: External unique identifier
     - `additional_attributes`: JSON field for platform-specific data
     - `custom_attributes`: User-defined attributes
     - `last_activity_at`: Timestamp of last interaction
     - `avatar_url`: Profile picture URL

2. **Contact Inboxes** (`app/models/contact_inbox.rb`)
   - Represents a contact's presence in a specific inbox
   - Links `contact_id` with `inbox_id`
   - Stores channel-specific identifiers
   - Contains `source_id` for platform-specific identification

3. **Conversations**
   - Linked to contacts via `contact_id`
   - One contact can have multiple conversations
   - Provides conversation history

## Contact Creation and Identification

### Creation Flow

1. **Web Widget**:
   - Pre-chat form collects basic information
   - Information used to create/update contact
   - Implementation: `app/javascript/widget/components/PreChatForm.vue`

2. **API/Integrations**:
   - External systems create contacts via API
   - Can include custom attributes
   - Implementation: `app/controllers/api/v1/accounts/contacts_controller.rb`

3. **Social Channels**:
   - Automatically created from social media profiles
   - Profile data used to populate contact details
   - Implementation: Channel-specific adapters (e.g., `app/services/facebook/...`)

### Contact Identification

Chatwoot uses several methods to identify and deduplicate contacts:

1. **Email Matching**:
   - Primary identifier for web/email channels
   - Implementation: `app/models/contact.rb#find_by_email`

2. **Phone Number Matching**:
   - Used for WhatsApp, SMS channels
   - Standardized format for matching
   - Implementation: `app/models/contact.rb#find_by_phone`

3. **Channel Identifiers**:
   - Platform-specific IDs (e.g., Facebook user ID)
   - Stored in `ContactInbox` for channel-specific identification
   - Implementation: `app/models/contact_inbox.rb`

4. **Custom Identifier**:
   - Developer-defined unique identifiers
   - Used when integrating with external systems
   - Implementation: `app/models/contact.rb#find_by_identifier`

## Contact Management Interface

### Contact List

**Path**: `/app/accounts/{account_id}/contacts`  
**Component**: `app/javascript/dashboard/routes/dashboard/contacts/ContactsView.vue`

Features:
- List view of all contacts in the account
- Search and filtering capabilities
- Contact creation button
- Key information display (name, last activity, etc.)

### Contact Profile

**Path**: `/app/accounts/{account_id}/contacts/{contact_id}`  
**Component**: `app/javascript/dashboard/routes/dashboard/contacts/ContactProfile.vue`

Features:
- Detailed contact information
- Conversation history
- Custom attributes display
- Contact editing capabilities
- Action buttons (start conversation, etc.)

### Contact Creation/Edit Form

**Component**: `app/javascript/dashboard/components/widgets/forms/ContactForm.vue`

Fields:
- Basic information (name, email, phone)
- Custom attributes
- Notes and additional details
- Social profiles

## Contact Segmentation and Organization

### Contact Filters

Contacts can be filtered by multiple criteria:

1. **Basic Filters**:
   - Search by name, email, phone
   - Filter by last activity date
   - Implementation: `app/finders/contact_finder.rb`

2. **Attribute-Based Filters**:
   - Filter by custom attributes
   - Filter by segment membership
   - Implementation: `app/javascript/dashboard/store/modules/contacts.js`

3. **Conversation-Based Filters**:
   - Contacts with open/resolved conversations
   - Contacts assigned to specific agents
   - Implementation: `app/controllers/api/v1/accounts/contacts_controller.rb#filter`

### Labels and Tagging

Contacts can be organized using:

1. **Labels**:
   - Applied to conversations, indirectly categorizing contacts
   - Implementation: `app/models/label.rb`

2. **Custom Attributes**:
   - User-defined fields for categorization
   - Implementation: `app/models/custom_attribute_definition.rb`

### Contact Segments

Segments are saved filters for contacts:

1. **Segment Definition**:
   - Set of filtering criteria
   - Saved for reuse
   - Implementation: `app/models/contact_filter.rb`

2. **Usage**:
   - Target specific groups for campaigns
   - Analyze customer segments
   - Implementation: `app/controllers/api/v1/accounts/contacts_controller.rb#filter`

## Contact Data Management

### Custom Attributes

User-defined fields for storing additional contact information:

1. **Definition**:
   - Model: `app/models/custom_attribute_definition.rb`
   - Types: text, number, boolean, date
   - Scoped to contact or conversation

2. **Storage**:
   - Stored in `custom_attributes` JSONB field
   - Implementation: `app/models/concerns/custom_field_validations.rb`

3. **UI**:
   - Display: `app/javascript/dashboard/components/widgets/CustomAttributes.vue`
   - Edit: `app/javascript/dashboard/components/widgets/forms/CustomAttributeForm.vue`

### Contact Merge

Functionality to combine duplicate contacts:

1. **Merge Process**:
   - Select primary and secondary contacts
   - Combine conversations and attributes
   - Implementation: `app/services/contacts/merge_service.rb`

2. **UI**:
   - Merge action in contact list/profile
   - Implementation: `app/javascript/dashboard/routes/dashboard/contacts/ContactProfile.vue`

### Data Enrichment

Methods to enhance contact data:

1. **Social Profile Linking**:
   - Connect social accounts to contact
   - Pull additional data from platforms
   - Implementation: `app/services/contacts/enrichment_service.rb`

2. **Activity Tracking**:
   - Monitor and record contact interactions
   - Update `last_activity_at` timestamp
   - Implementation: `app/models/concerns/activity_trackable.rb`

## API Endpoints

Contacts can be managed via API:

```
GET /api/v1/accounts/{account_id}/contacts
POST /api/v1/accounts/{account_id}/contacts
GET /api/v1/accounts/{account_id}/contacts/{id}
PATCH /api/v1/accounts/{account_id}/contacts/{id}
DELETE /api/v1/accounts/{account_id}/contacts/{id}
GET /api/v1/accounts/{account_id}/contacts/{id}/conversations
POST /api/v1/accounts/{account_id}/contacts/search
POST /api/v1/accounts/{account_id}/contacts/filter
```

**Implementation**:
- Controller: `app/controllers/api/v1/accounts/contacts_controller.rb`

## Privacy and Compliance

### GDPR Compliance

1. **Data Export**:
   - Export all contact data in portable format
   - Implementation: `app/controllers/api/v1/accounts/contacts_controller.rb#show`

2. **Right to Erasure**:
   - Delete contact and associated data
   - Implementation: `app/controllers/api/v1/accounts/contacts_controller.rb#destroy`

3. **Consent Management**:
   - Track consent for marketing communications
   - Implementation: Custom attributes tracking consent status

### Data Protection

1. **Field Encryption**:
   - Sensitive fields can be encrypted
   - Implementation: `app/models/concerns/encryptable.rb`

2. **Access Control**:
   - Contact visibility controlled by policies
   - Implementation: `app/policies/contact_policy.rb`

## Advanced Contact Features

### Contact Notes

Internal notes about contacts:

1. **Creation/Storage**:
   - Stored in `additional_attributes` or dedicated notes field
   - Implementation: `app/models/contact.rb`

2. **UI**:
   - Display: `app/javascript/dashboard/components/widgets/ContactNotes.vue`
   - Edit: Through contact profile

### Contact Timeline

Comprehensive activity history:

1. **Event Types**:
   - Conversation events
   - Attribute changes
   - System events (merge, etc.)

2. **Implementation**:
   - Activity tracking: `app/models/concerns/activity_message_handler.rb`
   - Display: `app/javascript/dashboard/components/widgets/conversation/ContactTimeline.vue`

### Campaigns and Contact Targeting

Using contacts for proactive outreach:

1. **Campaign Creation**:
   - Select contact segment
   - Craft message
   - Set delivery parameters
   - Implementation: `app/models/campaign.rb`

2. **Campaign Execution**:
   - Deliver messages to selected contacts
   - Track engagement metrics
   - Implementation: `app/jobs/campaigns/one_off_message_job.rb`

### CSAT Survey Responses

Track customer satisfaction metrics:

1. **Survey Collection**:
   - Send CSAT surveys after conversation resolution
   - Store responses linked to contact
   - Implementation: `app/models/csat_survey_response.rb`

2. **Analysis**:
   - Customer satisfaction reporting
   - Trends by contact/segment
   - Implementation: `app/controllers/api/v1/accounts/reports_controller.rb`

Contacts are a foundational element of Chatwoot, providing the context and continuity that enable personalized customer support experiences. The robust contact management system ensures that customer information is organized, accessible, and actionable across all communication channels. 