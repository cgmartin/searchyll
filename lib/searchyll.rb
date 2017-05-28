require "searchyll/version"
require "jekyll/hooks"
require "jekyll/plugin"
require "jekyll/generator"
require "searchyll/configuration"
require "searchyll/indexer"
require "nokogiri"
require "pp"

begin
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

  Jekyll::Hooks.register [:pages, :posts], :post_render do |post|
    indexer = indexers[post.site]
    next unless indexer

    # strip html
    nokogiri_doc = Nokogiri::HTML(post.output)

    puts %(indexing #{post.url})

    indexer << post.data.merge({
      id:     defined? post.id ? post.id : post.name,
      url:    post.url,
      text:   nokogiri_doc.xpath("//article//text()").to_s.gsub(/\s+/, " ")
    })
  end

rescue => e
  puts e.message
end
