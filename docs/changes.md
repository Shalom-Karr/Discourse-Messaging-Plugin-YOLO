# Changelog

All notable changes to the discourse-admin-messenger plugin are documented here.

---

## [Unreleased]

### `.github/workflows/plugin-tests.yml` — Added
- **What:** Added GitHub Actions CI workflow to run the full RSpec suite against a real Discourse environment (side-by-side clone of `discourse/discourse`).
- **Why:** Local Docker/WSL unavailable (blocked by IT); CI is the only way to run tests in a real Discourse environment without affecting the live forum.
- **Setup:** Uses Ruby 3.4, pgvector/pgvector:pg16 PostgreSQL, Redis, Node 22 + pnpm, and `LOAD_PLUGINS=1`.

### `plugin.rb` — Fixed
- **What:** Changed `require_relative "../app/controllers/..."` to `require_relative "app/controllers/..."`.
- **Why:** The `../` prefix resolved to `discourse/plugins/app/...` (wrong directory). The correct path relative to `plugin.rb` is `app/controllers/...` which resolves to `discourse/plugins/discourse-admin-messenger/app/controllers/...`.

### `config/settings.yml` — Fixed
- **What:** Changed `admin_messenger_merge_category_id` default from `-1` to `0`, added `min: 0`.
- **Why:** Discourse's site settings validator rejects negative integer values. `0` now serves as the sentinel value meaning "use the uncategorized category". The controller already handles `<= 0` as "use uncategorized".

### `app/controllers/discourse_admin_messenger/merge_to_public_controller.rb` — Fixed (multiple)
1. **`category_id == -1` → `category_id <= 0`**
   - **Why:** The `merge_category_id` sentinel was changed from `-1` to `0`; updated the check to use `<= 0` for robustness.

2. **Added `ensure_plugin_enabled` before_action**
   - **What:** Added a private `ensure_plugin_enabled` method that raises `Discourse::NotFound` when `admin_messenger_enabled` is false, wired as a `before_action`.
   - **Why:** `requires_plugin` only checks whether the plugin is installed/loaded, not whether its feature toggle is on. Without this check, the controller processed requests even when the plugin was disabled, returning 200 instead of 404.

3. **Guarded `StaffActionLogger#log_topic_made_public` call**
   - **What:** Changed the bare `StaffActionLogger.new(...).log_topic_made_public(topic)` call to first verify the method exists via `StaffActionLogger.method_defined?(:log_topic_made_public)`.
   - **Why:** This method was removed from Discourse's `StaffActionLogger` in a recent version, causing a `NoMethodError` during every merge operation.

### `lib/discourse_admin_messenger/guardian_extensions.rb` — Fixed (multiple)
1. **Removed `super` from `can_send_private_message_to_group?`**
   - **Why:** Current Discourse does not define `can_send_private_message_to_group?` in `Guardian`. Calling `super` caused `EnsureMagic#method_missing` to raise `NoMethodError`. The plugin is now the sole owner of this method.

2. **Changed `notify_fallback:` → `notify_moderators:` in `can_send_private_message?`**
   - **Why:** Discourse renamed this keyword argument. Passing the old name caused `ArgumentError: unknown keyword: :notify_fallback` when `super` was called.

### `spec/requests/merge_to_public_controller_spec.rb` — Fixed
- **What:** Updated the "falls back to uncategorized" test to use `admin_messenger_merge_category_id = 0` instead of `= -1`.
- **Why:** The setting default and sentinel value changed from `-1` to `0` (see `config/settings.yml` fix above).
