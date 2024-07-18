
Pod::Spec.new do |s|
    s.name          = 'OpenSSL'
    s.version       = '3.2.0-fuse0'
    s.summary       = 'Fuse Module for incorporating native-views into a Fuse application'
    s.homepage      = 'https://fuse.breautek.com'
    s.author        = { 'OpenSSL' => 'norman@breautek.com' }
    s.license       = {
        :type => 'Apache-2.0',
        :file => 'OpenSSL.xcframework/LICENSE'
    }

    s.ios.deployment_target = '15.0'
    
    s.source        = {
        :http => 'https://github.com/btfuse/openssl/releases/download/3.2.0-fuse0/OpenSSL.xcframework.zip',
        :sha1 => '99a1205ce2bb0e06e53e3b511afad0444e54e2bd'
    }

    s.vendored_frameworks = 'OpenSSL.xcframework'
end
