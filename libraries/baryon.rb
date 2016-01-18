#
# Cookbook Name:: baryon
#
# Copyright 2016 Mathieu Sauve-Frankel
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'poise_service/service_mixin'

module Baryon
  class Resource < Chef::Resource
    include Poise
    include PoiseService::ServiceMixin
    provides(:baryon)

    property(:path, kind_of: String, default: '/opt/baryon')
    property(:user, kind_of: String, default: 'baryon')
    property(:group, kind_of: String, default: 'baryon')
    property(:version, kind_of: String, default: lazy { node['baryon']['version'] })
    property(:download_url, kind_of: String, default: lazy { node['baryon']['download_url'] % { version: version }})
    property(:listen_port, kind_of: Fixnum, default: lazy { node['baryon']['listen_port'] })
    property(:github_api_token, kind_of: String, default: lazy { node['baryon']['github_api_token'] })
    property(:github_org, kind_of: String, default: lazy { node['baryon']['github_org'] })
    property(:github_webhook_secret, kind_of: String, default: lazy { node['baryon']['github_webhook_secret'] })
    property(:listen_address, kind_of: String, default: lazy { node['baryon']['listen_address'] })
    property(:use_ssl, kind_of: [ TrueClass, FalseClass], default: false)
    property(:ssl_cert, kind_of: String, template: true)
    property(:ssl_cert_path, kind_of: String, default: lazy { ::File.join(ssl_cert_dir, 'baryon.pem') })
    property(:ssl_key, kind_of: String, template: true)
    property(:ssl_key_path, kind_of: String, default: lazy { ::File.join(ssl_key_dir, 'baryon.pem') })
    property(:interval, kind_of: String, default: lazy { node['baryon']['interval'] })
    property(:no_sync, kind_of: [ TrueClass, FalseClass ], default: false)
    property(:berks_only, kind_of: [ TrueClass, FalseClass ], default: false)

    def bin_dir
      ::File.join(path, 'bin')
    end

    def ssl_dir
      ::File.join(path, 'ssl')
    end

    def ssl_cert_dir
      ::File.join(ssl_dir, 'certs')
    end

    def ssl_key_dir
      ::File.join(ssl_dir, 'private')
    end

    def command
      cmd = [ "#{bin_dir}/baryon" ]
      cmd << "-o #{github_org}"
      cmd << "-t #{github_api_token}" if github_api_token
      cmd << "-s #{github_webhook_secret}" if github_webhook_secret
      cmd << "-p #{listen_port}" if listen_port
      cmd << "-b #{listen_address}" if listen_address
      cmd << "-k #{ssl_key_path}" if use_ssl
      cmd << "-c #{ssl_cert_path}" if use_ssl
      cmd << "-i #{interval}" if interval
      cmd << "--no-sync" if no_sync
      cmd << "--berks-only" if berks_only
      cmd.join(' ')
    end
  end

  class Provider < Chef::Provider
    include Poise
    include PoiseService::ServiceMixin
    provides(:baryon)

    def action_enable
      notifying_block do
        install_baryon
      end
      super
    end

    def action_disable
      notifying_block do
      end
      super
    end

    def service_options(resource)
      resource.command(new_resource.command)
      resource.user(new_resource.user)
    end

    private

    def install_baryon
      poise_service_user new_resource.user

      directory new_resource.bin_dir do
        owner 'root'
        group 'root'
        mode 0755
        recursive true
      end

      remote_file "#{new_resource.bin_dir}/baryon" do
        owner 'root'
        group 'root'
        mode 0755
        source new_resource.download_url
      end

      if new_resource.use_ssl
        install_ssl
      end
    end

    def install_ssl
      directory new_resource.ssl_cert_dir do
        owner 'root'
        group 'root'
        mode 0755
        recursive true
      end

      file new_resource.ssl_cert_path do
        owner 'root'
        group 'root'
        mode '0644'
        content new_resource.ssl_cert_content
        sensitive true
      end

      directory new_resource.ssl_private_dir do
        owner 'root'
        group new_resource.group
        mode 0750
      end

      file new_resource.ssl_key_path do
        owner 'root'
        group new_resource.group
        mode '0640'
      end
    end
  end
end
