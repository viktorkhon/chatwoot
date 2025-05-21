# Chat Widget: Customization

The Chatwoot Chat Widget is designed to be highly customizable to match a business's branding and functional requirements. This document details the customization options available for the widget.

## Customization Overview

The widget can be customized in several key areas:
1. Visual appearance and branding
2. Behavioral settings
3. Content and messaging
4. Pre-chat forms and input fields
5. Advanced functionality through API

## Visual Customization

### Branding Colors and Styles

**Configuration Location**: Website Channel settings in Chatwoot Dashboard
- **Primary Color**: Sets the main color for header, buttons, and accents
  - Stored in `channel.widget_color` for `Channel::WebWidget`
  - Applied via CSS variables in `app/javascript/widget/assets/scss/variables.scss`

- **Logo**: Custom logo displayed in the widget header
  - Uploaded and stored via Active Storage
  - Referenced in `widget_config.json` as `logo_url`

- **Widget Position**: Control where the widget appears on the page
  - Options: `right` (default), `left`, `bottom-right`, `bottom-left`
  - Set via `position` in SDK initialization or settings

### Widget Launcher Styling

- **Launcher Icon**: Custom icon for the chat bubble
  - Default is a chat icon
  - Can be customized to use brand logo or different icon
  - Set via `widgetIcon` in settings

- **Launcher Size and Style**: Customize the appearance of the button
  - Controlled via CSS in `app/javascript/widget/components/Bubble.vue`

### Theme Options

- **Dark/Light Mode**:
  - Options: `light` (default), `dark`
  - Set via `theme` in widget config
  - Applies different color schemes from `app/javascript/widget/assets/scss/theme.scss`

- **Custom CSS**: Advanced option to inject custom styles
  - Set via `customStyles` in widget config
  - Applied to the widget iframe

## Behavioral Customization

### Widget Display Settings

- **Auto Popup**: Automatically open the widget after a delay
  - Configurable delay in seconds
  - Set via `autoPopup` and `popupDelay` in widget config

- **Persistent Widget**: Keep the widget open across page navigation
  - Set via `persistentWidget` in widget config
  - Uses localStorage to maintain state

- **Hide MessageBubble**: Option to hide the notification bubble on unread messages
  - Set via `hideMessageBubble` in widget config

### Availability Settings

- **Business Hours**: Set specific hours when the widget shows as "online"
  - Configured in inbox settings
  - Affects widget status and auto-responses

- **Widget Visibility**: Control when the widget appears
  - Can be set to show only on specific pages using URL patterns
  - Managed through `showOnlyOnRoutes` and `hideOnRoutes` in widget config

## Content and Messaging Customization

### Welcome Messages

- **Greeting Message**: Initial message shown when widget is opened
  - Set in channel settings via `greeting_message`
  - Displayed by `app/javascript/widget/components/Greeting.vue`

- **Away/Offline Message**: Message shown when outside business hours
  - Set in channel settings via `away_message`
  - Used when `working_hours_enabled` is true and current time is outside working hours

### Language and Localization

- **Widget Language**: Set the display language for UI elements
  - Set via `locale` in SDK initialization
  - Translations stored in `app/javascript/widget/i18n/locale/`

- **RTL Support**: Right-to-left language support
  - Automatically applied for RTL languages
  - Uses CSS `dir="rtl"` attribute

## Pre-Chat Forms and Input Fields

### Pre-Chat Form Configuration

- **Enable/Disable**: Turn pre-chat form on/off
  - Set via `pre_chat_form_enabled` in channel settings
  - Controlled by `PreChatFormEnabled` component

- **Form Fields**: Customize required fields
  - Configure via `pre_chat_form_options` JSONB field in channel settings
  - Options include:
    - Required fields (name, email, phone)
    - Custom fields (with types: text, number, etc.)
    - Field labels and placeholders

- **Implementation**:
  - Form Component: `app/javascript/widget/components/PreChatForm.vue`
  - Data stored with contact on submission
  - Custom attributes stored in contact's `custom_attributes`

## Advanced Customization via SDK API

### SDK Methods for Developers

The widget exposes a JavaScript API through `window.chatwootSDK` with methods:

- **`setUser(identifier, attributes)`**:
  ```javascript
  window.chatwootSDK.setUser('user-123', {
    name: 'John Doe',
    email: 'john@example.com',
    phone_number: '+1234567890',
    custom_attributes: {
      plan: 'Premium',
      registered_on: '2023-10-01'
    }
  });
  ```

- **`setCustomAttributes(attributes)`**:
  ```javascript
  window.chatwootSDK.setCustomAttributes({
    product_viewed: 'Coffee Maker',
    items_in_cart: 3
  });
  ```

- **`setLocale(locale)`**:
  ```javascript
  window.chatwootSDK.setLocale('es');
  ```

- **`toggle()`**: Open or close the widget programmatically

- **`popoutChatWindow()`**: Open chat in new window

### Event Listeners

Subscribe to widget events:

```javascript
window.chatwootSDK.on('message', function(message) {
  console.log('New message received', message);
});

// Other events: widget:opened, widget:closed, message:sent, message:received
```

### HMAC Identity Verification

For secure authentication of users:

```javascript
// Server-side: Generate HMAC using shared secret
const hmac = generateHmac(identifier, shared_secret);

// Client-side: Pass HMAC with user identification
window.chatwootSDK.setUser(
  'user-123',
  { /* user attributes */ },
  hmac
);
```

- Implementation: `app/javascript/widget/helpers/hmacHelper.js`
- Backend validation: `app/validators/hmac_validator.rb`

## Customization Implementation Details

### How Configuration is Stored and Applied

1. **Dashboard Config Storage**:
   - Settings stored in `Channel::WebWidget` model
   - UI in `app/javascript/dashboard/routes/dashboard/settings/inbox/channels/WebWidgetSettings.vue`

2. **Config Serving**:
   - Controller: `app/controllers/api/v1/widget/config_controller.rb`
   - Endpoint: `GET /api/v1/widget/config`
   - Returns configuration JSON for the specific widget token

3. **Widget Initialization**:
   - SDK loads configuration from server
   - Merges with any overrides from embed script
   - Applies settings to widget iframe
   - Code: `app/javascript/widget/store/modules/appConfig.js`

### Widget Initialization Flow

1. Website includes SDK script with websiteToken
2. SDK creates iframe and loads widget app
3. Widget app fetches configuration
4. Configuration applied to components
5. Widget renders according to settings

## Additional Customization Areas

- **Notification Sounds**: Customize sound for new messages
- **File Attachments**: Enable/disable file uploading
- **CSAT Survey**: Customize post-conversation surveys
- **Bot Integration**: Connect with chatbots (Dialogflow, etc.)
- **Exit Intent Display**: Show widget when user attempts to leave
- **Targeted Messages**: Show different greetings based on URL or user data

The extensive customization options allow businesses to create a chat experience that seamlessly integrates with their website while maintaining their brand identity and meeting specific functional requirements. 