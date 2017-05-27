require "searchyll/version"
require "jekyll/hooks"
require "jekyll/plugin"
require "jekyll/generator"
require "searchyll/configuration"
require "searchyll/indexer"
require "nokogiri"

if Jekyll.env == 'production'
  begin
    indexers = {}

    Jekyll::Hooks.register(:site, :pre_render) do |site|
      config = Searchyll::Configuration.new(site)
      indexers[site] = Searchyll::Indexer.new(config)
      indexers[site].start
    end

    Jekyll::Hooks.register :site, :post_render do |site|
      indexers[site].finish
    end

    Jekyll::Hooks.register :posts, :post_render do |post|
      # strip html
      nokogiri_doc = Nokogiri::HTML(post.output)

      puts %(indexing #{post.url})

      indexer = indexers[post.site]
      indexer << post.data.merge({
        id:     post.id,
        url:    post.url,
        text:   nokogiri_doc.xpath("//article//text()").to_s.gsub(/\s+/, " ")
      })
    end

  rescue => e
    puts e.message
  end

else
  puts "searchyll: skipping processing for a non-production build"
end


