import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { fn } from "@ember/helper";
import DButton from "discourse/components/d-button";

export default class CategoryNode extends Component {
  <template>
    <div class="category-node" style="padding-left: 20px;">
      <label>
        <input type="checkbox" checked={{@selectedCategoryIds.has @category.id}} {{on "click" (fn @toggleCategory @category.id)}}>
        {{@category.name}}
      </label>
      <div class="subcategories">
        {{#each @category.subcategories as |subcategory|}}
          <this @category={{subcategory}} @toggleCategory={{@toggleCategory}} @loadMoreSubcategories={{@loadMoreSubcategories}} @selectedCategoryIds={{@selectedCategoryIds}} />
        {{/each}}
        {{#if @category.has_more_subcategories}}
          <DButton @action={{fn @loadMoreSubcategories @category}} @label="Show more" />
        {{/if}}
      </div>
    </div>
  </template>
}