require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'json'
require 'google_drive'
require 'csv'

class Scrapper

 @@page_mairie_arronville = Nokogiri::HTML(open('http://annuaire-des-mairies.com/95/arronville.html'))
 @@annuaire_valdoise = Nokogiri::HTML(open('http://annuaire-des-mairies.com/val-d-oise.html'))

 def get_townhall_email(townhall_url)
   return townhall_url.xpath('/html/body/div/main/section[2]/div/table/tbody/tr[4]/td[2]').text
 end

 def get_townhall_name(annuaire)
     town_list =[]
     annuaire.xpath('//p/a').each do |el|
     town_list << el.text
     end
     return town_list
 end

 def get_townhall_url(annuaire)
   town_list_url =[]
   annuaire.xpath('//p/a').each do |el|
   url = "https://www.annuaire-des-mairies.com#{el.attr('href')[1..-1]}"
   town_list_url << url
   end
   return town_list_url
 end

 def get_town_list_mail(annuaire)
   puts "Pose toi, notre scribe est entrain de tout scraper à la main..."
   town_list_mail =[]
   get_townhall_url(annuaire).each do |e|
     adr = Nokogiri::HTML(open(e))
     mail = adr.xpath('/html/body/div/main/section[2]/div/table/tbody/tr[4]/td[2]').text
     town_list_mail << mail
   end
   return town_list_mail
 end

 def get_city_email_final(annuaire)
 town_with_mail = get_townhall_name(annuaire).zip(get_town_list_mail(annuaire))
 final_array = []
   town_with_mail.each do |e|
       final_array << {e[0] => e[1]}
   end
   return final_array
 end

 # Save as a text format
 def save_as_JSON(array)
   final_array = array
   File.open("db/emails.json", "w") do |town|
   town.write(final_array.to_json)
   end
 end

 # Scrap emails with in Google API
 def save_as_spreedsheet(array)

   session = GoogleDrive::Session.from_config("config.json")
   ws = session.spreadsheet_by_key("1jCyeGCeITqEWCu5r4NaTE8TxD0WHa9PNwuY93XP_Y2w").worksheets[0]

   final_array = array

   ws[1, 1] = "Nom des Villes"
   ws[1, 2] = "Emails des Villes"

   row = 3
   final_array.each do |x|
   ws[row, 1] = x.keys.join
   ws[row, 2] = x.values.join
   row += 1
   end

   # Cannot load change without it
   ws.save
   ws.reload
   end

 # Scrap in a .csv file
 def save_as_csv(array)
   final_array = array
   CSV.open("db/emails.csv", "w") do |csv|
   csv << ["Nom des Mairies", "Emails des Mairies"]
   final_array.each do |x|

   csv << [x.keys.join, x.values.join]
     end
   end
 end

 def perform
   puts "Salut, sous quel format veux tu scrapper les addresses Emails ? (entre seulement le chiffre"

   puts "1: Format JSON"
   puts "2: Google Spreadsheet"
   puts "3: Format CSV"
   puts "4: Je ne souhaite pas prendre les emails de ces honnêtes citoyens"
   print "> "

   good_choice = "\nTrès bon choix ! \n ------------"
   excel = "\nTu utilises encore Excel !? Considères toi chanceux pour aujourd'hui"
   ending = " ------------ \n Scrapping Terminé"

   choice = gets.chomp.to_i

   if choice == 1
     puts good_choice
     save_as_JSON(get_city_email_final(@@annuaire_valdoise))
     puts ending

   elsif choice == 2
     puts good_choice
     save_as_spreedsheet(get_city_email_final(@@annuaire_valdoise))
     puts ending

   elsif choice == 3
     puts excel
     save_as_csv(get_city_email_final(@@annuaire_valdoise))
     puts ending

   else
     puts "You lose..."
   end

 end
end
