//class for Committee Hearings & Agenda Matters

class Events {
  String eventDate, eventName;
  String[] matterFiles;
  int eventID;
  
  
  Events(int tID, String tDate, String tName){
    this.eventID = tID;
    this.eventDate = tDate;
    this.eventName = tName;
    matterFiles = new String[0];
  }
  
  void getEventMatters(){
    //request all EventItems on EventID
    
    try{
      
      String eMattersURL = "https://webapi.legistar.com/v1/nyc/Events/" +this.eventID+ "/EventItems?token=" +token;
      JSONArray eMattersJSON;
      
      eMattersJSON = loadJSONArray(eMattersURL);
      
      for (int i=0; i< eMattersJSON.size(); i++) {
        JSONObject eMatterItem = eMattersJSON.getJSONObject(i);
        if(eMatterItem.isNull("EventItemMatterFile") == false){
          matterFiles = append(this.matterFiles, eMatterItem.getString("EventItemMatterFile"));
        }
        
      }
      
      
    } catch(Exception e){
      println("Error in getEventMatters(): " +e);
    }
  }
  
  void printEvent(){
    println("---------------------");
    println("EventID: " +this.eventID+ "; EventDate: " +this.eventDate+ "; EventName: " +this.eventName);
    if(this.matterFiles.length > 0) printArray(this.matterFiles);
    println("---------------------");
  }
  
}
