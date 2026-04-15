# frozen_string_literal: true

require "rails_helper"

RSpec.describe DiscourseAdminMessenger::TopicCreatorExtension do
  fab!(:user)
  fab!(:admin)
  fab!(:moderator)
  fab!(:mod_user) { Fabricate(:user) }
  fab!(:non_mod_user) { Fabricate(:user) }
  fab!(:moderators_group) do
    Group.find_by(name: "moderators") || Fabricate(:group, name: "moderators")
  end

  before do
    SiteSetting.admin_messenger_enabled = true
    SiteSetting.admin_messenger_required_group = "admins"
    SiteSetting.admin_messenger_allowed_moderator_group = "moderators"
    moderators_group.add(mod_user) unless moderators_group.users.include?(mod_user)
  end

  describe ".validate_admin_group_included" do
    let(:pm_params) do
      { archetype: Archetype.private_message, target_group_names: "", target_usernames: "" }
    end

    context "when the plugin is disabled" do
      before { SiteSetting.admin_messenger_enabled = false }

      it "returns true (no validation)" do
        expect(
          described_class.validate_admin_group_included(pm_params, user),
        ).to eq(true)
      end
    end

    context "when the topic is not a PM" do
      it "returns true for regular topics" do
        params = { archetype: Archetype.default }
        expect(described_class.validate_admin_group_included(params, user)).to eq(true)
      end
    end

    context "when the user is staff" do
      it "returns true for admins" do
        expect(described_class.validate_admin_group_included(pm_params, admin)).to eq(true)
      end

      it "returns true for moderators" do
        expect(described_class.validate_admin_group_included(pm_params, moderator)).to eq(true)
      end
    end

    context "when the admins group is included as a target group" do
      it "returns true" do
        params = pm_params.merge(target_group_names: "admins")
        expect(described_class.validate_admin_group_included(params, user)).to eq(true)
      end

      it "is case-insensitive" do
        params = pm_params.merge(target_group_names: "Admins")
        expect(described_class.validate_admin_group_included(params, user)).to eq(true)
      end

      it "works with comma-separated group names" do
        params = pm_params.merge(target_group_names: "some_group,admins")
        expect(described_class.validate_admin_group_included(params, user)).to eq(true)
      end
    end

    context "when a moderator member is included as a direct recipient" do
      it "returns true when a moderator-group member is a target username" do
        params = pm_params.merge(target_usernames: mod_user.username)
        expect(described_class.validate_admin_group_included(params, user)).to eq(true)
      end

      it "returns false when target username is not a moderator member" do
        params = pm_params.merge(target_usernames: non_mod_user.username)
        expect(described_class.validate_admin_group_included(params, user)).to eq(false)
      end
    end

    context "when neither condition is met" do
      it "returns false with no targets" do
        expect(described_class.validate_admin_group_included(pm_params, user)).to eq(false)
      end

      it "returns false with unrelated group" do
        params = pm_params.merge(target_group_names: "some_other_group")
        expect(described_class.validate_admin_group_included(params, user)).to eq(false)
      end
    end

    context "with custom group settings" do
      fab!(:custom_group) { Fabricate(:group, name: "support_team") }
      fab!(:custom_mod_group) { Fabricate(:group, name: "helpers") }
      fab!(:helper_user) { Fabricate(:user) }

      before do
        SiteSetting.admin_messenger_required_group = "support_team"
        SiteSetting.admin_messenger_allowed_moderator_group = "helpers"
        custom_mod_group.add(helper_user)
      end

      it "validates against the custom required group" do
        params = pm_params.merge(target_group_names: "support_team")
        expect(described_class.validate_admin_group_included(params, user)).to eq(true)
      end

      it "validates against the custom moderator group members" do
        params = pm_params.merge(target_usernames: helper_user.username)
        expect(described_class.validate_admin_group_included(params, user)).to eq(true)
      end

      it "no longer accepts the default admins group" do
        params = pm_params.merge(target_group_names: "admins")
        expect(described_class.validate_admin_group_included(params, user)).to eq(false)
      end
    end
  end
end
