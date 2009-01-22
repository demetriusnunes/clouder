require File.dirname(__FILE__) + '/spec_helper.rb'

describe "Entity" do

  before :all do
    class Notes < Clouder::Entity
      uri "http://localhost:9292/notes"
    end
    Notes.all.each { |id| Notes.new(id).destroy }
  end
  
  it "should let you create entity classes" do
    n = Notes.new
    n.new?.should == true
  end
  
  it "should let you inspect its uri" do
    Notes.uri.should == "http://localhost:9292/notes"
  end
  
  it "should retrieve all instances" do
    size = Notes.all.size
    
    Notes.create(:text => "note 1").should == true
    Notes.create(:text => "note 2").should == true
    
    Notes.all.size.should == size + 2
  end
  
  it "should let you access attributes" do
    n = Notes.new
    n.text = "My Note"
    n.author = "John Doe"
    
    n.text.should == "My Note"
    n.author.should == "John Doe"
  end
  
  it "should let you save new objects" do
    n = Notes.new
    n.new?.should == true
    n.uri.should == nil
    n.last_modified.should == nil
    n.etag.should == nil
            
    n.text = "My Note"
    n.author = "John Doe"
   
    n.save
    
    n.new?.should == false
    n.uri.should_not == nil
    n.last_modified.should be_close(Time.now, 10)
    n.etag.should_not == nil
  end
  
  it "should let you retrieve saved objects" do
    n = Notes.new
    n.text = "My Note"
    n.author = "John Doe"
    n.save

    id, etag, last_modified = n.id, n.etag, n.last_modified
        
    n = Notes.new(id)
    n.text.should == "My Note"
    n.author.should == "John Doe"
    n.id.should == id
    n.etag.should == etag
    n.last_modified.should == last_modified
  end

  it "should let you update saved objects" do
    n = Notes.new
    n.text = "My Note"
    n.author = "John Doe"
    n.save

    n = Notes.new(n.id)
    n.versions.size.should == 1
    n.text = "My modified note"
    n.author = "John Doe II"
    n.save.should == true

    n = Notes.new(n.id)
    n.versions.size.should == 2
    n.text.should == "My modified note"
    n.author.should == "John Doe II"
  end

  it "should let you delete existing objects" do
    size = Notes.all.size
    n = Notes.new
    n.text = "My Note"
    n.author = "John Doe"
    n.save
    Notes.all.size.should == size + 1
    n.destroy
    Notes.all.size.should == size
  end
end
