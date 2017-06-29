require 'active_support/concern'

module SolrDoc
  extend ActiveSupport::Concern
  include ActionView::Helpers::SanitizeHelper

  included do

    after_commit :update_index, on: [:create, :update]

    before_destroy :delete_from_index

    # Prepare Solr document hash for the record
    def solr_doc_data
      doc = {}


      # To support indexing of records of different classes, create a unique id by concatenating
      #   class name (downcased and underscored) and record id (see solr_id below)...
      doc[:id] = solr_id


      # ... then record class name and record id as record_type, record_id
      doc[:record_type] = self.class.to_s.underscore
      doc[:record_id] = self.id


      # This will add all attributes that correspond to database columns (make sure these are all in the schema, or modify)
      attrs = self.class.column_names.map { |n| n.to_sym }
      attrs.each do |a|
        if a != :id
          doc[a] = self[a]
        end
      end


      ######################################################
      # Here you can add other elements to the doc as needed
      #
      # If you are indexing records from multiple models, it's a good idea to use a case statement here
      #   to specify which fields to index for which model, e.g.:
      #
      # case self
      # when Foo
      #   doc['foo_attribute'] = self.foo_attribute
      # when Boo
      #   doc['boo_attribute'] = self.boo_attribute
      # end
      #
      ######################################################


      # remove nil/empty values
      doc.delete_if { |k,v| nil_or_empty?(v) }


      doc
    end


    def solr_id
      "#{ self.class.to_s.underscore }_#{ id }"
    end


    # Updates the record in the Solr index
    def update_index
      self.reload
      SearchIndex.update_record(self)
    end


    # Remove the record from the Solr index
    def delete_from_index
      SearchIndex.delete_record(self)
    end

  end

end
