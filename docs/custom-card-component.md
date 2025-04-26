# Custom Card Component

A flexible and powerful card component for Chatwoot that supports rich markdown formatting, images, and interactive actions.

## Features

- Rich markdown support for text formatting
- Image display
- Interactive buttons with link and postback actions
- Dark mode support
- Responsive design
- Custom styling options

## API Endpoints

### Create Custom Card
```http
POST /api/v1/accounts/{account_id}/conversations/{conversation_id}/custom_cards
```

### Update Custom Card
```http
PATCH /api/v1/accounts/{account_id}/conversations/{conversation_id}/custom_cards/{custom_card_id}
```

### Delete Custom Card
```http
DELETE /api/v1/accounts/{account_id}/conversations/{conversation_id}/custom_cards/{custom_card_id}
```

## Request Structure

### Required Fields
- `title` (string): Card title (supports markdown)
- `description` (string): Card description (supports markdown)

### Optional Fields
- `image_url` (string): URL for the card's image
- `price` (string): Price or cost information (supports markdown)
- `actions` (array): Array of action buttons
- `supports_markdown` (boolean): Enable/disable markdown support (default: true)
- `private` (boolean): Mark message as private (default: false)

### Action Object Structure
```typescript
{
  type: "link" | "postback",  // Required
  text: string,              // Required
  uri?: string,              // Required for type="link"
  payload?: string           // Required for type="postback"
}
```

## Markdown Support

The component supports the following markdown features:

- Headers (h1-h3)
- Bold and italic text
- Lists (ordered and unordered)
- Code blocks and inline code
- Blockquotes
- Links
- Paragraphs
- Line breaks

## Example Usage

### Basic Card
```json
{
  "custom_cards": [
    {
      "title": "Welcome Message",
      "description": "Hello! How can I help you today?",
      "price": "**Starting at** $99/month",
      "actions": [
        {
          "type": "postback",
          "text": "Get Started",
          "payload": "start_conversation"
        }
      ]
    }
  ]
}
```

### Rich Card with Markdown
```json
{
  "custom_cards": [
    {
      "title": "## Product Information",
      "description": "### Features\n\n- **Real-time** chat support\n- *Customizable* interface\n- Secure data handling\n\n```javascript\nconst features = ['chat', 'customization', 'security'];\n```\n\n> Contact us for more information",
      "price": "### Pricing\n\n- **Basic**: $99/month\n- **Pro**: $199/month\n- **Enterprise**: *Contact us*\n\n> All prices are in USD",
      "image_url": "https://example.com/product.jpg",
      "actions": [
        {
          "type": "link",
          "text": "View Documentation",
          "uri": "https://docs.example.com"
        },
        {
          "type": "postback",
          "text": "Request Demo",
          "payload": "request_demo"
        }
      ]
    }
  ]
}
```

## Response Structure

Successful responses include:

```json
{
  "id": "string",
  "title": "string",
  "description": "string",
  "price": "string",
  "image_url": "string",
  "actions": [
    {
      "type": "string",
      "text": "string",
      "uri": "string",
      "payload": "string"
    }
  ],
  "supports_markdown": boolean,
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

## Error Handling

The API returns appropriate HTTP status codes:

- `200`: Success
- `400`: Bad Request (invalid data)
- `401`: Unauthorized
- `404`: Not Found
- `500`: Server Error

## Styling

The component uses Tailwind CSS classes and supports dark mode. Custom styles can be overridden using the following classes:

```scss
.card-container
.card
.card-media
.card-image
.card-content
.card-title
.card-description
.card-actions
.card-action-button
```

## Integration Example

```javascript
import { createCustomCard } from 'dashboard/api/customCard';

const createCard = async () => {
  try {
    const response = await createCustomCard({
      conversationId: '123',
      accountId: '456',
      customCards: [
        {
          title: 'Welcome',
          description: 'Hello!',
          actions: [
            {
              type: 'postback',
              text: 'Start',
              payload: 'start'
            }
          ]
        }
      ]
    });
    console.log('Card created:', response);
  } catch (error) {
    console.error('Error creating card:', error);
  }
};
```

## Security Considerations

1. Always validate user input before sending to the API
2. Sanitize markdown content to prevent XSS attacks
3. Use HTTPS for image URLs
4. Implement proper authentication for API access

## Browser Support

- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This component is part of the Chatwoot project and is licensed under the MIT License. 