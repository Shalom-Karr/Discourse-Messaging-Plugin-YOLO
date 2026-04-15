# discourse-admin-messenger (Discourse-Messaging-Plugin-YOLO)

> Users can message — as long as the admins (or a moderator) are in the room.

A Discourse plugin that allows any user to send personal messages (PMs) provided the **@admins** group or any member of the **@moderators** group is included as a recipient. Any participant can then **merge the conversation to public view**, converting it into a regular topic.

Built on the same architectural patterns as [discourse-mini-mod](https://github.com/alltechdev/discourse-mini-mod).

## How it works

1. **User creates a PM** → plugin enforces that the `@admins` group or a moderator member is included
2. **Participants converse** → the PM functions normally
3. **Any participant clicks "Merge to Public"** → conversation becomes a public topic
4. Optionally, the merged topic is **unlisted first** so it can be reviewed

## Settings

All settings are under **Admin → Site Settings → Admin Messenger**.

| Setting | Default | Description |
|---------|---------|-------------|
| `admin_messenger_enabled` | `false` | Master switch for the plugin |
| `admin_messenger_required_group` | `"admins"` | Group that must be included as a recipient on every non-staff PM |
| `admin_messenger_allowed_moderator_group` | `"moderators"` | Group whose individual members can also satisfy the PM requirement |
| `admin_messenger_merge_category_id` | `-1` | Category for merged-to-public topics. `-1` = uncategorized |
| `admin_messenger_allow_all_users_pm` | `false` | Allow users below the normal PM trust level to send messages |
| `admin_messenger_merge_unlists_first` | `true` | Unlist merged topics initially for review before full visibility |

## Permissions

| Scenario | Allowed? |
|----------|----------|
| User sends PM to `@admins` group | ✅ Yes |
| User sends PM to `@john` (john is a moderator) | ✅ Yes |
| User sends PM to `@john` (moderator) and `@mike` (not a moderator) | ✅ Yes — one moderator in the recipients is enough |
| User sends PM to `@jane` and `@admins` | ✅ Yes |
| User sends PM to `@bob` (bob is NOT a moderator or admin) | ❌ No |
| Staff user sends PM to anyone | ✅ Always allowed |

| User Type | Can Merge to Public? |
|-----------|---------------------|
| Staff/Admin | ✅ Always |
| Direct PM participant | ✅ Yes |
| Member of an allowed group on the PM | ✅ Yes |
| Non-participant | ❌ No |

## Installation

Add to your `app.yml`:

```yaml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/Shalom-Karr/Discourse-Messaging-Plugin-YOLO.git
```

Then rebuild:

```
./launcher rebuild app
```

## Documentation

See [docs/](docs/) for detailed documentation:
- [Setup & Installation](docs/setup.md)
- [Messaging Rules](docs/messaging.md)
- [Merge to Public](docs/merge-to-public.md)
- [Comparison with discourse-mini-mod](docs/comparison.md)

## Inspired by

This plugin is architecturally inspired by [discourse-mini-mod](https://github.com/alltechdev/discourse-mini-mod). It uses the same `Guardian.prepend` via `reloadable_patch` pattern, the same `config/settings.yml` structure with `client:` flags, and the same `server.en.yml` + `client.en.yml` locale layout.
