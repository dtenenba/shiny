

htmlEscape <- local({
  .htmlSpecials <- list(
    `&` = '&amp;',
    `<` = '&lt;',
    `>` = '&gt;'
  )
  .htmlSpecialsPattern <- paste(names(.htmlSpecials), collapse='|')
  .htmlSpecialsAttrib <- c(
    .htmlSpecials,
    `'` = '&#39;',
    `"` = '&quot;',
    `\r` = '&#13;',
    `\n` = '&#10;'
  )
  .htmlSpecialsPatternAttrib <- paste(names(.htmlSpecialsAttrib), collapse='|')
  
  function(text, attribute=T) {
    pattern <- if(attribute)
      .htmlSpecialsPatternAttrib 
    else
      .htmlSpecialsPattern
    
    # Short circuit in the common case that there's nothing to escape
    if (!grepl(pattern, text))
      return(text)
    
    specials <- if(attribute)
      .htmlSpecialsAttrib
    else
      .htmlSpecials
    
    for (chr in names(specials)) {
      text <- gsub(chr, specials[[chr]], text, fixed=T)
    }
    
    return(text)
  }
})

isTag <- function(x) {
  inherits(x, "shiny.tag")
}

#' @export
appendChild <- function(tag, child) {
  tag$children[[length(tag$children)+1]] <- child
  tag
}

# create a tag 
#' @export
tag <- function(`_tag_name`, varArgs) {
  
  # create basic tag data structure
  tag <- list()
  class(tag) <- "shiny.tag"
  tag$name <- `_tag_name`
  tag$attribs <- list()
  tag$children <- list()
  
  # process varArgs
  varArgsNames <- names(varArgs)
  if (is.null(varArgsNames))
    varArgsNames <- character(length=length(varArgs))
  
  if (length(varArgsNames) > 0) {
    for (i in 1:length(varArgsNames)) {
      # save name and value
      name <- varArgsNames[[i]]
      value <- varArgs[[i]]
      
      # process attribs
      if (nzchar(name))
        tag$attribs[[name]] <- value
      
      # process child tags
      else if (isTag(value)) {
        tag$children[[length(tag$children)+1]] <- value
      }
      
      # recursively process lists of children
      else if (is.list(value)) {
        
        appendChildren <- function(tag, children) {
          for(child in children) {
            if (isTag(child))
              tag <- appendChild(tag, child)
            else if (is.list(child))
              tag <- appendChildren(tag, child)
            else
              tag <- appendChild(tag, as.character(child))
          }
          return (tag)
        }
        
        tag <- appendChildren(tag, value)
      }
      
      # everything else treated as text
      else {
        tag <- appendChild(tag, as.character(value))
      }
    }
  }
  
  # return the tag
  return (tag)
}


#' @export
writeChildren <- function(children, textWriter, indent, context) {
  for (child in children) {
    if (isTag(child)) {
      writeTag(child, textWriter, indent, context)
    }
    else {
      child <- htmlEscape(child, attribute=FALSE)
      indentText <- paste(rep(" ", indent*3), collapse="")
      textWriter(paste(indentText, child, "\n", sep=""))
    }
  }
}

#' @export
writeTag <- function(tag, textWriter, indent=0, context = NULL) {
  
  # optionally process a list of tags
  if (!isTag(tag) && is.list(tag)) {
    sapply(tag, function(t) writeTag(t, textWriter, indent, context))
    return (NULL)
  }
  
  # first call optional filter -- exit function if it returns false
  if (!is.null(context) && !is.null(context$filter) && !context$filter(tag))
    return (NULL)
  
  # compute indent text
  indentText <- paste(rep(" ", indent*3), collapse="")
  
  # write tag name
  textWriter(paste(indentText, "<", tag$name, sep=""))
  
  # write attributes
  for (attrib in names(tag$attribs)) {
    attribValue <- tag$attribs[[attrib]]
    if (!is.na(attribValue)) {
      text <- htmlEscape(attribValue, attribute=TRUE) 
      textWriter(paste(" ", attrib,"=\"", text, "\"", sep=""))
    }
    else {
      textWriter(paste(" ", attrib, sep=""))
    }
  }
  
  # write any children
  if (length(tag$children) > 0) {
    
    # special case for a single child text node (skip newlines and indentation)
    if ((length(tag$children) == 1) && is.character(tag$children[[1]]) ) {
      text <- htmlEscape(tag$children[1], attribute=FALSE)
      textWriter(paste(">", text, "</", tag$name, ">\n", sep=""))
    }
    else {
      textWriter(">\n")
      writeChildren(tag$children, textWriter, indent+1, context)
      textWriter(paste(indentText, "</", tag$name, ">\n", sep=""))
    }
  }
  else {
    # only self-close void elements 
    # (see: http://dev.w3.org/html5/spec/single-page.html#void-elements)
    if (tag$name %in% c("area", "base", "br", "col", "command", "embed", "hr", 
                        "img", "input", "keygen", "link", "meta", "param",
                        "source", "track", "wbr")) {
      textWriter("/>\n")
    }
    else {
      textWriter(paste("></", tag$name, ">\n", sep=""))
    }
  }
}


#' @export
p <- function(...)  tag("p", list(...))

#' @export
h1 <- function(...) tag("h1", list(...))

#' @export
h2 <- function(...) tag("h2", list(...))

#' @export
h3 <- function(...) tag("h3", list(...))

#' @export
h4 <- function(...) tag("h4", list(...))

#' @export
h5 <- function(...) tag("h5", list(...))

#' @export
h6 <- function(...) tag("h6", list(...))

#' @export
a <- function(...) tag("a", list(...))

#' @export
br <- function(...) tag("br", list(...))

#' @export
div <- function(...) tag("div", list(...))

#' @export
span <- function(...) tag("span", list(...))

#' @export
pre <- function(...) tag("pre", list(...))

#' @export
code <- function(...) tag("code", list(...))

#' @export
img <- function(...) tag("img", list(...))

#' @export
strong <- function(...) tag("strong", list(...))

#' @export
em <- function(...) tag("em", list(...))



# environment used to store all available tags
#' @export
tags <- new.env()
tags$a <- function(...) tag("a", list(...))
tags$abbr <- function(...) tag("abbr", list(...))
tags$address <- function(...) tag("address", list(...))
tags$area <- function(...) tag("area", list(...))
tags$article <- function(...) tag("article", list(...))
tags$aside <- function(...) tag("aside", list(...))
tags$audio <- function(...) tag("audio", list(...))
tags$b <- function(...) tag("b", list(...))
tags$base <- function(...) tag("base", list(...))
tags$bdi <- function(...) tag("bdi", list(...))
tags$bdo <- function(...) tag("bdo", list(...))
tags$blockquote <- function(...) tag("blockquote", list(...))
tags$body <- function(...) tag("body", list(...))
tags$br <- function(...) tag("br", list(...))
tags$button <- function(...) tag("button", list(...))
tags$canvas <- function(...) tag("canvas", list(...))
tags$caption <- function(...) tag("caption", list(...))
tags$cite <- function(...) tag("cite", list(...))
tags$code <- function(...) tag("code", list(...))
tags$col <- function(...) tag("col", list(...))
tags$colgroup <- function(...) tag("colgroup", list(...))
tags$command <- function(...) tag("command", list(...))
tags$data <- function(...) tag("data", list(...))
tags$datalist <- function(...) tag("datalist", list(...))
tags$dd <- function(...) tag("dd", list(...))
tags$del <- function(...) tag("del", list(...))
tags$details <- function(...) tag("details", list(...))
tags$dfn <- function(...) tag("dfn", list(...))
tags$div <- function(...) tag("div", list(...))
tags$dl <- function(...) tag("dl", list(...))
tags$dt <- function(...) tag("dt", list(...))
tags$em <- function(...) tag("em", list(...))
tags$embed <- function(...) tag("embed", list(...))
tags$eventsource <- function(...) tag("eventsource", list(...))
tags$fieldset <- function(...) tag("fieldset", list(...))
tags$figcaption <- function(...) tag("figcaption", list(...))
tags$figure <- function(...) tag("figure", list(...))
tags$footer <- function(...) tag("footer", list(...))
tags$form <- function(...) tag("form", list(...))
tags$h1 <- function(...) tag("h1", list(...))
tags$h2 <- function(...) tag("h2", list(...))
tags$h3 <- function(...) tag("h3", list(...))
tags$h4 <- function(...) tag("h4", list(...))
tags$h5 <- function(...) tag("h5", list(...))
tags$h6 <- function(...) tag("h6", list(...))
tags$head <- function(...) tag("head", list(...))
tags$header <- function(...) tag("header", list(...))
tags$hgroup <- function(...) tag("hgroup", list(...))
tags$hr <- function(...) tag("hr", list(...))
tags$html <- function(...) tag("html", list(...))
tags$i <- function(...) tag("i", list(...))
tags$iframe <- function(...) tag("iframe", list(...))
tags$img <- function(...) tag("img", list(...))
tags$input <- function(...) tag("input", list(...))
tags$ins <- function(...) tag("ins", list(...))
tags$kbd <- function(...) tag("kbd", list(...))
tags$keygen <- function(...) tag("keygen", list(...))
tags$label <- function(...) tag("label", list(...))
tags$legend <- function(...) tag("legend", list(...))
tags$li <- function(...) tag("li", list(...))
tags$link <- function(...) tag("link", list(...))
tags$mark <- function(...) tag("mark", list(...))
tags$map <- function(...) tag("map", list(...))
tags$menu <- function(...) tag("menu", list(...))
tags$meta <- function(...) tag("meta", list(...))
tags$meter <- function(...) tag("meter", list(...))
tags$nav <- function(...) tag("nav", list(...))
tags$noscript <- function(...) tag("noscript", list(...))
tags$object <- function(...) tag("object", list(...))
tags$ol <- function(...) tag("ol", list(...))
tags$optgroup <- function(...) tag("optgroup", list(...))
tags$option <- function(...) tag("option", list(...))
tags$output <- function(...) tag("output", list(...))
tags$p <- function(...) tag("p", list(...))
tags$param <- function(...) tag("param", list(...))
tags$pre <- function(...) tag("pre", list(...))
tags$progress <- function(...) tag("progress", list(...))
tags$q <- function(...) tag("q", list(...))
tags$ruby <- function(...) tag("ruby", list(...))
tags$rp <- function(...) tag("rp", list(...))
tags$rt <- function(...) tag("rt", list(...))
tags$s <- function(...) tag("s", list(...))
tags$samp <- function(...) tag("samp", list(...))
tags$script <- function(...) tag("script", list(...))
tags$section <- function(...) tag("section", list(...))
tags$select <- function(...) tag("select", list(...))
tags$small <- function(...) tag("small", list(...))
tags$source <- function(...) tag("source", list(...))
tags$span <- function(...) tag("span", list(...))
tags$strong <- function(...) tag("strong", list(...))
tags$style <- function(...) tag("style", list(...))
tags$sub <- function(...) tag("sub", list(...))
tags$summary <- function(...) tag("summary", list(...))
tags$sup <- function(...) tag("sup", list(...))
tags$table <- function(...) tag("table", list(...))
tags$tbody <- function(...) tag("tbody", list(...))
tags$td <- function(...) tag("td", list(...))
tags$textarea <- function(...) tag("textarea", list(...))
tags$tfoot <- function(...) tag("tfoot", list(...))
tags$th <- function(...) tag("th", list(...))
tags$thead <- function(...) tag("thead", list(...))
tags$time <- function(...) tag("time", list(...))
tags$title <- function(...) tag("title", list(...))
tags$tr <- function(...) tag("tr", list(...))
tags$track <- function(...) tag("track", list(...))
tags$u <- function(...) tag("u", list(...))
tags$ul <- function(...) tag("ul", list(...))
tags$var <- function(...) tag("var", list(...))
tags$video <- function(...) tag("video", list(...))
tags$wbr <- function(...) tag("wbr", list(...))

# environment used to do substitution in withTags
.tagSubs <- new.env()
for (tagName in ls(tags)) {
  .tagSubs[[tagName]] <- substituteDirect(quote(tags$tag), list(tag=tagName))
}

# evaluate an expression with the set of html tags in scope
#' @export
withTags <- function(expr) {
 exprTree <- substitute(eval(quote(expr)))
 targetExpr <- substituteDirect(exprTree, .tagSubs)
 eval.parent(targetExpr)
}