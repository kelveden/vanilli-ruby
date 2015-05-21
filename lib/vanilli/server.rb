require 'rest-client'

class VanilliServer
  def initialize(port:, staticRoot: nil, staticInclude: [], staticExclude: [], staticDefault: "index.html", logLevel: "warn")
    @staticRoot = staticRoot
    @staticDefault = staticDefault
    @staticInclude = staticInclude.join(",")
    @staticExclude = staticExclude.join(",")
    @port = port
    @logLevel = logLevel
  end

  def start()
    @pid = spawn("vanilli --port #{@port} --logLevel=#{@logLevel} --staticRoot=#{@staticRoot} --staticDefault=#{@staticDefault} --staticInclude=#{@staticInclude} --staticExclude=#{@staticExclude}")

    Timeout::timeout(3) {
      begin
        RestClient.get "http://localhost:#{@port}/_vanilli/ping"
      rescue
        sleep 0.1
        retry
      end
    }

    return self
  end

  def stop()
    if (@pid)
      Process.kill("KILL", @pid)
      Process.wait @pid
    end
    @pid = nil
  end
end
