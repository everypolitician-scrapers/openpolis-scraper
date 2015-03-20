#!/usr/bin/ruby

# Convert OpenPolis lists to CSV

require 'csv'
require 'nokogiri'
require 'open-uri/cached'
require 'pry'

sources = { 
  'Senate' => 'http://politici.openpolis.it/istituzione/senatori/5',
  'Chamber of Deputies' => 'http://politici.openpolis.it/istituzione/deputati/4',
}

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

sources.each do |house, url|
  noko = noko_for(url)
  noko.css('div.genericblock table tr:nth-child(n+3)').each do |tr|
    info = tr.css('td')
    data = { 
      id: info[0].at_css('a')['href'].split('/').last,
      name: info[0].text.strip,
      surname: info[0].at_css('.surname').text.strip,
      group: info[1].text.strip,
      area: info[2].text.strip,
      house: house,
    }
    puts data
  end
end
