#' Reads Thomson Reuters Web of Knowledge/Science and ISI reference export files (.txt and .ciw)
#'
#' \code{references_read} This function reads Thomson Reuters Web of Knowledge
#' and ISI format reference data files into an R friendly data format.
#'
#' @param data either a directory, used in conjuction with dir=TRUE, or a file
#'   name to load.
#' @param dir if TRUE then data is assumed to be a directory name from which all
#'   files will be read, but if FALSE then data is assumed to be a single file
#'   to read, defaults to FALSE
#' @param include_all should all columns be included, or just the most commonly recorded. 
#'  default=FALSE.
#'  the following Web of Science data fields are only included if users select the `include_all=TRUE` option in `references_read()`: CC, CH, CL, CT, CY, DT, FX, GA, GE, ID, IS, J9, JI, LA, LT, MC, MI, NR, PA, PI, PN, PS, RID, SU, TA, VR.
#' @export references_read
#' 
references_read <- function(data = ".", dir = FALSE, include_all=FALSE) {
 ## 	NOTE: The fields stored in our output table are a combination of the
 ## 		"Thomson Reuters Web of Knowledge" FN format and the "ISI Export
 ## 		Format" both of which are version 1.0:
  output <- data.frame(
  "filename" = character(0),
  "AB" = character(0),
  "AF" = character(0),
  "AU" = character(0),
  "BP" = character(0),
  "C1" = character(0),
  "CC" = character(0),
  "CH" = character(0),
  "CL" = character(0),
  "CR" = character(0),
  "CT" = character(0),
  "CY" = character(0),
  "DE" = character(0),
  "DI" = character(0),
  "DT" = character(0),
  # 	"EF" = character(0),	##	End file
  "EM" = character(0),
  "EP" = character(0),
  # 	"ER" = character(0),	##	End record
  "FN" = character(0),
  "FU" = character(0),
  "FX" = character(0),
  "GA" = character(0),
  "GE" = character(0),
  "ID" = character(0),
  "IS" = character(0),
  "J9" = character(0),
  "JI" = character(0),
  "LA" = character(0),
  "LT" = character(0),
  "MC" = character(0),
  "MI" = character(0),
  "NR" = character(0),
  "PA" = character(0),
  "PD" = character(0),
  "PG" = character(0),
  "PI" = character(0),
  "PN" = character(0),
  "PS" = character(0),
  "PT" = character(0),
  "PU" = character(0),
  "PY" = character(0),
  "RI" = character(0), # NEW field code for Thomson-Reuters ResearcherID
  "RID" = character(0), # OLD field code for Thomson-Reuters ResearcherID
  # Older searchers will have RID, not RI ACTUALLY LOOK SL IKE NOT
  "OI" = character(0), # New field code for ORCID ID (added EB Jan 2017)
  "PM" = character(0), # Pubmed ID Number (added by EB 3 dec 2017)
  "RP" = character(0),
  "SC" = character(0),
  "SI" = character(0),
  "SN" = character(0),
  "SO" = character(0),
  "SU" = character(0),
  "TA" = character(0),
  "TC" = character(0),
  "TI" = character(0),
  "UT" = character(0),
  "VR" = character(0),
  "VL" = character(0),
  "WC" = character(0),
  "Z9" = character(0),
  stringsAsFactors = FALSE
  )

  ## 	This is an index for the current record, it gets iterated for each
  # record we advance through:
  i <- 1
  if (dir) {
    file_list <- dir(path = data)
  } else {
    file_list <- data
  }

  ## 	Strip out any files in the directory that aren't Web of Knowledge files:
  file_list <- file_list[ grep(".ciw|.txt", file_list) ]

  if (length(file_list) == 0) {
    stop("ERROR:  The specified file or directory does not contain any
          Web of Knowledge or ISI Export Format records!")
  }
  message("Now processing all references files")
  filename <- file_list[1]
  counter <- 1
  for (filename in file_list) {
    if (dir) {
      in_file <- file(paste0(data, "/", filename), "r")
    }
    if (!dir) {
      in_file <- file(filename, "r")
    }

    field <- ""

    ## 	Process the first line to determine what file type it is:
    ## 		NOTE:  We could add the encoding="UTF-8" flag to the readLines in
    ## 		order to remove the byte-order mark (BOM) from some exported
    ## 		files coming out of ISI, but there seems to be a bug in the
    ## 		readLines() function after bringing a UTF-8 file in, in that
    ## 		it doesn't respsect the BOM characters.  So we'll just read
    ## 		the files in with no encoding specified and strip the BOM if

    read_line <- readLines(in_file, n = 1, warn = FALSE)

    if (length(read_line) > 0) {

      read_line <- gsub("^[^A-Z]*([A-Z]+)(.*)$", "\\1\\2", read_line)


      ## 	Strip the first two characters from the text line,
      # skip the third (should be a space) and store the rest:
      pre_text <- substr(read_line, 1, 2)
      line_text <- substr(read_line, 4, nchar(read_line))

      if (pre_text != "FN") {
        close(in_file)
        error<-paste0("ERROR:  The file ", filename, " doesn't appear to be a valid
      ISI or Thomson Reuters reference library file!")
        stop(error)
      }

      ## 	Check to see if this is a "ISI Export Format" file, in which
      ## 		case we need to parse out the first line into three fields:
      if (substr(line_text, 1, 3) == "ISI") {
        field <- pre_text

        ## 	Pull apart the FN, VR and PT fields all contained on the first
        ## 		line of the ISI file format:
        matches <- regexec(
          "^(.*) VR (.*) PT (.*)",
          line_text
        )

        match_strings <- regmatches(
          line_text,
          matches
        )

        ## 	Store those fields:
        output[i, "FN"] <- paste(match_strings[[1]][2], "\n", sep = "")

        output[i, "VR"] <- paste(match_strings[[1]][3], "\n", sep = "")

        output[i, "PT"] <- paste(match_strings[[1]][4], "\n", sep = "")
      } else {

        ## 	If this is not an ISI export format then just parse the first
        ## 		line normally into the FN field:
        field <- pre_text
        if (field %in% names(output)) {
          output[i, field] <- ""
          output[i, field] <- trimws(ifelse(length(line_text) == 1,
                                    paste(output[i, field], line_text,
                                    sep = "\n")), "both")
        }
      }
    } else {
      utils::flush.console()
      stop("WARNING:  Nothing contained in the specified file!")
    }


    ## 	Process the remaining lines in the file (see the note above about
    ## 		the encoding= flag and necessity for it, but why we didn't use it):
    while (length(read_line <- readLines(in_file, n = 1, warn = FALSE)) > 0) {
      ## 	Strip the first three characters from the text line:
      pre_text <- substr(read_line, 1, 2)

      line_text <- substr(read_line, 4, nchar(read_line))


      ## 	Check to see if this is a new field:
      if (pre_text != "  ") {
        field <- pre_text
        ## 	If the field is in our file and in our data structure then
        ## 		initialize it to an empty string:
        if (field %in% names(output)) {
          output[i, field] <- ""
        }
      }

      ## 	Check to see if the current field is one we are saving to output:
      if (field %in% names(output)) {
  ## 	... if it is then append this line's data to the field in our output:

        output[i, field] <- trimws(ifelse(length(line_text) == 1,
                              paste(output[i, field], line_text, sep = "\n"
        )), "both")
      }

      # 	If this is the end of a record then add any per-record items and
      # 		advance our row:
      if (field == "ER") {
        output[i, "filename"] <- filename

        ## 	These fields are not repeated for every record, so we set them
        ## 		from the first record where they were recorded:

        output[i, "FN"] <- output[1, "FN"]
        output[i, "VR"] <- output[1, "VR"]

        i <- i + 1
      }
    }

    close(in_file)
    ############################### Clock######################################
    total <- length(file_list)
    pb <- utils::txtProgressBar(min = 0, max = total, style = 3)
    utils::setTxtProgressBar(pb, counter)
    counter <- counter + 1
    utils::flush.console()
    ############################################################################
  }
  ############################################## 3
  # Post Processing
  # We need to clean this file, page breaks are inserted in the raw file
  # These are problematic because they mean
  # different things for different fields

  output$RI <- gsub("\n", "", output$RI, fixed = TRUE)
  output$RI <- gsub("; ", ";", output$RI, fixed = TRUE)
  #This fixes a problem where in earlier WOS pulls RI is stored
  # as RID with no name associated
  output$RI[!grepl("/", output$RI)] < -NA
  output$OI <- gsub("\n", "", output$OI, fixed = TRUE)
  output$OI <- gsub("; ", ";", output$OI, fixed = TRUE)
  output$PY <- gsub("\n", "", output$PY, fixed = TRUE)
  output$C1 <- gsub("\n", "/", output$C1, fixed = TRUE)
  output$AF[is.na(output$AF)] <- output$AU[is.na(output$AF)]
  output$refID <- seq_len(nrow(output))

  # now done in base R, runs slower
  dupe_output <- do.call(rbind, lapply(unique(output$UT),
                                  function(x) output[output$UT == x, ][1, ]))
  ############################################
  # Prepare for printing

  if ( include_all == TRUE ){
    return(dupe_output)
  }

  if ( include_all != TRUE ){

  dropnames <- c("CC", "CH", "CL", "CT", "CY",
                 "DT", "FX", "GA", "GE", "ID",
                 "IS", "J9", "JI", "LA", "LT",
                 "MC", "MI", "NR", "PA", "PI",
                 "PN", "PS", "RID", "SI", "SU",
                 "TA", "VR")

  rdo <- dupe_output[, !(names(dupe_output) %in% dropnames) ]

  return(rdo)
  }
}
