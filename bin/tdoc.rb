#!/usr/bin/ruby
require 'rubygems'
require 'test/unit'
require 'shoulda'

$: << 'lib'

LINST='^[#|\s]*'

def mk_context(file,test_case=nil)
  test_name=File.basename(file).sub('.tdoc','')
  unless test_case
    test_case=eval "::Test#{test_name.capitalize}=Class.new(Test::Unit::TestCase)"
  end
  text=File.read(file)
  directives=text.scan(/#{LINST}tdoc_(.+?):\s*(.+)/).inject({}) {|h,d| h[d[0].to_sym]||=[];h[d[0].to_sym] << d[1];h}
  directives[:require].to_a.each {|r| require r}
  tests=text.split(/#{LINST}[Ee]xamples:/)[1..-1].map do |test|
    [test.split(/\n/)[0], test.scan(/#{LINST}>>\s*(.+)\n#{LINST}=>\s*(.+)/) ]
  end
  test_case.class_eval do
    define_method :setup do
        eval directives[:setup].join ';'
    end
    context test_name do 
      setup do 
        eval directives[:setup].join ';'
      end
    end
    tests.each do |test|
      should test[0] do
        test[1].each do |assertion|
          assert_equal eval(assertion[0]), eval(assertion[1])
        end
      end
    end
  end
end
def mk_tests(test_dir)
  files=Dir.glob("#{test_dir}/*.tdoc")
  files.each { |file| mk_context(file)}
end
mk_tests(ARGV[0])



