class Postprocessor

  attr_accessor :text

  def initialize(text, marker)
    @text = text
    @marker = marker
  end

  def process
    text.gsub!("<p></div></p>", "</div>")
    text.gsub!(/id="(.*):(\d*?)"/, %Q{id="\\1_#{@marker}_\\2"})
    text.gsub!(/href="#(.*):(\d*?)"/, %Q{href="#\\1_#{@marker}_\\2"})
    #self.text = %{<div class="chapter">\n#{text}\b</div>}
    text
  end

end
