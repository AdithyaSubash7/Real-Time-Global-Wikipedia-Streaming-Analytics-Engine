library(tidyverse)
library(shiny)
library(lubridate)
library(tidytext)
library(shinythemes)

#frontend
ui<- fluidPage(
  
  theme = shinythemes::shinytheme("flatly"),
  titlePanel("Live Wikipedia Streaming Analytics Engine"),
  hr(),
  
  sidebarLayout(
    sidebarPanel(
      width = 3,
      tags$h4("Stream Controls", style= "font-weight: bold;"),
      p("Status: Connected to Python Stream Engine", style= "color: green; font-weight: bold;"),
      
      #auto refresh tracking status indicator
      helpText("Dashboard updates automatically every 2 seconds"),
      hr(),
      
      #interactive live topic filter
      textInput("search_filter", "Filter Dashboard by Topic: ", value = ""),
      helpText("Type keywords like 'FIFA World Cup', 'Davis Cup'or 'Olympic' to isolate streams.")
    ),
    
    mainPanel(
      width = 9,
      #real time ingestion kpi scorecards
      fluidRow(
        column(4, uiOutput("kpi_total_edits")),
        column(4, uiOutput("kpi_velocity")),
        column(4, uiOutput("kpi_bots"))
      ),
      br(),
      
      tabsetPanel(
        tabPanel("Top Trending Pages", plotOutput("wikiPlot")),
        tabPanel("Stream Velocity (Over Time)", plotOutput("timePlot")),
        tabPanel("Key Concepts & Words", plotOutput("wordPlot")),
        tabPanel("Global Language Distribution", plotOutput("langPlot"))
      )
    )
  )
)

#server
server<- function(input, output, session){
  
  live_data<- reactivePoll(2000, session,
    checkFunc = function(){
      
      if(file.exists("live_wiki_data.csv")){
        file.info("live_wiki_data.csv")$mtime
      }else{
        NULL
      }
    },
    valueFunc = function(){
      if(file.exists("live_wiki_data.csv")){
        read.csv("live_wiki_data.csv", stringsAsFactors = FALSE, encoding= "utf-8")
      } else{
        data.frame(Timestamp= character(), PageTitle= character(), Is_bot= logical(), Wiki_Language= character())
      }
    }
  )
  
  #instant filtering for all plots
  filtered_data<- reactive({
    df <- live_data()
    
    if (nrow(df)== 0) return(df)
    
    if(input$search_filter != ""){
      df<- df %>%
        filter(str_detect(tolower(PageTitle), tolower(input$search_filter)))
    }
    return(df)
  })
  
  #kpi 1: Total row counter
  output$kpi_total_edits<- renderUI({
    data<- filtered_data()
    wellPanel(
      style= "background-color: #f8f9fa; border-left: 5px solid #2c3e50; padding: 10px;",
      h3(format(nrow(data), big.mark= ","), style= "margin-top:0; color:#7f8c8d;"),
      p("Total Live Events Analyzed", style= "margin-bottom:0; color: #7f8c8d;")
    )
  })
  
  #kpi 2: Velocity tracker (edits/min)
  output$kpi_velocity <- renderUI({
    data<- filtered_data()
    if(nrow(data)== 0) avg_speed <- 0
    else{
    avg_speed<- data %>%
      mutate(minute= substr(Timestamp, 1, 16)) %>%
      count(minute) %>%
      summarize(avg= round(mean(n), 1)) %>%
      pull(avg)
    }
    
    wellPanel(
      style="background-color: #f8f9fa; border-left: 5px solid #e74c3c; padding: 10 px;",
      h3(if(is.na(avg_speed))0 else avg_speed, style= "margin-top: 0; font-weight: bold; color: #e74c3c;"),
      p("Average Ingestion Velocity (Events/Min)", style= "margin-bottom: 0; color:#7f8c8d;")
    )
  })
  
  #kpi 3: Bot traffic footprint
  output$kpi_bots <- renderUI({
    data<- filtered_data()
    if(nrow(data)== 0) bot_pct <- 0
    else{
      bot_pct<- round((sum(data$Is_bot == "True" | data$Is_bot == TRUE, na.rm= TRUE) / nrow(data)) *100, 1)
    }
    
    wellPanel(
      style= "background-color: #f8f9fa; border-left: 5px solid #f39c12; padding: 10px;",
      h3(paste0(bot_pct, "%"), style= "margin-top: 0; font-weight: bold; color: #f39c12;"),
      p("Automated Bot Automation Ratio", style= "margin-bottom: 0; color: #7f8c8d;")
    )
  })
  
  #plot 1
  output$wikiPlot<- renderPlot({
    
    wiki_data <- filtered_data()
    if(nrow(wiki_data)== 0) return(NULL)
    
    #top 10 trending pages bar chart
    wiki_data %>%
      tail(3000) %>%
      #filtering out raw data codes
      filter(!str_detect(PageTitle, "^Q\\d+")) %>%
      filter(!str_detect(PageTitle, "^File:")) %>%
      filter(!str_detect(PageTitle, "^User:")) %>%
      filter(!str_detect(PageTitle, "^Category:")) %>%
      count(PageTitle, sort = TRUE) %>%
      head(10) %>%
      mutate(Short_Title= stringr::str_trunc(PageTitle, 35)) %>%
      ggplot(aes(x= reorder(PageTitle, n), y=n))+
      geom_col(fill= "steelblue")+
      coord_flip()+
      labs(
        title= "Top 10 Most Active Wikipedia Pages Right Now",
        x= NULL,
        y= "Number of Live Edits"
      )+
      theme_minimal(base_size= 14)
  })
  
  #plot 2
  output$langPlot<- renderPlot({
    wiki_data <- filtered_data()
    if (nrow(wiki_data)== 0) return(NULL)
    
    lang_labels <- c(
      "WWW" = "Wikidata Global Core",
      "COMMONS" = "Shared Media Commons",
      "EN" = "English Wikipedia",
      "CE"= "Chechan Wikipedia",
      "DE" = "German Wikipedia",
      "IT" = "Italian Wikipedia",
      "FR" = "French Wikipedia",
      "ES" = "Spanish Wikipedia",
      "FA" = "Persian Wikipedia",
      "ZH" = "Chinese Wikipedia",
      "RU" = "Russian Wikipedia",
      "UR" = "Urdu Wikipedia",
      "HE" = "Hebrew Wikipedia",
      "PL" = "Poland Wikipedia"
    )
    
    wiki_data %>%
      tail(2000) %>%
      count(Wiki_Language, sort= TRUE) %>%
      head(12) %>%
      mutate(Lang_Clean= toupper(Wiki_Language)) %>%
      mutate(Lang_Full= ifelse(Lang_Clean %in% names(lang_labels), lang_labels[Lang_Clean], paste(Lang_Clean, "Domain"))) %>%
      ggplot(aes(x= reorder(Lang_Full, n), y=n)) +
      geom_col(fill= "#18bc9c")+
      geom_text(aes(label= format(n, big.mark= ",")), hjust= -0.2, size= 5, fontface= "bold") +
      coord_flip()+
      labs(
        title= "Top Active Language Domain & Vectors Nodes", 
        x= NULL,
        y= "Total Traffic Event Log") +
      theme_minimal(base_size= 14)+
      theme(axis.text.y= element_text(size= 12, face= "bold"))
  })
  
  #plot 3
  output$timePlot<- renderPlot({

    wiki_data <- filtered_data()
    if(nrow(wiki_data)== 0) return(NULL)
    
    #Time plot
    wiki_data %>%
      tail(2000) %>%
      #converting raw text
      mutate(RealTime= as.POSIXct(Timestamp, format= "%Y-%m-%d %H:%M:%S")) %>%
      filter(!is.na(RealTime))%>%
      #rounding the time to the nearest minute
      mutate(minute= lubridate::floor_date(RealTime, "1 minute"))%>%
      count(minute) %>%
      ggplot(aes(x= minute, y= n, group= 1))+
      geom_line(color= "firebrick", size= 1.2)+
      geom_point(color= "firebrick", size= 2)+
      scale_x_datetime(date_labels = "%H:%M", date_breaks = "1 mins")+
      labs(
        title= "Real-Time Wikipedia Edit Velocity Profile",
        x= "Wall Clock Time",
        y= "Total Edits"
      )+
      theme_minimal(base_size= 14)+
      theme(axis.text.x = element_text(angle= 45, hjust= 1))
  })
  
  #plot 4
  output$wordPlot<- renderPlot({

    wiki_data <- filtered_data()
    if(nrow(wiki_data)== 0) return(NULL)
    
    wiki_data %>%
      tail(1000) %>%
      unnest_tokens(bigram, PageTitle, token= "ngrams", n=2) %>%
      separate(bigram, c("word1", "word2"), sep= " ") %>%
      filter(!word1 %in% stop_words$word, !word2 %in% stop_words$word) %>%
      filter(!word1 %in% c("user", "wikipedia", "talk", "sandbox", "page", "requests", "protection", "unknown")) %>%
      filter(!word2 %in% c("user", "wikipedia", "talk", "sandbox", "page", "requests", "protection", "unknown")) %>%
      filter(!is.na(word1) & !is.na(word2))%>%
      unite(bigram, word1, word2, sep= " ")%>%
      count(bigram, sort= TRUE) %>%
      head(10) %>%
      ggplot(aes(x= reorder(bigram,n), y=n))+
      geom_col(fill= "darkslategrey")+
      coord_flip()+
      labs(
        title= "Top 10 Live Trending Concepts & Phrases",
        x= NULL,
        y= "Context Extraction Count"
      )+
      theme_minimal(base_size= 14)
  })
}

shinyApp(ui= ui, server= server)