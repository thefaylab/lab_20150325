#### Functions for Fay lab meeting 3/25/15
## Model fitting using Maximum Likelihood


#' Schaefer biomass dynamics function
#' @author Gavin Fay
#' @description This function calculates biomass based on the Schaefer production function
#' @param bio
#' @param r
#' @param k
#' @param catch
schaefer.bio <- function(bio=100,r=0.2,k=200,catch=0)
{
  #calculate the biomass
  new.bio <- bio + bio*r*(1-bio/k) - catch
  #prevent negative biomass (we might want to add a penalty for this later)
  new.bio <- max(c(1,new.bio),na.rm=TRUE)
  #function returns the value for the new biomass
  return(new.bio)
}

#' Predict the biomass time series
#' @author Gavin Fay
#' @description calculates predicted biomass time series based on the Schaefer
#' production model given values for starting biomass, r, and k. 
predict.bio <- function(start.bio=100,catch=rep(0,10),r=0.2,k=200)
{
  #get length of time series for predictions
  nyears <- length(catch)+1
  #set up our vector for the predicted biomass
  pred.bio <- rep(NA,nyears)
  #initialize first year biomass
  pred.bio[1] <- start.bio
  #predict the biomass for remaining years
  for (year in 2:nyears)
    pred.bio[year] <- schaefer.bio(pred.bio[year-1],r,k,catch[year-1])
  #function returns the biomass time series
  return(pred.bio)
}
  
nll.function <- function(predict.bio,obs,q,sigma) 
{
  log.like <- 0
  for (iobs in 1:length(obs))
   {
    #check if there was an observation this year. NB Change this!
    if (obs[iobs]!=-99)
    {
     predicted <- q*mean(predict.bio[iobs:(iobs+1)],na.rm=TRUE)
     log.like <- log.like + loglike(obs[iobs],predicted,sigma) 
    }
   }
  return(-1.*log.like)
}
  
loglike <- function(observed,predicted,sigma)
{
  log.like <- (-1./pi)*log(sigma) -
    (1./(2*sigma^2))*(log(observed)-log(predicted))^2
  return(log.like)
}
  
objfun <- function(params=c(log.startbio=1,log.r=-0.2,log.k=10,log.q=-1,
                          log.sigma=-0.2),catch=rep(0,10),obs=rep(10,10),flag=1)
{
  #transform parameters
  start.bio <- exp(params['log.startbio'])
  r <- exp(params['log.r'])
  k <- exp(params['log.k'])
  q <- exp(params['log.q'])
  sigma <- exp(params['log.sigma'])
  
  #predict the biomass time series
  predict.bio <- predict.bio(start.bio,catch,r,k)

  #compute the (negative log) likelihood function
  nll <- nll.function(predict.bio,obs,q,sigma)
  
  #return the value for the negative log-likelihood
  if (flag==1)
    {
    results <- NULL
    results$nll <- nll  
    results$predict.bio <- predict.bio
    return(results)
   }
  if (flag==0) return(nll)
}


TheData <- read.csv("Yellowtail.csv")
head(TheData)
init.params <- c(log.startbio=log(100),
                 log.r=log(0.5),
                 log.k=log(200),
                 log.q=log(0.9),
                 log.sigma=-0.2)
catch <- TheData$Yield..kt.
obs <- TheData$Survey..kg.tow.
objfun(init.params,catch,obs,flag=1)

a <- optim(par=init.params,fn=objfun,catch=catch,obs=obs,flag=0,method="SANN")

objfun(a$par,catch,obs,flag=1)
exp(a$par)