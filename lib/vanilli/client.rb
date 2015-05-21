require 'rest-client'
require 'json'

private def unwrapRegExp(thing)
  if thing.is_a?(Regexp)
    return {regex: thing.source}
  else
    return thing
  end
end

private def failBodyWithNoContentType(body, contentType)
  if (body and !contentType)
    raise "Body was specified for but content-type was missing."
  end
end

private def mapHash(h, f)
  if (h.nil?)
    return nil
  else
    return h.map { |key, value| {key => send(f, value)} }.reduce(:merge)
  end
end

private def stripNils(h)
  return h.delete_if { |k, v| v.nil? }
end

private def stringifyNonJsonContent(contentBlob)
  body = contentBlob[:body]

  if ((body.is_a? Hash) and (contentBlob[:contentType] != "application/json"))
    return contentBlob.merge({body: body.to_json})
  else
    return contentBlob;
  end
end

class VanilliClient
  class Stub
    attr_writer :expect

    def initialize(criteria:, priority:)
      @criteria = criteria
      @priority = priority
    end

    def respond_with(status, body: nil, contentType: nil, headers: nil, times: 1)
      if (status.nil?)
        raise "Status code is missing."
      end

      failBodyWithNoContentType(body, contentType)

      @response =
          stringifyNonJsonContent(
              stripNils({
                            status: status,
                            contentType: contentType,
                            body: body,
                            headers: headers
                        }))
      @times = times

      return self
    end

    def wait(milliseconds:)
      @response[:wait] = milliseconds
      return self
    end

    def capture(captureId)
      @captureId = captureId
      return self
    end

    def to_json()
      return stripNils({
                           criteria: stripNils(@criteria),
                           priority: @priority,
                           response: stripNils(@response),
                           times: @times,
                           captureId: @captureId,
                           expect: @expect
                       }).to_json
    end
  end

  def on_request(method, url, contentType: nil, body: nil, query: nil, headers: nil, priority: nil)
    if (!url)
      raise "Url is missing."
    end

    failBodyWithNoContentType(body, contentType)

    stub = Stub.new(criteria: stringifyNonJsonContent({
                                                          method: method,
                                                          url: unwrapRegExp(url),
                                                          contentType: contentType,
                                                          body: body,
                                                          query: mapHash(query, :unwrapRegExp),
                                                          headers: mapHash(headers, :unwrapRegExp)
                                                      }),
                    priority: priority)

    return stub
  end

  def on_get(url, query: nil, headers: nil, priority: nil)
    return on_request("GET", url, query: query, headers: headers, priority: priority)
  end

  def on_post(url, query: nil, headers: nil, priority: nil, contentType: nil, body: nil)
    return on_request("POST", url, query: query, headers: headers, priority: priority, contentType: contentType, body: body)
  end

  def on_put(url, query: nil, headers: nil, priority: nil, contentType: nil, body: nil)
    return on_request("PUT", url, query: query, headers: headers, priority: priority, contentType: contentType, body: body)
  end

  def on_delete(url, query: nil, headers: nil, priority: nil)
    return on_request("DELETE", url, query: query, headers: headers, priority: priority)
  end

  def stub(*stubs)
    stubs.each do |stub|
      begin
        RestClient.post "http://localhost:9000/_vanilli/stubs", stub.to_json, content_type: :json, accept: :json
      rescue => e
        raise e.response
      end
    end
  end

  def expect(expectation)
    expectation.expect = true
    return self.stub(expectation)
  end

  def clear()
    begin
      RestClient.delete "http://localhost:9000/_vanilli/stubs"
    rescue => e
      raise e.response
    end
  end

  def verify()
    begin
      res = JSON.parse(RestClient.get "http://localhost:9000/_vanilli/verify")
    rescue => e
      raise e.response
    end

    if (res["errors"].length > 0)
      raise "VERIFICATION FAILED: " + res["errors"].join("\n")
    end
  end

  def get_captures(captureId)
    begin
      return JSON.parse(RestClient.get "http://localhost:9000/_vanilli/captures/" + captureId)
    rescue => e
      raise e.response
    end
  end

  def get_capture(captureId)
    return get_captures(captureId).last
  end
end
