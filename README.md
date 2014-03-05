ryerson-searchengines-vsm
=========================

Search Engines Assignment (Vector Space Model)

This assignment was done as a part of the Ryerson Search Engines Course (CPS842). 
The engine implements the Vector Space Model and searches the CACM document collection (obtained at http://ir.dcs.gla.ac.uk/resources/test_collections/cacm/ ).

For assignment details, read 'assignment.txt'

---------------------------------------------------

Details:
    Postings lists are ordered by document id.
    The search results returned by search include all relevant results (where cosine similarity > 0).
    The output in a2.rb is however limited to the top 25 results.
    The output file out.txt contais a more detailed, full list of search results from the last run of a2.rb.
    
    Standard TD-IDF weighting scheme used:
        w_doc = tf * idf = ( 1+log(f) ) * ( N/df )
        w_q   = ( 1+log(f) )
        


This assignement includes the following program files:

 - invert.rb        (run to generate inverted index)
 - a2.rb            (ui to perform searches using the vector space model)
 - eval.rb          (runs queries from query.text and compares with results from qrels.text)
 - search.rb        (library containing the implementation of the vector space model)
 - dictionary.rb    (library used by ruby programs)
 - stemmify.rb      (library used for stemming terms)
 
 
Running programs:

    invert.rb
        >> Usage: ruby invert.rb <document input file name> [-stem] [-stopwords]
        >> Generates 'index' and 'doc_info' data files

    a2.rb
        >> Usage: ruby a2.rb [-stem] [-stopwords]
        >> Enter 'ZZEND' to exit program
        
    eval.rb
        >> Usage: ruby eval.rb [-stem] [-stopwords]
        
    NOTE: Add optional flags '-stem' and '-stopwords' to turn stemming and/or stopword removal ON.
          Make sure to use the same flags for running programs as used for generating the index.
          The index is created based on stemming and stopwords and won't be compatible otherwise.

Generated files:
 
    index
        > generated by running invert.rb        
        > serialized inverted index
        
    doc_info
        > generated by running invert.rb 
        > serialized document information for caching
        > needed for information display in a2.rb
        
 
Used CACM files: 

    cacm.all
        > used as a document input for inverted index
        > contains a collection of documents and document data
        
    common_words
        > required when using the '-stopwords' flag
        > contains list of stopwords to drop from index and queries
        
    query.text
        > used by eval.rb
        > contains a list of queries that are ran through search.rb
        
    qrels.text
        > used by eval.rb
        > contains a list of relevant results for queries from query.text
        
        
Other files:
 - sample.txt   (contains a sample run of the search program)      
 - eval.txt     (contains the output from running eval.rb)
 - out.txt      (output file generated by running a2.rb, containing more detailed information about query results)
 