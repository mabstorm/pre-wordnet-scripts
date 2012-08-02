#!/usr/bin/ruby

require 'ap'
require './wn_queries_helper.rb'

$metaphor_file = "../metaphors.txt"
$metaphor_lines = File.open($metaphor_file,'r').readlines
$regex = {'metaphors' => Regexp.new(/\$\$\$(.*)/),
          'sensekeys' => Regexp.new(/%%([^%]*%[\S]*)/)}

#---------------------------------------------#
#-------Processing the metaphors file---------#
#---------------------------------------------#
def sensekeys2
  show_matches { |array, line| array.push(line.scan(/#{$regex['sensekey']}/)) }
end

def metaphors2
  show_matches { |array, line| array.push(line.scan(/#{$regex['metaphor']}/)) }
end

=begin # method_missing approach, produces same result as metaclass approach
def method_missing(method_id)
  show_what = method_id.to_s.match(/show_(.*)/)
  if !show_what.nil?
    type = show_what[1].gsub(/s$/,'')
    return show_matches {|array, line| array.push(line.scan($regex[type]))} if $regex.has_key?(type)
  end
  super
end
=end

# defining show_metaphors, show_sensekeys, etc. at runtime
metaclass = class << self; self; end
$regex.each_pair do |name,key|
  metaclass.send(:define_method, "show_#{name}") { show_matches { |array, line| array.push(line.scan(key)) } }
end

def show_matches
  matches = Array.new
  $metaphor_lines.each {|line| yield matches, line}
  matches = matches.flatten.compact
end

#-------------------------------------------------------#
#---------Dealing with metaphors in the database--------#
#-------------------------------------------------------#
def has_word? word
  $db.query("SELECT wordid FROM words WHERE lemma==?", word).to_a.length > 0
end
def has_definition? definition
  $db.query("SELECT synsetid FROM synsets WHERE definition==?", definition).to_a.length > 0
end
def has_phrasetype? synsetid
  $db.query("SELECT phrasetype FROM phrasetypes WHERE synsetid==?", synsetid).to_a.length > 0
end
def get_sensenum wordid, synsetid
  $db.query("SELECT max(sensenum) FROM senses WHERE wordid==? AND synsetid==?", wordid, synsetid).to_a.first.first + 1 rescue 1
end
def has_new_sensekey? sensekey
  $db.query("SELECT new_sensekey FROM senses WHERE new_sensekey==?", sensekey).to_a.length > 0
end
def has_old_sensekey? sensekey
  $db.query("SELECT sensekey FROM senses WHERE sensekey==?", sensekey).to_a.length > 0
end
def new_sensekey_from_old sensekey
  $db.query("SELECT new_sensekey from senses WHERE sensekey==?", sensekey).to_a.first.first
end
def get_new_old_synsetid
  $db.query("SELECT MAX(synsetid) FROM synsets").to_a.first.first + 1
end

class Metaphor
  attr_accessor :text, :synsetid, :wordid, :casedwordid, :senseid, :members, :type, :definition, :sensenum, :lexid, :sensekey, :new_sensekey, :new_synsetid
  def initialize(text)
    @members = Array.new
    @text = text
    @lexid = 0
  end
  def add_member word, position, list_of_keys
    mm = MetaphorMember.new(word, position, @senseid)
    list_of_keys.each {|key| mm.add_key(key) }
    @members.push(mm)
  end
  def commit_self
    return false if @definition.nil?
    $db.commit if $db.transaction_active?
    $db.transaction

    # add word
    $db.execute("INSERT INTO words VALUES(NULL, ?)", @text.downcase)           unless has_word?(@text.downcase)
    @wordid = $db.execute("SELECT wordid FROM words WHERE lemma==?", @text.downcase)

    # add synset
    @synsetid = get_new_old_synsetid
    $db.execute("INSERT INTO synsets VALUES(NULL, ?, 'p', 0, ?)", @synsetid, @definition) unless has_definition?(@definition)
    @synsetid = $db.execute("SELECT synsetid FROM synsets WHERE definition==?", @definition).to_a.first.first
    @new_synsetid = $db.execute("SELECT id FROM synsets WHERE definition==?", @definition).to_a.first.first

    # add phrasetype
    $db.execute("INSERT INTO phrasetypes VALUES(?, 'idiom')", @synsetid)       unless has_phrasetype?(@synsetid)
    @sensenum = get_sensenum(@wordid, @synsetid)
    clean_text = @text.downcase.gsub(/[\s]+/, "_")
    @sensekey = "#{clean_text}%6:00:00::"
    @new_sensekey = "#{clean_text}##{sensenum}:p"

    # add sense
    $db.execute("INSERT INTO senses VALUES(?,NULL,?,NULL,?,?,NULL,?,?)", @wordid, @synsetid, @sensenum, @lexid, @sensekey, @new_sensekey) unless (has_new_sensekey?(@new_sensekey) || has_old_sensekey?(@sensekey))

    @senseid = $db.execute("SELECT senseid FROM senses WHERE sensekey==?", @sensekey).to_a.first.first

    # add sensetags
    @members.each {|member| member.senseid=@senseid; member.commit_self}

    $db.commit
  end

end

class MetaphorMember
  attr_accessor :word, :wordid, :casedwordid, :sensetagid, :position, :key_pairs, :senseid
  def initialize(word, position, senseid)
    @word = word
    @position = position
    @wordid = lookup_wordid
    @key_pairs = Array.new
    @senseid = senseid
  end
  def add_key sensekey
    @key_pairs.push([sensekey, new_sensekey_from_old(sensekey)])
  end
  def commit_self
    @sensetagid = self.get_next_sensetagid
    return if @sensetagid.nil? # already is in the database or problem occurred
    @key_pairs.each do |pair|
      # add list of possible sense readings for this particular word in this phrase
      $db.execute("INSERT INTO sensetags VALUES(?,?,?)", @sensetagid, pair[0], pair[1])
    end
    # add the information about this word in this phrase
    $db.execute("INSERT INTO taggedtexts VALUES(?,NULL,?,?,?)", @wordid, @sensetagid, @position, @senseid)
  end
  def lookup_wordid
    @wordid = $db.execute("SELECT wordid FROM words WHERE lemma==?", @word)
  end
  def get_next_sensetagid
    return nil if ($db.query("SELECT wordid FROM taggedtexts WHERE wordid==? AND position==? AND senseid==?", @wordid, @position, @senseid).to_a.length > 0)
    $db.query("SELECT MAX(sensetagid) FROM sensetags").to_a.first.first + 1 rescue 0
  end
end

# prototype for testing
$m = Metaphor.new("Beat a dead horse")
$m.add_member("beat", 0, ["belabor%2:41:00::"])
$m.add_member("dead", 2, ["dead%5:00:00:noncurrent:00"])
$m.add_member("horse", 3, ["argument%1:10:00::"])
$m.definition = "(USA) If someone is trying to convince people to do or feel something without any hope of succeeding, they're beating a dead horse. This is used when someone is trying to raise interest in an issue that no-one supports anymore; beating a dead horse will not make it do any more work."

#main
if __FILE__ == $0
  puts show_sensekeys.length
  puts sensekeys2.length
  puts show_metaphors.length
  puts metaphors2.length

end



