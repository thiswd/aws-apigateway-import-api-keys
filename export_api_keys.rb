require 'optparse'
require_relative 'lib/api_keys_exporter'

class ExportApiKeys
  USAGE_INSTRUCTION = "Usage: ruby export_api_keys.rb --region REGION --wait-time WAIT_TIME".freeze

  def self.run
    options = parse_arguments
    importer = ApiKeysExporter.new(options[:region], options[:wait_time], options[:profile])
    importer.execute
  end

  private

  def self.parse_arguments
    options = {}
    OptionParser.new do |opts|
      opts.banner = USAGE_INSTRUCTION
      opts.on("--region REGION", "AWS Region") { |region| options[:region] = region }
      opts.on("--wait-time WAIT_TIME", Integer, "Wait time in seconds for rate limit handling") do |wt|
        options[:wait_time] = wt
      end
      opts.on("--profile PROFILE", "AWS Profile") { |profile| options[:profile] = profile }
    end.parse!

    validate_arguments(options)
    options
  end

  def self.validate_arguments(options)
    missing_args = []
    missing_args << '--region' unless options[:region]

    if missing_args.any?
      puts "Missing arguments: #{missing_args.join(', ')}"
      puts USAGE_INSTRUCTION
      exit
    end
  end
end

ExportApiKeys.run
