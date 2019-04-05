#
# Copyright 2019 (c) Andrey Galkin
#

Puppet::Type.newtype(:cfbackup_path) do
    desc "DO NOT USE DIRECTLY."
    
    autorequire(:cfsystem_flush_config) do
        ['begin']
    end
    autonotify(:cfsystem_flush_config) do
        ['commit']
    end
    
    ensurable do
        defaultvalues
        defaultto :absent
    end
    
    
    newparam(:name) do
        isnamevar

        validate do |value|
            unless value =~ /^(\/[a-z0-9_]+)+$/i
                raise ArgumentError, "%s is not a valid path" % value
            end
        end
    end
     
    newproperty(:namespace) do
        validate do |value|
            unless value =~ /^[a-zA-Z_][a-zA-Z0-9_-]*$/
                raise ArgumentError, "%s is not valid namespace" % value
            end
        end
    end

    newproperty(:id) do
        validate do |value|
            unless value =~ /^[a-zA-Z_][a-zA-Z0-9_-]*$/
                raise ArgumentError, "%s is not valid ID" % value
            end
        end
    end

    newproperty(:type) do
    end

    newproperty(:compress) do
    end

    newproperty(:prepare) do
    end
end

