require 'coderay'

class Preprocessor

  attr_accessor :text, :input

  def initialize(text)
    @text = text
    @result = []
    @input = text.split("\n")
  end

  def next_line
    @input.shift
  end

  def peek
    @input.first
  end

  def end_marker_matching?(directive_name)
    @input.each do |line|
      return false if scan_directive(line)
      directive = scan_directive_end(line)
      return directive == directive_name if directive
    end
    return false  
  end

  def scan_directive(line)
    match = line.match(%r{///(.*)})
    if match then match[1] else nil end
  end

  def scan_directive_end(line)
    match = line.match(/\\\\\\(.*)/)
    if match then match[1] else nil end
  end

  def append_result(line)
    @result << line
  end

  def empty?
    @input.empty?
  end

  def process
    LineProcessor.new(next_line, self).process until @input.empty? 
    @result.join("\n")
  end

end

class LineProcessor
  attr_accessor :line, :parent, :directive_name, :body, :params

  def initialize(line, parent)
    @line = line
    @parent = parent
    @params = {}
    @body = line
  end

  def scan_directive
    match = line.match(%r{///(.*)})
    @directive_name = if match then match[1] else nil end
  end

  def scan
    scan_directive
    if directive_name
      load_parameters
      scan_body
    end
  end

  def scan_body
    @body = parent.next_line
    if parent.end_marker_matching?(directive_name)
      until parent.peek.start_with?("\\\\\\")
        @body += "\n#{parent.next_line}"
      end
    end
    parent.next_line if parent.peek && parent.peek.start_with?("\\\\\\")
  end

  def load_parameters
    return if parent.empty?
    while parent.peek.start_with?(":")
      parameter_match = parent.next_line.match(":(.*?)\s(.*)")
      params[parameter_match[1].to_sym] = parameter_match[2]
    end
  end

  def included_modules
    (class << self; self end).included_modules
  end

  def process
    scan
    extend_module
    process_text
  end

  def extend_module
    case directive_name
    when "sidebar" then extend SidebarDirective
    when "cssidebar" then extend CoffeeScriptSidebarDirective
    when "code" then extend CodeDirective
    else 
      extend(NilDirective)
    end
  end

end

module NilDirective

  def process_text
    parent.append_result(body)
  end

end

module SidebarDirective

  def process_text
    processed_text = %{<div class="sidebar" markdown="1">\n}
    if params[:title]
      processed_text += %{<div class="sidebar-title">#{params[:title]}</div>\n}
    end
    divs = body.split("\n").map do |line| 
      %{<div class="sidebar-body" markdown="1">#{line}</div>}
    end
    processed_text += divs.join("\n")
    processed_text += %{</div>}
    parent.append_result(processed_text)
  end
end

module CoffeeScriptSidebarDirective

  def process_text
    processed_text = %{<div class="sidebar coffeescript" markdown="1">\n}
    if params[:title]
      processed_text += %{<div class="sidebar-title">#{params[:title]}</div>\n}
    end
    processed_text += "#{body}\n"
    processed_text += %{</div>}
    parent.append_result(processed_text)
  end
end

module CodeDirective

  def command
    "cd #{params[:dir]}; git show #{params[:branch]}:#{params[:file]}"
  end

  def recovered_code
    `#{command}`.strip
  end

  def display_body
    if params[:file] then recovered_code else body end 
  end

  def language
    extension = (params[:type] || params[:file].split(".").last).strip
    case extension
    when "rb" then :ruby
    when "js" then :javascript
    when "html" then :html
    when "css" then :css
    end
  end

  def process_text
    header = %{<div class="code-filename">#{params[:file]}</div>}
    processed_text = CodeRay.scan(display_body, language)
        .html(:line_numbers => :table)
    footer = %{<div class="code-caption">#{params[:caption]}</div>}
    parent.append_result(header) if params[:file]
    parent.append_result(processed_text)
    parent.append_result(footer)
  end

end