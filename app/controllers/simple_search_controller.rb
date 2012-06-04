class SimpleSearchController < ApplicationController
  #def search
    #search_string = params[:searchfor]
    #search_op = SimpleSearchOperation.new(search_string)
    #search_op.do_search
    #@view_data = search_op.view_data
    #@user = User.find(session[:user_id])
  #end

  def show
    @friends = User.find(session[:user_id])
  end

  def search
  
    search_string = params[:searchfor]
    search_lists = Array.new
    tag_lists = Array.new

    params.each do |parameter|
       #param_str = parameter.to_s
       #seems that parameter[0] contains the key, in this case "list.id", where id is some number
       #so we can just parse that
       print parameter[0]
       print "\n"
       if parameter[0][0,5] == "list."
         search_lists.push(parameter[0].split(".")[1].to_s)
       end
       if parameter[0][0,4] == "tag."
         tag_lists.push(parameter[0].split(".")[1].to_s)
       end
    end



    search_lists.each do |list|
      print "Looking at lists"
      print "\n"
      print list
    end

    #search list now contains list of list ids and tag_ids to search over and search_string contains the search text
    
    #initialize searchResult = null
    searchResult = Array.new
    actualSearchResult = Array.new
    simpleSearch = false
      
    #store simple search result on search_string
    simpleSearchResult = Store.where("name like ?  or detail_info like ?", "%" + search_string + "%", "%" + search_string + "%").select("id").all
    
    #print "Printing simpleSearchResult \n"    
    #simpleSearchResult.each do |store|
    #    print store.id
    #    print "\n"
    #end
    
    if(search_lists == []  && tag_lists == [])
      simpleSearch = true
    end
    
    if simpleSearch == false
    
          #get a list of stores that belong to any of the lists in search_lists
          search_lists.each do |list|
            listresult = ListStore.find(:all, :conditions => {:list_id => list })
            listresult.each do |store|
              searchResult.push(store)
            end
          end
          
          #remove duplicates
          searchResult = searchResult.uniq
          
          #print "Printing searchResults : \n"          
          #searchResult.each do |st|
          #    print st.store_id
          #    print "\n"
          #end
          
          
          deleteSearchResult = Array.new
          
          #for each store in searchResult, 
          #remove a store if there is no tag associated and 
          #search_string is not found either in store_name or in store_description   
          searchResult.each do |store|
            #print "Checking for store "+ store.store_id.to_s + "\n"
         
            flag = false
         
            # flag = true if some (search) tag is associated with the store   
            tag_lists.each do |tag|
              if  StoresTags.exists?(:store_id => store.store_id, :tag_id => tag_id)
                #print "flag turned true for " + store.store_id.to_s + " and " + tag_id.to_s + "\n"
                flag = true
              end
            end
            
            # flag = true if the store exists on search result of simple search query on search_string
            simpleSearchResult.each do |st|
              if st.id == store.store_id
                #print "flag turned true for " + store.store_id.to_s + " for simpleSearch \n"
                flag = true
              end
            end
            
            # if flag is still false remove store from searchResult
            if flag == false
              #print "deleting store with id = " + store.store_id.to_s + "\n"
              deleteSearchResult.push(store)  
            end
          end
          
          searchResult = searchResult - deleteSearchResult
          
          searchResult.each do |liststoreobject|
            store = Store.find_by_id(liststoreobject.store_id)
            actualSearchResult.push(store)
          end

    else    
          simpleSearchResult.each do |store|
            store = Store.find_by_id(store)
            actualSearchResult.push(store)
          end      
    end

    #print "Printing actual search results \n"
    #actualSearchResult.each do |store|
    #  print store.id
    #  print "\n"
    #end

    #return searchResults
    @view_data = actualSearchResult
    @lists = search_lists
    render 'simple_search/search'
  end

  #renders Advanced Search bar with user's friends lists in container
  def search_advanced
    puts 'IN SEARCH_ADVANCED #####'
    @friends = getFriendsList(session[:access_token]) #mock friends (actually just users in the database)
   #@friends = User.find(:all)
    render :partial=>"simple_search/advanced_search_bar", :locals=>{ :friends=>@friends }  
  end
  
  #Retrieves friend's lists when selected
  def get_list
    @friend = User.find(params[:friend_id].split(".")[1])
    @list = List.find_users_lists(@friend.id)
    render :partial=>"simple_search/list_selection", :collection => @list, :locals => { :friend => @friend }
  end
  
  #Uses FB API to retrieve friends list
  def approve_tag
    #check to see if params[:tag_value] matches any tag that is in the database
    #if matches, return tag object.
    if Tag.exists?(:name => params[:tag_value])
      @tag = Tag.where(:name => params[:tag_value]).first
    else
      @tag = nil
    end
    #if tag does not exist, don't return a tag. 
    render :partial=>'simple_search/approved_tag', :locals => { :tag => @tag }
  end 

  def getFriendsList(access_token)
    user = FbGraph::User.me(access_token)
    user = user.fetch
    friends_list = user.friends
    @friends = Array.new
    
    friends_list.each do |friend|
      if User.exists?(:fb_id => friend.identifier)
        user = User.where(:fb_id => friend.identifier).first
        @friends.push(user)
      end
    end
   
    @friends
  end
end