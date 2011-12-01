class RDoc::Parser::Tdoc < RDoc::Parser::Simple
  LINST='^[#|\s]*'
  LINSTM='[#|\s]*'
  EXTENSIONS={:tests => '.rdoc',:requires => '.rb'}
  parse_files_matching(/\.rdoc/)
  def initialize(top_level, file_name, content, options, stats)
    super
    @content=process_includes(file_name)
  end
  def process_includes(file_name)
    content=File.read(file_name)
    test_name=File.basename(file_name,'.rdoc')
    test_dir=File.dirname(file_name)
    content.gsub!(/(#{LINST}):include:\s*(.+)/) do |foo|
      indent=$1
      fn=$2
      if fn.match(/#{EXTENSIONS[:requires]}/)
        "\nThe following examples require the file '#{fn}', whose contents follow:\n#{process_includes(fn).gsub(/^/,indent + '  ')}\n"
      else
        process_includes(fn).gsub(/^/,indent)
      end
    end
    content.sub!(/(#{LINST})setup\s+(.*?)#{LINSTM}end\s+/m) {|foo| 
      indent=$1
      "The following code: \n#{$2.gsub(/^/,indent+'  ')}\nprecedes each of the following examples.\n\n"
    }
    Dir.glob("#{test_dir}/#{test_name}.rb").each do |fn|
      tests=content.split(/#{LINST}[Ee]xamples?:/,2)
      content="#{tests[0]}\nThe following examples require the file '#{fn}', whose contents follow:\n#{process_includes(fn).gsub(/^/,'  ')}\nExamples: #{tests[1]}"
    end
    Dir.glob("#{test_dir}/#{test_name}/*.rdoc").each do |fn|
      content+="\n#{process_includes(fn)}\n"
    end
    content
  end
end
