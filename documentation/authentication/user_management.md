# Authentication and User Management

Chatwoot's authentication system is built on top of Devise and DeviseTokenAuth, providing a robust framework for user authentication, registration, and session management.

## Core Authentication Models

### User Model

**File**: `app/models/user.rb`

The `User` model is the central entity for authentication and contains the following key components:

- **Devise Modules**: Implements multiple authentication features through Devise
  ```ruby
  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :trackable,
         :validatable,
         :confirmable,
         :password_has_required_content,
         :omniauthable, omniauth_providers: [:google_oauth2]
  ```

- **User Types**: Different types of users (standard users and administrators)
- **Availability Status**: Tracks user availability with enum: `{ online: 0, offline: 1, busy: 2 }`
- **Account Associations**: Users can belong to multiple accounts through `account_users` join table
- **Token Authentication**: Integrated with DeviseTokenAuth for API authentication

### SuperAdmin Model

**File**: `app/controllers/super_admin/devise/sessions_controller.rb`

A separate authentication model for system administrators with elevated privileges:

- Manages the SuperAdmin login process
- Has a distinct authentication flow from regular users
- Provides access to system-wide administration features

## Authentication Flows

### Email/Password Authentication

1. **Registration**:
   - Users register via the registration form
   - A confirmation email is sent
   - User confirms email through confirmation link

2. **Login Process**:
   - Controller: `DeviseOverrides::SessionsController`
   - Handled via `POST` to `/auth/sign_in`
   - Returns authentication tokens for subsequent API requests

3. **Password Recovery**:
   - Controller: `DeviseOverrides::PasswordsController`
   - User requests password reset via email
   - System generates a reset token and sends a recovery email
   - User sets new password using the token

### OAuth Authentication (Google)

**Controller**: `DeviseOverrides::OmniauthCallbacksController`

1. User initiates OAuth flow via Google
2. On successful authentication, the system:
   - Finds existing user by email or creates a new account
   - Generates an SSO authentication token
   - Redirects to the login page with token for automatic login

3. Implementation details:
   ```ruby
   def sign_in_user
     @resource.skip_confirmation! if confirmable_enabled?
     encoded_email = ERB::Util.url_encode(@resource.email)
     redirect_to login_page_url(email: encoded_email, sso_auth_token: @resource.generate_sso_auth_token)
   end
   ```

### SSO Authentication

**Module**: `SsoAuthenticatable` (included in User model)

1. System generates temporary SSO tokens for third-party authentication
2. Tokens are validated during login process via `valid_sso_auth_token?` method
3. After successful authentication, tokens are invalidated for security

## Token Management

1. **Token Generation**:
   - Generated on successful authentication
   - Used for API access authentication

2. **Token Storage**:
   - Stored in the `tokens` JSON field in the User model
   - Client apps store tokens in local storage or secure storage

3. **Token Validation**:
   - Each API request includes authentication headers
   - `DeviseTokenAuth::Concerns::SetUserByToken` validates tokens
   - Current user set in `ApplicationController#set_current_user`

## Account Scoping and Authorization

1. **Multi-Account Support**:
   - Users can belong to multiple accounts
   - Current account determined by request context

2. **Role-Based Access**:
   - Access control through Pundit policies
   - Role information stored in AccountUser join model
   - `Current.user` and `Current.account` track the active context

3. **Authorization Implementation**:
   ```ruby
   def pundit_user
     {
       user: Current.user,
       account: Current.account,
       account_user: Current.account_user
     }
   }
   ```

## Email Confirmation Process

1. **Confirmation Controller**: `DeviseOverrides::ConfirmationsController`
2. **Flow**:
   - User receives email with confirmation token
   - User clicks link, sending token to confirmation controller
   - On successful confirmation, user account is activated

## Security Features

1. **Password Requirements**: 
   - Custom validator: `password_has_required_content`
   - Enforces password complexity requirements

2. **Session Management**:
   - Token rotation on each authentication
   - Configurable token lifespan
   - Session invalidation on password change

3. **Request Protection**:
   - CSRF protection for browser-based sessions
   - Rate limiting for authentication attempts

## API Authentication Endpoints

1. **Sign In**: `POST /auth/sign_in`
2. **Sign Out**: `DELETE /auth/sign_out` 
3. **Password Reset**: `POST /auth/password`
4. **Password Update**: `PUT /auth/password`
5. **Registration**: `POST /auth`
6. **Email Confirmation**: `GET /auth/confirmation`

## Frontend Authentication Handling

Authentication state is managed in the Vue.js frontend via:

- Storage of authentication tokens
- Automatic token refresh mechanism
- Authentication state management in Vuex
- Protected routes requiring authentication

The authentication system provides a secure, flexible foundation for user management while supporting multiple authentication methods and role-based access control. 