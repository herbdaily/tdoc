#!/usr/bin/ruby
require 'rubygems'
require 'test/unit'
require 'shoulda'

$: << 'lib'

LINST='^[#|\s]*'
LINSTM='[#|\s]*'
EXTENSIONS={:tests => '.rdoc',:requires => '.rb'}
DEFAULT_FILE="README#{EXTENSIONS[:tests]}"

def process(file) #called at end of script
  files=Dir.glob(file)
  if files.count > 1
    files.each {|f|  system("#{$PROGRAM_NAME} #{f} #{ARGV}")}
  else
    test_name=File.basename(file).sub(/\..*?$/,'')
    test_case=Class.new(Test::Unit::TestCase)
    Object.const_set(:"Test#{test_name.capitalize}", test_case)
    mk_test_context(files[0], test_case)
  end
end
def mk_test_context(file, test_case=nil)
  test_name=File.basename(file).sub(/\..*?$/,'')
  test_dir=File.dirname(file)
  text=File.read(file)
  opts={
    :requires => Dir.glob("#{test_dir}/#{test_name}#{EXTENSIONS[:requires]}"),
    :contexts => Dir.glob("#{test_dir}/#{test_name}/*#{EXTENSIONS[:tests]}"),
    :test_cases => [],
  }
  [:requires, :test_cases].each do |opt|
    text.scan(/#{LINST}:include:\s*(.+#{EXTENSIONS[opt]})/).each do |files|
      files[0].split(',').each do |f|
        opts[opt] << f unless f.match(/^blob/)
      end
    end
  end
  opts[:requires].each {|r| require "#{r}" if FileTest.exist? "#{r}" }
  opts[:test_cases].delete_if {|c| c.match(/#{test_name}/)}
  setup_text=text.match(/#{LINSTM}setup\s+(.*?)#{LINSTM}end\s+/m).to_a[1]
  tests=text.split(/#{LINST}[Ee]xamples?:/).to_a[1..-1].to_a.map do |test|
    test.gsub!(/#{LINST}>>\s*(.+)\n#{LINST}=>\s*(.+)/) {|m| 
      expected, actual=[$2,$1]
      #assert equal cannot take a hash as its first argument
      expected.sub!(/^\{(.*)\}\s*$/) {|m| "Hash[#{$1}]"}
      "assert_equal #{expected}, #{actual}"
    }
    lines=test.split(/\n/)
    test_text=lines.map {|l| l.match(/#{LINST}(assert.+)/) && $1}.compact.join ";\n"
    [lines[0], test_text]
  end
  context_proc=lambda {
    context test_name do
      setup do
        eval setup_text.to_a.join ';'
      end
      tests.each do |test|
        should test[0] do
          eval test[1] 
        end
      end
      opts[:contexts].compact.each do |c| 
        mk_test_context(c).call
      end
    end
  }
  opts[:test_cases].each {|c| process(c)}
  if test_case
    test_case.context test_name do 
      setup do 
        eval setup_text.to_a.join ';'
      end
      tests.each do |test|
        should test[0] do
          eval test[1] 
        end
      end
      opts[:contexts].compact.each  do |c| 
        mk_test_context(c).call
      end
    end 
  else
    context_proc
  end
end
process(ARGV.shift || DEFAULT_FILE)
