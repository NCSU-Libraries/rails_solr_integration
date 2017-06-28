class SearchController < ApplicationController

  def index
    ######################################################################
    # Process request params
    ######################################################################

    # Assigns some params to instance variables that can be used in views
    @q = params[:q]
    @page = params[:page] || 1
    @per_page = params[:per_page] || 20
    @total = Order.count
    @pages = (@total.to_f / @per_page.to_i).ceil
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


    # Respond according to requested format
    respond_to do |format|
      format.html
      format.json do
        render :json => @solr_response
      end
    end

  end

end
