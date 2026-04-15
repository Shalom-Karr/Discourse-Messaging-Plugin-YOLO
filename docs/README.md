# Documentation — discourse-admin-messenger

Welcome to the documentation for the **discourse-admin-messenger** Discourse plugin.

## Table of Contents

- [Setup & Installation](setup.md) — How to install, configure, and enable the plugin
- [Messaging Rules](messaging.md) — How the PM permission system works with admin/moderator groups
- [Merge to Public](merge-to-public.md) — How any participant can convert a PM to a public topic
- [Comparison with discourse-mini-mod](comparison.md) — Architectural similarities and differences

## Quick Overview

This plugin extends Discourse's personal messaging system to:

1. **Require oversight** — Non-staff users must include the `@admins` group or a member of the `@moderators` group when creating PMs
2. **Empower participants** — Any participant in a PM can merge the conversation to a public topic (not just staff)
3. **Maintain auditability** — Merge actions are logged with metadata tracking original participants, timestamps, and the user who triggered the merge
