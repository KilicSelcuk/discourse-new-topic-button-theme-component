import Component from "@glimmer/component";
import { getOwner } from "@ember/application";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import DButtonTooltip from "discourse/components/d-button-tooltip";
import routeAction from "discourse/helpers/route-action";
import Category from "discourse/models/category";
import i18n from "discourse-common/helpers/i18n";
import I18n from "discourse-i18n";
import DTooltip from "float-kit/components/d-tooltip";

export default class CustomHeaderTopicButton extends Component {
  @service composer;
  @service currentUser;
  @service router;
  @service siteSettings;

  dateolustur = new Date(Date.now()).toLocaleString('tr-TR', {  year: 'numeric', month: 'numeric', day: 'numeric', hour: 'numeric', minute: 'numeric', second: 'numeric' });

  canCreateTopic = this.currentUser?.can_create_topic;

 
  topic = this.router.currentRouteName.includes("topic")
    ? getOwner(this).lookup("controller:topic")
    : null;

  get userHasDraft() {
    return this.currentUser?.get("has_topic_draft");
  }

  get currentTag() {
    if (this.router.currentRoute.attributes?.tag?.id) {
      return [
        this.router.currentRoute.attributes?.tag?.id,
        ...(this.router.currentRoute.attributes?.additionalTags ?? []),
      ]
        .filter(Boolean)
        .filter((t) => !["none", "all"].includes(t))
        .join(",");
    } else {
      return this.topic?.model?.tags?.join(",");
    }
  }

  get currentCategory() {
    return (
      this.router.currentRoute.attributes?.category ||
      (this.topic?.model?.category_id
        ? Category.findById(this.topic?.model?.category_id)
        : null)
    );
  }

  get canCreateTopicWithTag() {
    return (
      !this.router.currentRoute.attributes?.tag?.staff ||
      this.currentUser?.staff
    );
  }

  get canCreateTopicWithCategory() {
    return !this.currentCategory || this.currentCategory?.permission;
  }

  get createTopicDisabled() {
    if (this.userHasDraft) {
      return false;
    } else {
      return (
        !this.canCreateTopic ||
        !this.canCreateTopicWithCategory ||
        !this.canCreateTopicWithTag ||
        this.currentCategory?.read_only_banner
      );
    }
  }

  get createTopicLabel() {
    return this.userHasDraft
      ? I18n.t("topic.open_draft")
      : settings.new_topic_button_text;
  }

  get createTopicTitle() {
    if (!this.userHasDraft && settings.new_topic_button_title.length) {
      return settings.new_topic_button_title;
    } else {
      return this.createTopicLabel;
    }
  }

  get showAnon() {
    if (settings.show_to_anon && !this.currentUser) {
      return true;
    }
  }

  @action
  createTopic() {
    this.composer.openNewTopic({
      preferDraft: true,
      category: this.currentCategory,
      tags: this.currentTag,
      create_as_post_voting: "true",
    });
  }

  @action
  createTopic_resimli() {
    this.composer.openNewTopic({
      preferDraft: true,
      category: this.currentCategory,
      tags: ["resimli-soru"],
      title: "Hızlı resimli soru sor - "+this.dateolustur,
    });
  }

  <template>
    {{#if this.currentUser}}
      <DButtonTooltip>
        <:button>
          <DButton
            @action={{this.createTopic_resimli}}
            @translatedLabel=""
            @translatedTitle="Resimli soru sor"
            @icon=image
            id="new-create-topic-resimli"
            class="btn-primary header-create-topic-resimli"
            disabled={{this.createTopicDisabled}}
          />
          <DButton
            @action={{this.createTopic}}
            @translatedLabel=""
            @translatedTitle="Yeni konu/soru oluştur"
            @icon=question-circle
            id="new-create-topic"
            class="btn-primary header-create-topic"
            disabled={{this.createTopicDisabled}}
          />
        </:button>
        <:tooltip>
          {{#if this.createTopicDisabled}}
            <DTooltip
              @icon="info-circle"
              @content={{i18n (themePrefix "button_disabled_tooltip")}}
            />
          {{/if}}
        </:tooltip>
      </DButtonTooltip>
    {{/if}}

    {{#if this.showAnon}}
      <DButton
        @action={{routeAction "showLogin"}}
        @translatedLabel={{this.createTopicLabel}}
        @translatedTitle={{this.createTopicTitle}}
        @icon={{settings.new_topic_button_icon}}
        {{! template-lint-disable no-duplicate-id }}
        id="new-create-topic"
        class="btn-primary header-create-topic"
      />
    {{/if}}
  </template>
}
