require 'scraperwiki'
require 'nokogiri'
require 'uri'
require 'cgi'
require 'open-uri'

class ElsevierJournal
    def initialize(title,kb_uri)
        @kb_uri = kb_uri
        @editorial_board = []
    end
    
    attr_reader :title, :kb_uri
    attr_accessor :about_uri, :editorial_uri, :editorial_board

    def getAboutUri
      about = Nokogiri::XML(open(@kb_uri))
      @about_uri = about.xpath('//a[contains(text(), "About this Journal")]/@href').inner_text
    end

    def getEditorialUri
      editorial = Nokogiri::HTML(open(@about_uri))
      @editorial_uri = editorial.xpath('//a[contains(text(), "View full editorial board")]/@href').inner_text
    end
    
    def getEditorialBoard
      board = Nokogiri::HTML(open(@editorial_uri))
      name = ""
      affilation = ""
      role = ""
      board.xpath('//div[@class="contentCol"]/div[@class="pod"]/div').each do |section|
        section_class = section.xpath('@class').inner_text
        if(section_class=="infoText")
          role = section.inner_text
          next
        elsif(section_class=="podArticle")
          name = section.xpath('h3/span').inner_text
          affiliation = section.xpath('p/span').inner_text
        else
          next
        end
        @editorial_board.push(EditorPerson.new(name,affiliation,role))
      end
    end

end

class EditorPerson
	def initialize(name,affiliation,role)
		@name = name
		@affiliation = affiliation
		@role = role
	end

	attr_reader :name, :affiliation, :role
end

ej = ElsevierJournal.new("Academic Pediatrics","http://www.sciencedirect.com/science/journal/18762859")
ej.getAboutUri
puts ej.about_uri
ej.getEditorialUri
puts ej.editorial_uri
ej.getEditorialBoard

#elsevier_master_uri = "https://www.kbplus.ac.uk/kbplus/publicExport/pkg/512?format=json"
#elsevier_master_json = open(elsevier_master_uri)

#elsevier_master = JSON.parse(File.read(elsevier_master_json))

#elsevier_master["titles"].each do |t|
#	publication_title = t["title"].chomp
#	publication_uri = t["hostPlatformURL"].chomp
#  ej = ElsevierJournal.new(publication_title,publication_uri)
#  ej.getEditorialBoard
  ej.editorial_board.each do |p|
    record = {
      'journal_title' => publication_title,
      'journal_uri' => publication_uri,
      'name' => p.name,
      'affiliation' => p.affiliation,
      'role' => p.role
    }
    ScraperWiki.save_sqlite(unique_keys=['journal_title','journal_uri','name','affiliation','role'],record)
    sleep 1
  end
#end