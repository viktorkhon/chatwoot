# n8n Integration with Local Chatwoot Development

This guide shows how to integrate n8n with your local Chatwoot development environment for automated messaging and webhook workflows.

## 🔗 Step 1: Expose Local Server to Internet

Choose one method to make your local development server accessible to n8n:

### Option A: ngrok (Recommended)
```bash
# Download from https://ngrok.com/download
ngrok http 3000
# Result: https://abc123.ngrok.io -> localhost:3000
```

### Option B: Cloudflare Tunnel (Free)
```bash
npx cloudflared tunnel --url localhost:3000
# Result: https://xyz.trycloudflare.com -> localhost:3000
```

### Option C: LocalTunnel
```bash
npx localtunnel --port 3000
# Result: https://xyz.loca.lt -> localhost:3000
```

## 📡 Step 2: Chatwoot Webhook Configuration

### Available Webhook Endpoints

Your local Chatwoot provides these webhook endpoints:

#### 1. **Account Webhooks** (Main ones for n8n)
```
POST https://your-tunnel-url.com/api/v1/accounts/{account_id}/webhooks
GET  https://your-tunnel-url.com/api/v1/accounts/{account_id}/webhooks
PUT  https://your-tunnel-url.com/api/v1/accounts/{account_id}/webhooks/{id}
DEL  https://your-tunnel-url.com/api/v1/accounts/{account_id}/webhooks/{id}
```

#### 2. **Integration Webhooks**
```
POST https://your-tunnel-url.com/api/v1/integrations/webhooks
```

#### 3. **Channel-Specific Webhooks**
```
POST https://your-tunnel-url.com/webhooks/telegram/{bot_token}
POST https://your-tunnel-url.com/webhooks/whatsapp/{phone_number}
POST https://your-tunnel-url.com/webhooks/line/{line_channel_id}
POST https://your-tunnel-url.com/webhooks/sms/{phone_number}
```

## 🔧 Step 3: Create Webhook in Chatwoot

### Method 1: Via Rails Console
```ruby
# In your Rails console (docker-compose -f docker-compose.dev.yaml exec rails bundle exec rails console)

# Get your account
account = Account.find(2)  # Replace 2 with your account_id

# Create webhook pointing to n8n
webhook = account.webhooks.create!(
  url: 'https://your-n8n-webhook-url.com/webhook/chatwoot',
  subscriptions: [
    'conversation_created',
    'conversation_updated', 
    'message_created',
    'message_updated'
  ]
)

puts "✅ Webhook created: #{webhook.id}"
puts "URL: #{webhook.url}"
puts "Subscriptions: #{webhook.subscriptions}"
```

### Method 2: Via API (Postman/curl)
```bash
curl -X POST https://your-tunnel-url.com/api/v1/accounts/2/webhooks \
  -H "Content-Type: application/json" \
  -H "api_access_token: YOUR_API_TOKEN" \
  -d '{
    "webhook": {
      "url": "https://your-n8n-webhook-url.com/webhook/chatwoot",
      "subscriptions": ["message_created", "conversation_created"]
    }
  }'
```

## 🤖 Step 4: n8n Workflow Configuration

### 1. **Receive Chatwoot Events (Webhook Trigger)**

Create an n8n workflow with:
- **Trigger**: Webhook node
- **URL**: `https://your-n8n-instance.com/webhook/chatwoot`
- **Expected events**: message_created, conversation_created, etc.

### 2. **Send Messages to Chatwoot (HTTP Request)**

Configure HTTP Request node:
```json
{
  "method": "POST",
  "url": "https://your-tunnel-url.com/api/v1/accounts/2/conversations/{{conversation_id}}/messages",
  "headers": {
    "Content-Type": "application/json",
    "api_access_token": "YOUR_API_TOKEN"
  },
  "body": {
    "content": "Your automated response message",
    "message_type": "outgoing",
    "private": false
  }
}
```

## 🔑 Step 5: Get API Access Token

### Method 1: Via Rails Console
```ruby
# Create API access token for n8n
account = Account.find(2)
user = account.users.first

# Create access token
access_token = user.access_token
puts "API Access Token: #{access_token.token}"
```

### Method 2: Via Chatwoot UI
1. Login to http://localhost:3000
2. Go to Settings → Integrations → API Access Tokens
3. Create new token
4. Copy token for n8n use

## 📨 Common API Endpoints for n8n

### Send Message
```
POST /api/v1/accounts/{account_id}/conversations/{conversation_id}/messages
Body: {
  "content": "Hello from n8n!",
  "message_type": "outgoing"
}
```

### Create Contact
```
POST /api/v1/accounts/{account_id}/contacts
Body: {
  "name": "John Doe",
  "email": "john@example.com",
  "phone_number": "+1234567890"
}
```

### Update Conversation Status
```
PATCH /api/v1/accounts/{account_id}/conversations/{conversation_id}
Body: {
  "status": "resolved"
}
```

### Assign Conversation
```
PATCH /api/v1/accounts/{account_id}/conversations/{conversation_id}/assignments
Body: {
  "assignee_id": 1
}
```

## 🧪 Testing Your Integration

### 1. **Test Webhook Reception**
1. Send a message via your widget on CodePen
2. Check n8n webhook logs for received event
3. Verify conversation and message data

### 2. **Test Message Sending**
1. Create n8n workflow to send message
2. Trigger workflow manually
3. Check message appears in Chatwoot conversation

### 3. **End-to-End Test**
1. Customer sends message via widget
2. n8n receives webhook event
3. n8n processes and sends automated response
4. Customer sees response in widget

## 🔄 Sample n8n Workflow JSON

```json
{
  "nodes": [
    {
      "name": "Webhook",
      "type": "n8n-nodes-base.webhook",
      "parameters": {
        "path": "chatwoot",
        "responseMode": "responseNode"
      }
    },
    {
      "name": "Filter Messages",
      "type": "n8n-nodes-base.if",
      "parameters": {
        "conditions": {
          "string": [
            {
              "value1": "={{$node[\"Webhook\"].json[\"event\"]}}", 
              "value2": "message_created"
            }
          ]
        }
      }
    },
    {
      "name": "Send Response",
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "url": "https://your-tunnel-url.com/api/v1/accounts/2/conversations/{{$node[\"Webhook\"].json[\"conversation\"][\"id\"]}}/messages",
        "method": "POST",
        "headers": {
          "api_access_token": "YOUR_API_TOKEN"
        },
        "body": {
          "content": "Thanks for your message! An agent will respond shortly.",
          "message_type": "outgoing"
        }
      }
    }
  ]
}
```

## 🚨 Important Notes

- **Development Only**: This setup is for development/testing only
- **Tunnel Stability**: Free tunnel services may disconnect; consider paid options for longer sessions
- **API Rate Limits**: Be mindful of API rate limits in your workflows
- **Security**: Don't expose production credentials; use development tokens only

## 🎯 Quick Start Checklist

- [ ] Start your local Chatwoot: `.\scripts\dev-setup.ps1 start`
- [ ] Expose via tunnel: `ngrok http 3000` or `npx cloudflared tunnel --url localhost:3000`
- [ ] Get your public URL (e.g., https://abc123.ngrok.io)
- [ ] Create webhook in Chatwoot pointing to n8n
- [ ] Get API access token from Chatwoot
- [ ] Configure n8n workflow with your tunnel URL
- [ ] Test end-to-end: Widget → Chatwoot → n8n → Response

Your local development environment is now ready for n8n integration! 🎉 