//NYC Council Legislation Tracker
//Monitors relevant NYC Council Legislative Items for changes and alerts user
//requires manually inputting filename of bill (e.g. Int 0487-2018) in NYC_LegislationList.csv
//Daniel Schwarz, 2018


String fileName = "NYC_LegislationList.csv";
boolean change = false;
boolean scheduled = false;
String[] changeList;
Table table;
Matters[] m;
Events[] events;
String date;
String disp = "";
String[] log;
int len = 0;
float yStart = 50;
PFont hFont, bFont;
int rowNo = 0;
boolean[] dispLine = new boolean[100];

//add your API token here:
String token = "put-your-token here";

void setup() {
  size(170, 100);
  background(0);
  bFont = createFont("font/Roboto-Regular.ttf", 16);
  textFont(bFont, 12);
  text("loading resources...", 20, 50);
  hFont = createFont("font/Roboto-Bold.ttf", 24);
  surface.setResizable(true);
  date = year() + nf(month(), 2) + nf(day(), 2);
  

  //check internet connection
  try {
    //open log
    log = loadStrings("data/log.txt");
    if(log.length>0){
      len = log.length;
    }
    
    table = loadTable(fileName, "header");
    println(table.getRowCount() + " total items in " +fileName);

    //init and populate Objects
    m = new Matters[table.getRowCount()];
    int i = 0;
    for (TableRow row : table.rows()) {


      println("------------ Row: " +i+ " ------------");
      m[i] = new Matters();
      m[i].matterFile = row.getString("MatterFile");
      if (int(row.getString("MatterID"))!=0) {
        m[i].matterID = int(row.getString("MatterID"));
        m[i].matterName = row.getString("MatterName");
        m[i].introductionDate = row.getString("IntroductionDate");
        m[i].version = row.getString("Version");
        m[i].sponsorCount = row.getInt("SponsorCount");
        m[i].sponsors = row.getString("Sponsors");
        m[i].actionCount = row.getInt("ActionCount");
        m[i].actions = row.getString("Actions");
        m[i].lastChange = row.getString("LastChangeDate");
        m[i].changeDetail = row.getString("LastChangeDetail");
      } else {
        m[i].checkComplete();
      }

      //update all matters & check for changes
      m[i].update();

      i++;
    }
    
    
    //get Committee schedules
    getCurEvents();
    
    refMattersEvents();
    
    if(scheduled){
      println("------scheduled------");
      surface.setSize(1200, 800);
    }
    if (change) {
      println("------changed------");
      surface.setSize(1200, 800);
      //save copy of old csv with priorDate appended to filename
      String savePrior = fileName.substring(0, fileName.length()-4) + "_pre" + str(year()) + nf(month(), 2) + nf(day(), 2) +".csv";
      saveTable(table, "data/" + savePrior);

      //updating table
      i = 0;
      for (TableRow row : table.rows()) {
        row.setString("MatterFile", m[i].matterFile);
        row.setInt("MatterID", m[i].matterID);
        row.setString("MatterName", m[i].matterName);
        row.setString("IntroductionDate", m[i].introductionDate);
        row.setString("Version", m[i].version);
        row.setInt("SponsorCount", m[i].sponsorCount);
        row.setString("Sponsors", m[i].sponsors);
        row.setInt("ActionCount", m[i].actionCount);
        row.setString("Actions", m[i].actions);
        row.setString("LastChangeDate", m[i].lastChange);
        row.setString("LastChangeDetail", m[i].changeDetail);
        i++;
      }

      //save csv with current data
      saveTable(table, "data/" + fileName);

      //save updates to append-only log (.txt)
      saveStrings("data/log.txt", log);
    }
    
  } 
  catch(Exception e) {
    println("Error on csv handling");
  }
  
  textSize(16);
  fill(0);
  
  if (change || scheduled) {
    for(int i = len; i<log.length; i++){
        disp = disp + i +" - " +log[i] + "\n";
        dispLine[rowNo] = true;
        rowNo += 1 + int(textWidth(i +" - " +log[i])/(width-100));
        //row numbers
    }
    
  }
}



void draw() {
  background(255);
  
  if (change || scheduled) {
    //for(int i = len; i<log.length; i++){
    //  text(i+" - " +log[i], 50, 50+(i-len)*25, width*.75, 25);
    //}
    for(int i = 0; i<rowNo; i++){
      if(dispLine[i]){
        line(0, yStart+40 + i*25 -3, width, yStart+40 + i*25 -3);
      }
    }
    
    textFont(hFont, 24);
    text("NYC Legislation Tracker - Changelog:", 50, yStart);
    textFont(bFont, 16);
    textLeading(25);
    text(disp, 50, yStart+40, width-100, height*3);
    
  } else {
    println("no change, exiting");
    exit();
  }

}


void getCurEvents() {
  String eventsURL = "https://webapi.legistar.com/v1/nyc/events?$filter=EventDate+ge+datetime%27" +year()+ "-" +nf(month(), 2)+ "-" +nf(day(), 2)+ "%27+and+EventDate+lt+datetime%27" +(year()+1) + "-" +nf(month(), 2)+ "-" +nf(day(), 2)+ "%27&token=" +token;
  JSONArray eventsJSON;

  eventsJSON = loadJSONArray(eventsURL);
  events = new Events[eventsJSON.size()];
  for (int i=0; i< eventsJSON.size(); i++) {
    JSONObject eventItem = eventsJSON.getJSONObject(i);
    events[i] = new Events(eventItem.getInt("EventId"), eventItem.getString("EventDate"), eventItem.getString("EventBodyName"));
    
    events[i].getEventMatters();
    
    //events[i].printEvent();
  }

}

void refMattersEvents(){
  //compare all events[i].matterFiles[j] with all m[k].matterFile
  
  for(int i=0; i<events.length; i++){
    
    for(int j=0; j<events[i].matterFiles.length; j++){

      for(int k=0; k<m.length; k++){
        //println("comparing " +events[i].matterFiles[j]+ " with " +m[k].matterFile);
        
        if(events[i].matterFiles[j].indexOf(m[k].matterFile)!=-1){
          scheduled = true;
          println("Scheduled Hearing at Committee: "+events[i].eventName+ " on " +events[i].eventDate+ " for: " +m[k].matterFile);
          log = append(log, date+ ": " +m[k].matterFile+ " is scheduled at Committee: " +events[i].eventName+ " on " +events[i].eventDate);
        }
        
      }
    }
  }
  
}

void keyReleased(){
  if(key==CODED){
    if(keyCode == UP){
      if(yStart <= 25){
        yStart += 25;
      } else {
        yStart = 50;
      }
    } else if(keyCode == DOWN){
      if(yStart+40+rowNo*25 >= height*.25){
        yStart -= 25;
      }
    } else if(keyCode == LEFT){
      yStart = 50;
    }
  }  
}

void mouseWheel(MouseEvent event) {
  if(yStart+40+rowNo*25 >= height*.25){
    yStart -= event.getCount()*25;
  }
  if(yStart > 25){
    yStart = 50;
  } else if( yStart+40+rowNo*25 < height*.25){
    yStart = height*.25 -(40+rowNo*25);
  }
}
