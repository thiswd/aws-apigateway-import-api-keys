require 'optparse'
require_relative 'api_key_exporter'

class ExportApiKeys
  def self.run
    options = parse_arguments
    importer = ApiKeyExporter.new(options[:region], options[:file])
    importer.export_api_keys
    importer.delete_input_file
  end

  def self.parse_arguments
    options = {}
    OptionParser.new do |opts|
      opts.banner = "Usage: ruby import_usage_plans.rb --region REGION --file FILE"

      opts.on("--region REGION", "AWS Region") { |region| options[:region] = region }
      opts.on("--file FILE", "Path to the usage_plans.json file") { |file| options[:file] = file }
    end.parse!

    validate_arguments(options)
    options
  end

  private

  def self.validate_arguments(options)
    missing_args = []
    missing_args << '--region' unless options[:region]
    missing_args << '--file' unless options[:file]

    if missing_args.any?
      puts "Missing arguments: #{missing_args.join(', ')}"
      puts "Usage: ruby import_usage_plans.rb --region REGION --file FILE"
      exit
    end
  end
end

ExportApiKeys.run
