# frozen_string_literal: true

module DiscourseAdminMessenger
  module GuardianExtensions
    def can_send_private_message?(target, notify_moderators: false)
      return true if super
      return false unless SiteSetting.admin_messenger_enabled
      return false unless SiteSetting.admin_messenger_allow_all_users_pm
      return false if @user.blank? || @user.anonymous?
      return false if @user.silenced?
      true
    end

    def can_send_private_message_to_group?(group)
      # Note: current Discourse does not define can_send_private_message_to_group? in Guardian,
      # so we do not call super. This method is added entirely by this plugin.
      return false unless SiteSetting.admin_messenger_enabled
      return false if @user.blank? || @user.anonymous?
      return false if @user.silenced?

      required_group = SiteSetting.admin_messenger_required_group.presence || "admins"
      mod_group = SiteSetting.admin_messenger_allowed_moderator_group.presence || "moderators"

      group.name.downcase == required_group.downcase || group.name.downcase == mod_group.downcase
    end
  end
end
