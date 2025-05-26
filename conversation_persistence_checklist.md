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

- [ ] **ConversationsController** (`app/controllers/api/v1/widget/conversations_controller.rb`)
  - [ ] Webhook prevention logic to avoid duplicates
  - [ ] Redis mapping management and cleanup
  - [ ] Enhanced error handling for conversation creation
  - [ ] Detailed logging for debugging conversation issues
  - [ ] Toggle typing endpoint fixes (removed from before_action filter)

- [ ] **MessagesController** (`app/controllers/api/v1/widget/messages_controller.rb`)
  - [ ] Modified `set_conversation` to return error instead of creating new conversations
  - [ ] Enhanced logging for message creation flow
  - [ ] Safe navigation in `message_params` method
  - [ ] Proper error handling for NO_CONVERSATION scenarios

### Model Updates
- [ ] **Conversation Model** (`app/models/conversation.rb`)
  - [ ] `cleanup_redis_mappings_on_resolution()` callback
  - [ ] Automatic cleanup of Redis mappings when conversations are resolved
  - [ ] Enhanced webhook data with page information
  - [ ] Timestamp standardization for ActionCable events

- [ ] **Message Model** (`app/models/message.rb`)
  - [ ] Fixed `dispatch_update_event` timestamp conversion
  - [ ] Consistent Unix timestamp format in ActionCable broadcasts

### Helper Enhancements
- [ ] **WebsiteTokenHelper** (`app/controllers/concerns/website_token_helper.rb`)
  - [ ] Enhanced with visitor ID support
  - [ ] Redis fallback contact lookup
  - [ ] Improved contact creation logic
  - [ ] Better error handling and logging

## 🎨 Frontend Implementation Checklist

### Core Widget Files
- [ ] **App.vue** (`app/javascript/widget/App.vue`)
  - [ ] Visitor tracking initialization with `initializeVisitorTracking()`
  - [ ] Page navigation handling and state preservation
  - [ ] Conversation token extraction from URL parameters
  - [ ] Enhanced error handling in mounted() lifecycle
  - [ ] Fixed ES6 import statements (no Node.js require)
  - [ ] Page info updates and tracking

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

### ActionCable & Real-time Features
- [ ] **ActionCable Helper** (`app/javascript/widget/helpers/actionCable.js`)
  - [ ] Fixed event emission logic (only emit `ON_AGENT_MESSAGE_RECEIVED` for agent messages)
  - [ ] Proper message type classification (user messages = INCOMING, agent messages = OUTGOING)
  - [ ] Enhanced message processing with conversation validation
  - [ ] Real-time message display without duplicates

### Session & Webhook Management
- [ ] **IFrameHelper** (`app/javascript/sdk/IFrameHelper.js`)
  - [ ] Session-based webhook prevention
  - [ ] Smart conversation detection and routing
  - [ ] Enhanced session tracking with visual debugging
  - [ ] Prevents duplicate "widget opened" webhooks during navigation

## 🧪 Testing & Quality Assurance Checklist

### Test Coverage
- [ ] **Conversation Flow Tests** (`tests/conversation_flow.test.js`)
  - [ ] 45/45 tests passing
  - [ ] Complete coverage of persistence scenarios
  - [ ] Webhook prevention testing
  - [ ] Message handling and visibility tests
  - [ ] Duplicate message prevention tests
  - [ ] ActionCable event testing

- [ ] **User Requirements Tests** (`app/javascript/widget/specs/user_requirements_test.spec.js`)
  - [ ] 38/38 tests passing
  - [ ] Full coverage of user journey scenarios
  - [ ] Integration testing
  - [ ] Error resilience testing
  - [ ] API endpoint stability tests

- [ ] **Persistence Debug Tests** (`app/javascript/widget/conversation_persistence_debug.test.js`)
  - [ ] Visitor ID generation and persistence testing
  - [ ] Conversation flow simulation
  - [ ] API request structure validation
  - [ ] Page navigation simulation

### Quality Gates
- [ ] **Mandatory Testing Process**
  - [ ] Run tests before every change
  - [ ] All test suites must pass before deployment
  - [ ] Fix failing tests by either fixing code or updating tests
  - [ ] Iterate until all test scripts pass
  - [ ] No commits or deployments until ALL tests pass

### Error Handling & Resilience
- [ ] **Backend Stability**
  - [ ] All widget endpoints return proper responses (no 500 errors)
  - [ ] Redis fault tolerance with graceful degradation
  - [ ] Comprehensive error logging without breaking functionality
  - [ ] Safe parameter handling with fallbacks

- [ ] **Frontend Stability**
  - [ ] Widget initializes without runtime errors
  - [ ] Proper error handling for API failures
  - [ ] Graceful fallback when Redis is unavailable
  - [ ] Clean console output with essential logging only

## 🔄 User Journey Validation Checklist

### New User Experience
- [ ] **First Visit**
  - [ ] User opens widget → Visitor ID generated → Conversation created
  - [ ] Conversation stored in Redis + sessionStorage
  - [ ] "Live chat widget opened" webhook fires to n8n (once per session)
  - [ ] User can send messages immediately
  - [ ] Messages appear in real-time without duplicates

### Cross-Page Navigation
- [ ] **Page Navigation**
  - [ ] User navigates to new page → Conversation persists
  - [ ] No duplicate webhooks fired during navigation
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

### Conversation Resolution
- [ ] **End Conversation**
  - [ ] User clicks "End Conversation" → Conversation resolves
  - [ ] Redis mappings cleaned up automatically
  - [ ] Session tracking reset for next conversation
  - [ ] End Conversation button remains visible for new conversations
  - [ ] Next widget opening creates new conversation with webhook

### Incognito & Edge Cases
- [ ] **Incognito Mode**
  - [ ] Full functionality without cookies
  - [ ] Redis provides persistence across navigation
  - [ ] Visitor ID generation works consistently
  - [ ] All features work as expected

- [ ] **Error Scenarios**
  - [ ] Redis unavailable → Graceful degradation
  - [ ] Network issues → Proper error handling
  - [ ] Invalid tokens → Automatic cleanup and recovery
  - [ ] Stale mappings → Automatic validation and cleanup

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
- [ ] **Functionality Testing**
  - [ ] Widget loads and initializes without errors
  - [ ] All API endpoints respond correctly
  - [ ] Conversation persistence works across navigation
  - [ ] Webhooks fire correctly for n8n integration
  - [ ] Message sending and receiving works properly

- [ ] **Performance & Monitoring**
  - [ ] Clean console output with minimal logging
  - [ ] No memory leaks or performance issues
  - [ ] Redis operations perform efficiently
  - [ ] Error monitoring and alerting configured

## 📋 Maintenance & Monitoring Checklist

### Ongoing Monitoring
- [ ] **System Health**
  - [ ] Redis/Valkey connectivity and performance
  - [ ] Widget initialization success rate
  - [ ] API endpoint response times and error rates
  - [ ] Webhook delivery success rate

- [ ] **User Experience**
  - [ ] Conversation persistence success rate
  - [ ] Message delivery and display accuracy
  - [ ] Cross-page navigation seamlessness
  - [ ] Error handling effectiveness

### Documentation & Knowledge Transfer
- [ ] **Technical Documentation**
  - [ ] All changes documented in project context
  - [ ] API changes and new endpoints documented
  - [ ] Redis schema and data flow documented
  - [ ] Error handling and troubleshooting guides

- [ ] **Operational Documentation**
  - [ ] Deployment procedures updated
  - [ ] Monitoring and alerting configured
  - [ ] Troubleshooting runbooks created
  - [ ] Performance optimization guidelines

## 🎯 Success Criteria

### Primary Goals Achieved
- ✅ **Single Conversation Per Session**: Users maintain one conversation throughout their session
- ✅ **Cross-Page Persistence**: Conversations persist during all types of navigation
- ✅ **Webhook Prevention**: No duplicate webhooks during navigation (saves n8n processing)
- ✅ **Message Functionality**: All message sending/receiving works properly
- ✅ **Incognito Support**: Full functionality without cookies using Redis
- ✅ **Production Ready**: Stable, tested, and monitored implementation

### Technical Excellence
- ✅ **Comprehensive Testing**: 45+ tests covering all scenarios
- ✅ **Error Resilience**: Graceful handling of all failure modes
- ✅ **Performance Optimized**: Efficient Redis usage and minimal overhead
- ✅ **Clean Implementation**: Well-documented, maintainable code
- ✅ **Backward Compatible**: No breaking changes to existing functionality

---

**Note**: This checklist represents the complete implementation of the conversation persistence feature across 33+ development sessions. All items should be verified and tested before considering the feature complete and production-ready. 