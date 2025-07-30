#!/usr/bin/env ruby

require 'http'
require 'sqlite3'
require 'json'
require 'logger'
require 'securerandom'

class ApiCheck
  DEFAULT_TIMEOUT = 10
  DEFAULT_INTERVAL = 1
  DEFAULT_DURATION = 600

  def initialize(url:, name: nil, db_path: 'request_logs.db', duration: DEFAULT_DURATION, interval: DEFAULT_INTERVAL)
    @url = url
    @name = name
    @duration = duration
    @interval = interval
    @logger = setup_logger
    @db = setup_database(db_path)
    @stats = { total: 0, success: 0, errors: 0 }
    @start_time = nil
  end

  def run
    validate_url!
    
    @logger.info "Starting API monitoring for #{@duration} seconds..."
    @logger.info "Target URL: #{@url}"
    
    @start_time = Time.now
    end_time = @start_time + @duration

    while Time.now < end_time
      make_request
      sleep(@interval)
    end

    print_summary
    @logger.info "Monitoring completed."
  ensure
    @db&.close
  end

  private

  def setup_logger
    logger = Logger.new($stdout)
    logger.level = Logger::INFO
    logger.formatter = proc do |severity, datetime, progname, msg|
      "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{severity}: #{msg}\n"
    end
    logger
  end

  def setup_database(db_path)
    db = SQLite3::Database.new(db_path)
    create_table_if_not_exists(db)
    db
  rescue SQLite3::Exception => e
    @logger.error "Database error: #{e.message}"
    raise
  end

  def create_table_if_not_exists(db)
    db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS request_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT NOT NULL,
        name_parameter TEXT NOT NULL,
        response_status INTEGER NOT NULL,
        response_text TEXT NOT NULL,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
      );
    SQL
  end

  def validate_url!
    uri = URI.parse(@url)
    raise ArgumentError, "Invalid URL scheme" unless %w[http https].include?(uri.scheme)
  rescue URI::InvalidURIError => e
    raise ArgumentError, "Invalid URL format: #{e.message}"
  end

  def make_request
    start_time = Time.now
    
    # Use provided name or generate a random 15-character string for this request
    name_to_use = @name || SecureRandom.alphanumeric(15)
    
    begin
      response = HTTP
        .timeout(DEFAULT_TIMEOUT)
        .headers('Content-Type' => 'application/json')
        .post(@url, body: { name: name_to_use }.to_json)
      
      response_time = ((Time.now - start_time) * 1000).round
      
      log_request(response.status.code, response.body.to_s, name_to_use)
      update_stats(response.status.success?)
      
      if response.status.success?
        @logger.info "Request successful (#{response.status.code}) - #{response_time}ms - Name: #{name_to_use}"
      else
        @logger.info "Request failed with status #{response.status.code} - #{response_time}ms - Name: #{name_to_use}"
      end
      
    rescue HTTP::Error, HTTP::TimeoutError => e
      response_time = ((Time.now - start_time) * 1000).round
      error_msg = "HTTP Error: #{e.class} - #{e.message}"
      
      log_request(599, error_msg, name_to_use)
      update_stats(false)
      
      @logger.error "#{error_msg} - Name: #{name_to_use}"
    rescue StandardError => e
      response_time = ((Time.now - start_time) * 1000).round
      error_msg = "Unexpected error: #{e.class} - #{e.message}"
      
      log_request(599, error_msg, name_to_use)
      update_stats(false)
      
      @logger.error "#{error_msg} - Name: #{name_to_use}"
    end
  end

  def log_request(status, response_text, name_used)
    @db.execute(
      'INSERT INTO request_logs (url, name_parameter, response_status, response_text) VALUES (?, ?, ?, ?)',
      [@url, name_used, status, response_text]
    )
  rescue SQLite3::Exception => e
    @logger.error "Failed to log request: #{e.message}"
  end

  def update_stats(success)
    @stats[:total] += 1
    if success
      @stats[:success] += 1
    else
      @stats[:errors] += 1
    end
  end

  def print_summary
    success_rate = @stats[:total] > 0 ? (@stats[:success].to_f / @stats[:total] * 100).round(2) : 0
    
    # Calculate total running time
    total_running_time = @start_time ? (Time.now - @start_time).round(1) : 0
    
    puts "\n" + "="*50
    puts "MONITORING SUMMARY"
    puts "="*50
    puts "Total running time: #{total_running_time} seconds"
    puts "Total requests: #{@stats[:total]}"
    puts "Successful: #{@stats[:success]}"
    puts "Errors: #{@stats[:errors]}"
    puts "Success rate: #{success_rate}%"
    puts "="*50
  end
end

# Configuration
DEFAULT_URL = 'https://qa-challenge-nine.vercel.app/api/name-checker'
DEFAULT_DURATION = 600  # 10 minutes
DEFAULT_INTERVAL = 1    # 1 second

# Usage
if __FILE__ == $0
  require 'optparse'
  
  options = {
    url: DEFAULT_URL,
    duration: DEFAULT_DURATION,
    interval: DEFAULT_INTERVAL,
    db_path: 'request_logs.db'
  }
  
  OptionParser.new do |opts|
    opts.banner = "Usage: ruby ApiCheck.rb [options]"
    
    opts.on("-u", "--url URL", "API URL (default: #{DEFAULT_URL})") do |url|
      options[:url] = url
    end
    
    opts.on("-n", "--name NAME", "Name parameter (overrides random generation)") do |name|
      options[:name] = name
    end
    
    opts.on("-d", "--duration SECONDS", Integer, "Duration in seconds (default: #{DEFAULT_DURATION})") do |duration|
      options[:duration] = duration
    end
    
    opts.on("-i", "--interval SECONDS", Float, "Interval between requests (default: #{DEFAULT_INTERVAL})") do |interval|
      options[:interval] = interval
    end
    
    opts.on("--db-path PATH", "Database path (default: request_logs.db)") do |path|
      options[:db_path] = path
    end
    
    opts.on("-h", "--help", "Show this help message") do
      puts opts
      exit
    end
  end.parse!
  
  begin
    monitor = ApiCheck.new(
      url: options[:url],
      name: options[:name],
      duration: options[:duration],
      interval: options[:interval],
      db_path: options[:db_path]
    )
    monitor.run
  rescue ArgumentError => e
    puts "Configuration error: #{e.message}"
    exit 1
  rescue Interrupt
    puts "\nMonitoring interrupted by user"
    exit 0
  rescue StandardError => e
    puts "Fatal error: #{e.message}"
    exit 1
  end
end