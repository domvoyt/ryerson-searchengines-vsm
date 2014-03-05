
class TermData
    
    attr_reader :term_doc_freq, :postings
    
    def initialize
        @term_doc_freq = 0      # term document frequency
        @postings = {} # list of posting data
    end
    
    def addData( docid, position )
        
        if not @postings.has_key?( docid )
            @term_doc_freq += 1
            @postings[docid] = PostingData.new
        end
        
        @postings[docid].addData( position )
        
    end
    
end


class PostingData

    attr_reader :freq, :positions

    def initialize
        @freq = 0
        @positions = []
    end
    
    def addData( pos )
        @freq += 1
        positions.push( pos )
    end
    
end


class DocumentInfo
    
    attr_reader :title, :authors
    
    def initialize(doctitle, docauthors)
        @title = doctitle
        @authors = docauthors
    end
    
end
