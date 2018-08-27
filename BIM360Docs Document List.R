#######################################################################
## This R script is a sample code that demonstrate how to extract documents' data from a BIM 360 Docs project using Autodesk Forge APIs.
#####################################################################

# Define Forge App Client ID and Secret, BIM 360 Account ID, and Project ID
App_Client_ID <- "Input Autodesk Forge App Client ID here"
App_Client_Secret <- "Input Autodesk Forge App Secret ID here"
BIM360_Account_ID <- "Input Autodesk BIM 360 Account ID here"
BIM360Docs_Project_ID <- "Input Autodesk BIM 360 Docs Project ID here"


#Load libraries required for the R script
library(httr)
library(jsonlite)


#Define a function that loops through BIM 360 Docs folder structure to build a document list 
Parse_Folder <- function(folder_id, folder_name){
  Get_Folder_Content_URL <- paste("https://developer.api.autodesk.com/data/v1/projects/b.",
                                  BIM360Docs_Project_ID,
                                  "/folders/",
                                  folder_id,
                                  "/contents", sep="")
  Get_Folder_Content_Request <- GET(Get_Folder_Content_URL, add_headers("Authorization" = Access_Token))
  Get_Folder_Content_Data <- jsonlite::fromJSON(content(Get_Folder_Content_Request, "text", "application/json", "UTF-8"))
  Folder_Content_Files <- flatten(data.frame(Get_Folder_Content_Data["included"]))
  
  if (nrow(Folder_Content_Files) != 0){
    Folder_Content_Files$document.location <- rep(folder_name, nrow(Folder_Content_Files))
    Folder_Content_Files_SelectedColumns <- as.data.frame(Folder_Content_Files[, c("document.location",
                                                                                   "included.attributes.displayName",
                                                                                   "included.attributes.createUserName",
                                                                                   "included.attributes.createUserId",
                                                                                   "included.attributes.lastModifiedUserName",
                                                                                   "included.attributes.lastModifiedUserId",
                                                                                   "included.attributes.versionNumber",
                                                                                   "included.attributes.fileType",
                                                                                   "included.attributes.extension.type",
                                                                                   "included.attributes.createTime",
                                                                                   "included.attributes.lastModifiedTime"
                                                                                   )])
    
    BIM360Docs_Document_List <- rbind(BIM360Docs_Document_List, Folder_Content_Files_SelectedColumns)
    assign("BIM360Docs_Document_List", BIM360Docs_Document_List, envir = .GlobalEnv)
  }
  
  Folder_Content_Data <- flatten(data.frame(Get_Folder_Content_Data["data"]))
  if (nrow(Folder_Content_Data) != 0){
    for(i in 1:nrow(Folder_Content_Data)){
      if(Folder_Content_Data[i,"data.type"]=="folders"){
        tryCatch({
        Parse_Folder(Folder_Content_Data[i,"data.id"], paste(folder_name, "/", Folder_Content_Data[i,"data.attributes.displayName"], sep=""))
        }, error=function(e){})
      }
    }
  }
}


#Use Forge Authentication API to get access token
App_Authenticate <- POST("https://developer.api.autodesk.com/authentication/v1/authenticate",
                 add_headers("Content-Type" = "application/x-www-form-urlencoded"),
                 body=I(list(client_id = App_Client_ID,
                             client_secret = App_Client_Secret,
                             grant_type = "client_credentials",
                             "scope" = "data:read")),
                 encode = "form")
Access_Token <- paste("Bearer", content(App_Authenticate)$access_token,  sep=" ")


#Use Forge Data Managment API to Access Top Folders in the project
Get_Top_Folders_URL <- paste("https://developer.api.autodesk.com/project/v1/hubs/b.",
                             BIM360_Account_ID,
                             "/projects/b.",
                             BIM360Docs_Project_ID,
                             "/topFolders", sep="")
Get_Top_Folders_Request <- GET(Get_Top_Folders_URL, add_headers("Authorization" = Access_Token))
Get_Top_Folders_Data <- jsonlite::fromJSON(content(Get_Top_Folders_Request, "text", "application/json", "UTF-8"))
TopFolders_Content <- flatten(data.frame(Get_Top_Folders_Data))
BIM360Docs_Document_List <- data.frame(Date=as.Date(character()), File=character(), User=character(), stringsAsFactors=FALSE) 

for(i in 1:nrow(TopFolders_Content)){
  TopFolderName <- TopFolders_Content[i,"data.attributes.displayName"]
  if (TopFolderName != "ProjectTb" && TopFolderName != "Photos" && TopFolderName != "Recycle Bin" ){
    tryCatch({
  Parse_Folder(TopFolders_Content[i,"data.id"], TopFolderName)
    }, error=function(e){})
  }
}

names(BIM360Docs_Document_List)[names(BIM360Docs_Document_List)=="document.location"] <- "Document Location"
names(BIM360Docs_Document_List)[names(BIM360Docs_Document_List)=="included.attributes.displayName"] <- "File Name"
names(BIM360Docs_Document_List)[names(BIM360Docs_Document_List)=="included.attributes.createUserName"] <- "Created by"
names(BIM360Docs_Document_List)[names(BIM360Docs_Document_List)=="included.attributes.createUserId"] <- "Created by (ID)"
names(BIM360Docs_Document_List)[names(BIM360Docs_Document_List)=="included.attributes.lastModifiedUserName"] <- "Updated by"
names(BIM360Docs_Document_List)[names(BIM360Docs_Document_List)=="included.attributes.lastModifiedUserId"] <- "Updated by (ID)"
names(BIM360Docs_Document_List)[names(BIM360Docs_Document_List)=="included.attributes.versionNumber"] <- "Version"
names(BIM360Docs_Document_List)[names(BIM360Docs_Document_List)=="included.attributes.fileType"] <- "File Type"
names(BIM360Docs_Document_List)[names(BIM360Docs_Document_List)=="included.attributes.extension.type"] <- "Extension Type"
names(BIM360Docs_Document_List)[names(BIM360Docs_Document_List)=="included.attributes.createTime"] <- "Created Date"
names(BIM360Docs_Document_List)[names(BIM360Docs_Document_List)=="included.attributes.lastModifiedTime"] <- "Updated Date"


# Clear Variables
rm(i, Access_Token,
   App_Client_ID,
   App_Client_Secret,
   App_Authenticate,
   BIM360_Account_ID,
   BIM360Docs_Project_ID,
   Get_Top_Folders_URL, 
   Get_Top_Folders_Request,
   Get_Top_Folders_Data,
   TopFolders_Content,
   TopFolderName,
   Parse_Folder
)
