require(ggplot2)
require(scales)
require(dplyr)
require(memisc)
require(gridExtra)
require(GGally)
require(cluster)
require(factoextra)
require(matrixStats)
require(data.table)
require(fmsb)

#to install packages when the UI won't work
#install.packages('ggradar', dependencies=TRUE, repos='http://cran.rstudio.com/')

setwd('C:/Users/Aaron/Documents/Consulting/Deputy/Spotify_API')

#read in the data sets
streams <- read.csv('streams.csv')
artist.info <- read.csv('artist_info.csv')
song.features <- read.csv('song_features.csv')

#create summary variables for streams
streams.grouped <- streams %>% group_by(Track.Name, Artist) %>% 
  summarise(track_id = first(track_id),
            top.rank = min(Position),
            total.plays = sum(Streams),
            average.daily.plays = mean(Streams),
            days.in.chart = n())

#join data sets together
model.features <- merge(streams.grouped, artist.info, by.x = 'Artist', by.y = 'artist')
model.features <- merge(model.features, song.features)

str(model.features)

summary(model.features)

#write data out to csv for import to Tableau
write.csv(model.features, file="spotify_top_200_grouped.csv", row.names = F)

#cluster songs based on song features
cluster.input <- model.features[, c('track_id', 'energy', 'liveness',
                                    'tempo', 'speechiness', 'acousticness', 
                                    'instrumentalness', 'danceability', 'key', 
                                    'duration_ms' ,'loudness', 'mode', 'valence')]

rownames(cluster.input) <- cluster.input$track_id

#scale features for clustering
cluster.input.scaled <- scale(cluster.input[, c('energy', 'liveness', 'tempo', 'speechiness'
                                                , 'acousticness', 'instrumentalness', 'danceability'
                                                , 'key', 'duration_ms' ,'loudness', 'mode'
                                                , 'valence')])

#check that scaled features have mean 0 and sd 1
round(colMeans(cluster.input.scaled),digits = 4)
colSds(cluster.input.scaled)


fviz_nbclust(cluster.input.scaled, pam, method = "silhouette")+
  theme_classic()

clusters <- pam(cluster.input.scaled, 3)

for (x in rownames(clusters$medoids)) {
  print("Cluster medoid: ")
  print(model.features[model.features$track_id == x, c("Artist", "Track.Name")])
}

model.features$cluster <- clusters$cluster

fviz_cluster(clusters, 
             ellipse.type = "t",
             repel = F, 
             ggtheme = theme_classic(),
             labelsize = 0
)

fviz_silhouette(clusters, palette = "jco", ggtheme = theme_classic())


#create summary variables for streams
model.features.grouped <- model.features %>% group_by(cluster) %>% 
  summarise(num.songs = n(),
            med.energy = median(energy),
            med.liveness = median(liveness),
            med.tempo = median(tempo),
            med.speechiness = median(speechiness), 
            med.acousticness = median(acousticness),
            med.instrumentalness = median(instrumentalness),
            med.danceability = median(danceability),
            med.key = median(key),
            med.duration_ms = median(duration_ms),
            med.loudness = median(loudness),
            med.mode = median(mode),
            med.valence = median(valence))

model.features.grouped

model.features.grouped.scaled <- scale(model.features.grouped)

#write data out to csv for import to Python to test classification model
write.csv(model.features, file="spotify_top_200_clustered.csv", row.names = F)

#create data frame for radar plot
data <- as.data.frame(model.features.grouped.scaled[,3:14])
rownames(data)=paste("Cluster" , c(1:3), sep=" ")

#add rows for max and min values
data=rbind(rep(max(data),12) 
           , rep(min(data),12) 
           , data)

colors_in=c( 'red', 'dark green', 'blue')

#plot radar chart
radarchart(data, 
           axistype = 0,
           pty = 32,
           plty = c(1),
           plwd = 2,
           pcol = colors_in,
           title = 'Median Feature Values (scaled) by Cluster')
legend(x=1.1, y=1.2, legend = rownames(data[-c(1,2),]), bty = "n", pch=20 ,col=colors_in, cex=1, pt.cex=3)




