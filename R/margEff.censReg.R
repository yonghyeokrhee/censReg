margEff.censReg <- function( object, xValues = NULL,
    calcVCov = TRUE, returnJacobian = FALSE, ... ) {
   ## calculate marginal effects on E[y] at the mean explanatory variables
   allPar <- coef( object, logSigma = FALSE )

   # check if the model was estimated with panel data
   isPanel <- "sigmaMu" %in% names( allPar )
   
   ## (not for panel data)
   if( isPanel ) {
      stop( "the margEff() method for objects of class 'censReg'",
         " can not yet be used for panel data models" )
   }

   sigma <- allPar[ "sigma" ]
   beta <- allPar[ ! names( allPar ) %in% c( "sigma" ) ]
   if( is.null( xValues ) ) {
      xValues <- object$xMean
      if( length( xValues ) != length( beta ) ){
         print( beta )
         print( xValues )
         print( object$xMean )
         stop( "cannot calculate marginal effects due to an internal error:",
            " please contact the maintainer of this package" )
      }
   } else if( !is.vector( xValues ) ) {
      stop( "argument 'xValues' must be a vector" )
   } else if( length( xValues ) != length( beta ) ) {
      stop( "argument 'xValues' must be a vector with the number of elements",
         " equal to the number of estimated coefficients without sigma (",
         length( beta ), ")" )
   } else {
      names( xValues ) <- names( object$xMean )
   }
   
   xBeta <- drop( crossprod( xValues, beta ) )
   zRight <- ( object$right - xBeta ) / sigma
   zLeft <- ( object$left - xBeta ) / sigma
   result <- beta[ ! names( beta ) %in% c( "(Intercept)" ) ] * 
      ( pnorm( zRight ) - pnorm( zLeft ) )
   names( result ) <- 
      names( beta )[ ! names( beta ) %in% c( "(Intercept)" ) ]

   if( calcVCov || returnJacobian ){
      # compute Jacobian matrix
      jac <- matrix( 0, nrow = length( result ), ncol = length( allPar ) )
      rownames( jac ) <- names( result )
      colnames( jac ) <- names( allPar )
      for( j in names( result ) ) {
         for( k in names( allPar )[ -length( allPar ) ] ) {
            jac[ j, k ] <- 
               ( j == k ) * ( pnorm( zRight ) - pnorm( zLeft ) ) -
               ( beta[ j ] * xValues[ k ] / sigma ) *
               ( dnorm( zRight ) - dnorm( zLeft ) )
         }
         jac[ j, "sigma"] <- 0
         if( is.finite( object$right ) ) {
            jac[ j, "sigma"] <- jac[ j, "sigma"] - ( beta[ j ] / sigma ) *
               dnorm( zRight ) * zRight
         }
         if( is.finite( object$left ) ) {
            jac[ j, "sigma"] <- jac[ j, "sigma"] + ( beta[ j ] / sigma ) *
               dnorm( zLeft ) * zLeft
         }
      }
      if( calcVCov ) {
         attr( result, "vcov" ) <- 
            jac %*% vcov( object, logSigma = FALSE ) %*% t( jac )
      }
      if( returnJacobian ) {
         attr( result, "jacobian" ) <- jac
      }
   }

   # degrees of freedom of the residuals
   attr( result, "df.residual" ) <- object$df.residual

   class( result ) <- c( "margEff.censReg", class( result ) )
 
   return( result )
}