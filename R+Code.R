#install.packages("sqldf")
#install.packages("geosphere")
#install.packages("lubridate")
#install.packages("ggplot2")
#install.packages("sp")
#install.packages("rgdal")
#install.packages("rms")

#library(readr)
#library(sqldf)
#library(ggplot2)
#library(sp)
#library(rgdal)
#library(geosphere)
library(rms)

data0 <- read_csv("E:/hu500/HU500/pre-process/real_data.csv")
#data0 = read.csv("~/Downloads/real_data.csv", header=FALSE)
colnames(data0) = c("idx","fare","pickup_ts","pickup_long","pickup_lat","dropoff_long","dropoff_lat","passenger_count","time_window","weekday","distance")



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





## Model 2 -- revised model after cleaning data
model2 = lm(fare ~ . ,data=noout)
summary(model2, correlation = TRUE)

### Model 2 -- linearity
standardized2 = rstudent(model2)
fitted2 = scale(model2$fitted.values)
qqnorm(standardized2)
abline(0,1)

### Model 2 -- normality
hist(standardized2, breaks = 1000)

### Model 2 -- homogeneous
plot(fitted2)
abline(0,0)
abline(v = 0)


###Model 3 -- Model Selection
dat2 = noout

dat2.numeric = dat2[-c(3,4)]
cor(dat2.numeric)

###Manuel Step-wise regression
null=lm(fare ~ 1, data=dat2)
StepF0=null
summary(StepF0)

add1(StepF0, scope = ~passenger_count + time_window + weekday + distance, test='F', data=dat2)
StepF1=update(StepF0, ~ distance)
drop1(StepF1, test='F',data=dat2)

add1(StepF1, scope = ~passenger_count + time_window + weekday + distance, test='F', data=dat2)
StepF2=update(StepF1, ~ distance + time_window)
summary(StepF2)
drop1(StepF2, test='F',data=dat2)

add1(StepF2, scope = ~passenger_count + time_window + weekday + distance, test='F', data=dat2)
StepF3=update(StepF2, ~ distance + time_window + weekday)
summary(StepF3)
drop1(StepF3, test='F',data=dat2)

add1(StepF3, scope = ~passenger_count + time_window + weekday + distance, test='F', data=dat2)

model3 = lm(fare~distance + time_window + weekday,data=dat2)
summary(model3)
anova(model3)



### Model 4 -- Automatic Step-wise regression, to confirm Model 3
model4.full = ols(fare ~ passenger_count
                  + time_window + weekday + distance, data=dat2)
fastbw(model4.full, rule="p",sls=0.001)
