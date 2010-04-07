= clouder

* http://github.com/demetriusnunes/clouder

== DESCRIPTION:

A Ruby client library for accessing CloudKit (http://getcloudkit.com) 
RESTful repositories using simple Ruby objects.

== FEATURES/PROBLEMS:

At this time, *clouder* implements all methods in CloudKit API (as seen
in the checklist at the requirements section) and is good to be used in 
most basic cases.

Clouder::Entity is a subclass of OStruct, but that might change in
the future.
  
== SYNOPSIS:

Here is some sample code of how to use *clouder*, assuming that you
have a CloudKit server running at <tt>http://localhost:9292/</tt> and 
exposing "*notes*".

=== Entity declaration

  class Note < Clouder::Entity
    uri "http://localhost:9292/notes"
  end

=== Creating new documents

  n = Note.new
  n.new? # true
  n.text = "My first note"
  n.author = "John Doe"
  n.save
  n.new? # false
  
  # Short alternative
  n = Note.create(:text => "My first note", :author => "John Doe")

=== Retrieving a single document

  n = Note.get("d35bfa70-cca0-012b-cd41-0016cb91f13d") # some valid id
  puts n.text, n.author

=== Deleting documents

  n = Note.get("d35bfa70-cca0-012b-cd41-0016cb91f13d") # some valid id
  n.delete
  n.deleted? # true
  
=== Retrieving collections

  # This retrieves only the URIs
  uris = Note.all
  uris.each { |uri|
    n = Note.get(uri)
    puts n.text, n.author
  }

  # Using offset and limit
  uris = Note.all(:offset => 5, :limit => 10)

  # To retrieve full documents, use the :resolved option
  notes = Note.all(:resolved => true)
  
  # You can combine all the options
  notes = Note.all(:resolved => true, :offset => 3, :limit => 50)

=== Retrieving older versions of a document

  n = Note.get("d35bfa70-cca0-012b-cd41-0016cb91f13d") # some valid id

  # This retrieves only the URIs
  # - you can also use offset and limit options
  older_uris = n.versions(:limit => 5)

  # To retrieve full documents, use the :resolved option
  older_notes = n.versions(:resolved)

=== Inspecting some metadata for a repository

  # Which collections are available for this server?
  uris = Clouder.collections("http://localhost:9292/")
  uris # [ "notes" ]
  
  # Retrieving only the headers for a valid URI
  headers = Clouder.head("http://localhost:9292/notes")
  
== REQUIREMENTS:

* cloudkit server
* rest-client
* json

== CloudKit API (http://getcloudkit.com/rest-api.html) Checklist:

* GET /cloudkit-meta - OK!
* OPTIONS /%uri% - OK!
* GET /%collection% - OK!
* GET /%collection%/_resolved - OK!
* GET /%collection%/%uuid% - OK!
* GET /%collection%/%uuid%/versions - OK! 
* GET /%collection%/%uuid%/versions/_resolved - OK!
* GET /%collection%/%uuid%/versions/%etag% - OK!
* POST /%collection% - OK! 
* PUT /%collection%/%uuid% - OK! 
* DELETE /%collection%/%uuid% - OK! 
* HEAD /%uri% - OK!

== INSTALL:

* sudo gem install clouder

== TESTING:

Start the test server with (you need rack for this):

 rake test
 
Then run the specs with:

 rake spec

To have coverage report, run:

 rake rcov
 
== LICENSE:

(The MIT License)

Copyright (c) 2009 Demetrius Nunes

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
