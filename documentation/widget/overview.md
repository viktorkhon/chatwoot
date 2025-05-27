# Chat Widget: Overview

The Chatwoot Chat Widget is the primary frontend interface that businesses embed on their websites to enable live chat with their customers. It allows visitors to initiate conversations with support agents directly from the website.

## Overview

The widget is a lightweight, embeddable JavaScript application. It handles displaying the chat interface, sending and receiving messages in real-time, showing typing indicators, handling pre-chat forms, and managing the conversation lifecycle from the user's perspective.

## Embedding and Initialization

-   **Embed Script**: Businesses get a JavaScript snippet from their Chatwoot dashboard (Inbox settings for a Website channel). This script is added to their website's HTML.
    -   The script typically looks like:
        ```html
        <script>
          (function(d,t) {
            var BASE_URL="https://your-chatwoot-instance.com"; // Chatwoot instance URL
            var g=d.createElement(t),s=d.getElementsByTagName(t)[0];
            g.src=BASE_URL+"/packs/js/sdk.js"; // Main SDK loader
            g.defer = true; g.async = true; s.parentNode.insertBefore(g,s);
            g.onload=function(){
              window.chatwootSDK.run({
                websiteToken: 'YOUR_WEBSITE_TOKEN', // Unique token for the website inbox
                baseUrl: BASE_URL
              })
            }
          })(document,"script");
        </script>
        ```
-   **`sdk.js`**: This is the entry point (`app/javascript/sdk/sdk.js`). It loads the main widget application bundle (`widget.js`).
-   **Widget Initialization**: `window.chatwootSDK.run()` initializes the widget by:
    -   Setting up configuration (`websiteToken`, `baseUrl`, `locale`).
    -   Loading the main widget Vue application.
    -   Creating an iframe to host the widget UI, ensuring isolation from the parent website's styles and scripts.

## Core UI Components (within the iframe)

The widget UI is a Vue.js Single Page Application.

1.  **Launcher Button**:
    -   The small button/icon that sits on the website, which users click to open the chat window.
    -   Customizable appearance (color, icon).
    -   Component: `app/javascript/widget/components/Bubble.vue` (or similar).

2.  **Chat Window / Frame**:
    -   The main interface that opens when the launcher is clicked.
    -   Component: `app/javascript/widget/App.vue` is the root.
    -   Includes:
        -   **Header (`ChatHeader.vue`)**: Displays agent name (if assigned), company name/logo, online/offline status, options to close/minimize.
            -   Component: `app/javascript/widget/components/ChatHeader.vue`.
        -   **Message List (`MessageList.vue`)**: Shows the conversation history.
            -   Component: `app/javascript/widget/components/MessageList.vue`.
            -   Individual messages: `Message.vue`.
        -   **Reply Area/Composer (`ChatFooter.vue` / `ReplyBox.vue`)**: Text input for the user, send button, attachment option, emoji picker.
            -   Component: `app/javascript/widget/components/ChatFooter.vue`.
        -   **Pre-Chat Form (`PreChatForm.vue`)**: If enabled, shown before the conversation starts to collect user information (name, email, etc.).
            -   Component: `app/javascript/widget/components/PreChatForm.vue`.
        -   **CSAT Survey (`CSATInput.vue`)**: Shown after a conversation is resolved to collect customer satisfaction feedback.
            -   Component: `app/javascript/widget/components/CSATInput.vue`.
        -   **Typing Indicators**: Shows when an agent is typing.

## Key Functionalities

### 1. Starting a New Conversation
-   User clicks the launcher button.
-   If pre-chat form is enabled, it's displayed first. User submits form.
-   A new conversation is initiated with the backend.
-   User can start typing messages.

### 2. Sending and Receiving Messages
-   **Sending**: User types in the reply box and hits send. The message is sent to the backend via ActionCable (WebSocket).
-   **Receiving**: New messages from agents are received via ActionCable and displayed in the message list.
-   **Attachments**: Users can send attachments (images, files).
-   **Message Types**: Supports text, attachments, cards (e.g., agent sending product info), input fields (e.g., email collection).

### 3. Real-time Features
-   **Message Read Status**: The widget sends events when the user has seen new messages.
-   **Typing Indicators**: Shows "Agent is typing..." when an agent is composing a reply. The widget also sends user typing status.
-   **Presence Updates**: Shows if agents are online/offline.

### 4. Conversation Continuity
-   If the user navigates to a different page on the same website or closes and reopens the widget, their ongoing conversation is typically maintained (using `localStorage` or `sessionStorage` to store conversation identifiers).
-   The `contactPubsubToken` (`app/javascript/widget/helpers/uuid.js`, `getPubSubToken()`) is crucial for identifying the user/contact across sessions.

### 5. Customization and Configuration
-   **Appearance**: Widget color, launcher icon, position, dark/light mode. Configured from Chatwoot dashboard inbox settings.
-   **Locale/Language**: The widget supports multiple languages. Can be set via embed script or detected from browser.
-   **Pre-Chat Form**: Enable/disable and configure fields.
-   **Business Hours**: Widget can show out-of-office messages if configured.
-   **HMAC Identity Validation**: For securely identifying logged-in users from the parent website. `generateHmac()` in `app/javascript/widget/helpers/hmacHelper.js`.

### 6. SDK API
-   The `window.chatwootSDK` object provides methods that the parent website can use to interact with the widget:
    -   `toggle()`: Open/close the widget.
    -   `setUser(identifier, user)`: Set user identity for logged-in users.
    -   `setCustomAttributes(attributes)`: Send custom data about the user/session.
    -   `deleteCustomAttribute(attribute)`
    -   `setLabel(label)`
    -   `removeLabel(label)`
    -   `popoutChatWindow()`: Open chat in a new browser window.
    -   Event listeners: `on('event_name', callback)` to listen for widget events (e.g., `message`, `typing_on`, `typing_off`, `csat:triggered`).

## Core Technologies and Architecture (Frontend Widget)

-   **Framework**: Vue.js (version 2.x, as inferred from `app/javascript/widget/main.js` structure and mixins).
-   **State Management**: Vuex (`app/javascript/widget/store/index.js`). Modules for `appConfig`, `campaign`, `conversation`, `message`, `user`.
-   **Routing**: `vue-router` is used for internal navigation (e.g., between chat view and pre-chat form).
-   **API Communication**:
    -   Primarily ActionCable (WebSockets) for real-time messaging (`app/javascript/widget/helpers/actionCable.js`).
    -   Axios for initial setup calls or specific API interactions (`app/javascript/widget/api/`).
-   **Localization**: `vue-i18n` (`app/javascript/widget/i18n/index.js`).
-   **Styling**: SCSS (`app/javascript/widget/assets/scss/`).

## Key Frontend Directories for Widget

-   `app/javascript/widget/`: Root directory for the widget SPA.
    -   `api/`: API client services.
    -   `assets/`: SCSS, images.
    -   `components/`: Reusable Vue components.
    -   `composables/`: Vue 3 style composables (might be newer additions or for specific parts if migrating).
    -   `constants/`: Application constants.
    -   `helpers/`: Utility functions.
    -   `i18n/`: Localization files.
    -   `mixins/`: Vue 2 mixins.
    -   `store/`: Vuex store setup and modules.
    -   `views/`: Main view components (though many are in `components/`).
-   `app/javascript/sdk/`: Contains the `sdk.js` loader and potentially other SDK-related utilities.
-   `app/javascript/shared/`: Shared code (helpers, components) also used by the dashboard.

## Backend Interaction

-   **ActionCable Channel**: `app/channels/application_cable/widget_channel.rb`. Handles WebSocket communication for a specific contact.
-   **Controllers**:
    -   `app/controllers/api/v1/widget/messages_controller.rb`: For creating messages.
    -   `app/controllers/api/v1/widget/conversations_controller.rb`: For managing conversations (create, update identity, transcripts).
    -   `app/controllers/api/v1/widget/contacts_controller.rb`: For identifying and updating contact info.
    -   `app/controllers/api/v1/widget/inbox_members_controller.rb`: To fetch agent availability.
    -   `app/controllers/api/v1/widget/config_controller.rb`: To fetch inbox/widget configuration.
    -   `app/controllers/api/v1/widget/events_controller.rb`: To trigger events (e.g., webwidget_triggered).
    -   `app/controllers/api/v1/widget/campaigns_controller.rb`: For campaign interactions.
-   **Services**: `Messages::MessageBuilder` (`app/builders/messages/message_builder.rb`) is used to create messages, and it gathers `additional_attributes` like page URL, referrer, browser info from the widget.

The chat widget is a critical component for customer engagement, providing a direct line of communication from a business's website to its support team.