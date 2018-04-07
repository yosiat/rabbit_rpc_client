# frozen_string_literal: true

require 'bunny'
require 'oj'
require 'concurrent'
require 'securerandom'

class ConcurrentClient
  def initialize(service_name)
    @conn = Bunny.new
    @conn.start
    ch = @conn.create_channel

    @x = ch.default_exchange
    @reply_queue = ch.queue('', exclusive: true)
    @service_name = service_name

    futures = @futures = Concurrent::Map.new

    @timeout = nil

    @consumer = @reply_queue.subscribe(manual_ack: false) do |_delivery_info, properties, payload|
      correlation_id = properties[:correlation_id]
      promise = futures[correlation_id]

      promise.set payload
      futures.delete correlation_id
    end
  end

  def call(message)
    promise = Concurrent::IVar.new

    call_id = SecureRandom.uuid
    @futures.put call_id, promise

    @x.publish(Oj.dump(message),
               correlation_id: call_id,
               content_type: 'application/json',
               routing_key: @service_name,
               reply_to: @reply_queue.name)

    Oj.load(promise.value(@timeout))
  end

  def stop
    @consumer.cancel
    @conn.close
  end
end
