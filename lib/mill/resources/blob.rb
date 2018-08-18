module Mill

  class Resource

    class Blob < Resource

      FileTypes = %w{
        application/pdf

        application/zip

        application/ecmascript
        application/javascript
        text/ecmascript
        text/javascript
        application/x-javascript

        font/otf
        application/font-sfnt
        application/x-font-opentype
        application/x-font-otf

        application/mp4
        audio/mp4
        video/mp4
        video/vnd.objectvideo
        video/quicktime

        application/msword
        application/word
        application/x-msword
        application/x-word
        application/vnd.ms-powerpoint
        application/powerpoint
      }

    end

  end

end