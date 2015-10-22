require "vanilli/client"
require 'webmock/rspec'

RSpec.describe VanilliClient do
  DUMMY_PORT = 1234
  DUMMY_URL = "/some/url"
  DUMMY_CONTENT_TYPE = "some/contentype"
  DUMMY_STATUS = 111
  DUMMY_BODY = "somebody"

  def create_vanilli
    VanilliClient.new DUMMY_PORT
  end

  it "can be instantiated" do
    expect(VanilliClient.new DUMMY_PORT).to_not be_nil
  end

  context "stub creation" do

    it "can create a GET stub" do
      expect(create_vanilli.on_get("/my/path").criteria[:method]).to eq("GET")
    end

    it "can create a POST stub" do
      expect(create_vanilli.on_post("/my/path").criteria[:method]).to eq("POST")
    end

    it "can create a PUT stub" do
      expect(create_vanilli.on_put("/my/path").criteria[:method]).to eq("PUT")
    end

    it "can create a DELETE stub" do
      expect(create_vanilli.on_delete("/my/path").criteria[:method]).to eq("DELETE")
    end

    it "can create a HEAD stub" do
      expect(create_vanilli.on_head("/my/path").criteria[:method]).to eq("HEAD")
    end

    it "throws an error if url is missing from stub" do
      expect { create_vanilli.on_get(nil) }.to raise_error("Url is missing.")
    end

    it "throws an error if content type is missing from body" do
      expect { create_vanilli.on_post(DUMMY_URL, body: "") }.to raise_error("Body was specified for but content-type was missing.")
    end

    it "sets url on stub" do
      expect(create_vanilli.on_get("/my/url").criteria[:url]).to eq("/my/url")
    end

    it "unwraps url regex" do
      expect(create_vanilli.on_get(/whatever/).criteria[:url][:regex]).to eq("whatever")
    end

    it "sets body on stub" do
      expect(create_vanilli.on_post(DUMMY_URL, body: "mybody", content_type: DUMMY_CONTENT_TYPE).criteria[:body]).to eq("mybody")
    end

    it "converts non-json body hash into string" do
      expect(create_vanilli.on_post(/whatever/, body: {somefield: "somevalue"}, content_type: "not/json").criteria[:body]).to eq('{"somefield":"somevalue"}')
    end

    it "sets query on stub" do
      expect(create_vanilli.on_get(DUMMY_URL, query: {a: 1, b: 2}).criteria[:query]).to eq({a: 1, b: 2})
    end

    it "unwraps query regex" do
      expect(create_vanilli.on_get(DUMMY_URL, query: {a: /whatever/}).criteria[:query]).to eq({a: {regex: "whatever"}})
    end

    it "sets headers on stub" do
      expect(create_vanilli.on_get(DUMMY_URL, headers: {a: 1, b: 2}).criteria[:headers]).to eq({a: 1, b: 2})
    end

    it "unwraps header regex" do
      expect(create_vanilli.on_get(DUMMY_URL, headers: {a: /whatever/}).criteria[:headers]).to eq({a: {regex: "whatever"}})
    end

    it "sets priority" do
      expect(create_vanilli.on_get(DUMMY_URL, priority: 666).priority).to eq(666)
    end

    it "sets response status" do
      expect(create_vanilli.on_get(DUMMY_URL).respond_with(123).response[:status]).to eq(123)
    end

    it "sets response body" do
      stub = create_vanilli.on_get(DUMMY_URL).respond_with(123, body: "mybody", content_type: DUMMY_CONTENT_TYPE)

      expect(stub.response[:body]).to eq("mybody")
    end

    it "sets response content type" do
      stub = create_vanilli.on_get(DUMMY_URL).respond_with(123, body: DUMMY_BODY, content_type: "my/contenttype")

      expect(stub.response[:contentType]).to eq("my/contenttype")
    end

    it "throws an error if content type is missing from response body" do
      expect { create_vanilli.on_get(DUMMY_URL).respond_with(123, body: DUMMY_BODY) }.to raise_error("Body was specified for but content-type was missing.")
    end

    it "sets response headers" do
      stub = create_vanilli.on_get(DUMMY_URL).respond_with(123, headers: {a: "1", b: "2"})

      expect(stub.response[:headers]).to eq({a: "1", b: "2"})
    end

    it "sets times value" do
      stub = create_vanilli.on_get(DUMMY_URL).respond_with(123, times: 666)

      expect(stub.times).to eq(666)
    end

    it "does not set times value if :any" do
      stub = create_vanilli.on_get(DUMMY_URL).respond_with(123, times: :any)

      expect(stub.times).to be_nil
    end

    it "sets wait" do
      stub = create_vanilli.on_get(DUMMY_URL).respond_with(123).wait(milliseconds: 666)

      expect(stub.response[:wait]).to eq(666)
    end

    it "sets capture id" do
      stub = create_vanilli.on_get(DUMMY_URL).respond_with(123).capture("mycaptureid")

      expect(stub.capture_id).to eq("mycaptureid")
    end
  end

  context "vanilli server calls" do
    it "sends stubs as json" do
      # Given
      vanilli = create_vanilli
      url = "http://localhost:1234/_vanilli/stubs"

      stub_request(:post, url).to_return(status: 200)

      # When
      vanilli.stub(vanilli.on_get(DUMMY_URL).respond_with(DUMMY_STATUS))

      # Then
      expect(WebMock).to have_requested(:post, url)
        .with(body: '[{"criteria":{"method":"GET","url":"/some/url"},"response":{"status":111},"times":1}]',
              headers: {'Content-Type' => 'application/json'})
    end

    it "sends expectations as json" do
      # Given
      vanilli = create_vanilli
      url = "http://localhost:1234/_vanilli/expectations"

      stub_request(:post, url).to_return(status: 200)

      # When
      vanilli.expect(vanilli.on_get(DUMMY_URL).respond_with(DUMMY_STATUS))

      # Then
      expect(WebMock).to have_requested(:post, url)
      .with(body: '[{"criteria":{"method":"GET","url":"/some/url"},"response":{"status":111},"times":1}]',
        headers: {'Content-Type' => 'application/json'})
    end

    it "sends default stubs as json" do
      # Given
      vanilli = create_vanilli
      url = "http://localhost:1234/_vanilli/stubs"

      stub_request(:post, url).to_return(status: 200)

      # When
      vanilli.stub_default(vanilli.on_get(DUMMY_URL).respond_with(DUMMY_STATUS))

      # Then
      expect(WebMock).to have_requested(:post, url)
      .with(body: '[{"criteria":{"method":"GET","url":"/some/url"},"priority":100000,"response":{"status":111},"times":1}]',
        headers: {'Content-Type' => 'application/json'})
    end
  end
end