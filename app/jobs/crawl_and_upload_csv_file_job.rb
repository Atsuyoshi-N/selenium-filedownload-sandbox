require 'capybara'
# require 'capybara/rspec'
require 'selenium-webdriver'

class CrawlAndUploadCsvFileJob < ApplicationJob
  queue_as :default

  def perform(*args)
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument("--headless")
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-gpu')
    options.add_argument('--disable-popup-blocking')
    options.add_argument('--window-size=1440,900')
    driver = Selenium::WebDriver.for :chrome, options: options
    bridge = driver.send(:bridge)
    path = "/session/#{bridge.session_id}/chromium/send_command"
    command_hash = { cmd: 'Page.setDownloadBehavior',
                     params: {
      behavior: 'allow',
      downloadPath: File.absolute_path(Rails.root)
      }
    }
    bridge.http.call(:post, path, command_hash)
    url = 'http://localhost:8080'.freeze
    driver.navigate.to url
    csv_download_link = driver.find_element(:link, 'CSVをダウンロードする').click
    puts 'ダウンロードされました'
  end
end

