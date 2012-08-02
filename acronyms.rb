#!/usr/bin/ruby

require 'ap'

$acronym_file = "../acronym_samples.txt"
$acronym_lines = File.open($acronym_file,'r').readlines

class Acronym
  attr_accessor :alist, :slist, :def, :ex, :rel
  def initialize
  end
  def parse_acrolist(line)
    a,b = line.split(/\t/)
    @alist = a.split(",").map {|a| a.strip}
    @blist = b.split(",").map {|b| b.strip}
  end
  def parse_relation(line)
    matched = line.match(/(.*)\[(.*)\](.*)/)
    @rel = Relation.new(matched[1],matched[2],matched[3])
  end
  def parse_def(line)
    @def = line.delete("\"")
  end
  def parse_ex(line)
    @ex = line.delete("\"")
  end
end

class Relation
  attr_accessor :left, :rel, :right
  def initialize(left,rel,right)
    @left,@rel,@right = left.strip,rel.strip,right.strip
  end
end


def has_relation?(line)
  !line.match(/\[.*\]/).nil?
end

def process_all
  state = :start
  new_ac = nil
  all_acronyms = Array.new
  $acronym_lines.each do |line|
    line.strip!
    next if line.empty?
    case state
    when :start, :rel
      if has_relation? line
        new_ac.parse_relation(line)
        state = :start
      else
        new_ac = Acronym.new
        all_acronyms.push(new_ac)
        new_ac.parse_acrolist(line)
        state = :def
      end
    when :def
      new_ac.parse_def(line)
      state = :ex
    when :ex
      new_ac.parse_ex(line)
      state = :rel
    else
      puts "something strange happened to state"
    end
  end
  all_acronyms
end



# main
if __FILE__ == $0


end

