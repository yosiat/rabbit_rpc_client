# frozen_string_literal: true

require 'benchmark'
require 'benchmark/ips'
require 'HDRHistogram'
require 'securerandom'
require_relative './simple_client'
require_relative './concurrent_client'

SERVICE_NAME = ENV['SERVICE_NAME']

class << Benchmark
  # Benchmark realtime in milliseconds.
  #
  #   Benchmark.realtime { User.all }
  #   # => 8.0e-05
  #
  #   Benchmark.ms { User.all }
  #   # => 0.074
  def ms
    1000 * realtime { yield }
  end
end


def run_and_verify client
  n = Random::DEFAULT.rand(1_000)
  response = client.call('n' => n)
  raise "#{n} is not #{n + 1} it is #{response["result"]}" if response["result"] != n + 1
end

def stress(&block)
  threads = []
  hdr = HDRHistogram.new(1, 1_000, 3)

  runtime = Benchmark.measure do
    100.times do |_i|
      threads << Thread.new do
        hdr.record Benchmark.ms(&block)
      end
    end
    threads.map(&:join)
  end

  puts "Runtime: #{runtime}"
  puts hdr.latency_stats
end

def benchmark(client_klass, same_stress = false)
  puts "######################################"
  puts " #{client_klass.name}"
  puts "######################################\n"

  same_client = client_klass.new SERVICE_NAME

  Benchmark.ips do |x|
    x.report('new-client') do
      client = client_klass.new SERVICE_NAME
      client.call('n' => 1)
      client.stop
    end

    x.report('existing-client') do |_times|
      same_client.call('n' => 1)
    end

    x.compare!
  end

  same_client.stop

  puts 'Starting 100 concurrent requests with new client: \n'

  stress do
    client = client_klass.new SERVICE_NAME
    run_and_verify client
    client.stop
  end

  if same_stress
    puts 'Starting 100 concurrent requests with same client: \n'

    same_client = client_klass.new SERVICE_NAME
    stress do
      run_and_verify same_client
    end
    same_client.stop
  end
end

benchmark ConcurrentClient, true
benchmark SimpleClient
