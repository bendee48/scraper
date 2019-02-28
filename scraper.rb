require 'byebug'
require 'nokogiri'
require 'open-uri'
require 'watir'
require 'webdrivers'
require 'csv'

class Scraper

  def initialize
    @browser = browser = Watir::Browser.new(:chrome, {:chromeOptions => {:args => ['--headless', '--log-level=2']}})
    @url = url = "https://www.unquote.com/category/deals/page/"
    @page_num = 1
    @date_to = "january"
    #store of scraped data
    @data_array = []
  end

  def start
    puts "Scrape in progress..."
    page_loop
    save_to_csv
  end

  def page_loop
    #page loop
    @page_date = ""

    while @page_date != @date_to do
      current_url = @browser.goto(@url + @page_num.to_s)
      sleep 1
      @listing_links = @browser.div(id: "listings").wait_until(&:present?).h5s
      @page_date = @browser.times.first.wait_until(&:present?).text.strip.scan(/[A-Z]+/i).first.downcase
      @page_num += 1
      page_scrape
      #pause scrape
      if @page_num % 5 == 0
        puts "Pausing..."
        sleep rand(20..35)
      end
    end
  end

  def page_scrape
    @listing_links.each do |lst|
      lst.link.click
      #wait for key elements to load
      @browser.ul(class: "meta-taxonomy-list").wait_until(&:present?)
      sleep 1
      @browser.h1.wait_until(&:present?)
      @browser.p(class: "article-summary")
      sleep 1
      parsed_page = Nokogiri::HTML.parse(@browser.html)

      deal = [
        date =  parsed_page.css("li.author-dateline-time").text.strip,
        deal_type = parsed_page.css("ul.meta-taxonomy-list.breadcrumb").text.strip,
        title =  parsed_page.css("h1").text,
        content = parsed_page.css("p.article-summary").text.strip
      ]

      @data_array << deal
      puts "Adding deal: #{@data_array.count}"

      @browser.back
      sleep 1
      #testing
      break
    end
  end

  def save_to_csv
    puts "Scrape completed. #{@data_array.count} listings found."
    sleep 2
    puts "Saving to csv..."
    csv_headers = ["Date", "Deal Type", "Title", "Content"]
    date = Time.now.strftime("%d%m%y")

    CSV.open("scrape_data_#{date}.csv", "wb") do |csv|
      csv << csv_headers
      @data_array.each do |data|
        csv << data
      end
    end

    sleep 2
    puts "File saved."
  end

end

Scraper.new.start
