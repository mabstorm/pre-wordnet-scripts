#!/usr/bin/ruby
# -*- coding: utf-8 -*-

require 'sqlite3'
$semroles = File.open('../processed_semroles.txt','r').readlines
$db = SQLite3::Database.new("../working_wordnet.db")
$all_roles = %w{action theme product location agent instrument result cause patient beneficiary creator goal experiencer}
$ROLL_INDEX_OFFSET = 100

def key_to_synset(sensekey)
  sensekey.strip!
  r1 = $db.execute("SELECT synsetid FROM senses WHERE sensekey == ?", sensekey)
  if (r1.nil? || r1[0].nil?)
    puts "#{sensekey} empty #{r1} something..."
    return nil
  end
  r1[0][0]
end

def update_linktypes
  $db.transaction
  $all_roles.each_index do |i|
    role_i = i + $ROLL_INDEX_OFFSET
    next if ($db.execute("SELECT linkid FROM linktypes WHERE linkid == ?", role_i).length > 0) #check to see if it exists
    role = $all_roles[i]
    $db.execute("INSERT INTO linktypes VALUES ( ?, ?, 0 )", role_i, role)
  end
  $db.commit
end

def process_links
  # put everything in one transaction
  counter = 0
  $db.transaction
  $semroles.each do |fullline|
    line = fullline.strip.split("\t")
    (puts "skipped #{fullline}"; next) if line.length < 3
    p1 = line[0]
    p2 = line[1]
    role = line[2]
    s1 = key_to_synset(p1)
    s2 = key_to_synset(p2)
    next if (s1.nil? || s2.nil?)
    role_index = $all_roles.index(role) + $ROLL_INDEX_OFFSET
    # prevent duplicates
    (puts "semlink already exists: #{fullline}"; next) if ($db.execute("SELECT * FROM semlinks WHERE synset1id == ? AND synset2id == ? AND linkid == ?", s1, s2, role_index).length > 0)
    counter+=1
    $db.execute("INSERT INTO semlinks VALUES ( ?, ?, ? )", s1, s2, role_index)
  end
  $db.commit
end

if __FILE__ == $0
  update_linktypes
  process_links

end

