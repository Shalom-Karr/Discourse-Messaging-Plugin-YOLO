import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DButton from "discourse/components/d-button";
import i18n from "discourse-common/helpers/i18n";

export default class MergeToPublicButton extends Component {
  @service dialog;
  @service router;
  @tracked merging = false;

  get canMerge() {
    return this.args.topic?.can_merge_to_public;
  }

  get alreadyMerged() {
    return this.args.topic?.was_merged_from_pm;
  }

  @action
  confirmMerge() {
    this.dialog.yesNoConfirm({
      message: i18n("admin_messenger.merge_to_public.confirm"),
      didConfirm: () => this.performMerge(),
    });
  }

  async performMerge() {
    this.merging = true;
    try {
      const result = await ajax("/admin-messenger/merge-to-public", {
        type: "POST",
        data: { topic_id: this.args.topic.id },
      });

      if (result.success) {
        this.dialog.alert(i18n("admin_messenger.merge_to_public.success"));
        this.router.transitionTo("topic.fromParams", {
          slugOrId: result.topic_id,
        });
        window.location.reload();
      }
    } catch (e) {
      popupAjaxError(e);
    } finally {
      this.merging = false;
    }
  }

  <template>
    {{#if this.canMerge}}
      <DButton
        @action={{this.confirmMerge}}
        @icon="globe"
        @label="admin_messenger.merge_to_public.title"
        @disabled={{this.merging}}
        class="btn-primary merge-to-public-btn"
      />
    {{/if}}
  </template>
}
