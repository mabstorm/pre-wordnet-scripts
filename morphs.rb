#!/usr/bin/ruby


require 'sqlite3'

$db = SQLite3::Database.new("../working_wordnet.db")

def get_wordid(word)
  $db.execute("SELECT wordid FROM words WHERE lemma==?",word)
end

def get_morphids(wordid)
  $db.execute("SELECT morphid FROM morphmaps WHERE wordid==?",wordid)
end

def morphs(morphid)
  $db.execute("SELECT morph FROM morphs WHERE morphid==?", morphid)
end

def inflect(word)
  wordid = get_wordid(word)
  morphids = get_morphids(wordid)
  inflected = Array.new
  morphids.each do |morphid|
    inflected.push(morphs(morphid))
  end
  return inflected.flatten.compact
end

def print_morphs(all_morphs)
  all_morphs.each {|morph| puts morph}
end

if __FILE__ == $0
  print_morphs(inflect(ARGV[1]))
  
end



