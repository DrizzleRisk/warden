require "warden/errors"
require "warden/container/base"
require "warden/container/script_handler"
require "warden/container/remote_script_handler"
require "tempfile"
require "socket"

module Warden

  module Container

    class Insecure < Base

      def self.setup(config={})
        # noop
      end

      def container_root_path
        File.join(container_path, "root")
      end

      def do_create
        # Create container
        sh "#{root_path}/create.sh #{handle}"
        debug "container created"

        # Start container
        sh "#{container_path}/start.sh"
        debug "container started"
      end

      def do_destroy
        # Stop container
        sh "#{container_path}/stop.sh"
        debug "container stopped"

        # Destroy container
        sh "rm -rf #{container_path}"
        debug "container destroyed"
      end

      def create_job(script)
        job = Job.new(self)
        env = { "job_path" => File.join(container_root_path, job.path) }
        p = DeferredChild.new(env, File.join(container_path, "run.sh"), :input => script)
        p.callback { job.finish }
        p.errback { job.finish }

        job
      end

      # Nothing has to be done to map an external port to an insecure
      # container. The container lives in the same kernel namespaces as all
      # other processes, so it has to share its ip space them. To make it more
      # likely for a process inside the insecure container to bind to this
      # inbound port, we grab and return an ephemeral port.
      def _net_inbound_port
        socket = TCPServer.new("0.0.0.0", 0)
        socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1)
        socket.do_not_reverse_lookup = true
        port = socket.addr[1]
        socket.close
        port
      end
    end
  end
end
