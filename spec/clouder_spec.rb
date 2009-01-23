require File.dirname(__FILE__) + '/spec_helper.rb'

describe "Clouder" do
  
  it "should get available collections" do
    collections = Clouder.collections "http://localhost:9292/"
    collections.size.should == 1
    collections.first.should == "notes"
  end
    
end
