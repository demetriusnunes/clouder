require File.dirname(__FILE__) + '/spec_helper.rb'

describe "Entity" do

  before :all do
    class Note < Clouder::Entity
      uri "http://localhost:9292/notes"
    end
    Note.all.each { |id| Note.new(id).destroy }
  end

  it "should let you know the available methods for the class" do
    options = Note.options
    options.should == %w(GET HEAD POST OPTIONS)
  end

  it "should let you know the available methods for the object" do
    n = Note.new
    n.text = "My note"
    n.save
    n.options.should == %w(GET HEAD PUT DELETE OPTIONS)
  end
  
  it "should let you create entity classes" do
    n = Note.new
    n.new?.should == true
  end
  
  it "should let you inspect its uri" do
    Note.uri.should == "http://localhost:9292/notes"
  end
  
  it "should retrieve all uris" do
    size = Note.all.size
    Note.create(:text => "note 1").should be_an_instance_of(Note)
    Note.create(:text => "note 2").should be_an_instance_of(Note)
    Note.all.size.should == size + 2
  end

  it "should retrieve all instances" do
    size = Note.all.size
    Note.create(:text => "note 1").should be_an_instance_of(Note)
    Note.create(:text => "note 2").should be_an_instance_of(Note)
    
    notes = Note.all(:resolved => true)
    notes.each { |n| 
      n.should be_an_instance_of(Note) 
      n.etag.should_not == nil
      n.id.should_not == nil
      n.last_modified.should_not == nil
    }
    Note.all.size.should == size + 2
  end

  it "should retrieve all uris with limit and offset" do
    size = Note.all.size
    
    notes = []
    (1..4).each { |i| notes << Note.create(:text => "$note #{i}") }
    
    last_notes = Note.all(:limit => 4)
    last_notes.size.should == 4
    last_notes.should == notes.map { |n| n.path }.reverse
    
    last_notes = Note.all(:offset => 2, :limit => 2)
    last_notes.size.should == 2
    last_notes.should == notes[0..1].map { |n| n.path }.reverse

    last_notes = Note.all(:offset => 2)
    last_notes.size.should == size + 2
  end
  
  it "should let you access attributes" do
    n = Note.new
    n.text = "My Note"
    n.author = "John Doe"
    
    n.text.should == "My Note"
    n.author.should == "John Doe"
  end
  
  it "should let you save new objects" do
    n = Note.new
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
    n = Note.new
    n.text = "My Note"
    n.author = "John Doe"
    n.save

    id, etag, last_modified = n.id, n.etag, n.last_modified
        
    n = Note.new(id)
    n.text.should == "My Note"
    n.author.should == "John Doe"
    n.id.should == id
    n.etag.should == etag
    n.last_modified.should == last_modified
  end

  it "should let you update saved objects" do
    n = Note.new
    n.text = "My Note"
    n.author = "John Doe"
    n.save

    n = Note.new(n.id)
    n.versions.size.should == 1
    n.text = "My modified note"
    n.author = "John Doe II"
    n.save.should == true

    n = Note.new(n.id)
    n.versions.size.should == 2
    n.text.should == "My modified note"
    n.author.should == "John Doe II"
  end

  it "should let you delete existing objects" do
    size = Note.all.size
    n = Note.new
    n.text = "My Note"
    n.author = "John Doe"
    n.save
    Note.all.size.should == size + 1
    n.destroy
    Note.all.size.should == size
  end
  
  it "should let you query versions about the object" do
    n = Note.new
    n.versions.should == []
    n.text = "First version"
    n.save

    etag = n.etag
    n.versions.size.should == 1
    n.text = "Second version"
    n.save

    n.versions.size.should == 2
    n.versions[1].should =~ Regexp.new(etag)
    n.text = "Third version"   
    etag = n.etag
    n.save 
    n.versions.size.should == 3
    n.versions[1].should =~ Regexp.new(etag)
  end

  it "should let you query versions about the object using offset and limit" do
    etags = []
    n = Note.new
    n.text = "First version"
    n.save
    etags << n.etag
    
    n.text = "Second version"
    n.save
    etags << n.etag
    
    n.text = "Third version"   
    etag = n.etag
    n.save 
    etags << n.etag
    
    versions = n.versions(:limit => 2)
    versions.size.should == 2
    versions.first.should include(n.path)    
    versions.last.should =~ Regexp.new(etags[1])    
    
    versions = n.versions(:offset => 1, :limit => 2)
    versions.size.should == 2
    versions.first.should =~ Regexp.new(etags[1])    
    versions.last.should =~ Regexp.new(etags[0])    
    
    versions = n.versions(:offset => 2, :limit => 2)
    versions.size.should == 1
    versions.first.should =~ Regexp.new(etags[0])    
  end
  
end
