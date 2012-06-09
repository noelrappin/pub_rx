require 'ostruct'
require_relative '../lib/pub_rx/preprocessor'

class String
  def unindent 
    gsub(/^#{scan(/^\s*/).min_by{|l|l.length}}/, "")
  end
end

RSpec::Matchers.define :process_to do |result|
  match do |text|
    Preprocessor.new(text).process.strip.should == result.strip
  end

  failure_message_for_should do |text|
    actual = Preprocessor.new(text).process
    "Expected \n #{text} \n to return \n #{result} \n received \n #{actual} \n"
  end
end

RSpec::Matchers.define :have_module do |mod|
  match do |obj|
    obj.included_modules.first.should == mod 
  end
end

describe Preprocessor do 

  describe "sidebar processor" do

    it "creates a basic sidebar" do
      text = <<-EOF.unindent
        before

        ///sidebar
        inside

        after
      EOF
      result = %{before\n\n<div class="sidebar" markdown="1">\n<div class="sidebar-body" markdown="1">inside</div></div>\n\nafter}
      text.should process_to(result)
    end

    it "creates a sidebar with at title" do
      text = <<-END.unindent
        before

        ///sidebar
        :title A Sidebar
        inside

        after
      END
      result = <<-RESULT.unindent
       before
       
       <div class="sidebar" markdown="1">
       <div class="sidebar-title">A Sidebar</div>
       <div class="sidebar-body" markdown="1">inside</div></div>
       
       after
      RESULT
      text.should process_to(result)
    end

  end

  describe LineProcessor do
    let(:preproc) { Preprocessor.new(text) }
    let(:line_processor) { LineProcessor.new(preproc.next_line, preproc) }

    before(:each) do
      line_processor.scan
      line_processor.extend_module
    end
    subject { line_processor }

    describe "recognizing non directive text" do
      let(:text) { "content\nnot_content" }
      its(:directive_name) { should be_nil }
      its(:params) { should == {} }
      its(:body) { should == "content" }
      it { should have_module(NilDirective) }
    end

    describe "recognizing a directive" do
      let(:text) { "///sidebar\ncontent\nnot_content" }
      its(:directive_name) { should == "sidebar" }
      its(:params) { should == {} }
      its(:body) { should == "content" }
      it { should have_module(SidebarDirective) }
    end

    describe "recognizing parameters" do
      let(:text) { "///directive\n:parameter thing\ncontent" }
      its(:directive_name) { should == "directive" }
      its(:params) { should == {parameter: "thing"} }
      its(:body) { should == "content" }
    end

    describe "recognizing longer body if there is an end directive" do
      let(:text) { "///sidebar\ncontent\nmore content\n\\\\\\sidebar" }
      its(:directive_name) { should == "sidebar" }
      its(:params) { should == {} }
      its(:body) { should == "content\nmore content" }
    end

    describe "does not recognize longer body if there is another end directive" do
      let(:text) { "///sidebar\ncontent\nmore content\n\\\\\\other" }
      its(:directive_name) { should == "sidebar" }
      its(:params) { should == {} }
      its(:body) { should == "content" }
    end

    describe "does not recognize longer body if there is another start directive" do
      let(:text) { "///sidebar\ncontent\nmore content\n///sidebar" }
      its(:directive_name) { should == "sidebar" }
      its(:params) { should == {} }
      its(:body) { should == "content" }
    end
  end

  describe "directives" do

    class DummyParent
      attr_accessor :data
      def initialize
        @data = []
      end

      def append_result(text)
        @data << text
      end
    end
    
    describe NilDirective do
      it "should just pass its data to the parent" do
        dummy = OpenStruct.new(
            :body => "body", :params => {}, :parent => DummyParent.new)
        dummy.extend(NilDirective)
        dummy.process_text
        dummy.parent.data.should == ["body"]
      end
    end

    describe SidebarDirective do
      it "should create a sidebar" do
        dummy = OpenStruct.new(
              :body => "body", :params => {:title => "Title"}, 
              :parent => DummyParent.new)
        dummy.extend(SidebarDirective)
        dummy.process_text
        dummy.parent.data.should == [
          %{<div class="sidebar" markdown="1">\n<div class="sidebar-title">Title</div>\n<div class="sidebar-body" markdown="1">body</div></div>}]
      end
    end

    describe CodeDirective do
      let(:dummy) do 
        OpenStruct.new(
          :parent => DummyParent.new,
          :params => {:dir => "../js", :file => "app/assets.js", 
              :branch => "master"})
      end
      let(:body) { "before\n//##marker\ninside\n//##marker\nafter" }

      before(:each) do
        dummy.extend(CodeDirective) 
      end

      it "calls git" do
        dummy.command.should == 'cd ../js; git show master:app/assets.js'
        dummy.should_receive(:recovered_code).and_return("body")
        dummy.process_text
      end

      it "ignores markers" do
        dummy.should_receive(:recovered_code).and_return(body)
        dummy.display_body.should == "before\ninside\nafter"
      end

      it "limits to markers when asked" do
        dummy.params[:marker] = "marker"
        dummy.should_receive(:recovered_code).and_return(body)
        dummy.display_body.should == "\ninside\n"
      end

      it "elides markers when asked" do
        dummy.params[:elide] = "marker"
        dummy.should_receive(:recovered_code).and_return(body)
        dummy.display_body.should == "before\n...\nafter"
      end
    end

  end

end