
require 'benchmark'

require './dictionary.rb'
require './stemmify.rb'


def extract_terms(str)
    
    # clean up, separate and extract terms
    text = str.gsub(/[^A-Za-z0-9' ]/, ' ')
    text = text.gsub(/(?<last>[a-z])(?<first>[A-Z])/, '\k<last> \k<first>')
    terms = text.downcase.split
    
    all = str.split(" ")
    pos = 0
    
    # remove stopwords
    if @flag_stop
        terms = terms.delete_if { |t| @stopwords.include?( t ) }
    end
    
    # add all terms to hash
    terms.each do |word|
    
        # position matching
        if ( all[pos] != nil ) and not ( all[pos].downcase.include?( word ) )
            pos += 1
            redo
        end
        
        # stemming
        if @flag_stem
            word = word.stem
        end
        
        if not @hash.has_key?(word)
            @hash[word] = TermData.new
        end

        @hash[word].addData( @docid, (@docpos+pos) )
        pos += 1
        
    end
    
    @docpos += all.size
    
end


def get_stopword_list

    list = []
    
    File.open("common_words", "r") do |file|
        file.each_line do |line|
            list.push( line.chomp )
        end
    end

    return list
end


# Extract command-line arguments

message_usage = "Usage: ruby invert.rb <document input file name> [-stem] [-stopwords]\n\n"

if ARGV.length < 1
    puts"Error: Missing agruments."
    puts message_usage
    exit
end

@filename = ARGV.shift

if File.exists?( @filename )
    @file = File.open(@filename, "r")
else
    puts"Error: File #{@filename} does not exist."
    puts message_usage
    exit
end

if ARGV.include?( "-stem" )
    @flag_stem = true
end
if ARGV.include?( "-stopwords" )
    @flag_stop = true
    @stopwords = get_stopword_list
end


@hash = Hash.new    # Hash for the Term Dictionary
@docinfo = Hash.new # Hash for caching document related information
@current_op = ""    # Current operation ( .I, .W, .A etc)

@docid      # Current document id
@doctitle   # Current document title
@docauthors # Current document authors
@docpos     # Current position in the document

# time the inverted index creation
time = Benchmark.realtime do

    while (line = @file.gets)
        next if line == nil or line == ""
        
        # if special character, change current operation
        if (line[0] == ".")
            @current_op = line[1]
            
            if (@current_op == "I") # on document id
            
                # save previous document information
                if not @docid == nil
                    @docinfo[@docid] = DocumentInfo.new(@doctitle.chomp(" "), @docauthors.chomp(", "))
                end
                
                # reset fields
                @docid = line.split[1].to_i
                @doctitle = ""
                @docauthors = ""
                @docpos = 0
            end
            
        # else perform actions based on current state    
        else 
            case @current_op 
             
                when "T" # on title
                    @doctitle += line.chomp + " "
                    extract_terms(line)
                    
                when "W" # on abstract
                    extract_terms(line)
                    
                when "A" # on author
                    @docauthors += line.chomp + ", "
                    extract_terms(line)
                    
                when "N", "X", "B" # skip to next on those
                    next
            end
        end
    end
    
    # save last document information
    @docinfo[@docid] = DocumentInfo.new(@doctitle.chomp(" "), @docauthors.chomp(", "))
                
end

@file.close

# sort the hash
@hash = Hash[ @hash.sort_by { |k,v| k } ]

# print benchmark
puts
puts "Inverted Index Creation Time: #{time}\n\n"

# serialize the inverted index to a file
File.open("index", "wb") do |savefile|
    savefile.write( Marshal.dump( @hash ) )
end

# serialize the document information to a file
File.open("doc_info", "wb") do |savefile|
    savefile.write( Marshal.dump( @docinfo ) )
end
