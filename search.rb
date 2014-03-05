
require './dictionary.rb'

class VectorData

    attr_accessor :norm, :termid, :weight
    
    # termid and weight are parallel arrays
    # the term termid[i] has weight of weight[i]
        
    def initialize
        @norm = 0
        @termid = []
        @weight = []
    end
    
end

class VectorSpaceModel

    attr_reader :index

    def initialize( index_filename, number_of_docs )
        
        # Load index into memory
        if File.exists?( index_filename )
            File.open(index_filename, "rb") do |file|
                @index = Marshal.load( file.read )
            end
        else
            puts "Error: File does not exist. \nGenerate the index file by running 'invert.rb'."
            exit
        end
        
        # Collect information on the document vector
        @vdocs = Hash.new
        term_i = 0
        
        @index.each do |term, data|
            data.postings.each do |doc_id, doc_data|  
            
                idf = Math.log( number_of_docs / data.term_doc_freq )
                w = (1 + Math.log(doc_data.freq)) * idf
                
                if @vdocs[doc_id] == nil
                    @vdocs[doc_id] = VectorData.new
                end
                
                @vdocs[doc_id].norm += w*w
                @vdocs[doc_id].termid.push( term_i )
                @vdocs[doc_id].weight.push( w )
                
            end
            
            term_i += 1
        end
        
        @vdocs.each_value do |v|
            v.norm = Math.sqrt( v.norm )
        end
        
        @vdocs = Hash[ @vdocs.sort_by { |k,v| k } ]
    end
    
    
    def search( query )
        
        @vquery = VectorData.new
        query_terms = query.split
        term_i = 0
        
        # for each term in the dictionary
        @index.each do |term, data|
              
            # calculate the weight for query vector
            if (query_terms.include?( term ))
            
                w = ( 1 + Math.log(query_terms.count( term )) )
                
                @vquery.norm += w*w
                @vquery.termid.push( term_i )
                @vquery.weight.push( w )
            end
            
            term_i += 1
        end
        
        @vquery.norm = Math.sqrt( @vquery.norm )
        
        # return empty list if no terms matched to index
        return [] if (@vquery.norm == 0)
        
        # array to collect relevance scores
        scores = []
        
        # calculate the similarity between each document and query
        @vdocs.each do |docid, doc|
            
            weights_sum = 0
            
            # if term contained in query is found in current document
            # multiply their weights to find the sum of corresponding weights
            # (the numerator of cosine similarity formula)
            @vquery.termid.each_with_index do |tid, i|
                if (doc.termid.include?( tid ))
                    k = doc.termid.index( tid )
                    weights_sum += @vquery.weight[i] * doc.weight[k]
                end
            end
            
            # skip if weights_sum is 0
            next if (weights_sum == 0)
        
            # apply cosine similarity formula and save result
            sim = (weights_sum) / (doc.norm * @vquery.norm)
            
            scores.push( [docid, sim] )
        end
        
        # sort by highest relevance and return 
        return scores.sort{ |x,y| y[1] <=> x[1] }
    end

end
