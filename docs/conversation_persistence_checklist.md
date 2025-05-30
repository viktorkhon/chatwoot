# Chatwoot Conversation Persistence Feature - Complete Implementation Checklist

**Main Goal:** Track conversation persistence throughout single user session while maintaining ability to create new conversations, receive responses, and preserve all webhook functionality.

## 🎯 Core Requirements

### ✅ Primary Objectives
- [ ] **Single Conversation Per Session**: Users maintain one conversation throughout their session across page navigation
- [ ] **New Conversation Creation**: Users can still create new conversations when needed
- [ ] **Message Functionality**: Users can send and receive messages normally
- [ ] **Webhook Preservation**: All existing webhook functionality continues to work as before
- [ ] **Cross-Page Persistence**: Conversations persist during Shopify navigation, SPA routing, and page refreshes
- [ ] **Incognito Support**: Works without cookies using Redis-backed visitor tracking
- [ ] **COMPREHENSIVE Webhook Prevention**: NO webhooks sent during page navigation once conversation exists

## 🏗️ Backend Implementation Checklist

### Redis Infrastructure
- [ ] **VisitorConversationMapping Model** (`app/models/visitor_conversation_mapping.rb`)
  - [ ] Redis-backed visitor tracking system with 30-day TTL
  - [ ] Maps visitor fingerprints to conversation tokens for incognito users
  - [ ] Maps visitor fingerprints to contact source IDs for contact persistence
  - [ ] Tracks page info for visitors before conversation creation
  - [ ] Auto-cleanup when conversations are resolved
  - [ ] Graceful degradation when Redis is unavailable

- [ ] **Redis Configuration** (`lib/redis/config.rb`)
  - [ ] Railway Valkey service integration
  - [ ] Increased timeout and reconnection attempts
  - [ ] Connection pooling and error handling
  - [ ] Debug endpoint for Redis diagnostics

### Controller Enhancements
- [ ] **BaseController** (`app/controllers/api/v1/widget/base_controller.rb`)
  - [ ] Enhanced conversation lookup with Redis validation
  - [ ] `validate_redis_conversation_mapping()` method for stale mapping detection
  - [ ] Enhanced conversation token generation with conversation ID
  - [ ] Improved conversation lookup logic with fallback methods
  - [ ] Automatic cleanup of stale mappings when inconsistencies detected
  - [ ] Visitor ID extraction from headers/params
  - [ ] Safe parameter handling with fallbacks
  - [ ] **Fixed `conversations` method to return the ActiveRecord relation properly**
  - [ ] **Enhanced conversation lookup logging for debugging**
  - [ ] **Fixed inbox_id resolution when auth_token_params is empty**
  - [ ] **Restored proper conversation lookup logic after optimization**

- [ ] **ConversationsController** (`app/controllers/api/v1/widget/conversations_controller.rb`)
  - [ ] Webhook prevention logic to avoid duplicates
  - [ ] Redis mapping management and cleanup
  - [ ] Enhanced error handling for conversation creation
  - [ ] Detailed logging for debugging conversation issues
  - [ ] Toggle typing endpoint fixes (removed from before_action filter)
  - [ ] **Enhanced `update_last_seen` action with proper error handling and logging**
  - [ ] **Session cleanup on conversation resolution for webhook prevention**
  - [ ] **Auto-conversation creation after resolution feature (implemented and reverted)**

- [ ] **MessagesController** (`app/controllers/api/v1/widget/messages_controller.rb`)
  - [ ] Modified `set_conversation` to return error instead of creating new conversations
  - [ ] Enhanced logging for message creation flow
  - [ ] Safe navigation in `message_params` method
  - [ ] Proper error handling for NO_CONVERSATION scenarios
  - [ ] **Enhanced conversation lookup to prevent setUserLastSeen API calls from n8n messages**

### Model Updates
- [ ] **Conversation Model** (`app/models/conversation.rb`)
  - [ ] `cleanup_redis_mappings_on_resolution()` callback
  - [ ] Automatic cleanup of Redis mappings when conversations are resolved
  - [ ] Enhanced webhook data with page information
  - [ ] Timestamp standardization for ActionCable events
  - [ ] **Simplified Redis cleanup logging (removed DEBUG prefix)**

- [ ] **Message Model** (`app/models/message.rb`)
  - [ ] Fixed `dispatch_update_event` timestamp conversion
  - [ ] Consistent Unix timestamp format in ActionCable broadcasts

### Helper Enhancements
- [ ] **WebsiteTokenHelper** (`app/controllers/concerns/website_token_helper.rb`)
  - [ ] Enhanced with visitor ID support
  - [ ] Redis fallback contact lookup
  - [ ] Improved contact creation logic
  - [ ] Better error handling and logging
  - [ ] **Fixed `auth_token_params` method to handle missing auth tokens gracefully**

### Webhook & Event Management
- [ ] **WebhookListener** (`app/listeners/webhook_listener.rb`)
  - [ ] **Session-based webhook prevention for webwidget_triggered events**
  - [ ] **Redis-based session tracking (30-minute duration)**
  - [ ] **Prevents duplicate webhooks during page navigation**
  - [ ] **Automatic session cleanup on conversation resolution**
  - [ ] **Graceful degradation when Redis is unavailable**

- [ ] **AgentBotListener** (`app/listeners/agent_bot_listener.rb`)
  - [ ] **Session-based event prevention for webwidget_triggered events**
  - [ ] **Consistent session management with webhook listener**
  - [ ] **Prevents duplicate agent bot events during navigation**

## 🎨 Frontend Implementation Checklist

### Core Widget Files
- [ ] **App.vue** (`app/javascript/widget/App.vue`)
  - [ ] Visitor tracking initialization with `initializeVisitorTracking()`
  - [ ] Page navigation handling and state preservation
  - [ ] Conversation token extraction from URL parameters
  - [ ] Enhanced error handling in mounted() lifecycle
  - [ ] Fixed ES6 import statements (no Node.js require)
  - [ ] Page info updates and tracking
  - [ ] **REMOVED unnecessary fetchOldConversations() calls during navigation**
  - [ ] **Enhanced ensureConversationPersistence() to check state only**
  - [ ] **Eliminated potential API side effects during page navigation**
  - [ ] **Added comprehensive debug logging for navigation events**
  - [ ] **Enhanced ON_AGENT_MESSAGE_RECEIVED handler to prevent setUserLastSeen calls for n8n messages**

- [ ] **Utils Helper** (`app/javascript/widget/helpers/utils.js`)
  - [ ] Stable browser fingerprinting system with `generateVisitorId()`
  - [ ] `getVisitorId()` for consistent visitor identification
  - [ ] Cross-page tracking maintains visitor identity
  - [ ] Page info collection utilities

### Store Management
- [ ] **Conversation Actions** (`app/javascript/widget/store/modules/conversation/actions.js`)
  - [ ] Enhanced `sendMessageWithData` with NO_CONVERSATION error handling
  - [ ] `resolveConversation` and `startNewConversation` with visitor data cleanup
  - [ ] Proper temporary message replacement logic
  - [ ] Visitor tracking integration
  - [ ] Enhanced persistence across navigation
  - [ ] **Conversation creation safeguards to prevent multiple calls**
  - [ ] **AUTOMATIC conversation existence marking in sessionStorage**
  - [ ] **Conversation state tracking on creation AND fetch operations**
  - [ ] **Complete session cleanup on conversation resolution**
  - [ ] **Webhook session flag management for proper lifecycle**
  - [ ] **Reverted auto-conversation creation after resolution (back to original behavior)**

- [ ] **Conversation Mutations** (`app/javascript/widget/store/modules/conversation/mutations.js`)
  - [ ] `setConversationCookie` mutation
  - [ ] `replaceTemporaryMessage` for proper message handling
  - [ ] Clean logging without excessive debug output

- [ ] **AppConfig Store** (`app/javascript/widget/store/modules/appConfig.js`)
  - [ ] Complete page info state management
  - [ ] `updatePageInfo` action
  - [ ] `SET_PAGE_INFO` mutation

### API Integration
- [ ] **Conversation API** (`app/javascript/widget/api/conversation.js`)
  - [ ] Fixed API endpoints (correct `/api/v1/widget/messages` path)
  - [ ] Enhanced all API methods with visitor ID headers
  - [ ] Page info tracking in all requests
  - [ ] Consistent URL building using `buildSearchParamsWithLocale()`
  - [ ] Proper timestamp format (Unix timestamps)
  - [ ] **Strictly ensure `X-Visitor-ID` header is present on `POST /api/v1/widget/conversations` (conversation creation call)**

- [ ] **EndPoints Helper** (`app/javascript/widget/api/endPoints.js`)
  - [ ] Complete visitor ID integration
  - [ ] All endpoints include visitor ID headers
  - [ ] Page info tracking
  - [ ] Consistent URL construction patterns

- [ ] **Axios Configuration** (`app/javascript/widget/helpers/axios.js`)
  - [ ] Fixed `setHeader` and `clearHeader` implementations
  - [ ] Enhanced request/response interceptors
  - [ ] Visitor ID header injection
  - [ ] Conversation token handling
  - [ ] Clean logging with essential error reporting only
  - [ ] **Fixed conversation ID logging to avoid confusion between contact IDs and conversation IDs**

### ActionCable & Real-time Features
- [ ] **ActionCable Helper** (`app/javascript/widget/helpers/actionCable.js`)
  - [ ] Fixed event emission logic (only emit `ON_AGENT_MESSAGE_RECEIVED` for agent messages)
  - [ ] Proper message type classification (user messages = INCOMING, agent messages = OUTGOING)
  - [ ] Enhanced message processing with conversation validation
  - [ ] Real-time message display without duplicates

### Session & Webhook Management
- [ ] **IFrameHelper** (`app/javascript/sdk/IFrameHelper.js`)
  - [ ] **COMPREHENSIVE webhook prevention with dual-condition logic**
  - [ ] **Only send webwidget.triggered when: (1) Not sent in session AND (2) No conversation exists**
  - [ ] **SessionStorage tracking for conversation existence state**
  - [ ] **Helper methods for conversation state management**
  - [ ] **Enhanced session tracking with visual debugging**
  - [ ] **Prevents ALL duplicate webhooks during page navigation**
  - [ ] **Conversation state clearing on resolution for new webhook cycles**

## 🧪 Testing & Quality Assurance Checklist

### Test Coverage
- [ ] **Updated Conversation Flow Tests** (`tests/conversation_flow.test.js`)
  - [ ] Test webhook prevention during page navigation
  - [ ] Verify session-based webhook deduplication
  - [ ] Test conversation persistence with webhook prevention
  - [ ] Validate session cleanup on conversation resolution

- [ ] **Updated User Requirements Tests** (`app/javascript/widget/specs/user_requirements_test.spec.js`)
  - [ ] Test complete user journey with webhook prevention
  - [ ] Verify no duplicate webhooks during navigation
  - [ ] Test conversation resolution and session cleanup

- [ ] **Persistence Debug Tests** (`app/javascript/widget/conversation_persistence_debug.test.js`)
  - [ ] Visitor ID generation and persistence testing
  - [ ] Conversation flow simulation
  - [ ] API request structure validation
  - [ ] Page navigation simulation

### Quality Gates
- [ ] **Updated Testing Process**
  - [ ] Run updated tests with webhook prevention scenarios
  - [ ] All test suites must pass with new webhook logic
  - [ ] Verify webhook prevention doesn't break existing functionality
  - [ ] Test Redis session management edge cases

### Error Handling & Resilience
- [ ] **Backend Stability**
  - [ ] All widget endpoints return proper responses (no 500 errors)
  - [ ] Redis fault tolerance with graceful degradation
  - [ ] Comprehensive error logging without breaking functionality
  - [ ] Safe parameter handling with fallbacks
  - [ ] **Fixed conversation lookup issues that caused "0 conversations found" errors**
  - [ ] **Enhanced auth token handling for new visitors without tokens**
  - [ ] **Fixed WebWidget inbox access to prevent NoMethodError**
  - [ ] **Enhanced conversation token generation with comprehensive validation**
  - [ ] **Webhook prevention graceful degradation when Redis fails**

- [ ] **Frontend Stability**
  - [ ] Widget initializes without runtime errors
  - [ ] Proper error handling for API failures
  - [ ] Graceful fallback when Redis is unavailable
  - [ ] Clean console output with essential logging only
  - [ ] **Improved API response logging to avoid confusion**
  - [ ] **Fixed duplicate messages in chat widget**
  - [ ] **Proper message flow without redundant commits**
  - [ ] **Conversation creation safeguards prevent multiple calls**

## 🔄 User Journey Validation Checklist

### New User Experience
- [ ] **First Visit with Webhook Prevention**
  - [ ] User opens widget → Visitor ID generated → Conversation created
  - [ ] Conversation stored in Redis + sessionStorage
  - [ ] **"Live chat widget opened" webhook fires to n8n ONCE per session**
  - [ ] User can send messages immediately
  - [ ] Messages appear in real-time without duplicates

### Cross-Page Navigation with Webhook Prevention
- [ ] **Page Navigation**
  - [ ] User navigates to new page → Conversation persists
  - [ ] **NO duplicate webhooks fired during navigation**
  - [ ] **Session tracking prevents multiple webwidget_triggered events**
  - [ ] Conversation state maintained across Shopify theme changes
  - [ ] Messages remain visible and properly ordered
  - [ ] User can continue sending messages seamlessly

### Message Interaction
- [ ] **Message Sending**
  - [ ] User messages appear immediately in chat UI
  - [ ] Proper message type classification (user = INCOMING, agent = OUTGOING)
  - [ ] No duplicate pending messages
  - [ ] Temporary messages properly replaced with server confirmations
  - [ ] ActionCable events only fire for appropriate message types
  - [ ] **Fixed duplicate messages when creating new conversations**
  - [ ] **Proper message flow: backend includes initial message, frontend relies on updates**
  - [ ] **Enhanced conversation creation with message inclusion**

### Conversation Resolution with Session Cleanup
- [ ] **End Conversation**
  - [ ] User clicks "End Conversation" → Conversation resolves
  - [ ] Redis mappings cleaned up automatically
  - [ ] **Session tracking reset for next conversation**
  - [ ] **Webhook session keys cleared for next chat**
  - [ ] End Conversation button remains visible for new conversations
  - [ ] Next widget opening creates new conversation with webhook

### Webhook Lifecycle Validation
- [ ] **Complete Webhook Flow**
  - [ ] **First chat open** → webwidget_triggered webhook sent → New conversation
  - [ ] **Page navigation** → NO webhook sent → Same conversation maintained
  - [ ] **Continue chatting** → Message webhooks only → No conversation webhooks
  - [ ] **End conversation** → conversation_resolved webhook → Session cleared
  - [ ] **Next chat session** → webwidget_triggered webhook sent → New conversation

### Incognito & Edge Cases
- [ ] **Incognito Mode**
  - [ ] Full functionality without cookies
  - [ ] Redis provides persistence across navigation
  - [ ] Visitor ID generation works consistently
  - [ ] All features work as expected

- [ ] **Error Scenarios with Webhook Prevention**
  - [ ] Redis unavailable → Graceful degradation → Webhooks still work
  - [ ] Network issues → Proper error handling
  - [ ] Invalid tokens → Automatic cleanup and recovery
  - [ ] Stale mappings → Automatic validation and cleanup
  - [ ] **Missing auth tokens → Graceful handling for new visitors**
  - [ ] **Conversation lookup failures → Proper error responses**
  - [ ] **Session key conflicts → Proper Redis key management**

## 🚀 Deployment & Production Checklist

### Build & Deployment
- [ ] **Frontend Build**
  - [ ] All ES6 imports properly configured
  - [ ] No Node.js require statements in browser code
  - [ ] Vite build process completes successfully
  - [ ] All assets properly compiled and served

- [ ] **Backend Deployment**
  - [ ] Redis/Valkey service properly configured
  - [ ] Environment variables set correctly
  - [ ] Database migrations applied
  - [ ] All dependencies installed

### Production Validation
- [ ] **Functionality Testing with Webhook Prevention**
  - [ ] Widget loads and initializes without errors
  - [ ] All API endpoints respond correctly
  - [ ] Conversation persistence works across navigation
  - [ ] **Webhooks fire correctly for n8n integration WITHOUT duplicates**
  - [ ] Message sending and receiving works properly
  - [ ] **Session-based webhook prevention works in production**

- [ ] **Performance & Monitoring**
  - [ ] Clean console output with minimal logging
  - [ ] No memory leaks or performance issues
  - [ ] Redis operations perform efficiently
  - [ ] Error monitoring and alerting configured
  - [ ] **Webhook session tracking performs efficiently**

## 📋 Maintenance & Monitoring Checklist

### Ongoing Monitoring
- [ ] **System Health with Webhook Prevention**
  - [ ] Redis/Valkey connectivity and performance
  - [ ] Widget initialization success rate
  - [ ] API endpoint response times and error rates
  - [ ] **Webhook delivery success rate WITHOUT duplicates**
  - [ ] **Session tracking Redis key management**

- [ ] **User Experience**
  - [ ] Conversation persistence success rate
  - [ ] Message delivery and display accuracy
  - [ ] Cross-page navigation seamlessness
  - [ ] Error handling effectiveness
  - [ ] **Webhook prevention effectiveness (no duplicate n8n conversations)**

- [ ] **Debugging & Troubleshooting**
  - [ ] **Comprehensive conversation token generation logging**
  - [ ] **Enhanced Redis mapping validation and debugging**
  - [ ] **Detailed conversation creation flow logging**
  - [ ] **Token generation failure detection and reporting**
  - [ ] **Conversation ID consistency tracking**
  - [ ] **Webhook session tracking logging**

### Documentation & Knowledge Transfer
- [ ] **Technical Documentation**
  - [ ] All changes documented in project context
  - [ ] API changes and new endpoints documented
  - [ ] Redis schema and data flow documented
  - [ ] Error handling and troubleshooting guides
  - [ ] **Webhook prevention implementation documented**

- [ ] **Operational Documentation**
  - [ ] Deployment procedures updated
  - [ ] Monitoring and alerting configured
  - [ ] Troubleshooting runbooks created
  - [ ] Performance optimization guidelines
  - [ ] **Webhook session management procedures**
k Prevention**: Session-based deduplication prevents spam
