#!/ruby-1.9.2
# Conway's Game of Life in one line by Iain Hecker
# Found at: http://iain.nl/conways-game-of-life-or-writing-perl-in-ruby

String.class_eval{define_method(:to_grid){(self =~ /\A(\d+)x(\d+)\z/ ?
(0...split('x').last.to_i).map{|_| (0...split('x').first.to_i).map{|_| rand > 0.5 } } :
split("\n").map{|row| row.split(//).map{|cell_string| cell_string == "o" } }
).tap{|grid| grid.class.class_eval{define_method(:next){each{|row|
row.each{|cell| cell.class.class_eval{define_method(:next?){|neighbours|
(self && (2..3).include?(neighbours.select{|me| me }.size)) ||
(!self && neighbours.select{|me| me }.size == 3)}}}} &&
enum_for(:each_with_index).map{|row, row_num| row.enum_for(:each_with_index).map{|cell, col_num|
cell.next?([ at(row_num - 1).at(col_num - 1), at(row_num - 1).at(col_num),
at(row_num - 1).at((col_num + 1) % row.size), row.at((col_num + 1) % row.size),
row.at(col_num - 1), at((row_num + 1) % size).at(col_num - 1),
at((row_num + 1) % size).at(col_num), at((row_num + 1) % size).at((col_num + 1) % row.size) ])
} }} && define_method(:to_s){map{|row| row.map{|cell| cell ? "o" : "." }.join }.join("\n")}}}}}


# main
# defaults to 40x20, but takes a NUMxNUM argument for user-defined size
# defaults to 10 simulations, takes an argument after size for user-defined num runs
if __FILE__ ==$0
  grid = ARGV[0].nil? ? "40x20".to_grid : ARGV[0].to_s.to_grid
  to_run = ARGV[1].nil? ? 10 : ARGV[1].to_i
  to_run.times do |i|
    system('clear')
    puts grid.to_s
    grid = grid.next
    sleep 1
  end
end

