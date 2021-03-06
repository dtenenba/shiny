\name{tabsetPanel}
\alias{tabsetPanel}
\title{Create a tabset panel}
\usage{
  tabsetPanel(..., id = NULL, selected = NULL,
    type = c("tabs", "pills"),
    position = c("above", "below", "left", "right"))
}
\arguments{
  \item{...}{\code{\link{tabPanel}} elements to include in
  the tabset}

  \item{id}{If provided, you can use
  \code{input$}\emph{\code{id}} in your server logic to
  determine which of the current tabs is active. The value
  will correspond to the \code{value} argument that is
  passed to \code{\link{tabPanel}}.}

  \item{selected}{The \code{value} (or, if none was
  supplied, the \code{title}) of the tab that should be
  selected by default. If \code{NULL}, the first tab will
  be selected.}

  \item{type}{Use "tabs" for the standard look; Use "pills"
  for a more plain look where tabs are selected using a
  background fill color.}

  \item{position}{The position of the tabs relative to the
  content. Valid values are "above", "below", "left", and
  "right" (defaults to "above").  Note that the
  \code{position} argument is not valid when \code{type} is
  "pill".}
}
\value{
  A tabset that can be passed to \code{\link{mainPanel}}
}
\description{
  Create a tabset that contains \code{\link{tabPanel}}
  elements. Tabsets are useful for dividing output into
  multiple independently viewable sections.
}
\examples{
# Show a tabset that includes a plot, summary, and
# table view of the generated distribution
mainPanel(
  tabsetPanel(
    tabPanel("Plot", plotOutput("plot")),
    tabPanel("Summary", verbatimTextOutput("summary")),
    tabPanel("Table", tableOutput("table"))
  )
)
}
\seealso{
  \code{\link{tabPanel}}, \code{\link{updateTabsetPanel}}
}

