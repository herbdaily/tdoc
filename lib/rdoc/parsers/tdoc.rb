class RDoc::Parser::Tdoc < RDoc::Parser::Simple
  LINST='^[#|\s]*'
  parse_files_matching(/\.rdoc/)
  def initialize(top_level, file_name, content, options, stats)
    test_name=File.basename(file_name,'.rdoc')
    test_dir=File.dirname(file_name)
    if File.exists?("#{test_dir}/#{test_name}.rb")
      examples=content.split()
    end
    super(top_level, file_name, content, options, stats)
  end
end
