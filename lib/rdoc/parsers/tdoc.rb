class RDoc::Parser::Tdoc < RDoc::Parser::Simple
  LINST='^[#|\s]*'
  LINSTM='[#|\s]*'
  parse_files_matching(/\.rdoc/)
  def initialize(top_level, file_name, content, options, stats)
    p options.dry_run
    super
    @content=process_includes(file_name)
  end
  def process_includes(file_name)
    content=File.read(file_name)
    test_name=File.basename(file_name,'.rdoc')
    test_dir=File.dirname(file_name)
    content.gsub!(/(#{LINST}):include:\s*(.+)/) {|foo| indent=$1;process_includes($2).sub(/^/,indent)}
    content.gsub!(/(#{LINST})setup\s+(.*?)#{LINSTM}end\s+/m) {|foo| 
      indent=$1
      "The following code: \n#{$2.sub(/^/,indent+'  ')}\nprecedes each of the following examples.\n\n"
    }
    Dir.glob("#{test_dir}/#{test_name}.rb").each do |fn|
      tests=content.split(/#{LINST}[Ee]xamples?:/,2)
      content="#{tests[0]}\nThe following examples require the file '#{fn}', whose contents follow:\n#{process_includes(fn).sub(/^/,'  ')}\nExamples: #{tests[1]}"
    end
    Dir.glob("#{test_dir}/#{test_name}/*.rdoc").each do |fn|
      content+="\n#{process_includes(fn).sub(/^/,'  ')}\n"
    end
    content
  end
end
