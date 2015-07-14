module ActionCable
  module Server
    # Worker used by Server.send_async to do connection work in threads. Only for internal use.
    class Worker
      include ActiveSupport::Callbacks
      include Celluloid
      include ClearDatabaseConnections

      define_callbacks :work

      def invoke(receiver, method, *args)
        run_callbacks :work do
          receiver.send method, *args
        end
      rescue Exception => e
        logger.error "There was an exception - #{e.class}(#{e.message})"
        logger.error e.backtrace.join("\n")

        receiver.handle_exception if receiver.respond_to?(:handle_exception)
      end

      def run_periodic_timer(channel, callback)
        run_callbacks :work do
          callback.respond_to?(:call) ? channel.instance_exec(&callback) : channel.send(callback)
        end
      end

      private
        def logger
          ActionCable.server.logger
        end
    end
  end
end