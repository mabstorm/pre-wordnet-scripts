#!/usr/bin/ruby

require 'ap'

$metaphor_file = "../metaphors.txt"
$metaphor_lines = File.open($metaphor_file,'r').readlines
$regex = {'metaphor' => Regexp.new(/\$\$\$(.*)/),
          'sensekey' => Regexp.new(/%%([^%]*%[\S]*)/)}

def sensekeys2
  show_matches { |array, line| array.push(line.scan(/#{$regex['sensekey']}/)) }
end

def metaphors2
  show_matches { |array, line| array.push(line.scan(/#{$regex['metaphor']}/)) }
end

def method_missing(method_id)
  show_what = method_id.to_s.match(/show_(.*)/)
  if !show_what.nil?
    type = show_what[1].gsub(/s$/,'')
    if $regex.has_key?(type)
      return show_matches { |array, line| array.push(line.scan($regex[type])) }
    else
      super
    end
  else
    super
  end
end

def show_matches
  matches = Array.new
  $metaphor_lines.each {|line| yield matches, line}
  matches = matches.flatten.compact
end

class Metaphor
  attr_accessor :synsetid
  def initialize

  end

end

#main
if __FILE__ == $0
  puts show_sensekeys.length
  puts sensekeys2.length
  puts show_metaphors.length
  puts metaphors2.length

end



