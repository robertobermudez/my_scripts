#!/usr/bin/env ruby

require 'httparty'
require 'nokogiri'
require 'pry-byebug'
require 'pdfkit'

BASE_URL= 'https://ruby-gnome2.osdn.jp/'

unless File.exist? 'tut_html.html'
  tut_page = BASE_URL + 'hiki.cgi?tut-gtk'
  downloaded_page = HTTParty.get(tut_page)
  parsed_page = Nokogiri::HTML(downloaded_page.body)
  section_urls = parsed_page.xpath('//div[@class="body"]/div[@class="section"]/ul/li//a/@href').map(&:value)

  content = section_urls.map { |url| HTTParty.get(BASE_URL + url).body }.join('\n')

  File.open('./tut_html.html','w') do |file|
    file.write content
  end
end
parsed_content = Nokogiri::HTML(File.open('tut_html.html').read)

text = parsed_content.xpath('//div[@class="main"]/div')
text.css('div[@class="link"]').each { |elem| elem.remove }
text.css('span[@class="adminmenu"]').each { |elem| elem.remove }
text.css('div[@class="adminmenu"]').each { |elem| elem.remove }
text.css('img').each { |elem| elem['src'] =  BASE_URL + elem['src'] }
text.css('a').each { |elem| elem['href'] =  (BASE_URL + elem['href']).gsub('%3A', ':') if elem['href'].start_with?('hiki.cgi?')  }

File.open('cleaned_tut.html','w') do |file|
  file.write text
end

final_version = Nokogiri::HTML File.open('cleaned_tut.html').read
root_body = final_version.at_xpath('//body')
text.each { |elem| root_body.add_child elem }

File.open('./final_version_file', 'w') do |file|
  file.write final_version
end unless File.exist? './final_version_file'
kit = PDFKit.new(text.to_html.encode('UTF-8', :invalid => :replace, :undef => :replace), root_url: 'https://ruby-gnome2.osdn.jp/', protocol: 'https')
kit.stylesheets << './css_styles'
kit.to_file './tuto.pdf'
