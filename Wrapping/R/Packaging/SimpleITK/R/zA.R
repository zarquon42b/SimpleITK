redefineEnumeration <- function(enumerationName, the.function)
{
    current.enum <- get(paste(".__E__", enumerationName, sep = ""))
    the.names <- names(current.enum)
    values <- sapply(the.names, the.function)

    if (any(values== -99))
    {
        warning("Some enumeration names are not recognised\n")
    }
    names(values) <- the.names
    defineEnumeration(enumerationName, values)
}

.onLoad <- function(lib,pkg) {
  library.dynam("SimpleITK",pkg,lib)
  redefineEnumeration('_itk__simple__PixelIDValueEnum', GetPixelIDValueFromString)

  createPixLookup()
}

createPixLookup <- function( where = topenv(parent.frame()))
{
    m <- get(".__E___itk__simple__PixelIDValueEnum")
    # get rid of unknown type - can't access anyway. There will be errors if
    # it happens.
    # Also need to map Float32 to Float and Float64 to Double
    m <- m[m>=0]
    n <- names(m)
    # Turn the names into function names
    ff <- gsub("^sitk(.+)", "Image_GetPixelAs\\1", n)
    ff <- gsub("AsFloat32$", "AsFloat", ff)
    ff <- gsub("AsFloat64$", "AsDouble", ff)

    sitkPixelAccessMap <-  mget(ff, envir=where,
                                ifnotfound=rep(NA,length(ff)))
    names(sitkPixelAccessMap) <- n
    assign("sitkPixelAccessMap", sitkPixelAccessMap, envir=where)
}

ImportPixVec <- function(VP)
{
    ## some pixel vectors aren't automatically converted to
    ## R vectors, so we'll do it the long way to avoid having to
    ## write new swig fragments dealing with

    ## some pixel vectors work as expected - return them
    if (is.numeric(VP)) return(VP)

    l <- VP$'__len__'()
    res <- rep(NA, l)
    for (idx in 1:l) {
        res[idx] <- VP$'__getitem__'(idx-1)
    }
    return(res)
}

                                        # experimental bracket operator for images
setMethod('[', "_p_itk__simple__Image",
          function(x,i, j, k, drop=TRUE) {
                                        # check to see whether this is returning a single number or an image
            m <- sys.call()

            imdim <- Image_GetDimension(x)
            if ((length(m)-2) < imdim)
              {
                stop("Image has more dimensions")
              }
            imsize <- rep(1, 5)
            imsize[1:imdim] <- Image_GetSize(x)

            if (missing(i)) {
              i <- 1:imsize[1]
            } else {
              i <- (1:imsize[1])[i]
            }

            if (missing(j)) {
              j <- 1:imsize[2]
            } else {
              j <- (1:imsize[2])[j]
            }
            if (missing(k)) {
              k <- 1:imsize[3]
            } else {
              k <- (1:imsize[3])[k]
            }


            if (any(is.na(c(i,j,k)))) {
              stop("Indexes out of range")
            }
            i <- i - 1
            j <- j - 1
            k <- k - 1
            if ((length(i) == 1) & (length(j) == 1) & (length(k) == 1) ) {
              ## return a single point
              pixtype <- x$GetPixelID()
              aF <- sitkPixelAccessMap[[pixtype]]
              if (!is.null(aF)) {
                ## need to check whether we are using R or C indexing.
                return(ImportPixVec(aF(x, c(i, j,k))))
              }
            } else {
              ## construct and return an image
              pixtype <- x$GetPixelIDValue()
              resIm <- SingleBracketOperator(i,j,k,x)
              return(resIm);
            }

          }

          )
setMethod('[[', "_p_itk__simple__Image",
          function(x, i, j, ...) {
              return(VectorIndexSelectionCast(x, i-1)) 
          }
          )

setMethod('as.array', "_p_itk__simple__Image",
          function(x, drop=TRUE) {
            sz <- x$GetSize()
            components <- x$GetNumberOfComponentsPerPixel()
            if (components > 1) sz <- c(components, sz)
            if (.hasSlot(x, "ref")) x = slot(x,"ref")
            ans = .Call("R_swig_ImAsArray", x, FALSE, PACKAGE = "SimpleITK")
            dim(ans) <- sz
            if (components > 1) {
                ## vector images have planes stored next to each other.
                ## place in separate planes for sensible display
                perm <- c(2:length(sz), 1)
                ans <- aperm(ans, perm)
            }
            if (drop)
              return(drop(ans))
            return(ans)

            }
          )

as.image <- function(arr, spacing=rep(1, length(dim(arr))),
                     origin=rep(0,length(dim(arr))))
  {
    size <- dim(arr)
    return(ArrayAsIm(arr, size, spacing,origin))
  }
