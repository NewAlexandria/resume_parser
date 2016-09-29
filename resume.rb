require 'doc_ripper'
require 'open3'
require 'yomu'

class Resume
  def email_rx
    /([a-zA-Z0-9\-.+]*\@[^.]*\.)(com|org|net)/
  end
  # /[^@]+@([^@\.]+\.)+[^@\.]+/

  def email_rx_more
    /(|(([A-Za-z0-9]+_+)|([A-Za-z0-9]+\-+)|([A-Za-z0-9]+\.+)|([A-Za-z0-9]+\++))*[A-Za-z0-9]+@((\w+\-+)|(\w+\.))*\w{1,63}\.[a-zA-Z]{2,6})/i
  end

  def phone_rx
    /^\(*\d{3}\)*( |-)*\d{3}( |-)*\d{4}$/
  end

  # https://blog.codinghorror.com/regex-use-vs-regex-abuse/
  def initialize(base='./')
    @base = base
  end

  def all
    @all ||= Dir.
      entries(@base).
      grep(/^[^.]/).
      map do |f|
        case f.split(".").last
        when 'docx'
          res = extract(:docx, f)
          res = extract(:docrip, f) unless res.to_s.match(email_rx)
          res
        when 'rtf'
          extract(:rtf, f)
        else
          puts "ERR: didn't recognize extension of '#{f}'"
        end
      end
  end

  def extract(kind, filename)
    send("#{kind}_extract", filename)
  end


  def rtf_extract(filename)
    text = Yomu.read(:text, File.read(@base+filename))
  end

  def docrip_extract(filename)
    puts "trying DocRipper: #{filename}"
    text = DocRipper::rip(@base+filename)
  end

  def docx_extract(filename)
    cmds = [
      ["unzip", '-p', @base+filename, "word/document.xml"],
      ["sed", "-e" 's/<[^>]\{1,\}>/ /g; s/[^[:print:]]\{1,\}//g']
    ]
    data = ""
    Open3.pipeline_r(*cmds) do |o, ps|
      data = o.readlines
    end
    return data
  end
end

