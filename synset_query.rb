#!/usr/bin/ruby

# File meant to update the working_wordnet.db
module WNQ

require 'sqlite3'

$db = SQLite3::Database.new("../working_wordnet.db")


def WNQ.get_synsetids(word)
  $db.query("
               SELECT synsets.synsetid
                 FROM synsets, 
                      senses, 
                      words
                WHERE synsets.synsetid == senses.synsetid 
                      AND
                      senses.wordid == words.wordid 
                      AND
                      words.lemma LIKE ?
            ", word).to_a.flatten
end

def WNQ.get_members(synsetid)
  members_and_keys = Hash.new
  $db.query("
    SELECT words.lemma, senses.sensekey
      FROM synsets, 
           senses, 
           words
     WHERE synsets.synsetid==?
           AND
           synsets.synsetid == senses.synsetid 
           AND
           senses.wordid == words.wordid
           ", synsetid).to_a.each.each {|member, key| members_and_keys[member] = key}
end

def WNQ.get_definition(synsetid)
  $db.query("
    SELECT synsets.definition
    FROM   synsets
    WHERE  synsetid==?
    ", synsetid).to_a.flatten.first
end




end

class SynsetInfo
  attr_reader :synsets, :word
  def initialize(word)
    @word = word
    @synsets = Array.new
    WNQ.get_synsetids(word).each {|synsetid| @synsets.push(Synset.new(synsetid))}
  end
end

class Synset
  attr_reader :synsetid, :members_and_keys, :definition
  def initialize(synsetid)
    @synsetid = synsetid
    @members_and_keys = WNQ.get_members(synsetid)
    @definition = WNQ.get_definition(synsetid)
  end
end
