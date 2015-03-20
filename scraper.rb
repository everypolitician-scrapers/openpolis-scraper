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
    name,group,area = tr.css('td').map { |td| td.text.strip }
    data = { 
      name: name,
      group: group,
      area: area,
      house: house,
    }
    puts data
  end
end
