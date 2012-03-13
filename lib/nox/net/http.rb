require 'net/https'
require 'yaml'
require 'erb'

module Net
  class HTTP

    alias :old_request :request

    def request(req, body = nil, &block)

      uri = URI.parse((use_ssl? ? 'https://' : 'http://') +  @address.to_s + ':' + @port.to_s + req.path)
      config = nox_config[Rails.env.to_s]

      if (should_use_nox? && !should_ignore_request?(uri, config['ignore'])) && !Thread.current[:nox_in_progress]

        Thread.current[:nox_in_progress] = true

        http = Net::HTTP.new(config['host'], config['port'])

        headers = {
          'Nox-URL' => uri.to_s,
          'Nox-Timeout' => http.read_timeout.to_s,
          'Nox-Method' => req.method
        }

        req.each_header do |key, value|
          unless %(accept user-agent).include?(key)
            headers[key] = value
          end
        end

        # Make sure it doesn't fail
        exception = nil
        begin
          # For backwards compat. body is deprecated I believe (at least in 1.9.3 it returns nothings)
          actual_body = req.respond_to?(:body) ? req.body : body

          resp = http.request_post('/request', actual_body, headers)
        rescue Exception => e
          exception = e
        end

        # Turn off nox again
        Thread.current[:nox_in_progress] = nil

        # Raise the error we occured above (if we got one)
        raise exception if exception

        yield(resp) if block_given?

        return resp

      else

        return old_request(req, body, &block)

      end

    end

    def nox_config
      @@config ||= YAML::load(ERB.new(IO.read(File.join(Rails.root, 'config', 'nox.yml'))).result)
    end

    def should_ignore_request?(uri, rules)
      return false if rules.nil? || rules.empty?

      rules.each do |rule|
        matches = true

        rule.each do |key, test|
          value = uri.send(key)

          if test.kind_of?(Regexp)
            matches = false unless value =~ test
          else
            matches = false unless value.to_s == test.to_s
          end
        end

        return true if matches
      end

      false
    end

    def should_use_nox?
      File.exist? File.join(Rails.root, "tmp/nox.txt")
    end

  end
end
