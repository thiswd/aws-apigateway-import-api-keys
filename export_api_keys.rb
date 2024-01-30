require 'aws-sdk-apigateway'
require 'json'

if ARGV.length != 1
  puts "Usage: ruby export_keys.rb <AWS_REGION>"
  exit
end

region = ARGV[0]
apigateway = Aws::APIGateway::Client.new(region: region)

begin
  api_keys_with_plans = []
  retrieved_count = 0
  error_count = 0
  filename = "api_keys.json"

  page = nil
  loop do
    response = apigateway.get_api_keys(limit: 500, position: page)
    api_keys = response.items
    break if api_keys.empty?

    api_keys.each do |key|
      begin
        usage_plans = apigateway.get_usage_plans(key_id: key.id).items
        api_keys_with_plans << {
          id: key.id,
          name: key.name,
          value: key.value,
          usage_plan_ids: usage_plans.map(&:id)
        }
        retrieved_count += 1
      rescue Aws::APIGateway::Errors::ServiceError => e
        puts "Error retrieving usage plans for key #{key.id}: #{e.message}"
        error_count += 1
      end
    end

    page = response.position
    break unless page
  end

  File.write(filename, api_keys_with_plans.to_json)
  puts "Exported API keys with associated usage plans to #{filename}"
  puts "Total API Keys Retrieved: #{retrieved_count}"
  puts "Total Errors: #{error_count}"

rescue StandardError => e
  puts "An error occurred: #{e.message}"
end
