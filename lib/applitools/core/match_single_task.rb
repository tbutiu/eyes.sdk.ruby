require 'base64'
require_relative 'match_window_task'
module Applitools
  class MatchSingleTask < MatchWindowTask
    def initialize(logger, retry_timeout, app_output_provider)
      super(logger, 'nil', retry_timeout, app_output_provider)
    end

    private

    def perform_match(match_window_data)
      Applitools::ArgumentGuard.is_a? match_window_data, 'match_window_data', Applitools::MatchSingleCheckData
      Applitools::Connectivity::ServerConnector.match_single_window match_window_data
    end
  end
end
