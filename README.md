# Rails Solr integration pattern

A Rails design pattern for implementing Solr indexing and search.


## Configuration


### Rsolr

This project depends on the [RSolr library](https://github.com/rsolr/rsolr). Include it in your Gemfile:

```
gem 'rsolr'
```


### Solr set up

You must have a running Solr instance that your Rails app can connect to. Generally, this will be a multi-core set up, with one core dedicated to your application.

To prepare to connect to your Solr core:

1. Copy `config/solr.yml` to your 'config' directory, and update with specific connection information
2. Add the following to config/application.rb:<br>
```
ENV.update YAML.load_file('config/solr.yml')[Rails.env] rescue {}
```

The rest of these instructions assume that you have a core and schema set up and that you know what fields are available in your schema.


### Indexing

#### app/models/concerns/solr_doc.rb

This is an ActiveSupport::Concern that you will use to extend the models you need to index.
It provides some common class and instance methods that you can use on your models, the most important being `solr_doc_data()`, which generates the record (a hash of field names/values) that is sent to Solr. It is important that the hash keys correspond to fields in your schema. Detailed instructions in code.


### Search

#### app/models/search.rb

The Search model is used to execute queries against a Solr index. By default, searches will use the eDisMax query parser, which attempts to match the query term in one or more fields, giving different weight to matches in different fields according the parameters sent to Solr using the 'qf' (query fields) parameter. These values should be specified in this file (assigned to the `@@query_fields` class variable). You can also specify default values for certain other query paramters here. Detailed instructions in code.


## Usage


### Models

In each model you want to index and make searchable, add this at the top of the class definition:

```
include SolrDoc
```

This will add the following instance methods to the model:

* update_index() - adds or updates the record in the index
* delete\_from_index() - removes the record from the index
* solr\_doc_data() - prepares and returns a hash of record attributes sent to Solr. See configuration above.
* solr_id - generates the value for the Solr id field


### Controllers/views/helpers

At a minimum, you will need a search controller with at least one action, and a route to enable that action to process HTTP requests.

#### app/controllers/search_controller.rb

This file provides a basic implementation of a search controller.

#### config/routes.rb

Include this line to provide a route to your Search controller:

```
get 'search(.:format)' => 'search#index', as: 'searches'
```

#### app/helpers/search_helper.rb

Provides a variety of helper methods for use in views.

#### app/views/search/index.html.erb

Provides a very basic implementation of search form and results.
