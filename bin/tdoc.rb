#!/usr/bin/ruby
require 'rubygems'
require 'test/unit'
require 'shoulda'

$: << 'lib'

LINST='^[#|\s]*'
LINSTM='[#|\s]*'
EXTENSIONS={:contexts => '.rdoc',:tests => '.rdoc',:requires => '_require.rb'}
DEFAULT_FILE="README#{EXTENSIONS[:tests]}"

def process(files=nil) #called at end of script
  files||=DEFAULT_FILE
    if files.class==Array
      files.each {|f|`#{$PROGRAM_NAME} #{f}`}
    else
      mk_test_context(files)
    end
end
def mk_test_context(file, test_case=nil)
  test_name=File.basename(file).sub(/\..*?$/,'')
  test_dir=File.dirname(file)
  unless test_case
    test_case=Class.new(Test::Unit::TestCase)
    Object.const_set(:"Test#{test_name.capitalize}", test_case)
  end
  text=File.read(file)
  opts={
    :requires => Dir.glob("#{test_dir}/#{test_name}#{EXTENSIONS[:requires]}"),
    :contexts => Dir.glob("#{test_dir}/#{test_name}/*#{EXTENSIONS[:tests]}")
  }
  opts.keys.each do |opt|
      p EXTENSIONS,opt,EXTENSIONS[opt]
    text.scan(/#{LINST}:include:\s*(.+#{EXTENSIONS[opt]})/).each do |files|
      files[0].split(',').each do |f|
        opts[opt] << f unless f.match(/^blob/)
      end
    end
  end
  opts[:requires].each {|r| require "#{test_dir}/#{r}" if FileTest.exist? "#{test_dir}/#{r}" }
  opts[:test_cases]=[]
  opts[:contexts].map! {|c| 
    if c.match(/#{test_name}/)
      c
    else
      opts[:test_cases] << c
      nil
    end
  }
  opts[:contexts].compact.each {|c| mk_test_context "#{test_dir}/#{c}", test_case}
  opts[:test_cases].each {|c| process(c)}
  opts[:setup]=text.match(/#{LINSTM}setup\s+(.*?)#{LINSTM}end\s+/m).to_a.map {|m| m[1]}
  tests=text.split(/#{LINST}[Ee]xamples?:/).to_a[1..-1].to_a.map do |test|
    test.gsub!(/#{LINST}>>\s*(.+)\n#{LINST}=>\s*(.+)/) {|m| "assert_equal #{$1}, #{$2}"}
    lines=test.split(/\n/)
    test_text=lines.map {|l| l.match(/#{LINST}(assert.+)/) && $1}.compact.join ";\n"
    [lines[0], test_text]
  end
  test_case.context test_name do 
    setup do 
      eval opts[:setup].to_a.join ';'
    end
    tests.each do |test|
      should test[0] do
        eval test[1] 
      end
    end
  end
end
process
