# frozen_string_literal: true

module DiscourseAdminMessenger
  class MergeToPublicController < ::ApplicationController
    requires_plugin "discourse-admin-messenger"
    before_action :ensure_logged_in

    def merge
      topic_id = params.require(:topic_id)
      topic = Topic.find_by(id: topic_id)

      raise Discourse::NotFound.new(I18n.t("admin_messenger.errors.topic_not_found")) if topic.blank?

      unless topic.private_message?
        return(
          render json: { success: false, error: I18n.t("admin_messenger.errors.not_a_pm") },
                 status: 422
        )
      end

      if topic.custom_fields["merged_from_pm"].present?
        return(
          render json: { success: false, error: I18n.t("admin_messenger.errors.already_merged") },
                 status: 422
        )
      end

      # Check that the current user is a participant (not just staff)
      is_participant = current_user.staff? ||
        topic.topic_allowed_users.exists?(user_id: current_user.id) ||
        topic.topic_allowed_groups
          .joins("INNER JOIN group_users ON group_users.group_id = topic_allowed_groups.group_id")
          .where("group_users.user_id = ?", current_user.id)
          .exists?

      unless is_participant
        return(
          render json: { success: false, error: I18n.t("admin_messenger.errors.not_a_participant") },
                 status: 403
        )
      end

      # Determine the destination category
      category_id = SiteSetting.admin_messenger_merge_category_id
      category_id = SiteSetting.uncategorized_category_id if category_id.blank? || category_id == -1
      category = Category.find_by(id: category_id) || Category.find_by(id: SiteSetting.uncategorized_category_id)

      Topic.transaction do
        # Convert from PM to regular topic
        topic.archetype = Archetype.default
        topic.category_id = category.id
        topic.visible = false if SiteSetting.admin_messenger_merge_unlists_first
        topic.save!

        # Store metadata about the merge
        topic.custom_fields["merged_from_pm"] = true
        topic.custom_fields["merged_from_pm_at"] = Time.zone.now.iso8601
        topic.custom_fields["merged_from_pm_by"] = current_user.id
        topic.custom_fields["merged_pm_original_user_ids"] = topic.topic_allowed_users.pluck(:user_id).join(",")
        topic.custom_fields["merged_pm_original_group_ids"] = topic.topic_allowed_groups.pluck(:group_id).join(",")
        topic.save_custom_fields

        # Clear PM participant records since it's now public
        topic.topic_allowed_users.destroy_all
        topic.topic_allowed_groups.destroy_all

        # Add a small action post noting the conversion
        topic.add_moderator_post(
          current_user,
          I18n.t("admin_messenger.merge.small_action"),
          post_type: Post.types[:small_action],
          action_code: "public_topic",
        )

        StaffActionLogger.new(current_user).log_topic_made_public(topic) if current_user.staff? && defined?(StaffActionLogger)
      end

      render json: {
        success: true,
        message: I18n.t("admin_messenger.merge.success"),
        topic_url: topic.url,
        topic_id: topic.id,
      }
    end
  end
end
