module Castanaut; module Plugin

  ##
  # Contributed by Geoffrey Grosenbach
  # http://peepcode.com
  
  module Textmate

    ##
    # Types text into TextMate all at once.
    #
    # The as_snippet option is documented but doesn't seem to do anything.
    
    def tm_insert_text(text, as_snippet=false)
      escaped_text = text.gsub(/"/, '\"')
      snippet_directive = (as_snippet ? "with as snippet" : "")
      
      execute_applescript(%Q`
        tell application "TextMate"
          insert "#{escaped_text}" #{snippet_directive}
        end
      `)
    end

    ##
    # Open a file, optionally at a specific line and column.
    
    def tm_get_url(file_path, line=0, column=0)
      full_url = "txmt://open?url=file://#{file_path}&line=#{line}&column=#{column}"
      execute_applescript(%Q`
        tell application "TextMate"
          get url "#{full_url}"
        end
      `)
    end
        
  end

end; end
