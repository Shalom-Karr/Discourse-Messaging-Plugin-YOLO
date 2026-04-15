# frozen_string_literal: true

require "rails_helper"

RSpec.describe DiscourseAdminMessenger::MergeToPublicController do
  fab!(:user)
  fab!(:other_user) { Fabricate(:user) }
  fab!(:admin)
  fab!(:moderator)
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

  before do
    SiteSetting.admin_messenger_enabled = true
    SiteSetting.admin_messenger_merge_category_id = category.id
    SiteSetting.admin_messenger_merge_unlists_first = true
  end

  describe "POST /admin-messenger/merge-to-public" do
    context "when not logged in" do
      it "returns 403" do
        post "/admin-messenger/merge-to-public.json", params: { topic_id: pm_topic.id }
        expect(response.status).to eq(403)
      end
    end

    context "when the plugin is disabled" do
      before do
        SiteSetting.admin_messenger_enabled = false
        sign_in(user)
      end

      it "returns 404" do
        post "/admin-messenger/merge-to-public.json", params: { topic_id: pm_topic.id }
        expect(response.status).to eq(404)
      end
    end

    context "when logged in as a participant" do
      before { sign_in(user) }

      it "successfully merges a PM to a public topic" do
        post "/admin-messenger/merge-to-public.json", params: { topic_id: pm_topic.id }
        expect(response.status).to eq(200)

        json = response.parsed_body
        expect(json["success"]).to eq(true)
        expect(json["topic_id"]).to eq(pm_topic.id)
        expect(json["topic_url"]).to be_present

        pm_topic.reload
        expect(pm_topic.archetype).to eq(Archetype.default)
        expect(pm_topic.category_id).to eq(category.id)
        expect(pm_topic.custom_fields["merged_from_pm"]).to be_present
        expect(pm_topic.custom_fields["merged_from_pm_by"]).to eq(user.id.to_s)
      end

      it "unlists the topic when merge_unlists_first is true" do
        post "/admin-messenger/merge-to-public.json", params: { topic_id: pm_topic.id }
        expect(response.status).to eq(200)

        pm_topic.reload
        expect(pm_topic.visible).to eq(false)
      end

      it "keeps the topic visible when merge_unlists_first is false" do
        SiteSetting.admin_messenger_merge_unlists_first = false
        post "/admin-messenger/merge-to-public.json", params: { topic_id: pm_topic.id }
        expect(response.status).to eq(200)

        pm_topic.reload
        expect(pm_topic.visible).to eq(true)
      end

      it "clears PM participant records after merge" do
        post "/admin-messenger/merge-to-public.json", params: { topic_id: pm_topic.id }
        expect(response.status).to eq(200)

        pm_topic.reload
        expect(pm_topic.topic_allowed_users.count).to eq(0)
        expect(pm_topic.topic_allowed_groups.count).to eq(0)
      end

      it "stores original participant metadata in custom fields" do
        original_user_ids = pm_topic.topic_allowed_users.pluck(:user_id).sort

        post "/admin-messenger/merge-to-public.json", params: { topic_id: pm_topic.id }
        expect(response.status).to eq(200)

        pm_topic.reload
        stored_ids =
          pm_topic.custom_fields["merged_pm_original_user_ids"].split(",").map(&:to_i).sort
        expect(stored_ids).to eq(original_user_ids)
      end

      it "adds a small action post noting the conversion" do
        expect {
          post "/admin-messenger/merge-to-public.json", params: { topic_id: pm_topic.id }
        }.to change { pm_topic.posts.where(post_type: Post.types[:small_action]).count }.by(1)
      end

      it "falls back to uncategorized when merge_category_id is 0" do
        SiteSetting.admin_messenger_merge_category_id = 0
        post "/admin-messenger/merge-to-public.json", params: { topic_id: pm_topic.id }
        expect(response.status).to eq(200)

        pm_topic.reload
        expect(pm_topic.category_id).to eq(SiteSetting.uncategorized_category_id)
      end
    end

    context "when logged in as a group-based participant" do
      fab!(:allowed_group) { Fabricate(:group) }

      before do
        pm_topic.topic_allowed_groups.create!(group: allowed_group)
        allowed_group.add(other_user)
        sign_in(other_user)
      end

      it "successfully merges" do
        post "/admin-messenger/merge-to-public.json", params: { topic_id: pm_topic.id }
        expect(response.status).to eq(200)

        json = response.parsed_body
        expect(json["success"]).to eq(true)
      end

      it "records the merging user in custom fields" do
        post "/admin-messenger/merge-to-public.json", params: { topic_id: pm_topic.id }

        pm_topic.reload
        expect(pm_topic.custom_fields["merged_from_pm_by"]).to eq(other_user.id.to_s)
      end
    end

    context "when logged in as a non-participant" do
      before { sign_in(other_user) }

      it "returns 403 with not_a_participant error" do
        post "/admin-messenger/merge-to-public.json", params: { topic_id: pm_topic.id }
        expect(response.status).to eq(403)

        json = response.parsed_body
        expect(json["error"]).to include("participant")
      end
    end

    context "when logged in as staff (admin) who is also a participant" do
      before { sign_in(admin) }

      it "successfully merges" do
        post "/admin-messenger/merge-to-public.json", params: { topic_id: pm_topic.id }
        expect(response.status).to eq(200)

        json = response.parsed_body
        expect(json["success"]).to eq(true)
      end
    end

    context "error cases" do
      before { sign_in(user) }

      it "returns 404 for a non-existent topic" do
        post "/admin-messenger/merge-to-public.json", params: { topic_id: -999 }
        expect(response.status).to eq(404)
      end

      it "returns 422 if the topic is not a PM" do
        public_topic = Fabricate(:topic, user: user)
        post "/admin-messenger/merge-to-public.json", params: { topic_id: public_topic.id }
        expect(response.status).to eq(422)

        json = response.parsed_body
        expect(json["error"]).to include("not a personal message")
      end

      it "returns 422 if the topic was already merged" do
        pm_topic.custom_fields["merged_from_pm"] = true
        pm_topic.save_custom_fields

        post "/admin-messenger/merge-to-public.json", params: { topic_id: pm_topic.id }
        expect(response.status).to eq(422)

        json = response.parsed_body
        expect(json["error"]).to include("already been merged")
      end
    end
  end
end
