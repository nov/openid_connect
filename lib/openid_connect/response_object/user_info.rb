Dir[File.dirname(__FILE__) + '/user_info/*.rb'].each do |file| 
  require file
end