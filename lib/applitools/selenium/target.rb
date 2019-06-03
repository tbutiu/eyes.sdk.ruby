# frozen_string_literal: true

module Applitools
  module Selenium
    class Target
      include Applitools::FluentInterface
      class << self
        def frame(element)
          new.frame(element)
        end

        def window
          new
        end

        def region(*args)
          new.region(*args)
        end
      end

      attr_accessor :element, :frames, :region_to_check, :coordinate_type, :options, :ignored_regions,
        :floating_regions, :frame_or_element, :regions, :match_level

      private :frame_or_element, :frame_or_element=

      # Initialize a Applitools::Selenium::Target instance.
      def initialize
        self.frames = []
        self.options = {
          ignore_caret: true,
          ignore_mismatch: false,
          send_dom: nil,
          script_hooks: { beforeCaptureScreenshot: '' }
        }
        self.regions = {}
        reset_for_fullscreen
      end

      # Add the wanted ignored regions.
      #
      # @param [Applitools::Selenium::Element, Applitools::Region, ::Selenium::WebDriver::Element] region_or_element the region to ignore or an element representing the region to ignore
      # @param [Symbol, String] how A finder to be used (see Selenium::WebDriver documentation for complete list of available finders)
      # @param [Symbol, String] what An id or selector to find
      # @!parse def ignore(region_or_element, how, what, padding = Applitools::PaddingBounds::PIXEL_PADDING); end;

      def ignore(*args)
        if args.empty?
          reset_ignore
        else
          requested_padding = if args.last.is_a? Applitools::PaddingBounds
                                args.pop
                              else
                                Applitools::PaddingBounds::PIXEL_PADDING
                              end
          ignored_regions << case args.first
                             when Applitools::Region
                               proc { args.first.padding(requested_padding) }
                             when Applitools::Selenium::Element, ::Selenium::WebDriver::Element
                               proc do |_driver, return_element = false|
                                 region = args.first
                                 padding_proc = proc do |region|
                                   Applitools::Region.from_location_size(
                                       region.location, region.size
                                   ).padding(requested_padding)
                                 end
                                 next region, padding_proc if return_element
                                 padding_proc.call(region)
                               end
                             else
                               proc do |driver, return_element = false|
                                 region = driver.find_element(*args)
                                 padding_proc = proc do |region|
                                   Applitools::Region.from_location_size(
                                       region.location, region.size
                                   ).padding(requested_padding)
                                 end
                                 next region, padding_proc if return_element
                                 padding_proc.call(region)
                               end
                             end

        end
        self
      end

      # Sets the wanted floating region
      # @param region_or_element [Applitools::FloatingRegion, Selenium::WebDriver::Element, Applitools::Selenium::Element, Applitools::Region]
      # @param bounds [Applitools::FloatingBounds]
      # @!parse def floating(region_or_element, bounds, padding); end;
      # @param left [Integer]
      # @param top [Integer]
      # @param right [Integer]
      # @param bottom [Integer]
      # @param padding [Applitools::PaddingBounds]
      # @example
      #   target.floating(:id, 'my_id', 10, 10, 10, 10)
      # @example
      #   target.floating(:id, 'my_id', Applitools::FloatingBounds.new(10, 10, 10, 10))
      # @example
      #   target.floating(region, Applitools::FloatingBounds.new(10, 10, 10, 10))
      # @example
      #   target.floating(floating_region)
      # @example
      #   target.floating(floating_region, bounds)
      # @example
      #   target.floating(:id, 'my_id', Applitools::FloatingBounds.new(10, 10, 10, 10), Applitools::PaddingBounds.new(10, 10, 10, 10))
      # @!parse def floating(region_or_element, bounds, left,top, right, bottom, padding); end;

      def floating(*args)
        requested_padding = if args.last.is_a? Applitools::PaddingBounds
                              args.pop
                            else
                              Applitools::PaddingBounds::PIXEL_PADDING
                            end
        value = case args.first
                when Applitools::FloatingRegion
                  args.first.padding(requested_padding)
                when ::Applitools::Region
                  Applitools::FloatingRegion.any(args.shift, *args).padding(requested_padding)
                when ::Selenium::WebDriver::Element, Applitools::Selenium::Element
                  proc do |_driver, return_element = false|
                    args_dup = args.dup
                    region = args_dup.shift
                    padding_proc = proc do |region|
                      Applitools::FloatingRegion.any(region, *args_dup).padding(requested_padding)
                    end
                    next region, padding_proc if return_element
                    padding_proc.call(region)
                  end
                else
                  proc do |driver, return_element = false|
                    args_dup = args.dup
                    region = driver.find_element(args_dup.shift, args_dup.shift)
                    padding_proc = proc do |region|
                      Applitools::FloatingRegion.any(
                          region, *args_dup
                      ).padding(requested_padding)
                    end
                    next region, padding_proc if return_element
                    padding_proc.call(region)
                  end
                end
        floating_regions << value
        self
      end

      def layout(*args)

      end

      def content(*args)

      end

      def strict(*args)

      end

      def exact(*args)

      end

      # def match_level(*args)
      #   value = args.shift
      #   self
      # end

      def fully(value = true)
        options[:stitch_content] = value ? true : false
        handle_frames
        self
      end

      def frame(element)
        frames << frame_or_element if frame_or_element
        self.frame_or_element = element
        reset_for_fullscreen
        self
      end

      # Add the desired region.
      # @param [Applitools::Selenium::Element, Applitools::Region, ::Selenium::WebDriver::Element] element the target region or an element representing the target region
      # @param [Symbol, String] how The finder to be used (:css, :id, etc. see Selenium::WebDriver documentation for complete list of available finders)
      # @param [Symbol, String] what Selector or id of an element
      # @example Add region by element
      #   target.region(an_element)
      # @example Add target region by finder
      #   target.region(:id, 'target_region')
      # @return [Applitools::Selenium::Target] A Target instance.
      # @!parse def region(element, how, what); end;

      def region(*args)
        handle_frames
        self.region_to_check = case args.first
                               when Applitools::Selenium::Element, Applitools::Region, ::Selenium::WebDriver::Element
                                 proc { args.first }
                               when String
                                 proc do |driver|
                                   driver.find_element(name_or_id: args.first)
                                 end
                               else
                                 proc do |driver|
                                   driver.find_element(*args)
                                 end
                               end
        self.coordinate_type = Applitools::EyesScreenshot::COORDINATE_TYPES[:context_relative]
        options[:timeout] = nil
        reset_ignore
        reset_floating
        self
      end

      def send_dom(value = true)
        options[:send_dom] = value ? true : false
        self
      end

      def use_dom(value = true)
        options[:use_dom] = value ? true : false
        self
      end

      def script_hook(hook)
        options[:script_hooks][:beforeCaptureScreenshot] = hook
        self
      end

      def finalize
        return self unless frame_or_element
        region = frame_or_element
        self.frame_or_element = nil
        dup.region(region)
      end

      private

      def reset_for_fullscreen
        self.coordinate_type = nil
        self.region_to_check = proc { Applitools::Region::EMPTY }
        reset_ignore
        reset_floating
        options[:stitch_content] = false
        options[:timeout] = nil
        options[:trim] = false
      end

      def reset_ignore
        self.ignored_regions = []
      end

      def reset_floating
        self.floating_regions = []
      end

      def handle_frames
        return unless frame_or_element
        frames << frame_or_element
        self.frame_or_element = nil
      end
    end
  end
end
