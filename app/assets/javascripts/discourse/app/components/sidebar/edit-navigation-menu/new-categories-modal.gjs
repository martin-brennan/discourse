import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { TrackedSet } from "@ember-compat/tracked-built-ins";
import DButton from "discourse/components/d-button";
import EditNavigationMenuModal from "discourse/components/sidebar/edit-navigation-menu/modal";
import CategoryNode from "discourse/components/sidebar/edit-navigation-menu/category-node";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import Category from "discourse/models/category";
import { i18n } from "discourse-i18n";

export default class NewSidebarEditNavigationMenuCategoriesModal extends Component {
  @service currentUser;
  @service siteSettings;

  @tracked categories = [];
  @tracked filter = "";
  @tracked loading = true;
  @tracked hasMore = false;
  offset = 0;

  constructor() {
    super(...arguments);
    this.selectedCategoryIds = new TrackedSet(this.currentUser.sidebar_category_ids);
    this.loadCategories();
  }

  @action
  async loadCategories(parentId = null) {
    this.loading = true;
    try {
      const result = await ajax("/categories/hierarchical_search", {
        data: {
          term: this.filter,
          parent_category_id: parentId,
          offset: parentId ? (this.findCategory(this.categories, parentId).subcategories.length) : this.offset
        }
      });

      if (parentId) {
        const parent = this.findCategory(this.categories, parentId);
        parent.subcategories = [...parent.subcategories, ...result.categories];
        parent.has_more_subcategories = result.has_more;
      } else {
        this.categories = [...this.categories, ...result.categories];
        this.hasMore = result.has_more;
        this.offset += result.categories.length;
      }
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.loading = false;
    }
  }

  @action
  loadMore() {
    this.loadCategories();
  }

  @action
  loadMoreSubcategories(category) {
    this.loadCategories(category.id);
  }

  findCategory(categories, categoryId) {
    for (const category of categories) {
      if (category.id === categoryId) {
        return category;
      }
      if (category.subcategories) {
        const found = this.findCategory(category.subcategories, categoryId);
        if (found) {
          return found;
        }
      }
    }
  }

  @action
  onFilterInput(filter) {
    this.filter = filter.toLowerCase().trim();
    this.offset = 0;
    this.categories = [];
    this.loadCategories();
  }

  @action
  toggleCategory(categoryId) {
    if (this.selectedCategoryIds.has(categoryId)) {
      this.selectedCategoryIds.delete(categoryId);
    } else {
      this.selectedCategoryIds.add(categoryId);
    }
  }

  @action
  async save() {
    this.saving = true;
    const initialSidebarCategoryIds = this.currentUser.sidebar_category_ids;

    this.currentUser.set("sidebar_category_ids", [...this.selectedCategoryIds]);

    try {
      await this.currentUser.save(["sidebar_category_ids"]);
      this.args.closeModal();
    } catch (error) {
      this.currentUser.set("sidebar_category_ids", initialSidebarCategoryIds);
      popupAjaxError(error);
    } finally {
      this.saving = false;
    }
  }

  <template>
    <EditNavigationMenuModal
      @title="sidebar.categories_form_modal.title"
      @disableSaveButton={{this.saving}}
      @save={{this.save}}
      @onFilterInput={{this.onFilterInput}}
      @closeModal={{@closeModal}}
      class="sidebar__edit-navigation-menu__categories-modal"
    >
      <div class="category-tree">
        {{#each this.categories as |category|}}
          <CategoryNode @category={{category}} @toggleCategory={{this.toggleCategory}} @loadMoreSubcategories={{this.loadMoreSubcategories}} @selectedCategoryIds={{this.selectedCategoryIds}} />
        {{/each}}
        {{#if this.hasMore}}
          <DButton @action={{this.loadMore}} @label="Show more" />
        {{/if}}
        {{#if this.loading}}
          <div>Loading...</div>
        {{/if}}
      </div>
    </EditNavigationMenuModal>
  </template>
}