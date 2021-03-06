#
#    _____      _ ____  ____
#   / ___/_____(_) __ \/ __ )
#   \__ \/ ___/ / / / / __  |
#  ___/ / /__/ / /_/ / /_/ / 
# /____/\___/_/_____/_____/  
#
#
#
# BEGIN_COPYRIGHT
#
# This file is part of SciDB.
# Copyright (C) 2008-2014 SciDB, Inc.
#
# SciDB is free software: you can redistribute it and/or modify
# it under the terms of the AFFERO GNU General Public License as published by
# the Free Software Foundation.
#
# SciDB is distributed "AS-IS" AND WITHOUT ANY WARRANTY OF ANY KIND,
# INCLUDING ANY IMPLIED WARRANTY OF MERCHANTABILITY,
# NON-INFRINGEMENT, OR FITNESS FOR A PARTICULAR PURPOSE. See
# the AFFERO GNU General Public License for the complete license terms.
#
# You should have received a copy of the AFFERO GNU General Public License
# along with SciDB.  If not, see <http://www.gnu.org/licenses/agpl-3.0.html>
#
# END_COPYRIGHT
#

# Various functions that support S3 methods for the SciDB class
cbind.scidb = function(x)
{
  if(length(dim(x))!=1) return(x)
  newdim=make.unique_(c(x@D$name,x@attributes), "j")
  nd = sprintf("%s[%s,%s=0:0,1,0]",build_attr_schema(x) , build_dim_schema(x,bracket=FALSE),newdim)
  redimension(x, nd)
}

log.scidb = function(x, base=exp(1))
{
  log_scidb(x,base) 
}

colnames.scidb = function(x)
{
  if(is.null(x@gc$dimnames)) return(NULL)
  if(length(x@gc$dimnames)<2) return(NULL)
  x@gc$dimnames[[2]]
}

`colnames<-.scidb` = function(x, value)
{
  x
}

rownames.scidb = function(x)
{
  if(is.null(x@gc$dimnames)) return(NULL)
  x@gc$dimnames[[1]]
}

`rownames<-.scidb` = function(x, value)
{
  x
}

names.scidb = function(x)
{
  if(is.null(dim(x))) rownames(x)
  colnames(x)
}

`names<-.scidb` = function(x, value)
{
  colnames(x) <- value
}

dimnames.scidb = function(x)
{
  x@gc$dimnames
}

# SciDB labeled coordinates assignment
# Improve this:
# 1. Accept non-scidb array indices by making SciDB arrays out of them
# 2. Automatically adjust the origin of the label arrays to match x
`dimnames<-.scidb` = function(x, value)
{
  if(!is.list(value))
    stop("dimnames requires a list")
  if(length(value)!=length(dim(x)))
    stop("incorrect number of dimensions specified")
# Make sure that specified indices are all SciDB arrays.
# If not, try to make them so.
  value = lapply(1:length(value), function(j)
    {
      v = value[[j]]
      if(is.scidb(v) || is.scidbdf(v) || is.null(v))
      {
        return(v);
      }
      as.scidb(data.frame(label=v)[,1,drop=FALSE],
               start=x@D$start[j], chunkSize=x@D$chunk_interval[j])
    })

  check = unlist(lapply(1:length(value), function(j)
    {
      is.null(value[[j]]) || (value[[j]]@D$start[1] == x@D$start[j])
    }))
  if(!all(check))
    stop("Label array starting indices don't match data array--please check")
  check = unlist(lapply(1:length(value), function(j)
    {
      is.null(value[[j]]) || (nrow(value[[j]]) == dim(x)[j])
    }))
  check[is.na(check)] = FALSE
  if(!all(check))
    warning("Label lengths might not match array dimensions")
  x@gc$dimnames = value
  x@gc$depend =c (x@gc$depend, unlist(value))
  x
}

summary.scidb = function(x)
{
  warning("Not available.")
  invisible()
}

# XXX this will use insert, write me.
#`[<-.scidb` = function(x,j,k, ..., value)
#{
#  stop("Sorry, scidb array objects are read only for now.")
#}

# Array subsetting wrapper.
# x: A Scidb array object
# ...: list of dimensions
# 
# Returns a materialized R array if length(list(...))==0.
# Or, a scidb array promise.
`[.scidb` = function(x, ...)
{
  M = match.call()
  drop = ifelse(is.null(M$drop),TRUE,M$drop)
  eval = ifelse(is.null(M$eval),FALSE,M$eval)
  M = M[3:length(M)]
  if(!is.null(names(M))) M = M[!(names(M) %in% c("drop","eval"))]
# i shall contain a list of requested index values
  E = parent.frame()
  i = lapply(1:length(M), function(j) tryCatch(eval(M[j][[1]],E),error=function(e)c()))
# User wants this materialized to R...
  if(all(sapply(i,is.null)))
    return(materialize(x,drop=drop))
# Not materializing, return a SciDB array
  if(length(i)!=length(dim(x))) stop("Dimension mismatch")
  dimfilter(x,i,eval,drop=drop)
}

`dim.scidb` = function(x)
{
  if(length(x@dim)==0) return(NULL)
  x@dim
}

`dim<-.scidb` = function(x, value)
{
  stop("unsupported")
}


`str.scidb` = function(object, ...)
{
  name = substr(object@name,1,20)
  if(nchar(object@name)>20) name = paste(name,"...",sep="")
  cat("SciDB array name: ",name)
  cat("\nSciDB array schema: ",object@schema)
  cat("\nattribute in use: ",object@attribute)
  cat("\nAll attributes: ",object@attributes)
  cat("\nArray dimensions:\n")
  cat(paste(capture.output(print(data.frame(object@D))),collapse="\n"))
  cat("\n")
}

`print.scidb` = function(x, ...)
{
  cat("\nSciDB array ",x@name)
  if(nchar(x@attribute)>0)
    cat("\tattribute: ",x@attribute)
  cat("\n")
  print(head(x))
  if(is.null(x@dim)) j = x@length - 6
  else j = x@dim[1]-6
  if(j>2) cat("and ",j,"more rows not displayed...\n")
  if(length(x@dim)>0) {
    k = x@dim[2] - 6
    if(k>2) cat("and ",k,"more columns not displayed...\n")
  }
}

`ncol.scidb` = function(x) x@dim[2]
`nrow.scidb` = function(x) x@dim[1]
`dim.scidb` = function(x) {if(length(x@dim)>0) return(x@dim); NULL}
`length.scidb` = function(x) x@length

# Vector, Matrix, matrix, or data.frame only.
# XXX Future: Add n-d array support here (TODO)
as.scidb = function(X,
                    name=tmpnam(),
                    chunkSize,
                    overlap,
                    start,
                    gc=TRUE, ...)
{
  if(inherits(X,"data.frame"))
    if(missing(chunkSize))
      return(df2scidb(X,name=name,gc=gc,start=start,...))
    else
      return(df2scidb(X,name=name,chunkSize=chunkSize[[1]],gc=gc,start=start,...))
  if(missing(chunkSize))
  {
# Note nrow, ncol might be NULL here if X is not a matrix. That's OK, we'll
# deal with that case later.
    chunkSize=c(min(1000L,nrow(X)),min(1000L,ncol(X)))
  }
  if(length(chunkSize)==1) chunkSize = c(chunkSize, chunkSize)
  if(!missing(overlap)) warning("Sorry, overlap is not yet supported by the as.scidb function. Consider using the reparition function for now.")
  overlap = c(0,0)
  if(missing(start)) start=c(0,0)
  if(length(start)==1) start=c(start,start)
  if(inherits(X,"dgCMatrix"))
  {
# Sparse matrix case
    return(.Matrix2scidb(X,name=name,rowChunkSize=chunkSize[[1]],colChunkSize=chunkSize[[2]],start=start,gc=gc,...))
  }
  D = dim(X)
  start = as.integer(start)
  overlap = as.integer(overlap)
  type = .scidbtypes[[typeof(X)]]
  if(is.null(type)) {
    stop(paste("Unupported data type. The package presently supports: ",
       paste(.scidbtypes,collapse=" "),".",sep=""))
   }
  if(is.null(D)) {
# X is a vector
    if(!is.vector(X)) stop ("X must be a matrix or a vector")
    chunkSize = min(chunkSize[[1]],length(X))
    X = as.matrix(X)
    schema = sprintf(
      "< val : %s null>  [i=%.0f:%.0f,%.0f,%.0f]", type, start[[1]],
      nrow(X)-1+start[[1]], min(nrow(X),chunkSize), overlap[[1]])
    load_schema = schema
  } else {
# X is a matrix
    schema = sprintf(
      "< val : %s >  [i=%.0f:%.0f,%.0f,%.0f, j=%.0f:%.0f,%.0f,%.0f]", type, start[[1]],
      nrow(X)-1+start[[1]], chunkSize[[1]], overlap[[1]], start[[2]], ncol(X)-1+start[[2]],
      chunkSize[[2]], overlap[[2]])
    load_schema = sprintf("<val:%s null>[row=1:%.0f,1000000,0]",type,length(X))
  }
  if(!is.matrix(X)) stop ("X must be a matrix or a vector")

# Obtain a session from shim for the upload process
  session = getSession()
  on.exit( GET("/release_session",list(id=session)) ,add=TRUE)

# Upload the data
# XXX I couldn't get RCurl to work using the fileUpload(contents=x), with 'x'
# a raw vector. But we need RCurl to support SSL. As a work-around, we save
# the object. This extra local copy sucks and must be improved !!! XXX
# XXX The bug is in RCurl's curl.c addFormElement function.
# XXX
  fn = tempfile()
  bytes = writeBin(.Call("scidb_raw",as.vector(t(X)),PACKAGE="scidb"),con=fn)
  url = URI("upload_file",list(id=session))
  ans = postForm(uri = url, uploadedfile = fileUpload(filename=fn),
           .opts = curlOptions(httpheader = c(Expect = ""),'ssl.verifypeer'=0))
  unlink(fn)
  ans = ans[[1]]
  ans = gsub("\r","",ans)
  ans = gsub("\n","",ans)

# Load query
  query = sprintf("store(reshape(input(%s,'%s', 0, '(%s null)'),%s),%s)",load_schema,ans,type,schema,name)
  iquery(query)
  ans = scidb(name,gc=gc)
  ans
}
