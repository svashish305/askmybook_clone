require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.on("--pdf FILENAME", "Name of PDF") do |pdf|
    options[:pdf] = pdf
  end
end.parse!
filename = options[:pdf]

reader = PDF::Reader.new(filename)