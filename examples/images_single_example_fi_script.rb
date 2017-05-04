# require_relative '../lib/eyes_selenium'
require 'eyes_images'
require 'logger'

eyes = Applitools::Images::Eyes.new
eyes.api_key = ENV['APPLITOOLS_API_KEY']
eyes.log_handler = Logger.new(STDOUT)

viber_home_image_bytes = File.read('./images/viber-home.png', mode: 'rb')
viber_home_image = Applitools::Screenshot.from_datastream viber_home_image_bytes

eyes.test(app_name: 'Eyes.Java', test_name: 'home1') do
  target = Applitools::Images::Target.path('./images/viber-home.png').ignore(Applitools::Region.new(10, 10, 30, 30))
  eyes.check_single('entire image', target)
  target = target.region(Applitools::Region.new(1773, 372, 180, 220))
  eyes.check_single('Bada region', target)
  eyes.add_mouse_trigger(:click, Applitools::Region::EMPTY, Applitools::Location.new(1866, 500))
  target = Applitools::Images::Target.path('./images/viber-bada.png')
  eyes.check_single('Bada entire image', target)
end

eyes.test(app_name: 'Eyes.Java', test_name: 'home2') do
  target = Applitools::Images::Target.screenshot(viber_home_image)
  eyes.check_single('', target)
  target = Applitools::Images::Target.path('./images/viber-bada.png')
  eyes.check_single('', target)
end
