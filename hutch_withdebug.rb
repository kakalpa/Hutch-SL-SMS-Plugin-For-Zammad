

class Channel::Driver::Sms::Hutch
  NAME = 'sms/hutch'.freeze

  def initialize
    @access_token = nil
    @refresh_token = nil
    @oauth_provider_url = Setting.get('options::gateway') || 'https://bsms.hutch.lk'
  end

  def self.definition
    {
      name: 'Hutch SMS',
      adapter: 'sms/hutch',
      notification: [
        { name: 'options::gateway', display: __('Gateway'), tag: 'input', type: 'text', limit: 200, null: false, placeholder: 'https://bsms.hutch.lk', default: 'https://bsms.hutch.lk/api/sendsms' },
        { name: 'options::token', display: __('Token'), tag: 'input', type: 'text', limit: 200, null: false, placeholder: 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' },
        { name: 'options::username', display: __('Username'), tag: 'input', type: 'text', limit: 200, null: false, placeholder: 'username' },
        { name: 'options::password', display: __('Password'), tag: 'input', type: 'password', limit: 200, null: false, placeholder: 'password' },
        { name: 'options::sender', display: __('Sender'), tag: 'input', type: 'text', limit: 200, null: false, placeholder: '00491710000000' },
        { name: 'options::champain', display: __('Champain'), tag: 'input', type: 'text', limit: 200, null: false, placeholder: 'campaign name' },
        { name: 'options::mask', display: __('Mask'), tag: 'input', type: 'text', limit: 200, null: false, placeholder: 'mask' },
      ]
    }
  end

  def send(options, attr, _notification = false)
    Rails.logger.info "Sending SMS to recipient #{attr[:recipient]}"

    return true if Setting.get('import_mode')

    Rails.logger.info "Backend sending Hutch SMS to #{attr[:recipient]}"

    obtain_access_token(options) if @access_token.nil? || access_token_expired?

    begin
      send_create(options, attr)
      true
    rescue Faraday::UnauthorizedError
      Rails.logger.info "Token expired. Renewing access token..."
      renew_access_token(options)
      retry
    rescue => e
      Rails.logger.error "Error sending SMS: #{e.message}"
      false
    end
  end

  private

  def obtain_access_token(options)
    Rails.logger.info "Obtaining access token from #{@oauth_provider_url}/api/login"

    response = Faraday.post("#{@oauth_provider_url}/api/login") do |req|
      req.headers['Content-Type'] = 'application/json'
      req.headers['Accept'] = '*/*'
      req.headers['X-API-VERSION'] = 'v1'
      req.body = { username: options[:username], password: options[:password] }.to_json
    end

    if response.success?
      body = JSON.parse(response.body)
      @access_token = body['accessToken']
      @refresh_token = body['refreshToken']
      Rails.logger.info "Access token obtained successfully"
    else
      raise "Error obtaining access token: #{response.status} #{response.body}"
    end
  end

  def renew_access_token(options)
    response = Faraday.get("#{@oauth_provider_url}/api/token/accessToken") do |req|
      req.headers['Content-Type'] = 'application/json'
      req.headers['Accept'] = '*/*'
      req.headers['X-API-VERSION'] = 'v1'
      req.headers['Authorization'] = "Bearer #{@refresh_token}"
    end

    if response.success?
      body = JSON.parse(response.body)
      @access_token = body['accessToken']
      Rails.logger.info "Access token renewed successfully"
    else
      raise Faraday::UnauthorizedError.new("Error renewing access token: #{response.status} #{response.body}")
    end
  end

  def access_token_expired?
    return true if @access_token.nil?

    decoded_token = JWT.decode(@access_token, nil, false).first
    expiration_time = decoded_token['exp']

    current_time = Time.now.to_i
    expiration_time <= current_time
  end

  def send_create(options, attr)
    url = "#{@oauth_provider_url}/api/sendsms"
    return if Setting.get('developer_mode')

    payload = {
      campaignName: options[:champain],
      mask: options[:mask],
      numbers: attr[:recipient],
      content: attr[:message]
    }

    response = Faraday.post(url) do |req|
      req.headers['Content-Type'] = 'application/json'
      req.headers['Accept'] = '*/*'
      req.headers['X-API-VERSION'] = 'v1'
      req.headers['Authorization'] = "Bearer #{@access_token}"
      req.body = payload.to_json
    end

    if response.success?
      Rails.logger.info "SMS sent successfully"
    else
      message = "Received non-OK response from gateway URL '#{url}'"
      Rails.logger.error "#{message}: #{response.body.inspect}"
      raise message
    end
  end

end
