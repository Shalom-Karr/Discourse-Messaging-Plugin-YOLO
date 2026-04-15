import Component from "@glimmer/component";
import MergeToPublicButton from "../../components/merge-to-public-button";
import i18n from "discourse-common/helpers/i18n";

export default class MergeToPublicBanner extends Component {
  get topic() {
    return this.args.outletArgs?.model?.topic || this.args.outletArgs?.topic;
  }

  get showMergeButton() {
    return this.topic?.can_merge_to_public && this.topic?.isPrivateMessage;
  }

  get wasMerged() {
    return this.topic?.was_merged_from_pm;
  }

  <template>
    {{#if this.wasMerged}}
      <div class="admin-messenger-merged-notice">
        <span class="d-icon d-icon-info-circle"></span>
        {{i18n "admin_messenger.merge_to_public.already_merged"}}
      </div>
    {{/if}}
    {{#if this.showMergeButton}}
      <div class="admin-messenger-merge-banner">
        <p>{{i18n "admin_messenger.merge_to_public.description"}}</p>
        <MergeToPublicButton @topic={{this.topic}} />
      </div>
    {{/if}}
  </template>
}
