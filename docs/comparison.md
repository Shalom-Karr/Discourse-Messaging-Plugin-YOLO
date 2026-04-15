# Comparison with discourse-mini-mod

This plugin is architecturally based on [discourse-mini-mod](https://github.com/alltechdev/discourse-mini-mod) but solves a different problem.

> Looking for what mini-mods can do vs full moderators? See [mini-mod's own comparison doc](https://github.com/alltechdev/discourse-mini-mod/blob/master/docs/comparison.md).

## Problem being solved

| | discourse-mini-mod | discourse-admin-messenger |
|-|-------------------|-----------------------------|
| **Goal** | Give regular users category management powers | Enforce admin/moderator oversight on PMs |
| **Core concern** | Content organisation | Messaging accountability |
| **Who benefits** | Category group moderators | Any user who needs to message with admin visibility |
| **Staff relationship** | Extends what category group mods can do | Constrains what regular users can do without oversight |

## Architecture (shared patterns)

Both plugins follow identical structural conventions taken directly from Discourse's plugin API:

| Pattern | Both plugins |
|---------|-------------|
| **Lib files** | Top-level `require_relative` before `after_initialize` |
| **Monkey-patching** | `Guardian.prepend(...)` wrapped in `reloadable_patch` inside `after_initialize` |
| **Settings file** | `config/settings.yml` with per-setting `client: true/false` flags |
| **Server locale** | `config/locales/server.en.yml` — `site_settings:` + plugin-specific keys |
| **Client locale** | `config/locales/client.en.yml` — `admin_js.admin.site_settings.categories:` label |
| **Master switch** | A single `enabled` setting declared via `enabled_site_setting:` in the header |
| **Serializer additions** | `add_to_serializer` with paired `include_*?` guards |
| **Settings UI grouping** | Settings appear under a named category in `/admin/site_settings` |

## Key implementation differences

| Aspect | discourse-mini-mod | discourse-admin-messenger |
|--------|--------------------|---------------------------|
| **Guardian methods extended** | `can_create_category?`, `can_edit_category?`, `can_edit_topic?`, `can_close_topic?`, `can_admin_tags?`, and more | `can_send_private_message?`, `can_send_private_message_to_group?` |
| **Hook used** | None (Guardian is the single enforcement point) | `:before_create_topic` event for PM recipient validation |
| **Controller added** | None | `MergeToPublicController` — POST `/admin-messenger/merge-to-public` |
| **Route added** | None | `Discourse::Application.routes.append` inside `after_initialize` |
| **Who the feature empowers** | Category group moderators (a specific group assignment) | Any PM participant for the merge action |
| **Serializer target** | `:current_user` (`can_admin_tags`) | `:topic_view` (`can_merge_to_public`, `was_merged_from_pm`) + `:current_user` (`can_send_admin_messages`) |
| **Custom fields** | None | Merge metadata stored on topic custom fields |
| **JS frontend** | Loads admin bundle chunk for mini-mods via `register_html_builder` | Glimmer component + outlet connector for merge banner |

## Summary

discourse-admin-messenger lifts the structural playbook from discourse-mini-mod wholesale — the same `reloadable_patch` idiom, the same settings YAML shape, the same locale file layout — and applies it to a complementary domain: making sure personal messages always have an admin or moderator in the loop, and giving any participant a way to bring that conversation into the open.
