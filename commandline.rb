#!/ruby-1.9.2
# Comand-line Progress Indicator
# http://www.dzone.com/snippets/command-line-progress
#


# move cursor to beginning of line
cr = "\r"           


# ANSI escape code to clear line from cursor to end of line
# "\e" is an alternative to "\033"
# cf. http://en.wikipedia.org/wiki/ANSI_escape_code

clear = "\e[0K"     

# reset lines
reset = cr + clear



#-------------------------------- Example 1 --------------------------------


(1..100).each do |i| 
  print "#{reset}#{i}%"
  sleep(0.08)
  $stdout.flush
end

print "#{reset}"     # clear current line

$stdout.flush
puts "done"



#-------------------------------- Example 2 --------------------------------


chars = [ "|", "/", "-", "\\" ]

# 7 turns on reverse video mode, 31 red , ...
n = 31

str = "#{reset}\e[#{n};1m"   


(1..100).each do |i| 

   case i
      when   0..10    then print "#{str}#{chars[0]}"
      when  10..20    then print "#{str}#{chars[1]}"
      when  20..30    then print "#{str}#{chars[2]}"
      when  30..40    then print "#{str}#{chars[3]}"
      when  40..50    then print "#{str}#{chars[0]}"
      when  50..60    then print "#{str}#{chars[1]}"
      when  60..70    then print "#{str}#{chars[2]}"
      when  70..80    then print "#{str}#{chars[3]}"
      when  80..90    then print "#{str}#{chars[0]}"
      when  90..100   then print "#{str}#{chars[1]}"
   end

   sleep(0.1)
   $stdout.flush

end

print "\e[0m"
print "#{reset}" 

$stdout.flush
puts "done"



#-------------------------------- Example 3 --------------------------------


MAX = 80 

$stdout.sync = true     # alternative to $stdout.flush below

10.times do
   foo_string = Time.now.to_s
   s = foo_string[0..MAX].center(MAX)   # or rjust or ljust 
   print cr + s 
   #$stdout.flush 
   sleep(1.1)
end

print "\e[0m" 
print "#{reset}" 

$stdout.flush
puts "done"




