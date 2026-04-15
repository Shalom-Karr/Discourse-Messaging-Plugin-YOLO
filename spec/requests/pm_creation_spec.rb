# frozen_string_literal: true

require "rails_helper"

RSpec.describe "PM creation enforcement", type: :request do
  fab!(:user)
  fab!(:admin)
  fab!(:moderator)
  fab!(:admins_group) { Group.find_by(name: "admins") || Fabricate(:group, name: "admins") }

  before do
    SiteSetting.admin_messenger_enabled = true
    SiteSetting.admin_messenger_required_group = "admins"
    sign_in(user)
  end

  it "blocks a non-staff user from creating a PM without @admins" do
    expect {
      post "/posts.json",
           params: {
             raw: "Hello, anyone there?",
             title: "Needs help",
             archetype: "private_message",
             target_usernames: admin.username,
           }
    }.not_to change { Topic.count }

    expect(response.status).to eq(422)
  end

  it "allows a non-staff user to create a PM that includes @admins group" do
    expect {
      post "/posts.json",
           params: {
             raw: "Hello admins, need help.",
             title: "Question for admins",
             archetype: "private_message",
             target_usernames: admin.username,
             target_group_names: admins_group.name,
           }
    }.to change { Topic.count }.by(1)

    expect(response.status).to eq(200)
  end

  it "allows staff to create a PM without @admins" do
    sign_in(admin)

    expect {
      post "/posts.json",
           params: {
             raw: "Staff-to-staff message.",
             title: "Staff message",
             archetype: "private_message",
             target_usernames: moderator.username,
           }
    }.to change { Topic.count }.by(1)

    expect(response.status).to eq(200)
  end
end
