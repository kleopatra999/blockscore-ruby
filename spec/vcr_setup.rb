require 'vcr'
require 'rspec'

module BlockScore
  RECORD_MODE_KEY     = 'VCR_RECORD_MODE'.freeze
  ENVIRONMENT_API_KEY = 'BLOCKSCORE_TEST_KEY'.freeze
  PLACEHOLDER_API_KEY = 'BLOCKSCORE_TEST_KEY'.freeze

  extend self

  RSpec.configure do |config|
    config.before(:context) do
      BlockScore.api_key = ENV.fetch(ENVIRONMENT_API_KEY, PLACEHOLDER_API_KEY)
    end

    config.around(:each) do |example|
      record_option = ENV.fetch(RECORD_MODE_KEY, :none).to_sym
      vcr_on = example.metadata.fetch(:vcr, false)
      options = { record: (vcr_on ? record_option : :skip) }
      BlockScore.run_vcr_example(options, example)
    end
  end

  VCR.configure do |c|
    c.cassette_library_dir = 'spec/cassettes'
    c.hook_into :webmock
    c.configure_rspec_metadata!
    c.ignore_hosts 'codeclimate.com'

    c.filter_sensitive_data(PLACEHOLDER_API_KEY) { ENV[ENVIRONMENT_API_KEY] }
  end

  def run_vcr_example(options, example)
    if options.fetch(:record).equal?(:skip)
      WebMock.allow_net_connect!
      VCR.turned_off(&example)
      WebMock.disable_net_connect!
    else
      path = BlockScore.build_path(example.metadata.fetch(:full_description))

      VCR.use_cassette(path, options, &example)
    end
  end

  def build_path(full_description)
    full_description
      .split(/\s+/, 2)
      .join('/')
      .underscore
      .gsub(/[.#?]/, '/')
      .gsub(%r(\/+), '/')
      .strip
      .tr(' ', '_')
      .gsub(%r([/_ ]$), '')
  end
end
