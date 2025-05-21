# Dashboard: Automation Rule Management

Automation Rules in Chatwoot allow administrators to define rules that automatically perform actions on conversations when certain conditions are met. This helps streamline workflows, reduce manual effort, and ensure consistent handling of conversations.

## Overview

Automation rules work on an "event-condition-action" model. When a specific event occurs (e.g., a conversation is created), the system checks if predefined conditions are met. If they are, specified actions are executed (e.g., assign to a team, add a label, send an email).

## Access and UI Components

-   **Route**: `/app/accounts/{account_id}/settings/automation-rules` (or a similar path).
-   **Main Component**: `app/javascript/dashboard/routes/dashboard/settings/automationRules/Index.vue`. This page lists existing automation rules and allows for their creation, editing, and deletion.
    -   **Rule List**: Displays rules with their name, description, status (active/inactive), and triggering event.
        -   Component: `AutomationRuleTable.vue` or similar.
    -   **"Add Automation Rule" Button**: Opens a form or a dedicated page for creating a new rule.
        -   Component: `AddAutomationRule.vue` or `AutomationRuleForm.vue` (e.g., `app/javascript/dashboard/routes/dashboard/settings/automationRules/AutomationRuleForm.vue`).

-   **Automation Rule Form (Create/Edit)**:
    -   This is a complex form where users define:
        -   **Name and Description**: For identifying the rule.
        -   **Event**: The trigger for the rule (e.g., "Conversation Created", "Message Created", "Conversation Updated"). Selected from a dropdown.
            -   See `AutomationRule::EVENTS` in `app/models/automation_rule.rb`.
        -   **Conditions**: One or more conditions that must be met. Conditions are typically based on conversation attributes (status, inbox, priority), contact attributes (email, country), or message attributes (content).
            -   Each condition has a `field_name`, `filter_operator`, and `value`.
            -   UI: `AutomationRuleConditions.vue` or similar, allowing dynamic addition of conditions.
        -   **Condition Match Type**: `all` (all conditions must be true) or `any` (at least one condition must be true).
        -   **Actions**: One or more actions to be performed. Examples: "Assign to Agent", "Assign to Team", "Add Label", "Send Email to Transcript", "Send Webhook", "Mute Conversation", "Snooze Conversation", "Resolve Conversation", "Send Attachment".
            -   Each action type requires specific parameters (e.g., "Add Label" needs label ID, "Assign Agent" needs agent ID).
            -   UI: `AutomationRuleActions.vue` or similar, allowing dynamic addition of actions.
        -   **Active**: Toggle to enable or disable the rule.

## Key Functionalities

### 1. Listing Automation Rules
-   **Fetching Rules**:
    -   Vuex action: `automationRules/get` (`app/javascript/dashboard/store/modules/automationRules.js`).
    -   API: `GET /api/v1/accounts/{account_id}/automation_rules` via `AutomationRulesAPI.get()` (`app/javascript/dashboard/api/automationRules.js`).
    -   Controller: `app/controllers/api/v1/accounts/automation_rules_controller.rb#index`.

### 2. Creating/Editing an Automation Rule
-   **Frontend Process**:
    -   User fills out the `AutomationRuleForm.vue`.
    -   Data for conditions and actions is structured as arrays of objects.
    -   Vuex action: `automationRules/create` or `automationRules/update`.
    -   API: `POST` or `PATCH /api/v1/accounts/{account_id}/automation_rules/{rule_id}`.
-   **Backend Process**:
    -   Controller: `app/controllers/api/v1/accounts/automation_rules_controller.rb#create` or `#update`.
    -   Payload includes: `name`, `description`, `event_name`, `conditions` (array), `actions` (array), `active`, `conditions_match_type`.
    -   Saves or updates an `AutomationRule` record.
    -   Model: `AutomationRule` (`app/models/automation_rule.rb`). Conditions and actions are typically stored as JSONB arrays in the `conditions` and `actions` fields respectively.

### 3. Deleting an Automation Rule
-   **Frontend Process**:
    -   User confirms deletion.
    -   Vuex action: `automationRules/delete`.
    -   API: `DELETE /api/v1/accounts/{account_id}/automation_rules/{rule_id}`.
-   **Backend Process**:
    -   Controller: `app/controllers/api/v1/accounts/automation_rules_controller.rb#destroy`.
    -   Deletes the `AutomationRule` record.

### 4. Rule Execution
-   **Trigger**: When a relevant event occurs (e.g., a new conversation is created, a message is posted), the system needs to check and execute matching automation rules.
    -   This is often handled by `after_commit` callbacks on models like `Conversation` and `Message`, or within services that process these events (e.g., `Messages::NewMessageService`).
-   **Execution Service**: `AutomationRules::ProcessorService` (`app/services/automation_rules/processor_service.rb`).
    -   This service is called with the event name and the relevant object (e.g., the conversation).
    -   It fetches all active `AutomationRule` records for the account that listen to the given `event_name`.
    -   For each rule, it evaluates its `conditions` against the object using `AutomationRules::ConditionsFilterService` (`app/services/automation_rules/conditions_filter_service.rb`).
    -   If conditions are met (respecting `conditions_match_type`), it executes the defined `actions` using `AutomationRules::ActionService` (`app/services/automation_rules/action_service.rb`).
-   **Action Execution**: `AutomationRules::ActionService` iterates through the actions and calls specific methods or services to perform them (e.g., update conversation attributes, call a mailer, enqueue a webhook job).

## Automation Rule Structure (Model Level)

-   `app/models/automation_rule.rb`:
    -   `name`, `description`, `event_name` (enum or string).
    -   `conditions`: JSONB array, e.g., `[{ "field_name": "status", "filter_operator": "equal_to", "value": "open" }, ...]`.
        -   `AutomationRule::CONDITION_OPERATORS`, `AutomationRule::FILTER_OPERATORS`.
    -   `actions`: JSONB array, e.g., `[{ "action_name": "add_label", "action_params": ["label_id_1", "label_id_2"] }, ...]`.
        -   `AutomationRule::ACTION_TYPES`.
    -   `active` (boolean), `conditions_match_type` (enum: `all`, `any`).
    -   `account_id`.

## Available Events, Conditions, and Actions (Examples)

-   **Events**: `conversation_created`, `conversation_updated`, `message_created`, `contact_created`, `contact_updated`.
-   **Condition Fields (Conversation)**: `status`, `inbox_id`, `assignee_id`, `team_id`, `priority`, `labels`, `browser_language`, `country_code`, `conversation_language`.
-   **Condition Fields (Message)**: `message_type` (incoming/outgoing), `content`.
-   **Condition Fields (Contact)**: `email`, `phone_number`, `name`, `country_code`, `company_name`.
-   **Filter Operators**: `equal_to`, `not_equal_to`, `contains`, `does_not_contain`, `is_present`, `is_not_present`, `starts_with`, `ends_with`, `less_than`, `greater_than`.
-   **Actions**: `assign_agent`, `assign_team`, `add_label`, `remove_label`, `send_email_transcript`, `send_webhook_event`, `mute_conversation`, `snooze_conversation`, `resolve_conversation`, `change_priority`, `send_message` (send a predefined message), `send_attachment`.

## State Management (Vuex)

-   **`app/javascript/dashboard/store/modules/automationRules.js`**:
    -   Manages automation rules for the account.
    -   Actions: `get`, `create`, `update`, `delete`.
    -   Mutations: `SET_AUTOMATION_RULES_UI_FLAG`, `SET_AUTOMATION_RULES`, `ADD_AUTOMATION_RULE`, `EDIT_AUTOMATION_RULE`, `DELETE_AUTOMATION_RULE`.

## Backend Structure

-   **Model**: `AutomationRule` (`app/models/automation_rule.rb`).
-   **Controller**: `app/controllers/api/v1/accounts/automation_rules_controller.rb`.
-   **Services**:
    -   `AutomationRules::ProcessorService` (main execution orchestrator).
    -   `AutomationRules::ConditionsFilterService` (evaluates conditions).
    -   `AutomationRules::ActionService` (executes actions).
    -   Various sub-services within `app/services/automation_rules/actions/` for each specific action type (e.g., `AssignAgent.rb`, `AddLabel.rb`).

Automation rules are a powerful tool for customizing Chatwoot's behavior and reducing repetitive tasks for support agents.