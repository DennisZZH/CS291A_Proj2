def check_digest(digest)
  if digest.size == 64 and digest =~ /^[0-9a-f]+$/
    return true
  else
    return false
  end
end

if $PROGRAM_NAME == __FILE__
    puts check_digest 'e81659f6926gd335422e1d1dec86f3e38fa7c19f9bcgf7a22fc925135e32ca63'
    puts check_digest '1111111111111111111111111111111111111111111111111111111111111111'

    digest = '1111111111111111111111111111111111111111111111111111111111111111'
    path_str = digest.downcase
    path_str.insert(2, '/')
    path_str.insert(5, '/')
    puts path_str
end