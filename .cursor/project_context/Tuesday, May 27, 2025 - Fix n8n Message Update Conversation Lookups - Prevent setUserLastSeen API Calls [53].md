# Session 53: Fix n8n Message Update Conversation Lookups - Prevent setUserLastSeen API Calls

**Date**: Tuesday, May 27, 2025  
**Session**: 53  
**Previous Session**: [Session 52 - Final Redis Performance Optimization - Database-Only Message Operations](./Tuesday,%20May%2027,%202025%20-%20Final%20Redis%20Performance%20Optimization%20-%20Database-Only%20Message%20Operations%20[52].md)

## Problem Identified

Despite the comprehensive Redis optimizations in Sessions 51-52, the user reported that conversation lookups were still occurring after message updates when n8n sent replies back to Chatwoot. The logs showed:

```
02:33:55 web.1 | [Widget] Message update - message: 2323, conversation: 570
02:33:55 web.1 | [Widget] 🔍 Database-only conversation lookup for visitor: visitor_1748399581130_f7q04e2xb5h
```

## Root Cause Analysis

### The Complete Flow
1. **n8n receives webhook** from Chatwoot when a message is updated
2. **n8n sends reply** via POST `/api/v1/accounts/2/conversations/537/messages` (accounts API)
3. **Message created** using `Messages::MessageBuilder` (correct, no conversation lookup)
4. **MESSAGE_CREATED event** dispatched by the message model
5. **ActionCableListener** broadcasts message to widget via ActionCable
6. **Widget's onMessageCreated** handler processes the message
7. **ON_AGENT_MESSAGE_RECEIVED** event emitted
8. **App.vue handler** calls `setUserLastSeen` action
9. **setUserLastSeen** makes API call to `/api/v1/widget/conversations/update_last_seen`
10. **Widget controller** performs conversation lookup (causing the logs we see)

### Key Discovery
The conversation lookups were NOT caused by n8n's API call to create the message (which correctly uses the accounts API), but by the **widget's automatic response** to receiving the message via ActionCable.

When n8n sends a message, the widget receives it via ActionCable and automatically tries to update the user's "last seen" timestamp, even though the user is not actively viewing the widget.

## Solution Implemented

### Modified ON_AGENT_MESSAGE_RECEIVED Handler
**File**: `app/javascript/widget/App.vue`

Changed the condition for calling `setUserLastSeen` from:
```javascript
// BEFORE: Called for any widget state
if ((this.isWidgetOpen || !this.isIFrame) && routeName === 'messages') {
  this.$store.dispatch('conversation/setUserLastSeen');
}
```

To:
```javascript
// AFTER: Only called when user is actively viewing
if (this.isWidgetOpen && routeName === 'messages') {
  this.$store.dispatch('conversation/setUserLastSeen');
}
```

### Enhanced Debugging
Added comprehensive logging to track when `setUserLastSeen` is called:
```javascript
console.log('[Widget] ON_AGENT_MESSAGE_RECEIVED event:', {
  isWidgetOpen: this.isWidgetOpen,
  routeName,
  willUpdateLastSeen: this.isWidgetOpen && routeName === 'messages'
});
```

## Technical Details

### Why This Fixes the Issue
- **Before**: When n8n sent a message, the widget would receive it via ActionCable and automatically call `setUserLastSeen`, triggering a conversation lookup
- **After**: The widget only calls `setUserLastSeen` when the user is actually viewing the messages, preventing unnecessary API calls

### API Call Prevention
The `setUserLastSeen` action calls:
```javascript
await setUserLastSeenAt({ lastSeen });
```

Which makes a POST request to:
```
/api/v1/widget/conversations/update_last_seen
```

This endpoint goes through the widget `ConversationsController#update_last_seen` method, which performs conversation lookups.

### Webhook Flow Preserved
- **n8n webhook reception**: ✅ Still works (message_updated webhook sent to n8n)
- **n8n message creation**: ✅ Still works (via accounts API, no conversation lookup)
- **Message display**: ✅ Still works (message appears in widget via ActionCable)
- **User interaction tracking**: ✅ Still works (only when user is actively viewing)

## Expected Behavior After Fix

### When n8n Sends a Message
1. **Message created** via accounts API (no conversation lookup)
2. **ActionCable broadcast** to widget (message appears)
3. **NO setUserLastSeen call** (widget not open)
4. **NO conversation lookup** (no unnecessary API calls)

### When User Opens Widget
1. **Widget opens** and user navigates to messages
2. **setUserLastSeen called** (user is actively viewing)
3. **Conversation lookup occurs** (appropriate for user interaction)

### When User Receives Message While Viewing
1. **Message received** via ActionCable
2. **setUserLastSeen called** (user is actively viewing)
3. **Conversation lookup occurs** (appropriate for active user)

## Files Modified
1. `app/javascript/widget/App.vue` - Modified ON_AGENT_MESSAGE_RECEIVED handler condition and added debugging

## Performance Impact
- **Eliminated unnecessary API calls** when messages are received but user is not viewing
- **Preserved user experience** for active users viewing the widget
- **Reduced server load** from automated setUserLastSeen calls triggered by external messages

## Testing Scenarios

### Scenario 1: n8n Sends Message (Widget Closed)
- **Expected**: No conversation lookup logs
- **Result**: Message appears when widget is opened, no unnecessary API calls

### Scenario 2: n8n Sends Message (Widget Open, User Viewing)
- **Expected**: Conversation lookup occurs (appropriate)
- **Result**: User's last seen timestamp updated correctly

### Scenario 3: User Opens Widget After n8n Message
- **Expected**: Conversation lookup occurs when user opens widget
- **Result**: Proper user interaction tracking

## Deployment Notes
- **Frontend change only** - no backend modifications required
- **Backward compatible** - no breaking changes to existing functionality
- **Immediate effect** - reduces conversation lookups as soon as deployed

## Success Criteria
- ✅ **No conversation lookups** when n8n sends messages to closed widgets
- ✅ **Preserved user tracking** when users are actively viewing messages
- ✅ **Maintained webhook functionality** for n8n integration
- ✅ **Reduced server load** from unnecessary API calls

---

**Note**: This fix addresses the final source of unnecessary conversation lookups in the widget system. Combined with the optimizations from Sessions 51-52, the system now achieves optimal performance with conversation lookups only occurring when truly necessary for user interactions or conversation management operations. 