#
# Copyright 2018-2019 (c) Andrey Galkin
#


begin
    require File.expand_path( '../../../../puppet_x/cf_system', __FILE__ )
rescue LoadError
    require File.expand_path( '../../../../../../cfsystem/lib/puppet_x/cf_system', __FILE__ )
end

Puppet::Type.type(:cfbackup_path).provide(
    :cfprov,
    :parent => PuppetX::CfSystem::ProviderBase
) do
    desc "Provider for cfbackup_path"
    
    commands :systemctl => PuppetX::CfSystem::SYSTEMD_CTL
        
    def self.get_config_index
        'cfbackup_path'
    end

    def self.get_generator_version
        cf_system().makeVersion(__FILE__)
    end
    
    def self.check_exists(params)
        true
    end

    def self.on_config_change(newconf)
        true
    end
end

