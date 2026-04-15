# frozen_string_literal: true

# name: discourse-admin-messenger
# about: Allows users to send messages when the @admins group is included, with an option to merge conversations to public view
# version: 0.1.0
# authors: Shalom-KarrIncluded
# url: https://github.com/Shalom-Karr/Discourse-Messaging-Plugin-YOLO
# required_version: 2.7.0
# enabled_site_setting: admin_messenger_enabled

require_relative "lib/discourse_admin_messenger/guardian_extensions"
require_relative "lib/discourse_admin_messenger/topic_creator_extension"

after_initialize do
  %w[
    app/controllers/discourse_admin_messenger/merge_to_public_controller.rb
  ].each { |path| require_relative path }

  reloadable_patch do
    ::Guardian.prepend(DiscourseAdminMessenger::GuardianExtensions)
  end

  # Route: POST /admin-messenger/merge-to-public (any logged-in user who is a participant)
  Discourse::Application.routes.append do
    post "/admin-messenger/merge-to-public" =>
           "discourse_admin_messenger/merge_to_public#merge"
  end

  # Validate PM creation: if the plugin is enabled and the user is not
  # staff, require the admins group OR a moderators group member to be included.
  on(:before_create_topic) do |topic_params, creator|
    next unless SiteSetting.admin_messenger_enabled
    next unless topic_params[:archetype] == Archetype.private_message
    next if creator.user&.staff?

    target_group_names =
      Array(topic_params[:target_group_names]).flat_map { |n| n.split(",") }.map(&:strip)

    required_group = SiteSetting.admin_messenger_required_group.presence || "admins"
    mod_group_name = SiteSetting.admin_messenger_allowed_moderator_group.presence || "moderators"

    # Check 1: Is the required admin group included?
    admin_group_included = target_group_names.map(&:downcase).include?(required_group.downcase)

    # Check 2: Is any individual moderator group member included as a direct recipient?
    mod_member_included = false
    target_usernames =
      Array(topic_params[:target_usernames]).flat_map { |n| n.split(",") }.map(&:strip)

    if target_usernames.present?
      mod_group = Group.find_by("LOWER(name) = ?", mod_group_name.downcase)
      if mod_group
        mod_user_ids = GroupUser.where(group_id: mod_group.id).pluck(:user_id)
        target_user_ids = User.where(username: target_usernames).pluck(:id)
        mod_member_included = (target_user_ids & mod_user_ids).any?
      end
    end

    unless admin_group_included || mod_member_included
      creator.rollback_from_errors!(
        creator.topic,
        :base,
        I18n.t(
          "admin_messenger.errors.admins_group_required",
          group: required_group,
          mod_group: mod_group_name,
        ),
      )
    end
  end

  # Serializer: expose merge-to-public capability to the client
  # Any participant in the PM can merge (not just staff)
  add_to_serializer(:topic_view, :can_merge_to_public) do
    return false unless SiteSetting.admin_messenger_enabled
    return false unless object.topic.private_message?
    return false if scope.user.blank?

    topic = object.topic
    # Staff can always merge
    return true if scope.is_staff?
    # Any direct participant can merge
    return true if topic.topic_allowed_users.exists?(user_id: scope.user.id)
    # Any member of an allowed group can merge
    allowed_group_ids = topic.topic_allowed_groups.pluck(:group_id)
    return true if allowed_group_ids.any? && GroupUser.where(group_id: allowed_group_ids, user_id: scope.user.id).exists?

    false
  end

  add_to_serializer(:topic_view, :include_can_merge_to_public?) do
    SiteSetting.admin_messenger_enabled && object.topic.private_message?
  end

  add_to_serializer(:topic_view, :was_merged_from_pm) do
    object.topic.custom_fields["merged_from_pm"].present?
  end

  add_to_serializer(:topic_view, :include_was_merged_from_pm?) do
    SiteSetting.admin_messenger_enabled
  end

  add_to_serializer(:current_user, :can_send_admin_messages) do
    SiteSetting.admin_messenger_enabled
  end

  add_to_serializer(:current_user, :include_can_send_admin_messages?) do
    SiteSetting.admin_messenger_enabled
  end
end
