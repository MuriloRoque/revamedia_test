require 'kimurai'

class BroGripenSpider < Kimurai::Base
  @engine = :mechanize
  @start_urls = ["https://brogripen.se/property-search-result/?state_id=&prop_name=&city_id=&area_id=&type_id=&action_id=&rooms_id=&bed_id=&bath_id=&price_min=&price_max=&minarea_id=&maxarea_id=&features="]

  def parse(response, url:, data: {})
    posts_headers_css = "#page > div > div > div > div > div > div > div > div.map-property-list > div.row > div > div > div.property-image-wrap > a"
    count = response.css(posts_headers_css).count

    loop do
      browser.find('//*[@id="page"]/div/div/div/div/div/div/div/div[2]/div[2]/div/a', text: "Ladda fler objekt").click ; sleep 5
      response = browser.current_response

      new_count = response.css(posts_headers_css).count
      if count == new_count
        break
      else
        count = new_count
      end
    end

    urls = response.css(posts_headers_css).map { |elem| elem = elem[:href] }.compact
    in_parallel(:parse_listing, urls, threads: 3)

  end

  def parse_listing(response, url:, data: {})

    begin

      item = { external_source: self.class.to_s, external_link: url }
      item[:title] = response.css('#primary > div > div > div > div.property-title-wrap > div > h2').text
      item[:description] = response.css('#property-single-desc ul ~ p').text
      table = response.css('#property-single-desc > ul')
      item[:address] = table.css('li:nth-child(1) strong').text
      item[:square_meters] = table.css('li:nth-child(3) strong').text.scan(/\d/).join('')
      item[:images] = response.css('#primary > div > div > div > div.property-image-wrap > div > div > img').pluck(:src)
      item[:rent] = table.css('li:nth-child(8) strong').text
      item[:floor] = table.css('li:nth-child(4) strong').text
      item[:balcony] = table.css('li:nth-child(5) strong').text
      item[:elevator] = table.css('li:nth-child(7) strong').text
      item[:external_id] = table.css('li:nth-child(14) strong').text
      item[:landlord_name] = 'Erik Bengtsson'
      item[:landlord_phone] = '0854549608'
      item[:landlord_email] = 'erik@brogripen.se'
      save_to "brogripenResults.json", item, format: :pretty_json
    rescue => e
      logger.error url
      raise e
    end

  end

end

BroGripenSpider.crawl!