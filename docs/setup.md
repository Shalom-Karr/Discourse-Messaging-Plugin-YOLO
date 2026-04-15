# Setup & Installation

## Installation

Add the plugin's repository URL to your container's `app.yml`:

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

## Configuration

All settings are under **Admin → Site Settings → Admin Messenger**.

| Setting | Default | Description |
|---------|---------|-------------|
| `admin_messenger_enabled` | `false` | Master switch for the plugin |
| `admin_messenger_required_group` | `"admins"` | Group that must be included as a PM recipient (for non-staff users) |
| `admin_messenger_allowed_moderator_group` | `"moderators"` | Group whose individual members can also satisfy the PM requirement |
| `admin_messenger_merge_category_id` | `-1` | Category for merged-to-public topics. `-1` = uncategorized |
| `admin_messenger_allow_all_users_pm` | `false` | Allow users below the normal PM trust level to send messages |
| `admin_messenger_merge_unlists_first` | `true` | Unlist merged topics initially for review before full visibility |

## Enabling the Plugin

1. Go to **Admin → Site Settings**
2. Search for `admin_messenger_enabled`
3. Set to **true**
4. Optionally configure the other settings above
