require 'json'
require 'csv'
require 'aws-sdk-apigateway'

class ApiKeysJsonToCsvParser
  OUTPUT_FILENAME = "api_keys.csv".freeze

  def initialize(region, json_file)
    @apigateway = Aws::APIGateway::Client.new(region: region)
    @json_file = json_file
    @usage_plan_ids = {}
  end

  def execute
    load_usage_plan_ids
    api_keys = read_json_file
    write_csv_file(api_keys)
  rescue Aws::Errors::ServiceError => e
    puts "AWS Service Error occurred: #{e.message}"
  rescue IOError => e
    puts "File IO Error occurred: #{e.message}"
  rescue StandardError => e
    puts "An unexpected error occurred: #{e.message}"
  end

  private

  def read_json_file
    JSON.parse(File.read(@json_file))
  rescue Errno::ENOENT => e
    puts "JSON file not found: #{e.message}"
    exit
  rescue JSON::ParserError => e
    puts "Error parsing JSON file: #{e.message}"
    exit
  end

  def load_usage_plan_ids
    @apigateway.get_usage_plans.items.each do |plan|
      @usage_plan_ids[plan.name] = plan.id
    end
  rescue Aws::Errors::ServiceError => e
    puts "Failed to load usage plans from AWS: #{e.message}"
    exit
  end

  def write_csv_file(api_keys)
    CSV.open(OUTPUT_FILENAME, "wb") do |csv|
      csv << ["Name", "Key", "Description", "Enabled", "UsageplanIds"]
      api_keys.each do |key|
        usage_plan_ids = key["usage_plan_names"].map { |name| @usage_plan_ids.fetch(name, "") }.join(",")
        csv << [key["name"], key["value"], key["description"], key["enabled"] ? 'TRUE' : 'FALSE', usage_plan_ids]
      end
    end
  rescue Errno::EACCES => e
    puts "Access denied when writing to CSV file: #{e.message}"
    exit
  rescue StandardError => e
    puts "Failed to write CSV file: #{e.message}"
    exit
  end
end
