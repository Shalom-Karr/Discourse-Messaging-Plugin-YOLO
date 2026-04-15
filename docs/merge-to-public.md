# Merge to Public

## Overview

Any participant in a PM conversation can convert it into a public topic. This is not restricted to staff — any user who is a direct participant or a member of an allowed group on the PM can trigger the merge.

## How It Works

1. Open a PM that was created through the admin messenger flow
2. A banner appears at the top: "Convert this private message into a public topic"
3. Click **"Merge to Public"**
4. Confirm the action in the dialog
5. The PM is converted to a regular public topic

## What Happens During Merge

- The topic's archetype changes from `private_message` to `default`
- The topic is moved to the configured category (or uncategorized)
- If `admin_messenger_merge_unlists_first` is enabled, the topic is initially unlisted
- Original participant user IDs and group IDs are stored in custom fields
- A small action post is added: "This topic was converted from a private message to a public topic"
- PM participant records (allowed users/groups) are cleared

## Metadata Tracked

| Custom Field | Description |
|-------------|-------------|
| `merged_from_pm` | Boolean flag indicating this was merged from a PM |
| `merged_from_pm_at` | ISO 8601 timestamp of when the merge occurred |
| `merged_from_pm_by` | User ID of who triggered the merge |
| `merged_pm_original_user_ids` | Comma-separated list of original PM participant user IDs |
| `merged_pm_original_group_ids` | Comma-separated list of original PM allowed group IDs |

## Who Can Merge?

| User Type | Can Merge? |
|-----------|------------|
| Staff/Admin | ✅ Always |
| Direct PM participant | ✅ Yes |
| Member of an allowed group on the PM | ✅ Yes |
| Non-participant | ❌ No |
