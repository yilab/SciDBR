\name{index_lookup}
\alias{index_lookup}
\title{
index_lookup
}
\description{
The \code{index_lookup} function is a wrapper to the SciDB `index_lookup` operator.
It produces a new SciDB array that joins the unqiue indices defined in the array
\code{I} with values looked up in array \code{X} for attribute \code{attr}. Use
the \code{index_lookup} with the \code{unique} and \code{sort} functions.
}
\usage{
index_lookup(X, I, attr, new_attr=paste(attr,"index",sep="_"), eval)
}
\arguments{
  \item{X}{A scidb, scidbdf, or scidbexpr object}
  \item{I}{A scidb, scidbdf, or scidbexpr object}
  \item{attr}{A character string attribute name from the \code{X} array}
  \item{new_attr}{An optional character name for the new attribute, defaults to \code{attr} + "_index"}
  \item{eval}{A logical value: if TRUE then evaluate the \code{index_lookup} expression and return a \code{scidb} object, otherwise return a \code{scidbexpr} object that contains a character string representation of the un-evaluated SciDB query. By default, eval is set to FALSE if \code{index_lookup} is called from another function in the scidb package.}
}
\value{
Either a \code{scidb} object or a \code{scidbexpr} object depending on the value of \code{eval}.
}
\note{
Use \code{eval=FALSE} to defer expression evaluation for efficiency. Many functions in the SciDB package accept un-evaluated expresions represented as \code{scidbexpr} objects. One can compose these objects to form complex query expressions that can be evaluated in one transaction.
}
\author{
B. W. Lewis<blewis@paradigm4.com>
}
\seealso{
  \code{\link{scidb}}
}
\examples{
\dontrun{
library("scidb")
scidbconnect()

x <- as.scidb(iris)

# Create a unique list of elements of the "Species" attribute.
# Note that we choose to defer evaluation of this expression.
y <- unique(sort(project(x,"Species")), eval=FALSE)

# Append a new attribute to the array x called "Species_index" that
# enumerates the unique values of the "Species" attribute:
z <- index_lookup(x, y, "Species")

print(head(z))
}}