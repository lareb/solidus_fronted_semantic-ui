Spree::FrontendHelper.module_eval do

  def body_class
  @body_class ||= content_for?(:sidebar) ? 'ui two column grid' : 'ui grid'
  @body_class
  end
  def link_to_cart(text = nil)
    text = text ? h(text) : Spree.t('cart')
    css_class = nil

    if simple_current_order.nil? or simple_current_order.item_count.zero?
      text = "<i class='shopping cart icon'></i> #{text}: (#{Spree.t('empty')})"
      css_class = 'empty'
    else
      text = "<i class='shopping cart icon'></i> #{text}: (#{simple_current_order.item_count})  <span class='amount'>#{simple_current_order.display_total.to_html}</span>"
      css_class = 'full'
    end

    link_to text.html_safe, spree.cart_path, :class => "cart-info #{css_class}"
  end

  def flash_messages(opts = {})
    opts[:ignore_types] = [:commerce_tracking].concat(Array(opts[:ignore_types]) || [])

    flash.each do |msg_type, text|
      unless opts[:ignore_types].include?(msg_type)
        concat(content_tag :div, text, class: "alert alert-#{msg_type}")
      end
    end
    nil
  end

  def taxons_tree(root_taxon, current_taxon, max_level = 1)
    return '' if max_level < 1 || root_taxon.children.empty?
    content_tag :div, class: 'list-group' do
      root_taxon.children.map do |taxon|
        css_class = (current_taxon && current_taxon.self_and_ancestors.include?(taxon)) ? 'list-group-item active' : 'list-group-item'
        link_to(taxon.name, seo_url(taxon), class: css_class) + taxons_tree(taxon, current_taxon, max_level - 1)
      end.join("\n").html_safe
    end
  end

  def breadcrumbs(taxon, separator="&nbsp;")
    return "" if current_page?("/") || taxon.nil?
    separator = raw(separator)
    crumbs = [content_tag(:li, link_to(Spree.t(:home), spree.root_path) + separator)]
    if taxon
      crumbs << content_tag(:li, link_to(Spree.t(:products), products_path) + separator)
      crumbs << taxon.ancestors.collect { |ancestor| content_tag(:li, link_to(ancestor.name , seo_url(ancestor)) + separator) } unless taxon.ancestors.empty?
      crumbs << content_tag(:li, content_tag(:span, link_to(taxon.name , seo_url(taxon))), class: 'active')
    else
      crumbs << content_tag(:li, content_tag(:span, Spree.t(:products)), class: 'active')
    end
    crumb_list = content_tag(:ol, raw(crumbs.flatten.map{|li| li.mb_chars}.join), class: 'breadcrumb')
    content_tag(:nav, crumb_list, id: 'breadcrumbs', class: 'column')
  end

  def checkout_progress
    states = checkout_states
    items = states.map do |state|
      text = Spree.t("order_state.#{state}").titleize

      css_classes = []
      current_index = states.index(@order.state)
      state_index = states.index(state)

      if state_index < current_index
        css_classes << 'completed'
        text = link_to text, checkout_state_path(state)
      end

      css_classes << 'next' if state_index == current_index + 1
      css_classes << 'active' if state == @order.state
      css_classes << 'first' if state_index == 0
      css_classes << 'last' if state_index == states.length - 1

      # No more joined classes. IE6 is not a target browser.
      # Hack: Stops <a> being wrapped round previous items twice.
      if state_index < current_index
        content_tag('li', text, class: css_classes.join(' '))
      else
        content_tag('li', content_tag('a', text), class: css_classes.join(' '))
      end

    end

    content_tag('ul', raw(items.join("\n")), class: 'progress-steps nav nav-pills nav-justified', id: "checkout-step-#{@order.state}")
  end


end
