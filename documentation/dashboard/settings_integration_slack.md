# Dashboard: Slack Integration Settings

The Slack integration in Chatwoot allows teams to connect their Chatwoot account with their Slack workspace. This enables notifications about Chatwoot conversations to be posted in designated Slack channels, facilitating quicker awareness and collaboration.

## Overview

When configured, new conversations or messages in Chatwoot can trigger notifications in Slack. This helps keep the team informed even if they are not actively in the Chatwoot dashboard. Some integrations might also allow limited interaction with Chatwoot from Slack, though the primary use case documented is for notifications.

## Access and Configuration

-   **Route**: `/app/accounts/{account_id}/settings/integrations/slack` (or accessed via the main integrations list).
-   **Main Component**: `app/javascript/dashboard/routes/dashboard/settings/integrations/Slack.vue`.
-   **Initial State**: If not connected, it shows a "Connect to Slack" button.
-   **Connected State**: If already connected, it displays the current configuration (e.g., the Slack channel selected for notifications) and provides options to "Update Configuration" or "Disconnect".

## Configuration Steps

1.  **Initiate Connection**:
    -   User clicks "Connect to Slack" from the Chatwoot integrations page.
    -   Chatwoot redirects the user to Slack's OAuth 2.0 authorization screen.
    -   The request to Slack includes Chatwoot's `client_id` and requested `scopes` (permissions).
    -   Backend route involved in initiating: `GET /api/v1/accounts/{account_id}/integrations/slack/new_auth_url` (or similar logic to generate the Slack auth URL).

2.  **Slack Authorization**:
    -   User reviews the permissions Chatwoot is requesting and authorizes the application.
    -   Slack redirects the user back to Chatwoot's specified `redirect_uri` with an authorization `code`.

3.  **Token Exchange and Hook Creation (Backend)**:
    -   **Callback Controller**: `app/controllers/integrations/slack_callbacks_controller.rb#create`. This controller handles the redirect from Slack.
    -   It receives the authorization `code`.
    -   It makes a POST request to Slack's `oauth.v2.access` API endpoint to exchange the `code` for an `access_token`.
        -   This is typically done by a service or library method, e.g., `Slack::ExchangeAuthCodeService.new(code: params[:code]).perform`.
    -   **Storing Credentials**:
        -   The obtained `access_token` and other relevant information (like `team_id`, `bot_user_id`) are stored securely.
        -   A `Hook` record (or `IntegrationHook`) is created or updated for the account and the Slack app.
            -   `account_id`: Current account.
            -   `app_id`: `App.find_by(name: 'slack').id`.
            -   `settings`: May store `team_id`, `team_name`.
            -   `access_token`: The bot token, stored encrypted.
            -   `status`: Set to `enabled`.
        -   Model: `Hook` (`app/models/hook.rb`).
    -   The user is then redirected back to the Slack integration settings page in Chatwoot, which now shows a "connected" state.

4.  **Configure Notification Channel (Frontend & Backend)**:
    -   After successful connection, the user needs to select a Slack channel where Chatwoot notifications will be posted.
    -   **Frontend**: `Slack.vue` component fetches a list of available Slack channels using the stored access token.
        -   API call: `GET /api/v1/accounts/{account_id}/integrations/slack/list_channels` (or similar).
        -   Backend for listing channels: `app/controllers/api/v1/accounts/integrations/slack_controller.rb#list_channels` would use the stored bot token to call Slack's `conversations.list` API.
    -   User selects a channel from a dropdown.
    -   User saves the configuration.
    -   **Backend for saving configuration**:
        -   API: `POST /api/v1/accounts/{account_id}/integrations/slack` (for initial config) or `PATCH /api/v1/accounts/{account_id}/integrations/slack` (for updates).
        -   Controller: `app/controllers/api/v1/accounts/integrations/slack_controller.rb#create` or `#update`.
        -   The selected `channel_id` (or channel name) is saved in the `settings` hash of the `Hook` record for the Slack integration (e.g., `hook.settings['channel_id'] = selected_channel_id`).
        -   It may also create a `NotificationSetting` record for the account.

## Functionality

-   **Sending Notifications to Slack**:
    -   When a specified event occurs in Chatwoot (e.g., new conversation created, new message in an existing conversation), Chatwoot triggers a notification.
    -   **Trigger**: Typically from `after_commit` callbacks in models like `Conversation` or `Message`, or from services like `Messages::NewMessageService`.
    -   **Service**: `Integrations::Slack::SendNotificationService` (or similar, e.g., `Integrations::Slack::SendOnSlackService.new(message: message_object, hook: slack_hook).perform`).
    -   This service:
        -   Checks if Slack integration is active for the account and configured with a channel.
        -   Formats a message payload for Slack (using Slack's Block Kit or simple text).
        -   Uses the stored bot `access_token` to call Slack's `chat.postMessage` API to send the message to the configured channel.
    -   Relevant code: `lib/integrations/slack/chatwoot_channel_listener.rb` might contain logic related to processing events and preparing Slack messages.

## Updating and Disconnecting

-   **Updating Configuration**:
    -   Users can change the Slack channel for notifications. This follows a similar flow to step 4 above, using the `update` action in `SlackController`.
-   **Disconnecting Slack**:
    -   User clicks "Disconnect".
    -   API: `DELETE /api/v1/accounts/{account_id}/integrations/slack`.
    -   Controller: `app/controllers/api/v1/accounts/integrations/slack_controller.rb#destroy`.
    -   Backend deletes the `Hook` record associated with the Slack integration for that account.
    -   Optionally, it might call Slack's `auth.revoke` API to invalidate the stored token, though deleting the hook usually suffices to stop functionality.

## Key Files and Components

-   **Frontend**:
    -   `app/javascript/dashboard/routes/dashboard/settings/integrations/Slack.vue`: Main UI for Slack integration settings.
    -   API Client: `app/javascript/dashboard/api/integrations/slack.js` (if specific calls are made from frontend beyond general integration framework).
-   **Backend - Controllers**:
    -   `app/controllers/integrations/slack_callbacks_controller.rb`: Handles OAuth callback.
    -   `app/controllers/api/v1/accounts/integrations/slack_controller.rb`: Handles API requests for configuring, updating, and disconnecting Slack integration, listing channels.
-   **Backend - Models**:
    -   `Hook` (`app/models/hook.rb`): Stores integration configuration including encrypted `access_token` and `settings`.
    -   `App` (`app/models/app.rb`): Defines 'slack' as an available app type.
-   **Backend - Services/Libraries**:
    -   `lib/integrations/slack/`: Contains core logic for interacting with Slack API.
        -   `chatwoot_channel_listener.rb`: Processes events and prepares messages.
        -   `send_on_slack_service.rb` (or similar): Service to send messages.
    -   `Slack::ExchangeAuthCodeService` (hypothetical service for token exchange).

This integration streamlines communication by bringing Chatwoot updates directly into the team's Slack workspace.