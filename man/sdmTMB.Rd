% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/fit.R
\name{sdmTMB}
\alias{sdmTMB}
\title{Fit a spatial or spatiotemporal GLMM with TMB}
\usage{
sdmTMB(
  formula,
  data,
  time = NULL,
  spde,
  family = gaussian(link = "identity"),
  time_varying = NULL,
  weights = NULL,
  reml = FALSE,
  silent = TRUE,
  multiphase = TRUE,
  anisotropy = FALSE,
  control = sdmTMBcontrol(),
  enable_priors = FALSE,
  ar1_fields = FALSE,
  include_spatial = TRUE,
  spatial_trend = FALSE,
  normalize = FALSE,
  spatial_only = identical(length(unique(data[[time]])), 1L),
  quadratic_roots = FALSE
)
}
\arguments{
\item{formula}{Model formula. An offset can be included by including \code{offset}
in the model formula (a reserved word). The offset will be included in any
prediction. For index standardization, include \code{0 + as.factor(year)} (or
whatever the time column is called) in the formula.}

\item{data}{A data frame.}

\item{time}{The time column (as character).}

\item{spde}{An object from \code{\link[=make_spde]{make_spde()}}.}

\item{family}{The family and link. Supports \code{\link[=gaussian]{gaussian()}}, \code{\link[=Gamma]{Gamma()}},
\code{\link[=binomial]{binomial()}}, \code{\link[=poisson]{poisson()}}, \code{\link[=nbinom2]{nbinom2()}}, and \code{\link[=tweedie]{tweedie()}}.}

\item{time_varying}{An optional formula describing covariates that should be
modelled as a random walk through time.}

\item{weights}{Optional likelihood weights for the conditional model.
Implemented as in \pkg{glmmTMB}. In other words, weights do not have to sum
to one and are not internally modified.}

\item{reml}{Logical: use REML estimation rather than maximum likelihood?}

\item{silent}{Silent or include optimization details?}

\item{multiphase}{Logical: estimate the fixed and random effects in phases?
Phases are usually faster and more stable.}

\item{anisotropy}{Logical: allow for anisotropy? See \code{\link[=plot_anisotropy]{plot_anisotropy()}}.}

\item{control}{Optimization control options. See \code{\link[=sdmTMBcontrol]{sdmTMBcontrol()}}.}

\item{enable_priors}{Should weakly informative priors be enabled?
Experimental and likely for use with the \pkg{tmbstan} package. Note that
the priors are not yet sensible.}

\item{ar1_fields}{Estimate the spatiotemporal random fields as an AR1
process? Note that the parameter \code{ar1_phi} has been internally bounded
between \code{-1} and \code{1} with:  \code{2 * invlogit(ar1_phi) - 1} i.e. in R \code{2 * plogis(ar_phi) - 1}.}

\item{include_spatial}{Should a separate spatial random field be estimated?
If enabled then there will be a separate spatial field and spatiotemporal
fields.}

\item{spatial_trend}{Should a separate spatial field be included in the
trend? Requires spatiotemporal data.}

\item{normalize}{Logical: should the normalization of the random effects be
done in R during the outer-optimization step? For some cases, especially
with many knots, this may be faster. In others, it may be slower or suffer
from convergence problems. \emph{Currently disabled!}}

\item{spatial_only}{Logical: should only a spatial model be fit (i.e. do not
include spatiotemporal random effects)? By default a spatial-only model
will be fit if there is only one unique value in the time column or the
\code{time} argument is left at its default value of \code{NULL}.}

\item{quadratic_roots}{Logical: should quadratic roots be calculated?
Experimental feature for internal use right now. Note: on the sdmTMB side,
the first two coefficients are used to generate the quadratic parameters.
This means that if you want to generate a quadratic profile for depth, and
depth and depth^2 are part of your formula, you need to make sure these are
listed first and that an intercept isn't included. For example, \code{formula = cpue ~ 0 + depth + depth2 + as.factor(year)}.}
}
\description{
Fit a spatial or spatiotemporal GLMM with TMB. Particularly useful for
species distribution models and relative abundance index standardization.
}
\examples{
d <- subset(pcod, year >= 2011) # subset for example speed
pcod_spde <- make_spde(d$X, d$Y, n_knots = 50) # only 50 knots for example speed
plot_spde(pcod_spde)

# Tweedie:
m <- sdmTMB(density ~ 0 + depth_scaled + depth_scaled2 + as.factor(year),
data = d, time = "year", spde = pcod_spde, family = tweedie(link = "log"))
m

# Contents of the output object:
names(m)
m$model
TMB::sdreport(m$tmb_obj)
r <- m$tmb_obj$report()
names(r)

# Binomial:
pcod_binom <- d
pcod_binom$present <- ifelse(pcod_binom$density > 0, 1L, 0L)
m_bin <- sdmTMB(present ~ 0 + as.factor(year) + depth_scaled + depth_scaled2,
data = pcod_binom, time = "year", spde = pcod_spde,
family = binomial(link = "logit"))

# Gaussian:
pcod_gaus <- subset(d, density > 0 & year >= 2013)
pcod_spde_gaus <- make_spde(pcod_gaus$X, pcod_gaus$Y, n_knots = 50)
m_pos <- sdmTMB(log(density) ~ 0 + as.factor(year) + depth_scaled + depth_scaled2,
data = pcod_gaus, time = "year", spde = pcod_spde_gaus)

# Fit a spatial only model:
m <- sdmTMB(
density ~ depth_scaled + depth_scaled2, data = d,
spde = pcod_spde, family = tweedie(link = "log"))

# Spatial-trend example:
m <- sdmTMB(density ~ depth_scaled, data = d,
  spde = pcod_spde, family = tweedie(link = "log"),
  spatial_trend = TRUE, time = "year")

r <- m$tmb_obj$report()
r$ln_tau_O_trend
r$omega_s_trend

# Time-varying effects of depth and depth squared:
m <- sdmTMB(density ~ 0 + as.factor(year),
  time_varying = ~ 0 + depth_scaled + depth_scaled2,
  data = d, time = "year", spde = pcod_spde, family = tweedie(link = "log"))

# See the b_rw_t estimates; these are the time-varying (random walk) effects.
summary(m$sd_report)[1:19,]

# Experimental calculation of quadratic roots:
m <- sdmTMB(density ~ 0 + depth_scaled + depth_scaled2 + as.factor(year),
  data = d, time = "year", spde = pcod_spde, family = tweedie(link = "log"),
  quadratic_roots = TRUE)
.sd_report <- summary(m$sd_report)
params <- row.names(.sd_report)
params <- .sd_report[grep("quadratic", params), ]
params
b <- m$model$par[1:2]
x <- seq(min(d$depth_scaled), max(d$depth_scaled), length.out = 300)
y <- exp(1 + x * b[1] + x^2 * b[2])
plot(x, y, type = "l")
abline(h = y[which(y == max(y))] * 0.05)
abline(v = params[1:2, 1])
}
