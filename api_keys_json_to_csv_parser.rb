require 'json'
require 'csv'
require 'aws-sdk-apigateway'

class ApiKeysJsonToCsvParser

  def initialize(region, json_file)
    @apigateway = Aws::APIGateway::Client.new(region:)
    @json_file = json_file
    @usage_plan_ids = {}
  end

  def execute
    load_usage_plan_ids
    api_keys = read_json_file
    write_csv_file(api_keys)
  end

  private

  def read_json_file
    JSON.parse(File.read(@json_file))
  end

  def load_usage_plan_ids
    @apigateway.get_usage_plans.items.each do |plan|
      @usage_plan_ids[plan.name] = plan.id
    end
  end

  def write_csv_file(api_keys)
    output_filename = "api_keys.csv"
    CSV.open(output_filename, "wb") do |csv|
      csv << ["Name", "Key", "Description", "Enabled", "UsageplanIds"]
      api_keys.each do |key|
        usage_plan_ids = key["usage_plan_names"].map { |name| @usage_plan_ids[name] }.join(",")
        csv << [key["name"], key["value"], key["description"], key["enabled"] ? 'TRUE' : 'FALSE', usage_plan_ids]
      end
    end
  end
end
