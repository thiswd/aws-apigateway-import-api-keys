require 'aws-sdk-apigateway'
require 'json'

if ARGV.length != 1
  puts "Usage: ruby export_keys.rb <AWS_REGION>"
  exit
end

region = ARGV[0]
apigateway = Aws::APIGateway::Client.new(region: region)
input_file = "api_keys.json"

begin
  file = File.read(input_file)
  api_keys = JSON.parse(file)
rescue Errno::ENOENT => e
  puts "Error: File not found - #{e.message}"
rescue Errno::EACCES => e
  puts "Error: File not accessible - #{e.message}"
rescue JSON::ParserError => e
  puts "Error: File content is not valid JSON - #{e.message}"
rescue StandardError => e
  puts "An unexpected error occurred - #{e.message}"
end

unless api_keys.has_key?("items")
  puts "No API keys found in #{filename}"
  exit
end

begin
  api_keys_with_plans = []
  api_keys_count = 0
  api_keys_without_plan_count = 0
  error_count = 0
  filename = "api_keys_with_plans.json"

  api_keys["items"].each do |key|
    begin
      usage_plans = apigateway.get_usage_plans(key_id: key["id"]).items

      if usage_plans.empty?
        puts "Key #{key["name"]} (#{key["id"]}) has no usage plans"
        api_keys_without_plan_count += 1
      end

      api_keys_with_plans << {
        name: key["name"],
        value: key["value"],
        description: key["description"],
        usage_plan_names: usage_plans.map(&:name)
      }
      api_keys_count += 1
    rescue Aws::APIGateway::Errors::ServiceError => e
      puts "Error retrieving usage plans for key #{key["name"]} (#{key["id"]}): #{e.message}"
      error_count += 1
    end
  end

  File.write(filename, api_keys_with_plans.to_json)
  puts "Exported API keys with associated usage plans to #{filename}"
  puts "Total API Keys: #{api_keys_count}"
  puts "Total API Keys without usage plans: #{api_keys_without_plan_count}"
  puts "Total Errors: #{error_count}"

  begin
    puts "Deleting #{input_file}..."
    File.delete(input_file)
    puts "#{input_file} has been successfully deleted."
  rescue Errno::ENOENT
    puts "Error: The file #{input_file} does not exist."
  rescue StandardError => e
    puts "An error occurred while deleting the file #{input_file}: #{e.message}"
  end

rescue StandardError => e
  puts "An error occurred: #{e.message}"
end
