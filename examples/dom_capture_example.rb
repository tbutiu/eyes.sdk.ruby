# frozen_string_literal: true

require_relative '../lib/eyes_selenium'
require 'logger'
require 'openssl'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

eyes = Applitools::Selenium::Eyes.new
eyes.force_full_page_screenshot = true
eyes.api_key = ENV['APPLITOOLS_API_KEY']
eyes.log_handler = Logger.new(STDOUT)
eyes.match_level = Applitools::MATCH_LEVEL[:layout]
# eyes.send_dom = false

begin
  web_driver = Selenium::WebDriver.for :chrome
  eyes.test(
      app_name: 'DOM Capture',
      test_name: 'Applitools DomCapture test',
      viewport_size: { width: 800, height: 600 },
      driver: web_driver
  ) do |driver|
    driver.get 'https://nikita-andreev.github.io/applitools/dom_capture.html?aaa'
    eyes.check_window('initial')
  end
ensure
  web_driver.quit
end
