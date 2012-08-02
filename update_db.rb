#!/usr/bin/ruby

# File meant to update the working_wordnet.db

require 'sqlite3'

$db = SQLite3::Database.new("../wordnet_3.1+.db")

def get_senseid(sid, wid)
  $db.query("SELECT senseid FROM senses WHERE synsetid==? AND wordid==? LIMIT 1", sid, wid).to_a.flatten.first
end

$add_link = $db.prepare("INSERT INTO lexlinks_new VALUES(?,?,?)")

def new_lexlinks_table
  sid1_i = 0
  wid1_i = 1
  sid2_i = 2
  wid2_i = 3
  link_i = 4
  $db.query("SELECT * FROM lexlinks").each do |lexlink|
    sense1 = get_senseid(lexlink[sid1_i],lexlink[wid1_i])
    sense2 = get_senseid(lexlink[sid2_i],lexlink[wid2_i])
    $add_link.execute(sense1,sense2,lexlink[link_i])
  end

end

def add_phrase_tables
  $db.query("
  CREATE TABLE IF NOT EXISTS phrasetypes ( 
    synsetid INTEGER,
    type     VARCHAR 
  )
  ")
  $db.query("
  CREATE TABLE IF NOT EXISTS taggedtexts ( 
    wordid      INTEGER,
    casedwordid INTEGER,
    sensetagid  INTEGER,
    position    INTEGER,
    senseid     INTEGER 
  )
  ")
  $db.query("
  CREATE TABLE IF NOT EXISTS sensetags ( 
    sensetagid INTEGER,
    sensekey   VARCHAR 
  )
  ")


end

