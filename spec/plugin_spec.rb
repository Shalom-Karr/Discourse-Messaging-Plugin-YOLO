# frozen_string_literal: true

require "rails_helper"

RSpec.describe "DiscourseAdminMessenger plugin.rb" do
  fab!(:user)
  fab!(:admin)
  fab!(:moderator)
  fab!(:mod_user) { Fabricate(:user) }
  fab!(:admins_group) { Group.find_by(name: "admins") || Fabricate(:group, name: "admins") }
  fab!(:moderators_group) do
    Group.find_by(name: "moderators") || Fabricate(:group, name: "moderators")
  end

  before do
    SiteSetting.admin_messenger_enabled = true
    SiteSetting.admin_messenger_required_group = "admins"
    SiteSetting.admin_messenger_allowed_moderator_group = "moderators"
    moderators_group.add(mod_user) unless moderators_group.users.include?(mod_user)
  end

  describe ":before_create_topic event validation" do
    # The :before_create_topic handler in plugin.rb validates that non-staff
    # users include the admins group or a moderator member as a PM recipient.
    # These tests validate the same logic indirectly through TopicCreator.

    context "when the plugin is disabled" do
      before { SiteSetting.admin_messenger_enabled = false }

      it "does not enforce admin group requirement" do
        # This test verifies that the validation is skipped when disabled.
        # The actual :before_create_topic event fires during TopicCreator#create.
        result =
          DiscourseAdminMessenger::TopicCreatorExtension.validate_admin_group_included(
            { archetype: Archetype.private_message, target_group_names: "", target_usernames: "" },
            user,
          )
        expect(result).to eq(true)
      end
    end

    context "when the plugin is enabled" do
      it "allows PMs that include the admins group" do
        result =
          DiscourseAdminMessenger::TopicCreatorExtension.validate_admin_group_included(
            {
              archetype: Archetype.private_message,
              target_group_names: "admins",
              target_usernames: "",
            },
            user,
          )
        expect(result).to eq(true)
      end

      it "allows PMs that include a moderator member as direct recipient" do
        result =
          DiscourseAdminMessenger::TopicCreatorExtension.validate_admin_group_included(
            {
              archetype: Archetype.private_message,
              target_group_names: "",
              target_usernames: mod_user.username,
            },
            user,
          )
        expect(result).to eq(true)
      end

      it "rejects PMs from non-staff that include neither condition" do
        result =
          DiscourseAdminMessenger::TopicCreatorExtension.validate_admin_group_included(
            { archetype: Archetype.private_message, target_group_names: "", target_usernames: "" },
            user,
          )
        expect(result).to eq(false)
      end

      it "allows PMs from staff without restrictions" do
        result =
          DiscourseAdminMessenger::TopicCreatorExtension.validate_admin_group_included(
            { archetype: Archetype.private_message, target_group_names: "", target_usernames: "" },
            admin,
          )
        expect(result).to eq(true)
      end
    end
  end

  describe "topic_view serializer extensions" do
    fab!(:category) { Fabricate(:category) }

    fab!(:pm_topic) do
      Fabricate(
        :private_message_topic,
        user: user,
        topic_allowed_users: [
          Fabricate.build(:topic_allowed_user, user: user),
          Fabricate.build(:topic_allowed_user, user: admin),
        ],
      )
    end
    fab!(:pm_post) { Fabricate(:post, topic: pm_topic, user: user) }

    describe "#can_merge_to_public" do
      it "is true for a PM participant" do
        topic_view = TopicView.new(pm_topic.id, user)
        serializer = TopicViewSerializer.new(topic_view, scope: Guardian.new(user), root: false)
        json = serializer.as_json

        expect(json[:can_merge_to_public]).to eq(true)
      end

      it "is true for staff" do
        topic_view = TopicView.new(pm_topic.id, admin)
        serializer = TopicViewSerializer.new(topic_view, scope: Guardian.new(admin), root: false)
        json = serializer.as_json

        expect(json[:can_merge_to_public]).to eq(true)
      end

      it "is false for a non-participant" do
        other = Fabricate(:user)
        # Non-participants can't view PMs normally, but we test the serializer logic directly
        topic_view = TopicView.new(pm_topic.id, admin) # admin can view
        serializer = TopicViewSerializer.new(topic_view, scope: Guardian.new(other), root: false)
        json = serializer.as_json

        expect(json[:can_merge_to_public]).to eq(false)
      end

      it "is not included for non-PM topics" do
        public_topic = Fabricate(:topic, user: user, category: category)
        Fabricate(:post, topic: public_topic, user: user)
        topic_view = TopicView.new(public_topic.id, user)
        serializer =
          TopicViewSerializer.new(topic_view, scope: Guardian.new(user), root: false)
        json = serializer.as_json

        expect(json).not_to have_key(:can_merge_to_public)
      end

      it "is not included when plugin is disabled" do
        SiteSetting.admin_messenger_enabled = false
        topic_view = TopicView.new(pm_topic.id, user)
        serializer = TopicViewSerializer.new(topic_view, scope: Guardian.new(user), root: false)
        json = serializer.as_json

        expect(json).not_to have_key(:can_merge_to_public)
      end
    end

    describe "#was_merged_from_pm" do
      it "is false when topic has not been merged" do
        topic_view = TopicView.new(pm_topic.id, user)
        serializer = TopicViewSerializer.new(topic_view, scope: Guardian.new(user), root: false)
        json = serializer.as_json

        expect(json[:was_merged_from_pm]).to eq(false)
      end

      it "is true when topic has been merged" do
        pm_topic.custom_fields["merged_from_pm"] = true
        pm_topic.save_custom_fields

        topic_view = TopicView.new(pm_topic.id, user)
        serializer = TopicViewSerializer.new(topic_view, scope: Guardian.new(user), root: false)
        json = serializer.as_json

        expect(json[:was_merged_from_pm]).to eq(true)
      end
    end
  end

  describe "current_user serializer extensions" do
    describe "#can_send_admin_messages" do
      it "is true when the plugin is enabled" do
        serializer = CurrentUserSerializer.new(user, scope: Guardian.new(user), root: false)
        json = serializer.as_json

        expect(json[:can_send_admin_messages]).to eq(true)
      end

      it "is not included when the plugin is disabled" do
        SiteSetting.admin_messenger_enabled = false
        serializer = CurrentUserSerializer.new(user, scope: Guardian.new(user), root: false)
        json = serializer.as_json

        expect(json).not_to have_key(:can_send_admin_messages)
      end
    end
  end
end
