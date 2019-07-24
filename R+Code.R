
install.packages("sqldf")
install.packages("geosphere")
install.packages("lubridate")
install.packages("ggplot2")
install.packages("sp")
install.packages("rgdal")


###Randomly Selected Data Base with No of Obs = 1000
library(readr)
library(sqldf)
library(ggplot2)
library(sp)
library(rgdal)
library(geosphere)

data0 <- read_csv("E:/hu500/HU500/pre-process/real_data.csv")

###Data to begin, create a copy
dat0 = data0

###cleanup1: by human knowledge
dat0$distance[dat0$distance <= 0] = NA
dat0$pickup_long[dat0$pickup_long == 0] = NA
dat0$pickup_lat[dat0$pickup_lat == 0] = NA
dat0$dropoff_long[dat0$dropoff_long == 0] = NA
dat0$dropoff_lat[dat0$dropoff_lat == 0] = NA

dat0$pickup_long[dat0$pickup_long < -100] = NA
dat0$pickup_long[dat0$pickup_long > -50] = NA
dat0$pickup_lat[dat0$pickup_lat < 20] = NA
dat0$pickup_lat[dat0$pickup_lat > 60] = NA

dat0$dropoff_long[dat0$dropoff_long < -100] = NA
dat0$dropoff_long[dat0$dropoff_long > -50] = NA
dat0$dropoff_lat[dat0$dropoff_lat < 20] = NA
dat0$dropoff_lat[dat0$dropoff_lat > 60] = NA

dat0$pickup_long[abs(dat0$pickup_long) > 180] = NA
dat0$pickup_lat[abs(dat0$pickup_lat) > 90] = NA
dat0$dropoff_long[abs(dat0$dropoff_long) > 180] = NA
dat0$dropoff_lat[abs(dat0$dropoff_lat) > 90] = NA

summary(dat0)

###First remove unused columns
no_miss <- dat0[complete.cases(dat0), ]
summary(no_miss)


###Kmean cluster coords (lat, long)
geo.dist = function(df) {
  require(geosphere)
  d <- function(i,z){
    dist <- rep(0,nrow(z))
    dist[i:nrow(z)] <- distHaversine(z[i:nrow(z),1:2],z[i,1:2])
    return(dist)
  }
  dm <- do.call(cbind,lapply(1:nrow(df),d,df))
  return(as.dist(dm))
}

# FAILED ON WOODEN COMPUTER
# only_coord <- no_miss[,c(4,5)]
# km <- kmeans(geo.dist(only_coord),centers=4)
# hc <- hclust(geo.dist(only_coord))  


###cleanup2 by cutoffs
dat1 = no_miss[,-c(1,3,4,5,6,7)]
K = 5
N = nrow(dat1)
model1 = lm(fare ~ . ,data=dat1)

## laverage cutoff
leverage = hatvalues(model1)
cutleverage = (2*K + 2) / N
badlaverage = as.numeric(leverage > cutleverage)
table(badlaverage)

## cook cutoff
cooks = cooks.distance(model1)
cutcook = 4 / (N-K-1)
badcooks = as.numeric(cooks > cutcook)
table(badcooks)

## mahalnobis cutoff 
mahal = mahalanobis(
  dat1,
  colMeans(dat1, na.rm=TRUE),
  cov(dat1, use="pairwise.complete.obs")
)
cutmahal = qchisq(1-.001,ncol(dat1))
badmahal = as.numeric(mahal > cutmahal)
table(badmahal)

## remove outlier
total = badmahal + badcooks + badlaverage
noout = subset(dat1, total < 1)

## factor categorical data
noout$time_window = factor(noout$time_window)
noout$weekday = factor(noout$weekday)
str(noout)

## revised model.
model2 = lm(fare ~ . ,data=noout)
summary(model2, correlation = TRUE)

### linearity
standardized = rstudent(model2)
fitted = scale(model2$fitted.values)
qqnorm(standardized)
abline(0,1)

### normality
hist(standardized, breaks = 1000)

### homogeneous
plot(fitted)
abline(0,0)
abline(v = 0)



