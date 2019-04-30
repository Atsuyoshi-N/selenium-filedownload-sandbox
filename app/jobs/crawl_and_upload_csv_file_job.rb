require 'capybara'
require 'selenium-webdriver'
require 'csv'

class CrawlAndUploadCsvFileJob < ApplicationJob
  queue_as :default

  def perform(*args)
    chrome_options = Selenium::WebDriver::Chrome::Options.new
    # download_file_name = "csv_#{Time.zone.now.strftime("%Y%m%d-%H-%M-%S")}"
    # download_file_path = File.expand_path("./tmp/#{download_file_name}", File.absolute_path(Rails.root))
    download_file_path = File.expand_path("./tmp", File.absolute_path(Rails.root))
    puts download_file_path
    options = ["--headless", '--no-sandbox', '--disable-gpu', '--disable-popup-blocking', '--window-size=1440,900']
    options.each do |option|
      chrome_options.add_argument(option)
    end
    driver = Selenium::WebDriver.for :chrome, options: chrome_options
    bridge = driver.send(:bridge)
    path = "/session/#{bridge.session_id}/chromium/send_command"
    command_hash = {
      cmd: 'Page.setDownloadBehavior',
      params: {
        behavior: 'allow',
        downloadPath: download_file_path # download dir
      }
    }
    bridge.http.call(:post, path, command_hash)
    url = ENV['CSV_DOWNLOAD_URL'].to_s.freeze
    driver.navigate.to url
    csv_download_link = driver.find_element(:link, 'CSVをダウンロードする')
    download_file = csv_download_link.click
    sleep(20)

    store = Store.last
    file_location = Dir.glob(download_file_path+"/*.csv")[0]
    filename = File.open(Dir.glob(download_file_path+"/*.csv")[0][/[a-zA-Z0-9\-\_]*\.csv$/])
    puts file_location
    puts filename
    store.csv_file.attach(io: File.open(file_location), filename: filename, content_type: Mime[:csv].to_s)

  end

  def cleanup
    File.delete(tmp_file_path) if File.exist?(tmp_file_path)
  end

  def tmp_file_path
    Rails.root.join('tmp', 'toreta_reservations.csv')
  end
end

