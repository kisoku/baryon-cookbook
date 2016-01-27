default['baryon']['version'] = '0.1.0'
default['baryon']['download_url'] = "https://github.com/pantheon-systems/baryon/releases/download/v%{version}/Linux"
default['baryon']['listen_port'] = 8080
default['baryon']['listen_address'] = '127.0.0.1'
default['baryon']['github_api_token'] = nil
default['baryon']['github_org'] = nil
default['baryon']['github_webhook_secret'] = nil
default['baryon']['use_ssl'] = false
# you probably don't want this lower than the rate github resets the api rate limit
default['baryon']['interval'] = '24h'
