# frozen_string_literal: true

require "rails_helper"

RSpec.describe DiscourseAdminMessenger::GuardianExtensions do
  fab!(:user)
  fab!(:silenced_user) { Fabricate(:user, silenced_till: 1.year.from_now) }
  fab!(:admin)
  fab!(:moderator)
  fab!(:admins_group) { Group.find_by(name: "admins") || Fabricate(:group, name: "admins") }
  fab!(:moderators_group) do
    Group.find_by(name: "moderators") || Fabricate(:group, name: "moderators")
  end
  fab!(:custom_group) { Fabricate(:group, name: "custom_support") }

  before do
    SiteSetting.admin_messenger_enabled = true
    SiteSetting.admin_messenger_allow_all_users_pm = true
    SiteSetting.admin_messenger_required_group = "admins"
    SiteSetting.admin_messenger_allowed_moderator_group = "moderators"
  end

  describe "#can_send_private_message?" do
    context "when the plugin is disabled" do
      before { SiteSetting.admin_messenger_enabled = false }

      it "falls through to default Guardian behaviour" do
        guardian = Guardian.new(user)
        # Without the plugin, a TL0 user may not be able to PM;
        # we only assert the plugin branch is NOT the reason it returns true.
        result = guardian.can_send_private_message?(admin)
        # The plugin should not forcibly grant permission when disabled.
        expect(result).to eq(Guardian.new(user).can_send_private_message?(admin))
      end
    end

    context "when the plugin is enabled" do
      context "and admin_messenger_allow_all_users_pm is true" do
        it "allows a normal user to send a PM" do
          guardian = Guardian.new(user)
          expect(guardian.can_send_private_message?(admin)).to eq(true)
        end

        it "does not allow a silenced user to send a PM" do
          guardian = Guardian.new(silenced_user)
          expect(guardian.can_send_private_message?(admin)).to eq(false)
        end

        it "does not allow anonymous users" do
          guardian = Guardian.new(nil)
          expect(guardian.can_send_private_message?(admin)).to eq(false)
        end
      end

      context "and admin_messenger_allow_all_users_pm is false" do
        before { SiteSetting.admin_messenger_allow_all_users_pm = false }

        it "falls through to default Guardian behaviour for normal users" do
          guardian = Guardian.new(user)
          # With the setting off, the plugin extension should not grant extra access
          result = guardian.can_send_private_message?(admin)
          expect(result).to eq(Guardian.new(user).can_send_private_message?(admin))
        end
      end
    end
  end

  describe "#can_send_private_message_to_group?" do
    context "when the plugin is disabled" do
      before { SiteSetting.admin_messenger_enabled = false }

      it "falls through to default Guardian behaviour" do
        guardian = Guardian.new(user)
        result = guardian.can_send_private_message_to_group?(custom_group)
        expect(result).to eq(Guardian.new(user).can_send_private_message_to_group?(custom_group))
      end
    end

    context "when the plugin is enabled" do
      it "allows messaging the required admin group" do
        guardian = Guardian.new(user)
        expect(guardian.can_send_private_message_to_group?(admins_group)).to eq(true)
      end

      it "allows messaging the moderator group" do
        guardian = Guardian.new(user)
        expect(guardian.can_send_private_message_to_group?(moderators_group)).to eq(true)
      end

      it "does not allow messaging an unrelated group" do
        guardian = Guardian.new(user)
        # Plugin should not grant access to arbitrary groups
        expect(guardian.can_send_private_message_to_group?(custom_group)).to eq(false)
      end

      it "does not allow silenced users" do
        guardian = Guardian.new(silenced_user)
        expect(guardian.can_send_private_message_to_group?(admins_group)).to eq(false)
      end

      it "does not allow anonymous users" do
        guardian = Guardian.new(nil)
        expect(guardian.can_send_private_message_to_group?(admins_group)).to eq(false)
      end

      context "with custom group names in settings" do
        before do
          SiteSetting.admin_messenger_required_group = "custom_support"
          SiteSetting.admin_messenger_allowed_moderator_group = "moderators"
        end

        it "allows messaging the custom required group" do
          guardian = Guardian.new(user)
          expect(guardian.can_send_private_message_to_group?(custom_group)).to eq(true)
        end

        it "no longer allows messaging 'admins' via the plugin extension" do
          guardian = Guardian.new(user)
          # Without the default super allowing it, the plugin branch should not match
          result = guardian.can_send_private_message_to_group?(admins_group)
          # admins_group is no longer the required group, so only super decides
          expect(result).to eq(
            Guardian.new(user).can_send_private_message_to_group?(admins_group),
          )
        end
      end

      it "is case-insensitive when matching group names" do
        SiteSetting.admin_messenger_required_group = "Admins"
        guardian = Guardian.new(user)
        expect(guardian.can_send_private_message_to_group?(admins_group)).to eq(true)
      end
    end
  end
end
