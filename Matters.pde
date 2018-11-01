//class for Legislative Items


class Matters {
  String matterFile, matterName;
  int matterID, sponsorCount, actionCount;
  String introductionDate, version, sponsors, actions, lastChange, changeDetail;
  String url;
  boolean changeObj = false;

  JSONArray json;



  boolean checkComplete() {
    if (matterID==0) {
      println("Matter: " +this.matterFile+ " is incomplete, requesting ID from Legistar.");
      this.getMatterID();
      return false;
    } else {
      return true;
    }
  }



  void getMatterID() {
    try {
      println("requesting ID");
      this.url = "https://webapi.legistar.com/v1/nyc/matters?$filter=MatterFile+eq+%27" +this.matterFile.replace(" ", "%20")+ "%27&token=" +token;

      this.json = loadJSONArray(this.url);
      if (this.json.size()!=1) {
        println("Erroneous request; MatterFile " +this.matterFile+ " returned " +this.json.size()+ " items."); //write this to log
        log = append(log, date+ ": Erroneous request; MatterFile " +this.matterFile+ " returned " +this.json.size()+ " items.");
        //exit();
      }
      for (int i=0; i< this.json.size(); i++) {
        JSONObject legItem = json.getJSONObject(i);
        this.matterID = legItem.getInt("MatterId");
        this.matterName = legItem.getString("MatterName");
        this.introductionDate = legItem.getString("MatterIntroDate");
        this.version = legItem.getString("MatterVersion");
        this.lastChange = legItem.getString("MatterLastModifiedUtc");
        this.sponsors = ""; //declare empty
        this.actions = ""; //declare empty
      }
      println("MatterID: " +this.matterID+ "; MatterName: " +this.matterName+ "; IntroDate: " +this.introductionDate+ "; Version: " +this.version+ "; last modified: " +this.lastChange );
    } 
    catch (Exception e) {
      println("Error in getMatterID: " +e);
    }
  }



  void update() {
    println("updating fields");
    this.getMatterInfo();
    this.getSponsors();
    this.getActions();
  }



  void getMatterInfo() {

    this.url = "https://webapi.legistar.com/v1/nyc/matters?$filter=MatterFile+eq+%27" +this.matterFile.replace(" ", "%20")+ "%27&token=" +token;
    try {
      this.json = loadJSONArray(this.url);
      if (this.json.size()!=1) {
        println("Erroneous request [getMatterInfo()]; MatterFile " +this.matterFile+ " returned " +this.json.size()+ " items."); //write this to log
        log = append(log, date+ ": Erroneous request [getMatterInfo()]; MatterFile " +this.matterFile+ " returned " +this.json.size()+ " items.");
        //exit();
      }
      for (int i=0; i< this.json.size(); i++) {
        JSONObject legItem = json.getJSONObject(i);

        if (this.matterID != legItem.getInt("MatterId")) {
          println("___ Error: MatterID changed from " +this.matterID+ " to " +legItem.getInt("MatterId")); ////write this to log
          log = append(log, date+ ": ___ Error: MatterID changed from " +this.matterID+ " to " +legItem.getInt("MatterId"));
          this.matterID = legItem.getInt("MatterId");
          change = true;
        }
        if (!this.matterName.equals(legItem.getString("MatterName"))) {
          println("MatterName changed from " +this.matterName+ " to " +legItem.getString("MatterName")); ////write this to log
          log = append(log, date+ ": MatterName changed from \"" +this.matterName+ "\" to \"" +legItem.getString("MatterName")+"\"");
          this.matterName = legItem.getString("MatterName");
          change = true;
        }
        if (!this.introductionDate.equals(legItem.getString("MatterIntroDate"))) {
          println("___ Error: IntroductionDate changed from " +this.introductionDate+ " to " +legItem.getString("MatterIntroDate")); ////write this to log
          log = append(log, date+ ": " +this.matterFile+ " ___ Error: IntroductionDate changed from " +this.introductionDate+ " to " +legItem.getString("MatterIntroDate"));
          this.introductionDate = legItem.getString("MatterIntroDate");
          change = true;
        }
        if (!this.version.equals(legItem.getString("MatterVersion"))) {
          println("Version changed from " +this.version+ " to " +legItem.getString("MatterVersion")); ////write this to log
          log = append(log, date+ ": " +this.matterFile+ " Version changed from " +this.version+ " to " +legItem.getString("MatterVersion"));
          this.version = legItem.getString("MatterVersion");
          change = true;
        }
        if (!this.lastChange.equals(legItem.getString("MatterLastModifiedUtc"))) {
          println("LastChange changed from " +this.lastChange+ " to " +legItem.getString("MatterLastModifiedUtc")); ////write this to log
          log = append(log, date+ ": " +this.matterFile+ " LastChange changed from " +this.lastChange+ " to " +legItem.getString("MatterLastModifiedUtc"));
          this.lastChange = legItem.getString("MatterLastModifiedUtc");
          change = true;
        }
      }
      println("MatterID: " +this.matterID+ "; MatterName: " +this.matterName+ "; IntroDate: " +this.introductionDate+ "; Version: " +this.version+ "; last modified: " +this.lastChange );
    } 
    catch (Exception e) {
      println("Error in getMatterInfo: " +e);
    }
  }



  void getSponsors() {
    //get all Sponsors and count

    this.url = "https://webapi.legistar.com/v1/nyc/matters/" +this.matterID+ "/Sponsors?token=" +token;
    try {
      this.json = loadJSONArray(this.url);

      String names = "";
      int counter = 0;

      for (int i=json.size()-1; i>=0; i--) { //reverse for correct order
        JSONObject legSponsors = this.json.getJSONObject(i);
        if (legSponsors.getString("MatterSponsorName").indexOf("(by request of")==-1 && legSponsors.getString("MatterSponsorName").indexOf("in conjunction")==-1) {
          if (names.equals("")) {
            names = legSponsors.getString("MatterSponsorName");
          } else {
            names = names+ "; " +legSponsors.getString("MatterSponsorName");
          }
          counter++;
        }
      }

      //check for changes
      if (this.sponsorCount!=counter) {
        println("Prior sponsor count was " +this.sponsorCount+ "; new sponsor count is: " +counter); //Todo: write to log
        log = append(log, date+ ": " +this.matterFile+ " Prior sponsor count was " +this.sponsorCount+ "; new sponsor count is: " +counter);
        this.sponsorCount = counter;
        change = true;
      }
      if (!sponsors.equals(names)) {
        println("Prior sponsors were " +this.sponsors+ "; new sponsors are: " +names); //Todo: write to log
        log = append(log, date+ ": " +this.matterFile+ " Prior sponsors were " +this.sponsors+ "; new sponsors are: " +names);
        this.sponsors = names;
        change = true;
      }
    } 
    catch (Exception e) {
      println("Error in getSponsors(): " +e);
    }
  }


  void getActions() {
    //get all Actions

    this.url = "https://webapi.legistar.com/v1/nyc/matters/" +this.matterID+ "/Histories?token=" +token;
    try {
      this.json = loadJSONArray(this.url);

      String allActions = "";
      int counter = 0;

      for (int i=0; i<json.size(); i++) {
        JSONObject legActions = this.json.getJSONObject(i);

        if (allActions.equals("")) {
          allActions = legActions.getString("MatterHistoryActionDate") +": "+ legActions.getString("MatterHistoryActionName");
        } else {
          allActions = allActions+ "; " +legActions.getString("MatterHistoryActionDate") +": "+ legActions.getString("MatterHistoryActionName");
        }
        counter++;
      }

      //check for changes
      if (this.actionCount!=counter) {
        println("Prior action count was " +this.actionCount+ "; new action count is: " +counter); //Todo: write to log
        log = append(log, date+ ": " +this.matterFile+ " Prior action count was " +this.actionCount+ "; new action count is: " +counter);
        this.actionCount = counter;
        change = true;
      }
      if (!this.actions.equals(allActions)) {
        println("Prior actions were " +this.actions+ "; new actions are: " +allActions); //Todo: write to log
        log = append(log, date+ ": " +this.matterFile+ " Prior actions were " +this.actions+ "; new actions are: " +allActions);
        this.actions = allActions;
        change = true;
      }
    }
    catch (Exception e) {
      println("Error in getActions(): " +e);
    }
  }
}
