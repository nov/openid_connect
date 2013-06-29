Dir[File.dirname(__FILE__) + '/userinfo/*.rb'].each do |file|
  require file
end