#!/usr/bin/ruby
# -*- coding: utf-8 -*-

require 'pp'
$semtxt = '../semroles.txt'
$output_file = File.open('../processed_semroles.txt','w+')

$all_roles = %w{action theme product location agent instrument result cause patient beneficiary creator goal experiencer}

def match_sensekey(string)
  string.match(/[^\s%]*%[0-9]:[0-9][0-9]:[0-9][0-9]::/)
end

def match_primary(string)
  st = string.match(/n \[([^\]]*)\]/)
  st.nil? ? nil : st[1]
end

def match_role(string)
  $all_roles.each do |role|
    if (string.match(/#{role}:/))
      return role
    end
  end
  return nil
end


def print_all_sems(sems)
  sems.each {|sem| sem.print_sem($output_file)}
end

def process_file(lines)
  all_sems = Array.new
  current_prim = nil
  current_sem = nil
  current_role = nil
  lines.each do |line|
    prim = match_primary(line)
    next if (!current_sem.nil? && current_sem.primary==prim) # remove error where having the same artifact listed twice in a row caused an unfortunate key1->key1 match
    current_prim = prim if !prim.nil? 
    next if current_prim.nil?
    if (current_sem.nil? || current_sem.primary!=current_prim)
      current_sem = Semroles.new(current_prim)
      all_sems.push(current_sem)
      current_role = nil
      next
    end
    role = match_role(line)
    current_role = role if (!role.nil? && role!=current_role)
    key2 = match_sensekey(line)
    next if key2.nil?
    current_sem.roles[current_role] = Array.new if current_sem.roles[current_role].nil?
    current_sem.roles[current_role].push(key2)
  end
  return all_sems
end

class Semroles
  attr_accessor :primary, :roles
  def initialize(noun)
    @primary = noun
    @roles = Hash.new
  end
  def print_sem(fo)
    @roles.each_pair do |role, key_list|
      key_list.each do |sensekey2|
    	fo.puts "#{@primary}\t#{sensekey2}\t#{role}"
      end
    end
  end
end

#main
if __FILE__ == $0
  lines = File.open($semtxt,'r').readlines
  all_sems = process_file(lines)
  print_all_sems(all_sems)

end
