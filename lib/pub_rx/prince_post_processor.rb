class PrincePostProcessor

  attr_accessor :text, :footnotes

  def self.process_directory(digit="")
    text = File.new("output/#{digit}/index.html").read
    text = PrincePostProcessor.new(text).process
    File.open("output/#{digit}/prince_index.html", 'w') do |f|
      f << text
    end
  end

  def initialize(text)
    @text = text
    @footnotes = {}
    @counter = 0
  end

  def anchor_regex
    %r{<a.*?href="#(fn_.*?)".*?</a>}
  end

  def data_regex
    %r{<li\s*id="(.*?)">.*?<p>(.*?)</p>.*?</li>}m
  end

  def all_footnotes_regex
    %r{<div class="footnotes">.*?</div>}m
  end

  def reverse_footnote_regex
    %r{<a\s?href="#fn.*?class="reversefootnote".*?>.*?</a>}
  end

  def ulysses_media_regex
    %r{<img src="Media\/(.*).png".*\/>}
  end

  def process
    @text.gsub!(reverse_footnote_regex, "")
    @text.scan(data_regex) do |match|
      footnotes[match[0]] = match[1]
    end
    @text.gsub!(anchor_regex) do |match_string|
      %{<span class="footnote">#{footnotes[$1]}</span>}
    end
    @text.gsub!(ulysses_media_regex) do |match_string|
      filename = $1
      filename = File.basename(filename, ".png").split(".")[0 .. -2].join(".")
      result = %{<img src="images/#{filename}.png" style="height:90%;width:90%;" />}
      result
    end
    @text.gsub!(all_footnotes_regex, "")
    text
  end

end
