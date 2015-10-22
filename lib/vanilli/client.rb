require 'rest-client'
require 'json'

private def unwrap_regex(thing)
  if thing.is_a?(Regexp)
    return { regex: thing.source }
  else
    return thing
  end
end

private def fail_body_with_no_contenttype(body, content_type)
  fail 'Body was specified for but content-type was missing.' if body && !content_type
end

private def map_over_hash(h, f)
  if h.nil?
    return nil
  else
    return h.map { |key, value| { key => send(f, value) } }.reduce(:merge)
  end
end

private def strip_nils(h)
  h.delete_if { |_k, v| v.nil? }
end

private def stringify_non_json_content(content_blob)
  body = content_blob[:body]

  if (body.is_a? Hash) && (content_blob[:contentType] != 'application/json')
    return content_blob.merge(body: body.to_json)
  else
    return content_blob
  end
end

private def stubs_to_body(stubs)
  '[' + stubs.map(&:to_json).join(',') + ']'
end

# Provides ruby bindings for the vanilli client. API is a
# "rubified" (i.e. snake-case for camel-case) version of the
# default javascript API provided with vanilli.
class VanilliClient
  def initialize(port)
    @port = port
  end

  # Represents a single stub as will be registered with
  # the vanilli server.
  class Stub
    attr_writer :expect
    attr_writer :priority
    attr_reader :criteria
    attr_reader :priority
    attr_reader :response
    attr_reader :times
    attr_reader :capture_id

    def initialize(criteria:, priority:)
      @criteria = criteria
      @priority = priority
      @response = {}
    end

    # Construct the response for the stub
    def respond_with(status, body: nil, content_type: nil, headers: nil, times: 1)
      fail 'Status code is missing.' if status.nil?
      fail_body_with_no_contenttype(body, content_type)

      @response = stringify_non_json_content(
        @response.merge!(
          strip_nils(status: status, contentType: content_type, body: body, headers: headers)
        )
      )

      @times = times unless times == :any

      self
    end

    # Vanilli will wait the specified number of milliseconds
    # before responding with the stub response.
    def wait(milliseconds:)
      @response[:wait] = milliseconds
      self
    end

    # The body of the matching request(s) will be logged by vanilli
    # under the specified capture id.
    def capture(capture_id)
      @capture_id = capture_id
      self
    end

    # Converts the stub to JSON for sending to vanilli.
    def to_json
      strip_nils(criteria: strip_nils(@criteria),
                 priority: @priority,
                 response: strip_nils(@response),
                 times: @times,
                 captureId: @capture_id,
                 expect: @expect).to_json
    end

    def ensure_times_exists
      @expect = 1 unless @expect
    end
  end

  # Create a new Stub that will be matched
  # against the specified criteria.
  def on_request(method, url, content_type: nil, body: nil, query: nil, headers: nil, priority: nil)
    fail 'Url is missing.' unless url
    fail_body_with_no_contenttype(body, content_type)

    Stub.new(criteria: stringify_non_json_content(method: method,
                                                  url: unwrap_regex(url),
                                                  contentType: content_type,
                                                  body: body,
                                                  query: map_over_hash(query, :unwrap_regex),
                                                  headers: map_over_hash(headers, :unwrap_regex)),
             priority: priority)
  end

  # Creates a Stub for a GET request that will be
  # matched against the specified criteria.
  def on_get(url, query: nil, headers: nil, priority: nil)
    on_request('GET', url, query: query, headers: headers, priority: priority)
  end

  # Creates a Stub for a POST request that will be
  # matched against the specified criteria.
  def on_post(url, query: nil, headers: nil, priority: nil, content_type: nil, body: nil)
    on_request('POST', url, query: query, headers: headers, priority: priority, content_type: content_type, body: body)
  end

  # Creates a Stub for a PUT request that will be
  # matched against the specified criteria.
  def on_put(url, query: nil, headers: nil, priority: nil, content_type: nil, body: nil)
    on_request('PUT', url, query: query, headers: headers, priority: priority, content_type: content_type, body: body)
  end

  # Creates a Stub for a DELETE request that will be
  # matched against the specified criteria.
  def on_delete(url, query: nil, headers: nil, priority: nil)
    on_request('DELETE', url, query: query, headers: headers, priority: priority)
  end

  # Creates a Stub for a HEAD request that will be
  # matched against the specified criteria.
  def on_head(url, query: nil, headers: nil, priority: nil)
    on_request('HEAD', url, query: query, headers: headers, priority: priority)
  end

  # Registers the specified Stub(s) with the vanilli server.
  def stub(*stubs)
    RestClient.post "http://localhost:#{@port}/_vanilli/stubs",
                    stubs_to_body(stubs),
                    content_type: :json, accept: :json
  rescue => e
    raise e.response
  end

  # Registers the specified "default" stub(s) with the vanilli server.
  def stub_default(*stubs)
    defaults = stubs.map do |stub|
      stub.priority = 100_000
      stub
    end

    stub(*defaults)
  end

  # Registers the specified expectations(s) with the vanilli server.
  def expect(*expectations)
    RestClient.post "http://localhost:#{@port}/_vanilli/expectations",
                    stubs_to_body(expectations),
                    content_type: :json, accept: :json
  rescue => e
    raise e.response
  end

  # Clears the vanilli server of all stubs.
  def clear
    RestClient.delete "http://localhost:#{@port}/_vanilli/stubs"
  rescue => e
    raise e.response
  end

  # Verifies that all vanilli expectations have been met. If
  # not, an error is thrown.
  def verify
    begin
      res = JSON.parse(RestClient.get "http://localhost:#{@port}/_vanilli/verify")
    rescue => e
      raise e.response
    end

    fail 'VERIFICATION FAILED: ' + res['errors'].join('\n') if res['errors'].length > 0
  end

  # Pulls back details of all requests that were logged against the
  # specified capture id.
  def get_captures(capture_id)
    return JSON.parse(RestClient.get "http://localhost:#{@port}/_vanilli/captures/#{capture_id}")

  rescue RestClient::ResourceNotFound
    return []
  rescue => e
    raise e.response
  end

  # Pulls back details of the last request that was logged against the
  # specified capture id.
  def get_capture(capture_id)
    get_captures(capture_id).last
  end

  # Verifies that all vanilli expectations have been met. If
  # not, an error is thrown.
  def dump
    puts RestClient.get("http://localhost:#{@port}/_vanilli/dump")
  rescue => e
    raise e.response
  end
end
