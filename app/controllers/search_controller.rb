class SearchController < ApplicationController

  def index
    ######################################################################
    # Process request params
    ######################################################################

    # Assigns some params to instance variables that can be used in views
    @q = params[:q]
    @page = params[:page] || 1
    @per_page = params[:per_page] || 20
    @sort = params[:sort] || :id


    # If :reset_filters param is set to true, previously set filters (facet queries) will be unset
    if params[:reset_filters]
      params[:filters] = {}
    else
      params[:filters] ||= {}
    end


    # remove filters with no value
    params[:filters].delete_if { |k,v| v.blank? }


    # @filters only include facet values included in the request. Additional filters may be added to the query as needed.
    @filters = !params[:filters].blank? ? params[:filters].clone : {}


    # Convert values of '0' to false
    params.each do |k,v|
      if v == '0'
        params[k] = false
      end
    end


    # define base href used for pagination and filtering
    @base_href_options = {
      q: @q,
      filters: @filters.empty? ? nil : @filters.clone,
      per_page: params[:per_page] ? params[:per_page] : nil
    }


    # Execute Solr query by instantiating the Search model, passing params as options
    #   and then call `execute()` on the instance, assigning the Solr response
    #   to the instance variable @solr_response
    s = Search.new(params)
    @solr_response = s.execute
    @docs = @solr_response['response']['docs']
    @total = @solr_response['response']['numFound']
    @pages = (@total.to_f / @per_page.to_i).ceil


    # prepare facets
    process_facets(params)

    # Prepare pagination variables
    set_pagination_vars(params)

    # Respond according to requested format
    respond_to do |format|
      format.html
      format.json do
        render :json => @solr_response
      end
    end

  end

  private

  def set_pagination_vars(params)
    @per_page = params[:per_page] ? params[:per_page].to_i : 20

    @total = @solr_response['response']['numFound']
    @pages = (@total.to_f/@per_page.to_f).ceil

    @page = params[:page] ? params[:page].to_i : 1

    if @page <= 6
      @page_list_start = 1
    elsif (@page > (@pages - 9)) && ((@pages - 9) > 10)
      @page_list_start = @pages - 9
    else
      @page_list_start = @page - 5
    end

    if (@pages < 10) || ((@page + 4) > @pages)
      @page_list_end = @pages
    else
      @page_list_end = @page_list_start + 9
    end
  end

  def process_facets(params)
    @facets = {}
    if @solr_response['facet_counts']
      raw_facets = @solr_response['facet_counts']['facet_fields']

      # Convert facet_counts array to hash
      raw_facets.each do |f,v|
        if v.kind_of? Array
          @facets[f] = {}
          i = 0
          until i >= raw_facets[f].length
            value = raw_facets[f][i]
            count = raw_facets[f][i + 1]
            @facets[f][value] = count
            i += 2
          end
        else
          @facets[f] = v
        end
      end
    end
    @facets
  end

end
