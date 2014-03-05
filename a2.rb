
require './lib/search.rb'
require './lib/dictionary.rb'
require './lib/stemmify.rb'

def get_stopword_list
    list = []
    
    begin
        File.open(@filename_stopwords, "r") do |file|
            file.each_line { |line| list.push( line.chomp ) }
        end
    rescue
        puts "File '#{@filename_stopwords}' not found."
        puts "You are missing a file crucial to perform stopword removal.\n\n"
        exit
    end

    return list
end

def perform_stopword_removal(terms)
    terms.delete_if { |t| @stopwords.include?( t ) }
end

def perform_stemming(terms)
    terms.map { |t| t.stem }
end

@out = File.open("out.txt", "w")

@filename_index = "data/index"
@filename_docinfo = "data/doc_info"
@filename_stopwords = "cacm/common_words"

message_usage = "Usage: ruby a2.rb [-stem] [-stopwords]\n\n"

# Make sure the index file exists
if not File.exists?( @filename_index )
    puts "File '#{@filename_index}' not found."
    puts "You need to run 'inverse.rb' to generate '#{@filename_index}'.\n\n"
    exit
end

# Load document info into memory
begin
    File.open(@filename_docinfo, "rb") do |file|
        @docinfo = Marshal.load( file.read )
    end
rescue
    puts "File '#{@filename_docinfo}' not found."
    puts "You need to run 'inverse.rb' to generate '#{@filename_docinfo}'.\n\n"
    exit
end

# Extract command-line arguments
ARGV.each do |arg|

    if ( arg == "-stem" )
        @flag_stem = true
    elsif ( arg == "-stopwords" )
        @flag_stop = true
        @stopwords = get_stopword_list
    else
        puts "Incorrect argument #{arg}."
        puts message_usage
        exit
    end
end

ARGV.clear

# Create a Vector Space Model for searching
vsm = VectorSpaceModel.new( @filename_index, @docinfo.size )
    
# Query User
while( true )
    puts
    print "Enter Query: "
    
    query = gets
    
    if (query == "ZZEND\n")
        @out.close
        exit
    end
    
    # Prepare Query (cleaning up, stemming and stopword removal)
    orig = query
    query.gsub!(/[^A-Za-z0-9' ]/, ' ')
    query.downcase!
    
    if (@flag_stem or @flag_stop)
    
        query_terms = query.split
        
        if (@flag_stop) 
            query_terms = perform_stopword_removal(query_terms)
        end
        if (@flag_stem)
            query_terms = perform_stemming(query_terms)
        end
        
        query = query_terms.join(" ")
    
    end

    # Run the Vector Space Model Search on query
    results = vsm.search( query )
    
    # Display Results
    if (results.empty?)
        puts
        puts "Query did not match any documents."
        puts
        next
    end
    
    results.each_with_index do |r,i|
        break if i >= 25
        
        puts
        printf( "%2d)  ", i+1 )
        puts "#{@docinfo[r[0]].title}"
        puts "     Authors: #{@docinfo[r[0]].authors}"
        puts
    end
    
    # Add more results info to an output file
    @out.puts "Original Query: #{orig}"
    @out.puts "Prepared Query: #{query}"
    @out.puts
    
    results.each_with_index do |r,i|
        @out.printf("%4d) ", i+1)
        @out.printf("%04d:", r[0])
        @out.print "    #{r[1]}"
        @out.puts
        @out.puts "      Title:   #{@docinfo[r[0]].title}"
        @out.puts "      Authors: #{@docinfo[r[0]].authors}"
        @out.puts
    end
    
    @out.puts "Q-------------------------------------------------------------------------------"
    @out.puts 
    @out.flush
    
end
