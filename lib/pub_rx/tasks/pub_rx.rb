require_relative "../ebook_converter"
require_relative "../prince"
require_relative "../preprocessor"
require_relative "../postprocessor"
require_relative "../prince_post_processor"
require 'yaml'

## x = FileList["text/**/*.md"]
## x.pathmap("new file pattern %n %x")  %p %f %d %x %n {^source,target}

# directory "newdir"

# file "target file" => [source files] do
  # sh
# end

# TARGET_FILES.zip(SOURCE_FILES).each do |target, source|
# file target => ["newdir", source]

# file "final.png" => TARGET_FILES

# task convert => "final.png"

namespace :pub_rx do

  task :load do
    $settings = YAML.load_file("settings.yml")
  end

  task :clean do
    `rm output/preprocessed/*.*`
    `rm output/postprocessed/*.*`
    `rm output/converted/*.*`
  end

  task :preprocess => [:load, :clean] do
    Dir["text/**/*.md"].sort.each do |path|
      file_name = path.split("/")[-1]
      text = File.new(path).read
      text = Preprocessor.new(text).process
      File.open("output/preprocessed/#{file_name}", 'w') do |f|
        f << text
      end
    end
  end


  task :markdownify => :preprocess do
    Dir["output/preprocessed/*.md"].sort.each do |path|
      file_name = path.split("/")[-1]
      `multimarkdown #{path} > output/converted/#{file_name}.html`
    end
  end

  task :sass do
    `sass layout/styles.scss output/styles.css`
  end

  task :postprocess => :markdownify do
    Dir["output/converted/*.html"].sort.each do |path|
      file_name = path.split("/")[-1]
      text = File.new(path).read
      marker = file_name.split("_")[0]
      text = Postprocessor.new(text, marker).process
      File.open("output/postprocessed/#{file_name}", 'w') do |f|
        f << text
      end
    end
  end

  task :make_page => :postprocess do
    text = ""
    Dir["output/postprocessed/*.html"].sort.each do |path|
      text << File.new(path).read
    end
    html_template = File.new("layout/template.html").read
    html_template.gsub!("#body", text)
    File.open('output/index.html', 'w') do |f|
      f.puts html_template
    end
  end

  task :build => [:sass, :make_page]

  task :prince_post_process => :build do
    text = File.new("output/index.html").read
    text = PrincePostProcessor.new(text).process
    File.open('output/prince_index.html', 'w') do |f|
      f << text
    end
  end

  task :prince => :prince_post_process do
    princely = Prince.new
    princely.add_style_sheets("output/styles.css", "layout/code_ray.css")
    html_string = File.new('output/prince_index.html').read
    File.open("output/#{$settings["filename"]}.pdf", 'w') do |f|
      f.puts princely.pdf_from_string(html_string)
    end
  end

  task :pdf => :build do
    PdfConverter.new("output/index.html").convert
  end

  task :epub => :build do
    EpubConverter.new("output/index.html").convert
  end

  task :mobi => :build do
    MobiConverter.new("output/index.html").convert
  end

  task :ebooks => [:prince, :epub, :mobi]

end
