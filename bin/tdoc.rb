#!/usr/bin/ruby
require 'rubygems'
require 'test/unit'
require 'contest'
require 'irb'

$: << 'lib'

LINST='^[#|\s]*'
EXTENSIONS={:tests => '.rdoc',:requires => '.rb'}
DEFAULT_FILE=["README#{EXTENSIONS[:tests]}"]

START_IRB="IRB.setup nil; IRB.conf[:MAIN_CONTEXT] = IRB::Irb.new.context; require 'irb/ext/multi-irb'; IRB.irb nil, self"

def process(files) #called at end of script
  if files.class==Array 
    files.each {|f|  
      puts "\n\n--------------------\n#{f}:\n\n"
      result=system("#{$PROGRAM_NAME} #{f} #{ARGV}")
      puts "\n\nERRORS IN TEST #{f}!!!\n\n" unless result
    }
  else
    test_name=File.basename(files).sub(/\..*?$/,'')
    test_case=Class.new(Test::Unit::TestCase)
    Object.const_set(:"Test#{test_name.capitalize}", test_case)
    mk_test_context(files, test_case)
  end
end
def mk_test_context(file, test_case=nil)
  test_name=File.basename(file).sub(/\..*?$/,'')
  test_dir=File.dirname(file)
  $: << test_dir unless $:.include?(test_dir)
  text=File.read(file)
  opts={
    :requires => Dir.glob("#{test_dir}/#{test_name}#{EXTENSIONS[:requires]}"),
    :contexts => Dir.glob("#{test_dir}/#{test_name}/*#{EXTENSIONS[:tests]}"),
    :tests => [],
  }
  [:requires, :tests].each do |opt|
    text.scan(/#{LINST}:include:\s*(.+#{EXTENSIONS[opt]})/).each do |files|
      files[0].split(',').each do |f|
        opts[opt] << f unless f.match(/^blob/)
      end
    end
  end
  opts[:requires].each {|r| require "#{r}" if FileTest.exist? "#{r}" }
  opts[:tests].delete_if {|c| c.match(/#{test_name}/)}
  setup_text=text.sub(/(.*)\n#{LINST}setup\s*\n/m,'').sub(/\n#{LINST}end(.*)/m,'') if text.match(/#{LINST}setup\s*$/)
  tests=text.split(/#{LINST}[Ee]xamples?:/).to_a[1..-1].to_a.map do |test|
    test.gsub!(/#{LINST}>>\s*(.+)\n#{LINST}=>\s*(.+)/) {|m| 
      expected, actual=[$2,$1]
      #assert_equal cannot take a hash as its first argument
      expected.sub!(/^\{(.*)\}\s*$/) {|m| "Hash[#{$1}]"}
      "assert_equal #{expected}, #{actual}"
    }
    lines=test.split(/\n/)
    test_text=lines.map {|l| 
      if l.match(/#{LINST}!!!/)
        START_IRB
      else
        l.match(/#{LINST}(assert.+)/) && $1
      end
    }.compact.join ";\n"
    [lines[0], test_text]
  end
  tests=[['work',"assert(true);"]] if tests.empty? #avoids "no tests specified" error
  context_proc=lambda {
    context test_name do
      setup do
        eval setup_text.to_a.join(';') 
      end
      tests.each do |test|
        should test[0].to_s do
          eval test[1] 
        end
      end
      opts[:contexts].compact.each do |c| 
        mk_test_context(c).call
      end
    end
  }
  if test_case
    test_case.module_eval {mk_test_context(file).call}
    process opts[:tests] unless opts[:tests].empty?
  else
    context_proc
  end
end
if glob=ARGV.shift
  files=Dir.glob(glob)
  process(files.count > 1 ? files : files[0])
else
  process(DEFAULT_FILE)
end
