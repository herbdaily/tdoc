#!/usr/bin/ruby
require 'rubygems'
require 'test/unit'
require 'shoulda'

$: << 'lib'

TEST_DIR=ARGV[0] || 'tdoc/'
EXTENTION=ARGV[1] || '.tdoc'
LINST='^[#|\s]*'

def mk_context(file,test_case=nil)
  test_name=File.basename(file).sub(EXTENTION,'')
  unless test_case
    test_case=eval "::Test#{test_name.capitalize}=Class.new(Test::Unit::TestCase)"
  end
  text=File.read(file)
  directives=text.scan(/#{LINST}tdoc_(.+?):\s*(.+)/).inject({}) {|h,d| h[d[0].to_sym]||=[];h[d[0].to_sym] << d[1];h}
  directives[:require].to_a.each {|r| require r}
  directives[:context]||=[]
  text.scan(/#{LINST}:include:\s*(.+)/).each do |i|
    i[0].split(',').each do |file|
      directives[:context] << file
    end
  end
  directives[:context].to_a.each {|c| mk_context "#{TEST_DIR}#{c}", test_case}
  tests=text.split(/#{LINST}[Ee]xamples?:/).to_a[1..-1].to_a.map do |test|
    test.gsub!(/#{LINST}>>\s*(.+)\n#{LINST}=>\s*(.+)/) {|m| "assert_equal #{$1}, #{$2}"}
    lines=test.split(/\n/)
    test_text=lines.map {|l| l.match(/#{LINST}(assert.+)/) && $1}.compact.join ";"
    [lines[0], test_text]
  end
  test_case.context test_name do 
    setup do 
      eval directives[:setup].to_a.join ';'
    end
    tests.each do |test|
      should test[0] do
        eval test[1]
      end
    end
  end
end
def mk_tests(test_dir)
  files=Dir.glob("#{test_dir}*#{EXTENTION}")
  files.each { |file| mk_context(file)}
end
mk_tests(TEST_DIR)



