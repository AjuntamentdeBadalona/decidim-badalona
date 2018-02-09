source "https://rubygems.org"

ruby '2.5.0'

gem "decidim", "~> 0.9.2"
gem "decidim-assemblies"
gem 'faker'

gem 'uglifier', '>= 1.3.0'

gem "virtus-multiparams"

group :development, :test do
  gem 'byebug', platform: :mri
  gem "decidim-dev"
end

group :development do
  gem 'listen', '~> 3.1.0'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

group :production do
  gem 'passenger'
  gem 'fog-aws'
  gem 'dalli'
  gem 'sendgrid-ruby'
  gem 'newrelic_rpm'
  gem 'lograge'
  gem 'sentry-raven'
  gem 'sidekiq'
end

group :test do
  gem "rspec-rails"
  gem "database_cleaner"
end
