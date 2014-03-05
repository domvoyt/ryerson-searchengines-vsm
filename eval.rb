
require './search.rb'
require './dictionary.rb'
require './stemmify.rb'

class QueryFileInfo

    attr_accessor :query, :relevant

    def initialize
        @query = ""
        @relevant = []
    end
end

def get_stopword_list
    list = []
    
    begin
        File.open("common_words", "r") do |file|
            file.each_line { |line| list.push( line.chomp ) }
        end
    rescue
        puts "File 'common_words' not found."
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


message_usage = "Usage: ruby eval.rb [-stem] [-stopwords]\n\n"

# Extract command-line arguments
ARGV.each do |arg|
    if ( arg == "-help" )
        puts message_usage
        exit
    elsif ( arg == "-stem" )
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

# Open file query.text
begin
    @file_query = File.open("query.text", "r")
rescue
    puts "File 'query.text' not found.\n\n"
    exit
end

# Open file qrels.txt
begin
    @file_qrels = File.open("qrels.text", "r")
rescue
    puts "File 'qrels.txt' not found.\n\n"
    exit
end

# Read information from the files into memory
@info = Hash.new
@current_op = ""

@file_query.each_line do |line|
    next if line == nil or line == ""
    
    # if special character, change current operation
    if (line[0] == ".")
        @current_op = line[1]
        
        if (@current_op == "I") # on new query id
            @qid = line.split[1].to_i
            @info[@qid] = QueryFileInfo.new
        end
        
    # else perform actions based on current state    
    else 
        if (@current_op == "W")
            @info[@qid].query += line.chomp + " "
        end
    end
       
end

@file_qrels.each_line do |line|
    id_q, id_d = line.split
    @info[id_q.to_i].relevant.push( id_d.to_i )
end

# Create a Vector Space Model for searching
vsm = VectorSpaceModel.new( "index", 3204 )

puts

# Run querys
@info.each do |k,v|
    next if k == 0 or v.relevant.empty?

    # Prepare Query (cleaning up, stemming and stopword removal)
    query = v.query
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
    
    # Compare search results with relevance results from qrels
    retrieved = results.map { |r| r[0] }
    
    map_sum = 0.0
    num_rel = 0
    
    (retrieved.first(25)).each_with_index do |r,i|    
        if (v.relevant.include?( r ))
            num_rel += 1
            map_sum += (1.0 * num_rel / (i+1))
        end
    end
    
    r_precision =  1.0 * ( (retrieved.first(v.relevant.size)) & (v.relevant) ).size / (v.relevant).size
    map = map_sum / (v.relevant).size
    
    # Display Results
    puts "#{k}:"
    puts "    R-Precision = #{r_precision}"
    puts "    MAP = #{map}"
    
end
