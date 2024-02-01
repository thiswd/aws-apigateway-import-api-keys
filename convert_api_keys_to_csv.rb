require 'optparse'
require_relative 'api_keys_json_to_csv_parser'

class ConvertApiKeysToCsv
  USAGE_INSTRUCTION = "Usage: ruby convert_api_keys_to_csv.rb --region REGION --file FILE".freeze

  def self.run
    options = parse_arguments
    parser = ApiKeysJsonToCsvParser.new(options[:region], options[:file])
    parser.execute
  end

  private

  def self.parse_arguments
    options = {}
    OptionParser.new do |opts|
      opts.banner = USAGE_INSTRUCTION
      opts.on("--region REGION", "AWS Region") { |region| options[:region] = region }
      opts.on("--file FILE", "Path to the api_keys.json file") { |file| options[:file] = file }
    end.parse!

    validate_arguments(options)
    options
  end

  def self.validate_arguments(options)
    missing_args = []
    missing_args << '--region' unless options[:region]
    missing_args << '--file' unless options[:file]

    if missing_args.any?
      puts "Missing arguments: #{missing_args.join(', ')}"
      puts USAGE_INSTRUCTION
      exit
    end
  end
end

ConvertApiKeysToCsv.run
