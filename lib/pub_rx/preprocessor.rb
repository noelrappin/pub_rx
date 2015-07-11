require 'coderay'
require 'pygments'

class Preprocessor

  attr_accessor :text, :input

  def self.process_directory(pattern, subdir="")
    Dir[pattern].sort.each do |path|
      process_file(path, subdir)
    end
  end

  def self.process_file(path, subdir="")
    file_name = path.split("/")[-1]
    if path.split("/")[-2] != "text"
      file_name = "#{path.split("/")[-2]}_#{file_name}".gsub(" ", "-")
    else
      file_name = file_name.gsub(" ", "-")
    end
    text = File.new(path).read
    text = Preprocessor.new(text).process
    File.open("output/#{subdir}/preprocessed/#{file_name}", 'w') do |f|
      f << text
    end
  end

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

  def fix_ulysses_weirdness
    @body.gsub!(%r{^!\\\[}, "![")
    @body.gsub!(%r{^\\\[}, "[")
    @body.gsub!(%r{^\\\[}, "[")
    @body.gsub!("\\_", "_")
    @body.gsub!("\\\{", "{")
  end

  def process
    fix_ulysses_weirdness
    scan
    extend_module
    process_text
  end

  def extend_module
    case directive_name
    when "sidebar" then extend SidebarDirective
    when "cssidebar" then extend CoffeeScriptSidebarDirective
    when "code" then extend CodeDirective
    when "trust" then extend TrustDirective
    when "author" then extend AuthorDirective
    when "deprecation" then extend DeprecationDirective
    when "proptip" then extend ProtipDirective
    when "kansas" then extend KansasDirective
    when "definition" then extend DefinitionDirective
    when "zen" then extend ZenDirective
    when "letter" then extend LetterDirective
    when "inthis" then extend InThisDirective
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

module LetterDirective
  def process_text
    processed_text = %{<div class="letter" markdown="1">\n}
    processed_text += %{<blockquote>}
    divs = body.split("\n").map do |line|
      %{<div class="letter-body" markdown="1">#{line}</div>}
    end
    processed_text += divs.join("\n")
    processed_text += %{</blockquote>}
    processed_text += %{</div>}
    parent.append_result(processed_text)
  end
end

module InterpolationDirective

  def body_div
    body.split("\n").map do |line|
      %{<div class="#{dom_class}-body interp-body" markdown="1">#{line}</div>}
    end
  end


  def process_text
    processed_text = %{<div class="#{dom_class} interp" markdown="1">\n}
    processed_text += %{<div class="#{dom_class}-heading interp-heading">#{caption}</div>\n}
    divs = body_div
    processed_text += divs.join("\n")
    processed_text += %{</div>}
    parent.append_result(processed_text)
  end
end

module DefinitionDirective
  include InterpolationDirective
  def body_div
    [%{<div class="#{dom_class}-body interp-body" markdown="1"><strong>#{params[:term].strip}:</strong> #{body}</div>}]
  end

  def dom_class
    "definition"
  end

  def caption
    "Definition"
  end
end

module TrustDirective
  include InterpolationDirective

  def dom_class
    "trust-me"
  end

  def caption
    "Trust Me!"
  end
end

module AuthorDirective
  include InterpolationDirective

  def dom_class
    "author"
  end

  def caption
    "Author's Note"
  end
end

module DeprecationDirective
  include InterpolationDirective

  def dom_class
    "deprecation"
  end

  def caption
    "Deprecation Warning"
  end
end

module ProTipDirective
  include InterpolationDirective

  def dom_class
    "pro-tip"
  end

  def caption
    "Pro Tip!"
  end
end

module KansasDirective
  include InterpolationDirective

  def dom_class
    "kansas"
  end

  def caption
    "I don't think we're in Kansas anymore..."
  end
end

module ZenDirective
  include InterpolationDirective

  def dom_class
    "zen"
  end

  def caption
    "The Zen of Ember"
  end
end

module InThisDirective
  include InterpolationDirective

  def dom_class
    "in-this"
  end

  def caption
    "In This Chapter..."
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

  def directory
    p $settings
    params[:dir] || $settings["code_dir"]
  end

  def command
    p directory
    "cd #{directory}; git show #{params[:branch]}:#{file_name}"
  end

  def recovered_code
    `#{command}`.strip
  end

  def file_name
    return nil unless params[:file]
    params[:file].gsub("-", "_")
  end

  def marker_match
    case language
    when :ruby then "###{params[:marker]}"
    else
      "\/\/###{params[:marker]}"
    end
  end

  def elide_match
    "\/\/###{params[:elide]}"
  end

  def fix_ulysses_weirdness(result)
    result.gsub!(%r{^!\\\[}, "![")
    result.gsub!(%r{^\\\[}, "[")
    result.gsub!(%r{^\\\[}, "[")
    result.gsub!(%r{\\\[}, "[")
    result.gsub!(%r{\\<}, "<")
    result.gsub!(%r{\\>}, ">")
    result.gsub!("\\_", "_")
    result
  end

  def display_body
    raw = if file_name then recovered_code else body end
    if params[:marker]
      match = raw.match(%r{#{marker_match}(.*)#{marker_match}}m)
      if match
        return match[1]
      else
        p raw
        raise Exception, "Unknown marker #{params[:file]}  #{params[:branch]} #{params[:marker]}"
      end
    end
    if params[:elide]
      data = raw.match(%r{(.*)#{elide_match}(.*)#{elide_match}(.*)}m)
      return data[1] + "\n#{params[:elide_caption] || "..."}\n" + data[3]
    end
    if params[:line]
      line =  raw.split("\n")[params[:line].to_i]
      return fix_ulysses_weirdness(line)
    end
    if params[:lines]
      first, last = params[:lines].split("-")
      range = (first.to_i...last.to_i)
      lines = raw.split("\n")[range].map { |line| fix_ulysses_weirdness(line) }
      return lines.join("\n")
    end
    result = []
    raw.split("\n").each do |line|
      next unless line
      line = fix_ulysses_weirdness(line)
      result << line unless line.start_with?("//##")
    end
    result.join("\n")

  end

  def language
    # p display_body
    # p "---"
    #p params
    extension = params[:type]
    extension = params[:file].split(".").last.strip if extension.nil? && params[:file]
    case extension
    when "rb", "ruby" then :ruby
    when "js" then :javascript
    when "html", "mustache", "handlebars", "hbs" then :html
    when "css" then :css
    when "yaml" then :yaml
    when "erb" then :erb
    when "haml" then :haml
    else
      :text
    end
  end

  def process_text
    header = %{<div class="code-filename">#{file_name} (Branch: #{params[:branch]})</div>}
    header = header.gsub("\\_", "_")
    processed_text = CodeRay.scan(display_body, language)
        .div(:line_numbers => nil)
    # processed_text = Pygments.highlight(display_body, lexer: language)
    footer = %{<div class="code-caption">#{params[:caption]}</div>}
    parent.append_result(header) if params[:file]
    parent.append_result(processed_text)
    parent.append_result(footer)
  end

end

module TableDirective

  def process_text
    processed_text = %{<div class="table" markdown="1">}
    if params[:caption]
      processed_text += %{<div class="caption">#{params[:caption]}</div>\n}
    end
    processed_text += "#{body}\n"
    processed_text += %{</div>}
    parent.append_result(processed_text)
  end
end
