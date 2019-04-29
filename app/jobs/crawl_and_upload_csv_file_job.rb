require 'capybara'
require 'selenium-webdriver'

class CrawlAndUploadCsvFileJob < ApplicationJob
  queue_as :default

  def perform(*args)
    options = Selenium::WebDriver::Chrome::Options.new
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
        downloadPath: File.absolute_path(File.expand_path('./tmp', Rails.root)) # download dir
      }
    }
    bridge.http.call(:post, path, command_hash)
    url = ENV['CSV_DOWNLOAD_URL'].to_s.freeze
    driver.navigate.to url
    csv_download_link = driver.find_element(:link, 'CSVをダウンロードする')
    csv_download_link.click
  end
end

