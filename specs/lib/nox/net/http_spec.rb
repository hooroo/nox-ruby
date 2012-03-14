require 'spec_helper'
require 'nox/net/http'
require 'fileutils'

describe Net::HTTP do

  before :each do
    @http = Net::HTTP.new 'allow.com', 80
  end

  describe "#should_use_nox?" do

    it "should return false by default" do
      assert !@http.should_use_nox?
    end

    it "should return true if tmp/nox.txt is present" do
      touch_nox

      assert @http.should_use_nox?

      remove_nox
    end

  end

  describe "#nox_config" do

    it "should return the nox config" do
      @http.nox_config.must_be_instance_of Hash
    end

    it "should parse as a ERB template" do
      @http.nox_config['development']['ignore'][4]['port'].must_equal 3000
    end

    it "should load regular expressions" do
      @http.nox_config['development']['ignore'][3]['path'].must_equal /.gif$/
    end

  end

  describe "#should_ignore_request?" do

    it "should return false if the rules are nil" do
      assert !@http.should_ignore_request?(URI.parse("http://www.ruby-lang.org"), nil)
    end

    it "should return false if there are no rules" do
      assert !@http.should_ignore_request?(URI.parse("http://www.ruby-lang.org"), [])
    end

    it "should allow the host matching" do
      rules = [ { "host" => "localhost" } ]

      assert @http.should_ignore_request?(URI.parse("http://localhost"), rules)
      assert !@http.should_ignore_request?(URI.parse("http://foo.com"), rules)
    end

    it "should allow port matching" do
      rules = [ { "port" => 5000 } ]

      assert @http.should_ignore_request?(URI.parse("http://127.0.0.1:5000"), rules)
      assert !@http.should_ignore_request?(URI.parse("http://127.0.0.1:80"), rules)
    end

    it "should allow host and port matching" do
      rules = [ { "host" => "google.com", "port" => 8080 } ]

      assert @http.should_ignore_request?(URI.parse("http://google.com:8080"), rules)
      assert !@http.should_ignore_request?(URI.parse("http://google.com:1234"), rules)
    end

    it "should allow regular expression matching" do
      rules = [ { "path" => /\.gif$/ } ]

      assert @http.should_ignore_request?(URI.parse("http://www.ruby-lang.org/logo.gif"), rules)
      assert !@http.should_ignore_request?(URI.parse("http://www.ruby-lang.org/logo.png"), rules)
    end

    it "should allow matching when there are multiple rules defined" do
      rules = [ { "path" => /\.gif$/ }, { "host" => "google.com" } ]

      assert !@http.should_ignore_request?(URI.parse("http://ruby-lang.org"), rules)
      assert !@http.should_ignore_request?(URI.parse("http://localhost"), rules)
    end

  end

  describe "#request" do

    describe "with nox enabled" do

      before :each do
        touch_nox
      end

      it "should route traffic through nox" do
        stub_http_request(:any, "http://nox-server.com:1234/request").
          with(:headers => { 'Nox-Timeout'=>'60', 'Nox-Url'=>'http://allow.com/', 'Nox-Method' => 'GET' })
        @http.get '/'

        assert_requested(:post, "http://nox-server.com:1234/request")
      end

      it "should pass through post data" do
        stub_request(:post, "http://nox-server.com:1234/request").
          with(:body => {"per_page"=>"50", "q"=>"My query"},
               :headers => {'Accept'=>'*/*', 'Content-Type'=>'application/x-www-form-urlencoded', 'Nox-Method'=>'POST', 'Nox-Timeout'=>'60', 'Nox-Url'=>'http://allow.com/', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => "", :headers => {})

        response = Net::HTTP.post_form(URI.parse('http://allow.com/'), {"q" => "My query", "per_page" => "50"})

        assert_requested(:post, "http://nox-server.com:1234/request")
      end

      it "should ignore certain requests" do
        stub_request(:get, "http://allow.com/logo.gif")
        @http.get '/logo.gif'

        assert_requested(:get, "http://allow.com/logo.gif")
      end

      it "should handle different HTTP methods" do
        stub_http_request(:any, "http://nox-server.com:1234/request").
          with(:headers => { 'Nox-Timeout'=>'60', 'Nox-Url'=>'http://allow.com/delete', 'Nox-Method' => 'DELETE' })
        @http.delete '/delete'

        assert_requested(:post, "http://nox-server.com:1234/request")
      end

      it "should allow different types of post syntax" do
        stub_request(:post, "http://nox-server.com:1234/request").
            with(:body => "foo=bar&x=y",
                 :headers => {'Accept'=>'*/*', 'Nox-Method'=>'POST', 'Nox-Timeout'=>'60', 'Nox-Url'=>'http://allow.com/foo.html', 'User-Agent'=>'Ruby'}).
            to_return(:status => 200, :body => "", :headers => {})

        http = Net::HTTP.new("allow.com")
        http.post "/foo.html", "foo=bar&x=y"

        assert_requested(:post, "http://nox-server.com:1234/request")
      end

      after :each do
        remove_nox
      end

    end

    describe "with nox disabled" do

      before :each do
        remove_nox
      end

      it "should route traffic through nox" do
        stub_http_request(:get, "http://allow.com/")
        @http.get '/'

        assert_requested(:get, "http://allow.com/")
      end

      it "should route traffic through nox even if it has a ignore rule" do
        stub_http_request(:any, "http://allow.com/logo.gif")
        @http.get '/logo.gif'

        assert_requested(:get, "http://allow.com/logo.gif")
      end

    end

  end

  private

    def nox_txt
      "#{Rails.root}/tmp/nox.txt"
    end

    def touch_nox
      FileUtils.mkdir_p "#{Rails.root}/tmp"
      `touch #{nox_txt}`
    end

    def remove_nox
      `rm #{nox_txt}` if File.exist?(nox_txt)
    end

end
