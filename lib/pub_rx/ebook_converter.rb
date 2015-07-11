class EbookConverter

  attr_accessor :input_file, :format, :switches

  def initialize(input_file, format)
    @input_file = input_file
    @format = format
    @switches = $settings.dup
    @switches.delete("code_dir")
    @file_stem = @switches["filename"]
  end

  def input_dir
    input_file.split("/")[0 .. -2].join
  end

  def convert
    command = "ebook-convert #{input_file} #{input_dir}/#{@file_stem}.#{format}"
    switches.each do |key, value|
      next if key == "filename"
      next if key == "version"
      command << " --#{key}"
      command << " '#{value}'" if value
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
