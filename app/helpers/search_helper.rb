module SearchHelper

  include ApplicationHelper

  def search_pagination
    if @pages > 1
      output = '<div class="row">'
      output << '<ul class="pagination">'

      if @page_list_start == 1
        output << "<li class=\"arrow unavailable\">&laquo;</li>"
      else
        output << "<li class=\"arrow\">#{link_to('&laquo;'.html_safe, @base_href)}</li>"
      end

      (@page_list_start..@page_list_end).each do |n|
        href_options = @base_href_options.clone
        href_options[:page] = n
        href = searches_path(href_options)

        if n == @page
          output << "<li class=\"current\">"
        else
          output << "<li>"
        end

        output << link_to(n.to_s, href)
        output << "</li>"
      end

      last_href_options = @base_href_options.clone
      last_href_options[:page] = @pages
      last_href = searches_path(last_href_options)

      if @page_list_end == @pages
        output << "<li class=\"arrow unavailable\">&raquo;</li>"
      else
        output << "<li class=\"arrow\">#{link_to('&raquo;'.html_safe, last_href)}</li>"
      end

      output << '</ul>'
      output << '</div>'
      output.html_safe
    end
  end


  def facet_options
    output = '<div id="search-facets-options">'
    output << "<h2 class=\"filter-heading\">#{ filters_heading }</h2>"

    # Populate array assigned to ignore_facets with facets included in the response
    #   but for whatever reason you don't want to display to users.
    ignore_facets = []

    @facets.each do |k,v|
      if !ignore_facets.include?(k) && !v.empty?
        output << '<div class="facet">'
        output << "<h3>#{ facet_heading(k) }</h3>"
        output << facet_option_values(k, v)
        output << '</div>'
      end
    end

    output << '</div>'
    output.html_safe
  end


  def facet_heading(facet)
    facet.gsub(/_/, ' ').split.map(&:capitalize).join(' ')
  end


  def facet_option_values(facet, values)
    content = ''
    content << '<ul>'
    values.each do |v,count|
      content << "<li>#{ filter_link(facet, v, multivalued: true) }</li>"
    end
    content << '</ul>'
    output = values.length > 5 ? "<div class=\"scrollable\">#{ content }</div>" : content
    output.html_safe
  end


  def filter_link(facet,value,options={})
    output = ''
    label = options[:label] || value
    href_options = @base_href_options.clone

    filters = @filters.clone

    active_facet_value = nil

    if filters[facet]
      if (options[:multivalued] && filters[facet].include?(value)) ||
        (filters[facet] == value || value === true)
          active_facet_value = true
      end
    end

    if active_facet_value

      if filters[facet].kind_of? Array
        filters[facet].delete(value)
      else
        filters.delete(facet)
      end

      output << '<span class="active-facet">'
      output << label
      remove_label = '<i class="fa fa-times-circle"></i>'
      href_options[:filters] = filters
      href = searches_path(href_options)

      output << link_to(remove_label.html_safe, href, { class: 'remove-facet-link', title: 'Remove filter' } )
      output << '</span>'

    elsif filters[facet] && !options[:multivalued] && !active_facet_value
      # skip
    else
      if options[:multivalued]
        filters[facet] ||= []
        filters[facet] << value
      else
        filters[facet] = value
      end
      href_options[:filters] = filters
      href = searches_path(href_options)
      output << link_to(label, href, class: 'search-filter-link')
    end
    output.html_safe
  end


  def active_filters
    if !@filters.blank?

      output = '<div class="row" id="active-filters">'
      output << "<span class=\"label\">#{'Filter'.pluralize(@filters.length)}:</span> "
      @filters.each do |k,v|
        v.each do |value|
          output << filter_link(k, value, multivalued: true)
        end
      end
      output << '</div>'
      output.html_safe
    end
  end

end
