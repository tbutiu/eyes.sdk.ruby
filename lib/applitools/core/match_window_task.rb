require 'base64'
module Applitools
  class MatchWindowTask
    MATCH_INTERVAL = 0.5
    AppOuptut = Struct.new(:title, :screenshot64)

    attr_reader :logger, :running_session, :default_retry_timeout, :app_output_provider

    def initialize(logger, running_session, retry_timeout, app_output_provider)
      @logger = logger
      @running_session = running_session
      # @driver = driver
      @default_retry_timeout = retry_timeout
      @app_output_provider = app_output_provider

      ArgumentGuard.not_nil logger, 'logger'
      ArgumentGuard.not_nil running_session, 'running_session'
      ArgumentGuard.not_nil app_output_provider, 'app_output_provider'
      ArgumentGuard.greater_than_or_equal_to_zero retry_timeout, 'retry_timeout'

      return if app_output_provider.respond_to? :app_output
      raise Applitools::EyesIllegalArgument.new 'MatchWindowTask.new(): app_output_provider doesn\'t' /
        ' respond to :app_output'
    end

    def match_window(match_window_data, options = {})
      last_screenshot = options[:last_screenshot]
      region_provider = options[:region_provider]
      retry_timeout = options[:retry_timeout]
      should_match_window_run_once_on_timeout = options[:should_match_window_run_once_on_timeout]

      retry_timeout = default_retry_timeout if retry_timeout < 0

      logger.info "retry_timeout = #{retry_timeout}"
      elapsed_time_start = Time.now

      if retry_timeout.zero? || should_match_window_run_once_on_timeout
        sleep retry_timeout if should_match_window_run_once_on_timeout
        app_output = app_output_provider.app_output(region_provider, last_screenshot)
        match_window_data.app_output = app_output
        match_window_data.convert_ignored_regions_coordinates
        match_result = perform_match(match_window_data)
      else
        app_output = app_output_provider.app_output(region_provider, last_screenshot)
        match_window_data.app_output = app_output
        match_window_data.convert_ignored_regions_coordinates
        start = Time.now
        match_result = perform_match(match_window_data)
        retry_time = Time.now - start

        while retry_time < retry_timeout && !match_result.as_expected?
          sleep MATCH_INTERVAL
          app_output = app_output_provider.app_output(region_provider, last_screenshot)
          match_window_data.app_output = app_output
          match_window_data.convert_ignored_regions_coordinates
          match_result = perform_match(match_window_data)
          retry_time = Time.now - start
        end

        unless match_result.as_expected?
          app_output = app_output_provider.app_output(region_provider, last_screenshot)
          match_window_data.app_output = app_output
          match_window_data.convert_ignored_regions_coordinates
          match_result = perform_match(match_window_data)
        end
      end

      logger.info "Completed in #{format('%.2f', Time.now - elapsed_time_start)} seconds"

      match_result.screenshot = app_output.screenshot
      match_result
    end

    private

    def perform_match(match_window_data)
      Applitools::ArgumentGuard.is_a? match_window_data, 'match_window_data', Applitools::MatchWindowData
      Applitools::Connectivity::ServerConnector.match_window running_session, match_window_data
    end
  end
end
