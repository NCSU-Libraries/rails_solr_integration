class SearchIndex

  @@solr_url = "http://#{ENV['solr_host']}:#{ENV['solr_port']}#{ENV['solr_core_path']}"
  @@batch_size = 50


  # Remove all records from the index
  def self.wipe_index
    @solr = RSolr.connect :url => @@solr_url
    @solr.delete_by_query '*:*'
    @solr.commit
  end


  # Update a single record in the index
  def self.update_record(record)
    @solr = RSolr.connect :url => @@solr_url
    doc = record.solr_doc_data
    @solr.add doc
    @solr.commit
  end


  # Delete given record from the index
  def self.delete_record(record)
    @solr = RSolr.connect :url => @@solr_url
    @solr.delete_by_query "id:#{ record.solr_id }"
    @solr.commit
  end


  # Index all eligible records
  def self.execute_full
    @solr = RSolr.connect :url => @@solr_url
    update_batch = Proc.new do |records|
      batch = []
      records.each { |r| batch << r.solr_doc_data }
      if @solr.add batch
        print '.'
      end
      @solr.commit
    end

    ###
    # Add to 'classes' array all model classes to be indexed
    classes = [Foo]
    ###

    classes.each do |c|
      c.find_in_batches(batch_size: @@batch_size) do |records|
        update_batch.call(records)
      end
    end
  end


  def self.execute_clean
    wipe_index
    execute_full
  end


  private


  def update_batch(records)
    batch = []
    records.each { |r| batch << r.solr_doc_data }
    if @solr.add batch
      print '.'
    end
    @solr.commit
  end


end
