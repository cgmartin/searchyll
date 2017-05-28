require "searchyll/version"
require "jekyll/hooks"
require "jekyll/plugin"
require "jekyll/generator"
require "searchyll/configuration"
require "searchyll/indexer"
require "nokogiri"

indexers = {}

Jekyll::Hooks.register(:site, :pre_render) do |site|
  next unless Jekyll.env == 'production'
  config = Searchyll::Configuration.new(site)
  if config.elasticsearch_enabled
    indexers[site] = Searchyll::Indexer.new(config)
    indexers[site].start
  else
    puts 'Searchyll: Skipping Elasticsearch indexing...'
  end
end

Jekyll::Hooks.register :site, :post_render do |site|
  indexers[site].finish if indexers[site]
end

def index_post(indexer, post, type)
  # strip html
  nokogiri_doc = Nokogiri::HTML(post.output)

  puts %(indexing #{post.url})

  indexer << post.data.merge({
    type:   type,
    url:    post.url,
    text:   nokogiri_doc.xpath("//article//text()").to_s.gsub(/\s+/, " ")
  })
end

Jekyll::Hooks.register :pages, :post_render do |post|
  index_post(indexers[post.site], post, 'page') if indexers[post.site]
end

Jekyll::Hooks.register :posts, :post_render do |post|
  index_post(indexers[post.site], post, 'post') if indexers[post.site]
end

Jekyll::Hooks.register :documents, :post_render do |post|
  index_post(indexers[post.site], post, 'document') if indexers[post.site]
end
