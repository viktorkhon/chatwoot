# Redis Configuration in Chatwoot

This document covers Redis configuration settings used in Chatwoot.

## Keyspace Notifications

Chatwoot uses Redis keyspace notifications for tracking expired events. This is configured in the `lib/redis/config.rb` file.

### Configuration

By default, Chatwoot enables keyspace notifications for expired events (`Ex`). This is controlled by the `REDIS_KEYSPACE_NOTIFICATIONS` environment variable.

```ruby
# In lib/redis/config.rb
keyspace_notifications: ENV.fetch('REDIS_KEYSPACE_NOTIFICATIONS', 'Ex')
```

### Setting up in your environment

If you're using Valkey (or Redis), ensure your configuration has keyspace notifications enabled for expired events:

1. In your `valkey.conf` (or `redis.conf`), add or set:
   ```
   notify-keyspace-events Ex
   ```

2. If you're using environment variables, you can set:
   ```
   REDIS_KEYSPACE_NOTIFICATIONS=Ex
   ```

3. Make sure to restart your Redis/Valkey instance after changing configurations.

### Available Notification Options

Redis keyspace notification options:
- `K` - Keyspace events, published with `__keyspace@<db>__` prefix
- `E` - Keyevent events, published with `__keyevent@<db>__` prefix
- `g` - Generic commands (non-type specific) like DEL, EXPIRE, etc.
- `$` - String commands
- `l` - List commands
- `s` - Set commands
- `h` - Hash commands
- `z` - Sorted set commands
- `t` - Stream commands
- `d` - Module key type events
- `x` - Expired events (events generated when a key expires)
- `e` - Evicted events (events generated when a key is evicted for maxmemory)
- `m` - Key miss events (events generated when a key that doesn't exist is accessed)
- `A` - Alias for "g$lshztxed", all the commands

For detailed information, refer to [Redis Keyspace Notifications documentation](https://redis.io/docs/manual/keyspace-notifications/).

### Using Keyspace Notifications

When a key expires, Redis will publish a message to the `__keyevent@<db>__:expired` channel. You can subscribe to this channel to receive notifications when keys expire. 