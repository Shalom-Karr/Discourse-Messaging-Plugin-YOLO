import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "admin-messenger-init",

  initialize() {
    withPluginApi("1.0", (api) => {
      api.modifyClass("model:composer", {
        pluginId: "discourse-admin-messenger",

        get adminMessengerEnabled() {
          return this.siteSettings?.admin_messenger_enabled;
        },
      });

      api.composerBeforeSave(() => {
        const composer = api.container.lookup("service:composer")?.model;
        if (!composer) return;

        const siteSettings = api.container.lookup("service:site-settings");
        const currentUser = api.getCurrentUser();

        if (
          !siteSettings.admin_messenger_enabled ||
          composer.archetypeId !== "private_message" ||
          currentUser?.staff
        ) {
          return;
        }

        const requiredGroup =
          siteSettings.admin_messenger_required_group || "admins";

        const targetGroups = composer.targetGroups || "";
        const groupList = targetGroups
          .split(",")
          .map((g) => g.trim().toLowerCase());

        if (!groupList.includes(requiredGroup.toLowerCase())) {
          const updated = targetGroups
            ? `${targetGroups},${requiredGroup}`
            : requiredGroup;
          composer.set("targetGroups", updated);
        }
      });
    });
  },
};
