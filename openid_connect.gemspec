Gem::Specification.new do |s|
  s.name        = "openid_connect"
  s.version     = File.read("VERSION")
  s.authors     = ["nov matake"]
  s.email       = ["nov@matake.jp"]
  s.homepage    = "https://github.com/nov/openid_connect"
  s.summary     = %q{OpenID Connect Server & Client Library}
  s.description = %q{OpenID Connect Server & Client Library}
  s.license     = 'MIT'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.add_runtime_dependency "tzinfo"
  s.add_runtime_dependency "attr_required", ">= 1.0.0"
  s.add_runtime_dependency "activemodel"
  s.add_runtime_dependency "validate_url"
  s.add_runtime_dependency "email_validator"
  s.add_runtime_dependency "mail"
  s.add_runtime_dependency 'faraday', '~> 2.0'
  s.add_runtime_dependency 'faraday-follow_redirects'
  s.add_runtime_dependency "json-jwt", ">= 1.16"
  s.add_runtime_dependency "swd", "~> 2.0"
  s.add_runtime_dependency "webfinger", "~> 2.0"
  s.add_runtime_dependency "rack-oauth2", "~> 2.2"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rspec-its"
  s.add_development_dependency "webmock"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "rexml"
end
