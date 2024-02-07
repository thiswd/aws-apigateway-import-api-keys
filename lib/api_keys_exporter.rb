require 'aws-sdk-apigateway'
require 'json'

class ApiKeysExporter
  OUTPUT_FILENAME = "api_keys.json".freeze
  WAIT_TIME_DEFAULT = 1.freeze

  def initialize(region, wait_time, profile_name = 'default')
    credentials = Aws::SharedCredentials.new(profile_name: profile_name).credentials
    @apigateway = Aws::APIGateway::Client.new(region: region, credentials: credentials)
    @wait_time = wait_time || WAIT_TIME_DEFAULT
    @api_keys_with_plans = []
    @api_keys_count = 0
    @api_keys_without_plan_count = 0
    @error_count = 0
  end

  def execute
    export_api_keys
    print_results
  end

  private
  def export_api_keys
    token = nil
    per_page = 500

    begin
      loop do
        response = @apigateway.get_api_keys(limit: per_page, position: token, include_values: true)
        api_keys = response.items
        break if api_keys.empty?

        add_usage_plans(api_keys)

        token = response.position
        break unless token
      end
    rescue StandardError => e
      puts "An error occurred: #{e.message}"
    end

    save_to_file
  end

  def add_usage_plans(api_keys)
    api_keys.each do |key|
      begin
        usage_plans = @apigateway.get_usage_plans(key_id: key["id"]).items

        print_key_without_plan(key) if usage_plans.empty?

        @api_keys_with_plans << {
          name: key["name"],
          value: key["value"],
          description: key["description"],
          enabled: key["enabled"],
          usage_plan_names: usage_plans.map(&:name)
        }
        @api_keys_count += 1
        sleep 0.1
      rescue Aws::APIGateway::Errors::ServiceError => e
        if e.message.include?("Rate exceeded")
          puts "Rate limit hit, retrying..."
          sleep @wait_time
          retry
        else
          puts "Error retrieving usage plans for key #{key["name"]} (#{key["id"]}): #{e.message}"
          @error_count += 1
        end
      end
    end
  end

  def print_key_without_plan(key)
    puts "Key #{key["name"]} (#{key["id"]}) has no usage plans"
    @api_keys_without_plan_count += 1
  end

  def save_to_file
    File.write(OUTPUT_FILENAME, @api_keys_with_plans.to_json)
  end

  def print_results
    puts "Exported API keys with associated usage plans to #{OUTPUT_FILENAME}"
    puts "Total API keys imported: #{@api_keys_count}"
    puts "Total API keys without usage plans: #{@api_keys_without_plan_count}"
    puts "Total errors: #{@error_count}"
  end
end
