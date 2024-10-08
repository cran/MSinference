## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(fig.width=12, fig.height=8)

## -----------------------------------------------------------------------------
require(MSinference)
data(temperature, package = "MSinference")
str(temperature)

## -----------------------------------------------------------------------------
t_len    <- length(temperature)
t_len
ts_start <- 1659

## -----------------------------------------------------------------------------
grid <- construct_grid(t_len)
str(grid$gset, max.level = 1, vec.len = 4)

## -----------------------------------------------------------------------------
parameters <- estimate_lrv(data = temperature,
                           q = 25, r_bar = 10, p = 2)
cat("Long-run variance is equal to ", parameters$lrv, "\n")
sigmahat <- sqrt(parameters$lrv)

## -----------------------------------------------------------------------------
alpha    <- 0.05
sim_runs <- 5000

## -----------------------------------------------------------------------------
deriv_order = 1

## -----------------------------------------------------------------------------
quantiles <- compute_quantiles(t_len = t_len, grid = grid,
                               sim_runs = 10)

probs <- as.vector(quantiles$quant[1, ])
pos   <- which.min(abs(probs - (1 - alpha)))
quant <- quantiles$quant[2, pos]
quant

## -----------------------------------------------------------------------------
result <- compute_statistics(data = temperature,
                             sigma = sigmahat,
                             grid = grid,
                             deriv_order = deriv_order)
result$testing_result

## -----------------------------------------------------------------------------
gset         <- result$gset_with_vals
test_results <- (gset$vals_cor > quant) * sign(gset$vals)
gset$test    <- test_results

str(gset, max.level = 1, vec.len = 2)

## -----------------------------------------------------------------------------
sum(gset$test == -1)

## -----------------------------------------------------------------------------
set.seed(1)
results <- multiscale_test(data = temperature,
                           sigma = sigmahat,
                           grid = grid,
                           alpha = alpha,
                           deriv_order = deriv_order,
                           sim_runs = 100)
results$testing_result

## -----------------------------------------------------------------------------
plot(ts_start:(ts_start + t_len - 1), temperature, type = 'l',
     lty = 1, xlab = 'year', ylab = 'temperature',
     ylim = c(min(temperature) - 0.1, max(temperature) + 0.1))
title(main = "(a) observed yearly temperature", font.main = 1,
      line = 0.5)

## -----------------------------------------------------------------------------
# Epanechnikov kernel function, which is defined
# as f(x) = 3/4(1-x^2) for |x|<1 and 0 elsewhere
epanechnikov <- function(x)
{
  if (abs(x)<1)
  {
    result = 3/4 * (1 - x*x)
  } else {
    result = 0
  }
  return(result)
}

smoothing <- function(u, data_p, grid_p, bw){
  res = 0
  norm = 0
  for (i in 1:length(data_p)){
    res = res + epanechnikov((u - grid_p[i]) / bw) * data_p[i]
    norm = norm + epanechnikov((u - grid_p[i]) / bw)
  }
  return(res/norm)
}

bws <- c(0.01, 0.05, 0.1, 0.15, 0.2)
grid_points <- seq(from = 1 / t_len, to = 1,
                   length.out = t_len)
plot(NA, xlim = c(1659, 2019), ylim = c(8, 10.5),
     xlab = 'year', ylab = 'temperature',
     yaxp  = c(8, 10, 2), xaxp = c(1675, 2025, 7),
     mgp = c(2,0.5,0))
for (i in 1:5){
    smoothed <- mapply(smoothing, grid_points,
                       MoreArgs = list(temperature,
                                       grid_points,
                                       bws[i]))
    lines(ts_start:(ts_start + t_len - 1), smoothed,
          lty = i)
  }
legend(1900, 8.5, legend=c("bw = 0.01", "bw = 0.05", "bw = 0.10",
                           "bw = 0.15", "bw = 0.2"),
       lty = 1:5, cex = 0.95, ncol=1)

title(main = "(b) smoothed time series for different bandwidths",
      font.main = 1, line = 0.5)

## -----------------------------------------------------------------------------
require(MSinference)
data(covid, package = "MSinference")
str(covid)

## -----------------------------------------------------------------------------
covid <- covid[, c("DEU", "GBR", "ESP", "FRA", "ITA")]
covid <- na.omit(covid)

## -----------------------------------------------------------------------------
n     <- ncol(covid)
t_len <- nrow(covid)
n
t_len

## -----------------------------------------------------------------------------
sum(covid < 0)
covid[covid < 0] <- 0

## -----------------------------------------------------------------------------
matplot(1:t_len, covid, type = 'l', lty = 1, col = 1:t_len,
        xlab = 'Number of days since 100th case', ylab = 'cases')
legend("topright", legend = c("DEU", "GBR", "ESP", "FRA", "ITA"),
       inset = 0.02, lty = 1, col = 1:t_len, cex = 0.8)

## -----------------------------------------------------------------------------
sigma_vec <- rep(0, n)
for (i in 1:n){
  diffs <- (covid[2:t_len, i] - covid[1:(t_len - 1), i])
  sigma_squared <- sum(diffs^2) / (2 * sum(covid[, i]))
  sigma_vec[i] <- sqrt(sigma_squared)
}

sigmahat <- sqrt(mean(sigma_vec * sigma_vec))
sigmahat

## -----------------------------------------------------------------------------
alpha    <- 0.05
sim_runs <- 5000

## -----------------------------------------------------------------------------
ijset           <- expand.grid(i = 1:n, j = 1:n)
ijset           <- ijset[ijset$i < ijset$j, ]
rownames(ijset) <- NULL
ijset
grid <- construct_weekly_grid(t_len, min_len = 7, nmbr_of_wks = 4)

## -----------------------------------------------------------------------------
intervals <- data.frame('left' = grid$gset$u - grid$gset$h,
                        'right' = grid$gset$u + grid$gset$h,
                        'v' = 0)
intervals$v <- (1:nrow(intervals)) / nrow(intervals)

plot(NA, xlim=c(0,t_len),  ylim = c(0, 1 + 1/nrow(intervals)),
     xlab="days", ylab = "", yaxt= "n", mgp=c(2,0.5,0))
title(main = expression(The ~ family ~ of ~ intervals ~ italic(F)),
      line = 1)
segments(intervals$left * t_len, intervals$v,
         intervals$right * t_len, intervals$v,
         lwd = 2)

## -----------------------------------------------------------------------------
quantiles <- compute_quantiles(t_len = t_len, grid = grid,
                               n_ts = n, ijset = ijset,
                               sigma = sigmahat,
                               sim_runs = sim_runs,
                               epidem = TRUE)

probs <- as.vector(quantiles$quant[1, ])
pos   <- which.min(abs(probs - (1 - alpha)))
quant <- quantiles$quant[2, pos]
quant

## -----------------------------------------------------------------------------
result <- compute_statistics(data = covid, sigma = sigmahat,
                             n_ts = n, grid = grid,
                             epidem = TRUE)
result$testing_result

## -----------------------------------------------------------------------------
gset_with_values <- result$gset_with_values

for (i in seq_len(nrow(ijset))) {
   test_results <- gset_with_values[[i]]$vals > quant
   gset_with_values[[i]]$test <- test_results
}

str(gset_with_values, max.level = 2, vec.len = 2, list.len = 2)

## -----------------------------------------------------------------------------
results <- multiscale_test(data = covid, sigma = sigmahat,
                           n_ts = n, grid = grid, ijset = ijset,
                           alpha = alpha,
                           sim_runs = sim_runs,
                           epidem = TRUE)
results$testing_result

## -----------------------------------------------------------------------------
plot(covid[, 1], ylim=c(min(covid[, 1], covid[, 2]),
                        max(covid[, 1], covid[, 2])),
     type="l", col="blue", ylab="", xlab="", mgp=c(1, 0.5, 0))
lines(covid[, 2], col="red")
title(main = "(a) observed new cases per day", font.main = 1,
      line = 0.5)
legend("topright", inset = 0.02, legend=c("Germany", "UK"),
       col = c("blue", "red"), lty = 1, cex = 0.95, ncol = 1)

## -----------------------------------------------------------------------------
smoothing <- function(u, data_p, grid_p, bw){
  result      = 0
  norm        = 0
  T_size      = length(data_p)
  result = sum((abs((grid_p - u) / bw) <= 1) * data_p)
  norm = sum((abs((grid_p - u) / bw) <= 1))
  return(result/norm)
}

grid_points <- seq(from = 1 / t_len, to = 1, length.out = t_len)
smoothed_1  <- mapply(smoothing, grid_points,
                      MoreArgs = list(covid[, 1], grid_points,
                                      bw = 3.5 / t_len))

smoothed_2  <- mapply(smoothing, grid_points,
                      MoreArgs = list(covid[, 2], grid_points,
                                      bw = 3.5 / t_len))

plot(smoothed_1, ylim=c(min(covid[, 1], covid[, 2]),
                        max(covid[, 1], covid[, 2])),
     type="l", col="blue", ylab="", xlab = "", mgp=c(1,0.5,0))
title(main = "(b) smoothed curves from (a)", font.main = 1,
      line = 0.5)
lines(smoothed_2, col="red")

## -----------------------------------------------------------------------------
l <- 1 #First comparison in ijset
gset       <- results$gset_with_values[[l]]
reject     <- subset(gset, test == TRUE, select = c(u, h))
reject_set <- data.frame('startpoint' = (reject$u - reject$h) *
                           t_len,
                         'endpoint' = (reject$u + reject$h) *
                           t_len, 'values' = 0)
reject_set$values <- (1:nrow(reject_set)) / nrow(reject_set)
reject_min        <- compute_minimal_intervals(reject_set)

plot(NA, xlim=c(0, t_len),  ylim = c(0, 1 + 1 / nrow(reject_set)),
     xlab="", mgp=c(2, 0.5, 0), yaxt = "n", ylab = "")
title(main = "(c) minimal intervals produced by our test",
      font.main = 1, line = 0.5)
title(xlab = "days since the hundredth case", line = 1.7,
      cex.lab = 0.9)
segments(reject_min$startpoint, reject_min$values,
         reject_min$endpoint, reject_min$values, lwd = 2)
segments(reject_set$startpoint, reject_set$values,
         reject_set$endpoint, reject_set$values,
         col = "gray")

