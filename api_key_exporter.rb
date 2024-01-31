require 'aws-sdk-apigateway'
require 'json'

class ApiKeyExporter
  attr_reader :apigateway, :file_path
  def initialize(region, file_path)
    @apigateway = Aws::APIGateway::Client.new(region: region)
    @file_path = file_path
  end

  def export_api_keys
    api_keys = read_usage_plans
    api_keys_with_plans = []
    api_keys_count = 0
    api_keys_without_plan_count = 0
    error_count = 0
    filename = "api_keys_with_plans.json"

    api_keys.each do |key|
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
        sleep 0.1
      rescue Aws::APIGateway::Errors::ServiceError => e
        if e.message.include?("Rate exceeded")
          puts "Rate limit hit, retrying..."
          sleep 1
          retr
        else
          puts "Error retrieving usage plans for key #{key["name"]} (#{key["id"]}): #{e.message}"
          error_count += 1
        end
      end
    end

    File.write(filename, api_keys_with_plans.to_json)
    puts "Exported API keys with associated usage plans to #{filename}"
    puts "Total API Keys imported: #{api_keys_count}"
    puts "Total API Keys without usage plans: #{api_keys_without_plan_count}"
    puts "Total errors: #{error_count}"
  end

  def delete_input_file
    begin
      puts "Deleting #{file_path}..."
      File.delete(file_path)
      puts "#{file_path} has been successfully deleted."
    rescue Errno::ENOENT
      puts "Error: The file #{file_path} does not exist."
    rescue StandardError => e
      puts "An error occurred while deleting the file #{file_path}: #{e.message}"
    end
  end

  private

  def read_usage_plans
    begin
      file = File.read(file_path)
      api_keys = JSON.parse(file)
    rescue Errno::ENOENT => e
      puts "Error: File not found - #{e.message}"
      exit
    rescue Errno::EACCES => e
      puts "Error: File not accessible - #{e.message}"
      exit
    rescue JSON::ParserError => e
      puts "Error: File content is not valid JSON - #{e.message}"
      exit
    rescue StandardError => e
      puts "An unexpected error occurred - #{e.message}"
      exit
    end

    if api_keys.has_key?("items")
      api_keys["items"]
    else
      puts "No API keys found in #{file_path}"
      exit
    end
  end
end
