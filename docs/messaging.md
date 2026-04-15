# Messaging Rules

## How PM Permissions Work

When the plugin is enabled, **non-staff users** must satisfy at least one of these conditions to create a personal message:

### Option 1: Include the @admins Group
Add the `@admins` group (or whatever group is configured in `admin_messenger_required_group`) as a direct recipient of the PM.

### Option 2: Include a Moderator Group Member
Add any individual user who is a member of the `@moderators` group (or whatever group is configured in `admin_messenger_allowed_moderator_group`) as a direct recipient.

## Examples

| Scenario | Allowed? |
|----------|----------|
| User sends PM to `@admins` group | ✅ Yes |
| User sends PM to `@john` (john is a moderator) | ✅ Yes |
| User sends PM to `@john` (moderator) and `@mike` (not a moderator) | ✅ Yes — one moderator in the recipients is enough |
| User sends PM to `@jane` and `@admins` | ✅ Yes |
| User sends PM to `@bob` (bob is NOT a moderator or admin) | ❌ No |
| Staff user sends PM to anyone | ✅ Always allowed |

## Trust Level Override

If `admin_messenger_allow_all_users_pm` is enabled, even users below the normal PM trust level threshold can send messages — as long as they satisfy one of the two conditions above.

## How It Works Technically

1. The plugin hooks into Discourse's `:before_create_topic` event
2. For non-staff users creating a PM, it checks `target_group_names` for the admin group
3. It also checks `target_usernames` against members of the moderator group
4. The moderator check is a **set intersection** — if *any* of the named recipients is a moderator, the condition is satisfied, regardless of how many non-moderator recipients are also included
5. If neither condition is met, the PM creation is rejected with an error message
6. Guardian extensions relax `can_send_private_message?` and `can_send_private_message_to_group?`
