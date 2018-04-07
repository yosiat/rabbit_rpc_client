# frozen_string_literal: true

require 'bunny'
require 'oj'
require 'concurrent'
require 'securerandom'
require 'singleton'

class RabbitMQConnection
  include Singleton

  attr_reader :connection
  attr_reader :default_channel, :exchange

  def initialize
    @connection = Bunny.new
    @connection.start

    @default_channel = @connection.create_channel
    @exchange = @default_channel.default_exchange
  end

  def close
    @connection.stop
    @connection.close
  end
end

class RpcReplyConsumer
  include Singleton

  def initialize
    @reply_queue = RabbitMQConnection.instance.default_channel.queue('', exclusive: true)
    @futures = Concurrent::Map.new

    consume!
  end

  def name
    @reply_queue.name
  end

  def create_waiter_for_id(id)
    promise = Concurrent::IVar.new
    @futures[id] = promise
    promise
  end

  def close
    @consumer.cancel
  end

  private

  def consume!
    @consumer = @reply_queue.subscribe(manual_ack: false) do |_delivery_info, properties, payload|
      correlation_id = properties[:correlation_id]
      promise = @futures[correlation_id]
      raise "Empty promise for #{correlation_id}" if promise.nil?

      promise.set payload
      @futures.delete correlation_id
    end
  end
end

class ConcurrentClient
  DEFAULT_TIMEOUT = 60_000

  def initialize(service_name)
    @service_name = service_name
  end

  def call(message, timeout = DEFAULT_TIMEOUT)
    call_id = SecureRandom.uuid
    promise = RpcReplyConsumer.instance.create_waiter_for_id call_id

    dispatch message, correlation_id: call_id, reply_to: RpcReplyConsumer.instance.name

    Oj.load(promise.value(timeout))
  end

  def dispatch(message, options = {})
    RabbitMQConnection.instance.exchange.publish(
      Oj.dump(message),
      options.merge(
        content_type: 'application/json',
        routing_key: @service_name
      )
    )
  end

  def stop; end
end
