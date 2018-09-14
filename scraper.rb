#!/usr/bin/ruby
# frozen_string_literal: true

# Convert OpenPolis lists to CSV

require 'pry'
require 'scraped'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

sources = {
  'Senate'              => 'https://politici.openpolis.it/istituzione/senatori/5',
  'Chamber of Deputies' => 'https://politici.openpolis.it/istituzione/deputati/4',
}

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_person(url)
  noko = noko_for(url)
  data = {
    image:    noko.css('img#foto_politico/@src').text,
    email:    noko.css('div.contacts a[href*="mailto:"]/@href').map { |u| u.value.gsub('mailto:', '') }.uniq.join(';'),
    facebook: noko.css('div.contacts a[href*="facebook"]/@href').map(&:value).uniq.join(';'),
    twitter:  noko.css('div.contacts a[href*="twitter"]/@href').map(&:value).uniq.join(';'),
  }

  # TODO: This is a workaround for mailto: links containing YouTube links it
  # can be removed once they stop appearing on e.g. this page:
  # http://politici.openpolis.it/politico/franco-vazio/316193.
  data[:email] = data[:email].split(';').reject { |e| e.start_with?('http') }.join(';')

  data[:image] = URI.join(url, URI.escape(data[:image])).to_s unless data[:image].to_s.empty?
  data
end

ScraperWiki.sqliteexecute('DROP TABLE data') rescue nil

sources.each do |house, url|
  noko = noko_for(url)
  noko.css('div.genericblock table tr:nth-child(n+3)').each do |tr|
    tds = tr.css('td')
    link = URI.join(url, tds[0].css('a/@href').text).to_s
    data = {
      id:      link.split('/').last,
      name:    tds[0].text.tidy,
      surname: tds[0].at_css('.surname').text.tidy,
      party:   tds[1].text.tidy,
      area:    tds[2].text.tidy,
      house:   house,
      term:    18,
      source:  link,
    }.merge(scrape_person(link))
    ScraperWiki.save_sqlite([:id], data)
  end
end
