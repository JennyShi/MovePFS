=begin
  
Author: Junyi Shi
Version: 1.0
Organization: EMC Corporation
Date Created: 11/18/2013.

Description: This is a simple script for moving PFS from one project to the component team. Input is csv file.
  
=end

require 'rally_api_emc_sso' 
require 'csv'

if ARGV.size != 1
  puts "usage: ruby #{__FILE__} <fileName>" 
  exit
end

headers = RallyAPI::CustomHttpHeader.new()
headers.name = 'My Utility'
headers.vendor = 'MyCompany'
headers.version = '1.0'


#==================== Making a connection to Rally ====================
config = {:workspace => "Workspace 1"}
config[:project] = "Jenny-test"
config[:headers] = headers #from RallyAPI::CustomHttpHeader.new()

@rally = RallyAPI::RallyRestJson.new(config)

#check http://developer.help.rallydev.com/ruby-toolkit-rally-rest-api-json 
#use the example on this page from "Querying Rally" 

def start
  file_name = ARGV[0]
  puts "file_name: #{file_name}"
  
  input = CSV.read(file_name)

  header = input.first
    #puts header
  rows = []
  (1...input.size).each { |i| rows << CSV::Row.new(header, input[i]) }
  
  @FeatureCount = 0 #@iCount = 0 or rows.length-1
    while @FeatureCount<rows.length #@iCount<rows.length or @iCount> 0
      if(input[@FeatureCount]!= nil)
        puts rows[@FeatureCount]
        manage_userStory(rows[@FeatureCount])
      end
      @FeatureCount += 1
    end
end
        
def manage_userStory(row)
   
  puts "Managing feature #{@FeatureCount}"
  puts "\n"
  
  feature_id = row["Formatted ID"]
  puts feature_id

  feature = find_feature(feature_id)
 
  if (feature != nil)
    feature.each do |res|
      res.read
      componentTeam = res.ComponentTeam
      directChildrenCount = res.DirectChildrenCount

     if(componentTeam != nil)
        result = find_componentTeam(componentTeam)
        #puts result
        @project = result.first
        puts @project["_ref"]
        
        @iCount = 0
      
        res.UserStories.results.each{|story|
          story.read
          puts story._ref
          puts story.ObjectID
       
          result = find_UserStory("#{story.ObjectID}")
          userStory_id = result.first.FormattedID
          update_UserStory(userStory_id)
          @iCount += 1
        }
      end
    end
   
  end    

end

def find_feature(feature_id) 
  query = RallyAPI::RallyQuery.new()
  query.type = "portfolioitem/feature"
   
  query.fetch = "FormattedID"
  #query.project_scope_up = true
  #query.project_scope_down = true
  query.order = "FormattedID Asc"
  query.query_string = "(FormattedID = \"#{feature_id}\")"


  results = @rally.find(query)
#results = @rally.find(RallyAPI::RallyQuery.new({:type => :story,:query_string => "(Project = \"Completed\")" && "(FormattedID = US419)"}))
 # @feature = results.first

  if(results != nil)
    results.each do |h|
      h.read
      #puts h.inspect
      puts "FeatureID: #{h.FormattedID}"
      #puts h.Project
      puts "ComponentTeam #{h.ComponentTeam}"
      puts "DirectChildrenCount: #{h.DirectChildrenCount}"
      #puts h.UserStories.results
      #puts @userstory["ref"]
    end
  else
    puts "No such feature #{feature_id}"
  end
  results
end

def find_componentTeam(team_name)
  query = RallyAPI::RallyQuery.new()
  query.type = :project
  query.fetch = "Name"
  query.query_string = "(Name = \"#{team_name}\")"
  result = @rally.find(query)

  if(result.length != 0)
    puts "Find the team #{team_name}"
    puts "\n"
  else 
    puts "team #{team_name} not found"
    #exit
  end
  result
end 

def find_UserStory(userStory)
  #puts userStory
  query = RallyAPI::RallyQuery.new()
  query.type = "story"
  query.fetch = "Name,FormattedID,Children,DirectChildrenCount"
  query.query_string = "(ObjectID = \"#{userStory}\")"
  results = @rally.find(query)
  
 # result.first.read
 # puts result.first.read.Children.size
  
  if (results.length != 0)
    #puts result.FormattedID
  
    results.each{|res|
      res.read
      #puts res.inspect
      puts "Find #{res.FormattedID}"
      puts "Children number: #{res.Children.size}"
      #puts res.Childern
=begin
  if (res.Children != nil)
        
        #update_UserStory(@scopingTeam,res.FormattedID)
        
        res.Children.results.each{|c|
          c.read
          
          result = find_UserStory("#{c.ObjectID}")
          userStory_id = result.first.FormattedID
          update_UserStory(userStory_id)
          @iCount += 1
        }
         end
=end     
        #puts res.Children.results
        #find_UserStory(res.Children)
      #else
      #  return results
     
   }
   else
      puts "No such user story #{userStory}"
  end
  results
end

def update_UserStory(userStory_id)
  puts "Copying #{@iCount}..."
  #puts userStory_id
 # puts scopingTeam.class
  #puts scopingTeam
  field = {}
  field["Project"] = @project["_ref"]
  
  @rally.update("story","FormattedID|#{userStory_id}",field)
  
  puts "#{userStory_id} updated"
  puts "\n"

end

start