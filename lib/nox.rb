require "nox/version"
require "nox/http"

Net::HTTP.send(:include, Nox::HTTP)
