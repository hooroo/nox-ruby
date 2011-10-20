require 'net/https'
require 'yaml'

module Net
  class HTTP

    alias :old_request :request

    def request(req, body = nil, &block)

      if should_use_nox? && !Thread.current[:nox_in_progress]

        @@config ||= YAML.load_file(Rails.root.join("config/nox.yml"))
        config = @@config[Rails.env.to_s]

        Thread.current[:nox_in_progress] = true

        http = Net::HTTP.new(config['host'], config['port'])
        method = req.class.name.split('::').last.downcase
        headers = {
          'Nox-URL' => (use_ssl? ? 'https://' : 'http://') +  @address.to_s + ':' + @port.to_s + req.path,
          'Nox-Timeout' => http.read_timeout.to_s
        }

        req.each_header do |key, value|
          unless %(accept user-agent).include?(key)
            headers[key] = value
          end
        end

        # Make sure it doesn't fail
        exception = nil
        begin
          # TODO: Handle diff between post/get/put/delete, etc...
          resp = http.post('/request', body, headers)
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

    def should_use_nox?
      File.exist?(Rails.root.join("tmp/nox.txt"))
    end

  end
end
