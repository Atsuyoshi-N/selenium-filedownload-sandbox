require 'capybara'
require 'selenium-webdriver'
require 'csv'

class CrawlAndUploadCsvFileJob < ApplicationJob
  queue_as :default

  def perform(*args)
    options = Selenium::WebDriver::Chrome::Options.new
    download_file_name = "csv_#{Time.zone.now.strftime("%Y%m%d-%H-%M-%S")}"
    # download_file_path = Rails.root.join('/tmp', download_file_name)
    download_file_path = File.expand_path("./tmp/#{download_file_name}", File.absolute_path(Rails.root))
    puts download_file_name
    puts download_file_path
    each_options = ["--headless", '--no-sandbox', '--disable-gpu', '--disable-popup-blocking', '--window-size=1440,900']
    each_options.each do |option|
      options.add_argument(option)
    end
    driver = Selenium::WebDriver.for :chrome, options: options
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

    # store = Store.last.tap do |st|
      # st.csv_files.attach(download_file_path)
    # end
    # store.save
    store = Store.last
    # puts store.csv_files
    puts download_file_path
    # store.csv_file.attach(io: File.open(download_file_path), filename: download_file_name, content_type: "text/csv")
    # new_csv_file = store.csv_file.new
    puts Dir.glob(download_file_path+"/*.csv")
    filename = File.open(Dir.glob(download_file_path+"/*.csv")[0][/[a-zA-Z0-9\-\_]*\.csv$/])
    store.csv_file.attach(io: File.open(Dir.glob(download_file_path+"/*.csv")[0]), filename: filename, content_type: Mime[:csv].to_s)
    # store.csv_file.attach(File.open(Dir.glob(download_file_path+"/*.csv")[0]))
    # store.save
    # File.delete(download_file_path) if File.exist?(download_file_path)
    puts store.csv_file.attached?

  end

  def cleanup
    File.delete(tmp_file_path) if File.exist?(tmp_file_path)
  end

  def tmp_file_path
    Rails.root.join('tmp', 'toreta_reservations.csv')
  end
end

