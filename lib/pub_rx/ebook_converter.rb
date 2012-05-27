class EbookConverter
  
  attr_accessor :input_file, :format, :switches

  def initialize(input_file, format)
    @input_file = input_file
    @format = format
    @switches = init_switches
  end

  def init_switches
    {:"output-profile" => "ipad3",
     :authors => "Noel Rappin",
     :pubdate => 2012,
     :title => "Master Space and Time With JavaScript",
     :"use-auto-toc" => nil,
     #:"no-chapters-in-toc" => nil,
     #:"toc-threshold" => 0,
     #:"max-toc-links" => 0,
     :chapter => "//h:h1", 
     :"level1-toc" => "//h:h1", 
     :"level2-toc" => "//h:h2", 
     :"level3-toc" => "//h:h3"}
  end

  def input_dir
    input_file.split("/")[0 .. -2].join
  end

  def convert
    command = "ebook-convert #{input_file} #{input_dir}/book.#{format}"
    switches.each do |key, value|
      command << " --#{key}"
      command << " #{value}" if value
    end
    p command
    `#{command}`
  end

end

class PdfConverter < EbookConverter

  def initialize(input_file)
    super(input_file, "pdf")
  end

end

class EpubConverter < EbookConverter

  def initialize(input_file)
    super(input_file, "epub")
  end
end

class MobiConverter < EbookConverter

  def initialize(input_file)
    super(input_file, "mobi")
    @switches[:"output-profile"] = "kindle"
    @switches[:"mobi-toc-at-start"] = nil
  end

end