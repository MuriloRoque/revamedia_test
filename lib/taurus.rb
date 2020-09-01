require 'kimurai'

class TaurusSpider < Kimurai::Base
  @engine = :mechanize
  @start_urls = ["https://www.taurus.dk/boligudlejning/ledige-lejemal/"]

  def parse(response, url:, data: {})

    urls = response.css('div.blog.apartments div.inner a').map { |elem| elem = elem[:href] }.compact.map { |x| 'https://www.taurus.dk/' + x }
    in_parallel(:parse_listing, urls, threads: 3)

    if next_page = response.at_css("#s5_component_call_wrap_inner > div.blog.apartments > div.pagination > div > a:nth-child(8)")
      request_to :parse, url: absolute_url(next_page[:href], base: url)
    end

  end

  def parse_listing(response, url:, data: {})

    begin

      item = { external_source: self.class.to_s, external_link: url }
      item[:title] = response.css('#leje_layout > div.description-box > h1').text
      item[:description] = response.css('#leje_layout > div.description-box > p').text
      table = response.css('#leje_layout > div.fakta-box.s5_float_left > div.module_round_box > div > div > div:nth-child(2) > table')
      item[:zipcode] = table.css('/tr[contains("Postnummer")]').text.scan(/\d/).join('')
      address = table.css('/tr[contains("Vejnavn")]').text.gsub("Vejnavn",'') + ', ' + table.css('/tr[contains("Husnummer")]').text.scan(/\d/).join('') + ', ' + item[:zipcode]
      item[:address] = address.squish
      item[:property_type] = table.css('/tr[contains("Boligtype")]').text.gsub("Boligtype",'').squish
      item[:pet_allowed] = item[:square_meters] = table.css('/tr[contains("Husdyr tilladt")]').text.gsub("Boligareal (m2)",'').squish =~ /Ja/i ? true : false
      item[:square_meters] = table.css('/tr[contains("Boligareal (m2)")]').text.gsub("Boligareal (m2)",'').squish
      item[:room_count] = table.css('/tr[contains("Værelser")]').text.gsub("Værelser",'').scan(/\d/).join('')
      item[:available_date] = table.css('/tr[contains("Overtagelsesdato")]').text.gsub("Overtagelsesdato",'').squish
      item[:rent] = table.css('/tr[contains("Husleje (Mdl.)")]').text.scan(/\d/).join('')
      item[:deposit] = table.css('/tr[contains("Depositum")]').text.scan(/\d/).join('')
      item[:prepaid_rent] = table.css('/tr[contains("Forudbetalt leje")]').text.scan(/\d/).join('')
      item[:floor] = table.css('/tr[contains("Etage")]').text.scan(/\d/).join('')
      item[:landlord_name] = 'Taurus Property'
      item[:landlord_phone] = '86122020'
      item[:landlord_email] = 'pjj@taurus.dk'
      save_to "taurusResults.json", item, format: :pretty_json
    rescue => e
      logger.error url
      raise e
    end

  end

end

TaurusSpider.crawl!