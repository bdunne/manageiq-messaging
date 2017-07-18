module ManageIQ
  module Messaging
    class Topic
      include Common

      def self.publish(client, options)
        assert_options(options, [:event, :service])

        options = options.dup
        address, headers = topic_for_publish(options)
        headers[:sender] = options.delete(:sender) if options[:sender]
        headers[:message_type] = options.delete(:event_type) if options[:event_type]

        raw_publish(client, address, options[:event], headers)
      end

      def self.subscribe(client, options)
        assert_options(options, [:service])

        options = options.dup
        queue_name, headers = topic_for_subscribe(options)

        client.subscribe(queue_name, headers) do |event|
          begin
            sender = event.headers['sender']
            event_type = event.headers['event_type']
            event_body = decode_body(event.headers, event.body)
            $log.info("Event received: queue(#{queue_name}), event(#{event_body}), headers(#{event.headers})") if $log
            yield sender, event_type, event_body
            $log.info("Event processed") if $log
          rescue => err
            client.ack(event)
          end
        end
      end
    end
  end
end