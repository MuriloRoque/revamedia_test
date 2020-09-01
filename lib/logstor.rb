require 'kimurai'

class LogstorSpider < Kimurai::Base
  @engine = :mechanize
  @start_urls = ['http://logstorbo.dk/ledige-boliger/']

  def parse(response, url:, data: {})
    urls = response.css('div.section.apartments table tbody tr td a').map { |elem| elem = elem[:href] }.compact
    in_parallel(:parse_listing, urls, threads: 3)
  end

  def parse_listing(response, url:, data: {})
    item = { external_source: self.class.to_s, external_link: url }
    item[:title] = response.css('#main > div.houseInfo.pure-u-1.pure-u-sm-18-24.pure-u-md-18-24 > h2').text
    item[:description] = response.css('#main > div.houseInfo.pure-u-1.pure-u-sm-18-24.pure-u-md-18-24 > div.section.info').text
    left = response.css('#main > div.houseInfo.pure-u-1.pure-u-sm-18-24.pure-u-md-18-24 > div.houseDetails.pure-g > div.column1.pure-u-1.pure-u-sm-1.pure-u-md-2-3 > div.section.lastSection.left > table > tbody')
    right = response.css('#main > div.houseInfo.pure-u-1.pure-u-sm-18-24.pure-u-md-18-24 > div.houseDetails.pure-g > div.column1.pure-u-1.pure-u-sm-1.pure-u-md-2-3 > div.column2.pure-u-1.pure-u-sm-1.pure-u-md-1-3 > table > tbody')
    item[:city] = left.css('tr:first-child td:last-child').text
    item[:property_type] = left.css('tr:nth-child(2) td:last-child').text
    item[:pet_allowed] = left.css('tr:nth-child(5) td:last-child').text =~ /Ja/i ? true : false
    item[:square_meters] = right.css('tr:nth-child(5) td:last-child').text.gsub('m2', '').strip
    item[:room_count] = right.css('tr:nth-child(6) td:last-child').text
    item[:rent] = right.css('tr:nth-child(1) td:last-child').text.scan(/\d/).join('')
    item[:deposit] = right.css('tr:nth-child(2) td:last-child').text.scan(/\d/).join('')
    item[:heating_cost] = right.css('tr:nth-child(3) td:last-child').text.scan(/\d/).join('')
    item[:images] = response.css('#main > div.houseInfo.pure-u-1.pure-u-sm-18-24.pure-u-md-18-24 > div.imageContainer.pure-u-1.pure-u-sm-1.pure-u-md-2-3 > img').pluck(:src).map { |x| 'http://logstorbo.dk' + x }
    item[:landlord_name] = 'Løgstør Boligforening'
    item[:landlord_phone] = '98673241'
    item[:landlord_email] = 'post@logstorbo.dk'
    save_to 'logstorResults.json', item, format: :pretty_json
  rescue StandardError => e
    logger.error url
    raise e
  end
end

LogstorSpider.crawl!
