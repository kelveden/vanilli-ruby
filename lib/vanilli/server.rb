require 'rest-client'

# Provides hooks for starting and stopping a vanilli server. Relies on the vanilli CLI
# API and therefore requires vanilli to be installed.
class VanilliServer
  def initialize(port:, static_root: nil, static_include: [], static_exclude: [], static_default: 'index.html', log_level: 'warn')
    @static_root = static_root
    @static_default = static_default
    @static_include = static_include.join(',')
    @static_exclude = static_exclude.join(',')
    @port = port
    @log_level = log_level
  end

  # Shells out to start vanilli
  def start(cwd: '.')
    @pid = spawn("vanilli --port #{@port} \
                    --logLevel=#{@log_level} \
                    --staticRoot=#{@static_root} \
                    --staticDefault=#{@static_default} \
                    --staticInclude=#{@static_include} \
                    --staticExclude=#{@static_exclude}", chdir: cwd)

    Timeout.timeout(3) do
      begin
        RestClient.get "http://localhost:#{@port}/_vanilli/ping"
      rescue
        sleep 0.1
        retry
      end
    end

    self
  end

  # Stops the vanilli server by killing the
  # process started when shelling out to start vanilli
  def stop
    if @pid
      Process.kill('KILL', @pid)
      Process.wait @pid
    end
    @pid = nil
  end
end
