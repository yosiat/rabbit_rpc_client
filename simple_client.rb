# frozen_string_literal: true

require 'bunny'
require 'oj'
require 'securerandom'

class SimpleClient
  attr_reader :reply_queue
  attr_accessor :response, :call_id
  attr_reader :lock, :condition

  def initialize(service_name)
    @conn = Bunny.new
    @conn.start
    ch = @conn.create_channel

    @x = ch.default_exchange
    @reply_queue = ch.queue('', exclusive: true)
    @service_name = service_name.to_s

    @lock = Mutex.new
    @condition = ConditionVariable.new
    that = self

    @reply_queue.subscribe do |_delivery_info, properties, payload|
      if properties[:correlation_id] == that.call_id
        that.response = payload.to_s
        that.lock.synchronize { that.condition.signal }
      end
    end
  end

  def call(message)
    self.call_id = generate_uuid
    @x.publish(Oj.dump(message),
               content_type: "application/json",
               routing_key: @service_name,
               correlation_id: call_id,
               reply_to: @reply_queue.name)

    lock.synchronize { condition.wait(lock) }
    Oj.load(response)
  end

  def stop
    @conn.close
  end

  private

  def generate_uuid
    SecureRandom.uuid
  end
end
