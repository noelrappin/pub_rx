class Postprocessor

  def self.process_directory(digit="")
    Dir["output/#{digit}/converted/*.html"].sort.each do |path|
      file_name = path.split("/")[-1]
      text = File.new(path).read
      marker = file_name.split("_").select { |segment| segment.match(/\d+/) }.join("_")
      text = Postprocessor.new(text, marker).process
      File.open("output/#{digit}/postprocessed/#{file_name}", 'w') do |f|
        f << text
      end
    end
  end

  def self.make_page(digit="")
    text = ""
    Dir["output/#{digit}/postprocessed/*.html"].sort.each do |path|
      text << File.new(path).read
    end
    html_template = File.new("layout/template_#{digit}.html").read
    html_template.gsub!("#body", text)
    File.open("output/#{digit}/index.html", 'w') do |f|
      f.puts html_template
    end
  end

  attr_accessor :text

  def initialize(text, marker)
    @text = text
    @marker = marker
  end

  def process
    text.gsub!("<p></div></p>", "</div>")
    text.gsub!(/id="(.*?):(\d*?)"/, %Q{id="\\1_#{@marker}_\\2"})
    text.gsub!(/href="#(.*?):(\d*?)"/, %Q{href="#\\1_#{@marker}_\\2"})
    #self.text = %{<div class="chapter">\n#{text}\b</div>}
    text
  end

end
