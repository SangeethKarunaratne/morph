# frozen_string_literal: true

module Discourse
  class SingleSignOn
    ACCESSORS = %i[nonce name username email about_me external_email external_username external_name external_id].freeze
    FIXNUMS = [].freeze
    NONCE_EXPIRY_TIME = 10.minutes

    attr_accessor(*ACCESSORS)
    attr_writer :sso_secret, :sso_url

    def self.sso_secret
      raise "sso_secret not implemented on class, be sure to set it on instance"
    end

    def self.sso_url
      raise "sso_url not implemented on class, be sure to set it on instance"
    end

    def sso_secret
      @sso_secret || self.class.sso_secret
    end

    def sso_url
      @sso_url || self.class.sso_url
    end

    def self.parse(payload, sso_secret = nil)
      sso = new
      sso.sso_secret = sso_secret if sso_secret

      parsed = Rack::Utils.parse_query(payload)

      raise "Bad signature for payload" if sso.sign(parsed["sso"]) != parsed["sig"]

      decoded = Base64.decode64(parsed["sso"])
      decoded_hash = Rack::Utils.parse_query(decoded)

      ACCESSORS.each do |k|
        val = decoded_hash[k.to_s]
        val = val.to_i if FIXNUMS.include? k
        sso.send("#{k}=", val)
      end
      sso
    end

    def sign(payload)
      OpenSSL::HMAC.hexdigest("sha256", sso_secret, payload)
    end

    def to_url(base_url = nil)
      base = base_url.to_s || sso_url.to_s
      "#{base}#{base.include?('?') ? '&' : '?'}#{payload}"
    end

    def payload
      payload = Base64.encode64(unsigned_payload)
      "sso=#{CGI.escape(payload)}&sig=#{sign(payload)}"
    end

    def unsigned_payload
      payload = {}
      ACCESSORS.each do |k|
        next unless (val = send k)

        payload[k] = val
      end

      Rack::Utils.build_query(payload)
    end
  end
end
