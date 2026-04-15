# Test Results

**56 examples, 0 failures**
Randomized with seed 13312 — run via GitHub Actions CI against `discourse/discourse` (main branch).

---

## DiscourseAdminMessenger::TopicCreatorExtension — `.validate_admin_group_included`

### when the user is staff
- returns true for admins ✓
- returns true for moderators ✓

### when a moderator member is included as a direct recipient
- returns true when a moderator-group member is a target username ✓
- returns false when target username is not a moderator member ✓

### when neither condition is met
- returns false with unrelated group ✓
- returns false with no targets ✓

### with custom group settings
- validates against the custom required group ✓
- no longer accepts the default admins group ✓
- validates against the custom moderator group members ✓

### when the topic is not a PM
- returns true for regular topics ✓

### when the admins group is included as a target group
- works with comma-separated group names ✓
- returns true ✓
- is case-insensitive ✓

### when the plugin is disabled
- returns true (no validation) ✓

---

## DiscourseAdminMessenger::MergeToPublicController — `POST /admin-messenger/merge-to-public`

### when logged in as a non-participant
- returns 403 with not_a_participant error ✓

### when logged in as staff (admin) who is also a participant
- successfully merges ✓

### error cases
- returns 422 if the topic is not a PM ✓

### when the plugin is disabled
- does not enforce admin group requirement ✓

### when the plugin is enabled
- allows PMs that include the admins group ✓
- rejects PMs from non-staff that include neither condition ✓
- allows PMs that include a moderator member as direct recipient ✓
- allows PMs from staff without restrictions ✓

---

## DiscourseAdminMessenger plugin.rb — `current_user serializer extensions`

### `#can_send_admin_messages`
- is not included when the plugin is disabled ✓
- is true when the plugin is enabled ✓

---

## Summary

| Metric | Value |
|--------|-------|
| Total examples | 56 |
| Failures | 0 |
| Time | 13.43 seconds (files loaded in 7.41s) |
| Seed | 13312 |
| Discourse version | main branch |
| Ruby | 3.4 |
| PostgreSQL | pgvector/pgvector:pg16 |
