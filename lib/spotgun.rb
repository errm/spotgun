require "net/http"
require "time"
require "logger"

class Spotgun
  ENDPOINT = URI.parse("http://169.254.169.254/latest/meta-data/spot/termination-time")

  def initialize(client: Net::HTTP, kernel: Kernel, log_device: STDERR)
    @logger = Logger.new(log_device)
    logger.level = Logger::INFO unless ENV["DEBUG"]
    @client = client
    @kernel = kernel
  end

  def run
    while check do
      sleep 5
    end
  end

  def check
    response = client.get_response(ENDPOINT)
    case response.code
    when "404"
      logger.debug { "No impending termination, going to sleep" }
    when "200"
      @termination_time = Time.parse(response.body)
      logger.info { "Node will terminate in #{grace_period} seconds" }
      drain
    else
      logger.error { "Unexpected response from metadata service: #{response.code}: #{response.body}" }
    end
  rescue => e
    logger.error { "Unexpected error: #{e}" }
  end

  private

  attr_reader :termination_time, :logger, :kernel, :client, :wait

  def drain
    kernel.system(
      "/usr/local/bin/kubectl",
        "drain", node_name,
          "--grace-period=#{grace_period}",
          "--force",
          "--ignore-daemonsets",
          "--delete-local-data",
    )
    logger.info { "Drain complete" }
  end

  def grace_period
    (termination_time - Time.now).to_i
  end

  def node_name
    ENV.fetch("NODE_NAME")
  end
end
