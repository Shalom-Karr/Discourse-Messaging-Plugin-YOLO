# frozen_string_literal: true

module DiscourseAdminMessenger
  module TopicCreatorExtension
    def self.validate_admin_group_included(topic_params, user)
      return true unless SiteSetting.admin_messenger_enabled
      return true unless topic_params[:archetype] == Archetype.private_message
      return true if user&.staff?

      target_group_names =
        Array(topic_params[:target_group_names]).flat_map { |n| n.split(",") }.map(&:strip)

      required_group = SiteSetting.admin_messenger_required_group.presence || "admins"
      mod_group_name = SiteSetting.admin_messenger_allowed_moderator_group.presence || "moderators"

      # Check if required admin group is included
      return true if target_group_names.map(&:downcase).include?(required_group.downcase)

      # Check if any moderator member is a direct recipient
      target_usernames =
        Array(topic_params[:target_usernames]).flat_map { |n| n.split(",") }.map(&:strip)

      if target_usernames.present?
        mod_group = Group.find_by("LOWER(name) = ?", mod_group_name.downcase)
        if mod_group
          mod_user_ids = GroupUser.where(group_id: mod_group.id).pluck(:user_id)
          target_user_ids = User.where(username: target_usernames).pluck(:id)
          return true if (target_user_ids & mod_user_ids).any?
        end
      end

      false
    end
  end
end
