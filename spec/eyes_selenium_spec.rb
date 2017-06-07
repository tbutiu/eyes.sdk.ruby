require 'spec_helper'
require 'eyes_selenium'

RSpec.describe Applitools::Selenium::Eyes do
  let(:element) { Selenium::WebDriver::Element.new('', nil) }
  let(:target_locator) do
    double.tap do |t|
      allow(t).to receive(:frame)
    end
  end
  let(:original_driver) do
    double(Selenium::WebDriver).tap do |d|
      allow(d).to receive(:driver_for_eyes).and_return(d)
      allow(d).to receive(:execute_script).and_return(100, 100)
      allow(d).to receive(:execute_script).with(Applitools::Utils::EyesSeleniumUtils::JS_GET_CURRENT_SCROLL_POSITION).and_return({left: 0, top: 0})
      # allow(d).to receive(:find_element).and_return(element)
      # allow(d).to receive(:switch_to).and_return(target_locator)
      allow(d).to receive(:user_agent).and_return(nil)
      # allow(d).to receive(:screenshot_as).and_return(ChunkyPNG::Image.new(100,100).to_datastream.to_s)
      # allow(d).to receive(:default_content_viewport_size).and_return(Applitools::RectangleSize.new(100,100))
      # allow(d).to receive(:frame_chain).and_return([])
      # allow(d).to receive(:title)
    end
  end
  let(:driver) { Applitools::Selenium::Driver.new(subject, driver: original_driver) }
  let(:target) { Applitools::Selenium::Target.window }

  before do
    subject.api_key = 'API_KEY_FOR_TESTS'
    subject.open(driver: driver, app_name: 'app_name', test_name: 'test_name')
    allow_any_instance_of(Applitools::MatchWindowTask).to receive(:match_window).and_return(Applitools::MatchResults.new)
  end

  context ':check' do
    it 'performs \':read_target\' for match_data' do
      expect_any_instance_of(Applitools::MatchWindowData).to receive(:read_target)
      subject.check('', target)
    end

    it 'sets default values before \'reading\' target' do
      expect(subject).to receive(:set_default_settings).with(Applitools::MatchWindowData).and_raise Applitools::EyesError
      expect_any_instance_of(Applitools::MatchWindowData).to_not receive(:read_target)
      begin
        subject.check('', target)
      rescue Applitools::EyesError
      end
    end
  end
end
