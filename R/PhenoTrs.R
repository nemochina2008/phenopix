PhenoTrs <-
function(
	##title<< 
	## Method 'Trs' to calculate phenology metrics
	##description<<
	## This function implements threshold methods for phenology. This is rather an internal function; please use the function \code{\link{Phenology}} to apply this method.
	
	x, 
	### seasonal cycle of one year
	
	approach = c("White", "Trs"), 
	### approach to be used to calculate phenology metrics. 'White' (White et al. 1997) or 'Trs' for simple threshold.
	
	trs = 0.5,
	### threshold to be used for approach "Trs"
	
	min.mean = 0.1,
	### minimum mean annual value in order to calculate phenology metrics. Use this threshold to suppress the calculation of metrics in grid cells with low average values	
	formula=NULL,
	uncert=FALSE, 
	params=NULL, 
	breaks, 
	### calculate phenology metrics or return NA?
	
	# plot = FALSE,
	### plot results?
	
	...
	### further arguments (currently not used)
	
	##references<< 
	## White MA, Thornton PE, Running SW (1997) A continental phenology model for monitoring vegetation responses to interannual climatic variability. Global Biogeochem Cycles 11:217-234.
		
	##seealso<<
	## \code{\link{Phenology}}

) {
	if (all(is.na(x))) return(c(sos=NA, eos=NA, los=NA, pop=NA, mgs=NA, rsp=NA, rau=NA, peak=NA, msp=NA, mau=NA))

	# get statistical values
	n <- index(x)[length(x)]
	avg <- mean(x, na.rm=TRUE)
	x2 <- na.omit(x)
	avg2 <- mean(x2[x2 > min.mean], na.rm=TRUE)
	peak <- max(x, na.rm=TRUE)
	mn <- min(x, na.rm=TRUE)
	ampl <- peak - mn
	
	# get peak of season position
	pop <- median(index(x)[which(x == max(x, na.rm=TRUE))])
	
	# return NA if amplitude is too low or time series has too many NA values
	# if (!calc.pheno) {
	# 	if (avg < min.mean) { # return for all metrics NA if mean is too low
	# 		return(c(sos=NA, eos=NA, los=NA, pop=NA, mgs=NA, rsp=NA, rau=NA, peak=NA, msp=NA, mau=NA))
	# 	} else { # return at least annual average and peak if annual mean > min.mean
	# 		return(c(sos=NA, eos=NA, los=NA, pop=pop, mgs=avg2, rsp=NA, rau=NA, peak=peak, msp=NA, mau=NA))
	# 	}
	# }
		
	# select (or scale) values and thresholds for different methods
	approach <- approach[1]
	if (approach == "White") {
		# scale annual time series to 0-1
		ratio <- (x - mn) / ampl
		# trs <- 0.5
		trs.low <- trs - 0.1
		trs.up <- trs + 0.1
	}
	if (approach == "Trs") {
		ratio <- x
		a <- diff(range(ratio, na.rm=TRUE)) * 0.1
		trs.low <- trs - a
		trs.up <- trs + a
	}
			
	# identify greenup or dormancy period
	.Greenup <- function (x, ...) 
{
    ratio.deriv <- c(NA, diff(x))
    greenup <- rep(NA, length(x))
    greenup[ratio.deriv > 0] <- TRUE
    greenup[ratio.deriv < 0] <- FALSE
    return(greenup)
}
	greenup <- .Greenup(ratio)
			
	# select time where SOS and EOS are located (around trs value)
	bool <- ratio >= trs.low & ratio <= trs.up
			
	# get SOS, EOS, LOS
	soseos <- index(x)
	sos <- round(median(soseos[greenup & bool], na.rm=TRUE))
	eos <- round(median(soseos[!greenup & bool], na.rm=TRUE))
	los <- eos - sos
	los[los < 0] <- n + (eos[los < 0] - sos[los < 0])
	
	# get MGS, MSP, MAU
	mgs <- mean(x[ratio > trs], na.rm=TRUE)
	msp <- mau <- NA
		if (!is.na(sos)) {
		id <- (sos-10):(sos+10)
		id <- id[(id > 0) & (id < n)]
		msp <- mean(x[which(index(x) %in% id==TRUE)], na.rm=TRUE)
	}
	if (!is.na(eos)) {
		id <- (eos-10):(eos+10)
		id <- id[(id > 0) & (id < n)]
		mau <- mean(x[which(index(x) %in% id==TRUE)], na.rm=TRUE)
	}
	metrics <- c(sos=sos, eos=eos, los=los, pop=pop, mgs=mgs, rsp=NA, rau=NA, peak=peak, msp=msp, mau=mau)
	
	# if (plot) {
	# 	if (approach == "White") PlotPhenCycle(x, metrics=metrics, trs=trs, ...)
	# 	if (approach == "Trs") PlotPhenCycle(ratio, metrics=metrics, trs=trs, ...)
	# }
		
	return(metrics)
	### The function returns a vector with SOS, EOS, LOS, POP, MGS, rsp, rau, PEAK, MSP and MAU. }
}
