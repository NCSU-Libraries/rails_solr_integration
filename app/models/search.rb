class Search

  ######################################
  #
  # USAGE:
  #
  # 1. Create an instance of this model, passing desired options (described below) as a hash, e.g.:
  #    search = Search.new( { q: 'dogs' } )
  # 2. Execute the query with execute():
  #    search.execute()
  #
  # Returns a Solr response object
  #
  #
  #
  # AVAILABLE OPTIONS:
  #
  # :q
  #   The query string (if left blank all records will be returned from initial query)
  #
  # :filters
  #   A hash of field values to filter results, used to build Solr fq parameter
  #   SEE: https://wiki.apache.org/solr/CommonQueryParameters#fq
  #
  # :per_page
  #   Number of records to return per page (default: 20)
  #
  # :page
  #   Results page to return (default: 1)
  #
  # :lucene
  #   Set to true to use standard Lucene query parser (default false)
  #     SEE: https://cwiki.apache.org/confluence/display/solr/The+Standard+Query+Parser
  #   If this is not set to true, the eDisMax parser will be used
  #     SEE: https://cwiki.apache.org/confluence/display/solr/The+Extended+DisMax+Query+Parser
  #
  # :wt
  #   Set Solr response format (default: ruby, which is usually what you want)
  #
  # :start
  #   Specifies the starting record number (of total matching results)
  #
  # :sort
  #   Field to use for sorting results - must include 'asc' or 'desc', eg 'title asc'
  #
  # :group
  #   Set to true to use Solr result grouping
  #   SEE: https://cwiki.apache.org/confluence/display/solr/Result+Grouping
  #   If set to true, options hash must also include 'group.field' (key is a string rather than a symbol)
  #     indicating the field to group on
  #   May also optionally include 'group.limit' (default: 5)
  #
  # :facet
  #   Set to true to use Solr results faceting
  #   SEE: https://cwiki.apache.org/confluence/display/solr/Faceting
  #   If set to true, options hash must also include 'facet.field' (key is a string rather than a symbol)
  #   Additional optional fields: 'facet.field', 'facet.limit', 'facet.mincount'
  #
  # :bq
  #   Solr bq (boost query) parameter
  #   SEE: https://cwiki.apache.org/confluence/display/solr/The+DisMax+Query+Parser#TheDisMaxQueryParser-Thebq(BoostQuery)Parameter
  #
  # :mm
  #   Solr mm (minimum match) parameter
  #   SEE: https://cwiki.apache.org/confluence/display/solr/The+DisMax+Query+Parser#TheDisMaxQueryParser-Themm(MinimumShouldMatch)Parameter
  #
  # :pf
  #   Solr 'pf' (phrase field) parameter
  #   SEE: https://cwiki.apache.org/confluence/display/solr/The+DisMax+Query+Parser#TheDisMaxQueryParser-Thepf(PhraseFields)Parameter
  #
  # :ps
  #   Solr 'ps' (phrase slop) parameter
  #   SEE: https://cwiki.apache.org/confluence/display/solr/The+DisMax+Query+Parser#TheDisMaxQueryParser-Theps(PhraseSlop)Parameter
  #
  # :fq
  #  Explicitly sets the Solr 'fq' (filter query) parameter, but using :filters (see above) is easier
  #
  ######################################



  ######################################
  # CONFIGURATION
  ######################################

  ######################################
  # Query fields
  # Set Solr :qf (parameter, which specifies fields to search and boost factor for each
  # SEE: https://cwiki.apache.org/confluence/display/solr/The+DisMax+Query+Parser#TheDisMaxQueryParser-Theqf(QueryFields)Parameter
  # Keys in @@query_fields hash are field names, values are associated boost factors
  ######################################

  @@query_fields = {
    'title' => 1000,
    'description' => 500
  }

  ######################################
  # Set defaults for options (described above):
  ######################################

  # :wt
  @@wt_default = :ruby

  # :per_page
  @@per_page_default = 20

  # :mm
  @@mm_default = '2<75%'

  # :ps
  @@ps_default = 3

  # 'facet.limit'
  @@facet_limit_default = -1

  # 'facet.mincount'
  @@facet_mincount_default = 1

  # 'group.limit'
  @@group_limit_default = 5
  ###

  # Solr URL - constructed here using ENV vars declared on initialization
  @@solr_url = "http://#{ENV['solr_host']}:#{ENV['solr_port']}#{ENV['solr_core_path']}"

  ######################################
  # END CONFIGURATION
  ######################################



  def initialize(options = {})
    @options = options.clone
    @q = options[:q]
    @filters = !options[:filters].blank? ? options[:filters] : {}
    @page = options[:page] || 1
    @per_page = options[:per_page] ? options[:per_page].to_i : @@per_page_default
    @lucene = options[:lucene] || nil
    @start = options[:start] || ((@page.to_i - 1) * @per_page)
    @sort = options[:sort]
  end

  attr_accessor :q, :page, :per_page, :filters, :wt, :lucene


  def set_solr_params
    # Specify Ruby as Solr response format
    @solr_params = { :wt => options[:wt] || @@wt_default }
    @solr_params[:start] = @start
    @solr_params[:rows] = self.per_page
    @solr_params[:sort] = @sort ? @sort : nil

    if !self.lucene
      @solr_params[:defType] = 'edismax'
      @solr_params['q.alt'] = '*:*'

      # query string
      if !self.q.blank?
        @solr_params[:q] = self.q
      end


      ## result grouping
      if @options[:group] && @options['group.field']
        @solr_params['group'] = true
        @solr_params['group.field'] = @options['group.field']
        @solr_params['group.limit'] = @options['group.limit'] || @@group_limit_default
      end


      ## highlighting
      # @solr_params['hl'] = true
      # @solr_params['hl.fl'] = ''
      # @solr_params['hl.simple.pre'] = "<mark>"
      # @solr_params['hl.simple.post'] = "</mark>"


      # Set qf using @@query_fields config
      @solr_params[:qf] = ''
      @@query_fields.each do |k,v|
        @solr_params[:qf] += " #{k}"
        @solr_params[:qf] += v ? "^#{v}" : ''
      end
      @solr_params[:qf].strip!


      ## facets
      if @options[:facet] && @options['facet.field']
        @solr_params['facet'] = true
        @solr_params['facet.field'] = []
        @solr_params['facet.limit'] = @options['facet.limit'] || @@facet_limit_default
        @solr_params['facet.mincount'] = @options['facet.mincount'] || @@facet_mincount_default
      end

      # boost query
      @solr_params[:bq] = @options[:bq] || []

      # minimum match
      @solr_params[:mm] = @options[:mm] || @@mm_default

      # phrase fields/slop
      @solr_params[:pf] = options[:pf] || @@query_fields.keys
      @solr_params[:ps] = options[:ps] || @@ps_default

    else
      @solr_params[:defType] = 'lucene'
      @solr_params[:q] = self.q
    end

    # process filters (selected facets or :fq passed in params)
    if @options[:fq]
      @solr_params['fq'] = @options[:fq]
    else
      @fq = []
      if !@filters.blank?
        @filters.each do |k,v|
          case v
          when String
            # don't quote value for range queries
            if v.match(/^\[/)
              @fq << "#{k}: #{v}"
            elsif !nil_or_empty?(v)
              @fq << "#{k}: \"#{v}\""
            end
          when Array
            if !nil_or_empty?(v)
              v.each { |f| @fq << "#{k}: \"#{f}\"" }
            end
          else
            @fq << "#{k}: #{v}"
          end
        end
      end
      @solr_params['fq'] = @fq
    end

    @solr_params
  end


  def execute
    @solr = RSolr.connect :url => @@solr_url
    set_solr_params()
    @response = @solr.paginate self.page, self.per_page, "select", :params => @solr_params
  end


end
