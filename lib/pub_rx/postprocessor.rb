class Postprocessor

  attr_accessor :text

  def initialize(text)
    @text = text
  end

  def process
    text.gsub!("<p></div></p>", "</div>")
    text.gsub!(/id="(.*):(\d*?)"/, %q{id="\1_\2"})
    text.gsub!(/href="#(.*):(\d*?)"/, %q{href="#\1_\2"})
    #self.text = %{<div class="chapter">\n#{text}\b</div>}
    text
  end

end