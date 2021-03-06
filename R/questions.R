setRefClass('seQuestion',
            fields = list(
              questionID = 'character',
              answerCount = 'numeric',
              favoriteCount = 'numeric',
              owner = 'seUser',
              creationDate = 'POSIXct',
              lastActivityDate = 'POSIXct',
              upVoteCount = 'numeric',
              downVoteCount = 'numeric',
              viewCount = 'numeric',
              score = 'numeric',
              communityOwned = 'logical',
              title = 'character',
              comments = 'list',
              tags = 'list',
              answers = 'list',
              site = 'character'),
            methods = list()
            )

seQuestionFactory <- getRefClass('seQuestion')
seQuestionFactory$accessors(names(seQuestionFactory$fields()))

setMethod("show", signature='seQuestion', function(object) {
  print(object$getTitle())
})

buildQuestions <- function(jsonList, site) {
  userIDs <- sapply(jsonList, function(x) x[['owner']][['user_id']])
  users <- getUsers(userIDs, length(userIDs), site)
  names(users) <- sapply(users, function(x) x$getUserID())

  mapply(function(json, userID, users, site) {
    comments <- buildComments(json[['comments']], site)
    answers <- buildAnswers(json[['answers']], site)
    if ((!is.null(userID)) && (userID %in% names(users))) {
      curUser <- users[[as.character(userID)]]
    } else {
      curUser <- seUserFactory$new()
    }
    ## FIXME:  Dont' see a way right now to convert the tags return into
    ## seTag objects
    seQuestionFactory$new(questionID= json[['question_id']],
                          creationDate = convertDate(json[['creation_date']]),
                          lastActivityDate = convertDate(json[['last_activity_date']]),
                          upVoteCount = json[['up_vote_count']],
                          downVoteCount = json[['down_vote_count']],
                          favoriteCount = json[['favorite_count']],
                          answerCount = json[['answer_count']],
                          viewCount = json[['view_count']],
                          score = json[['score']],
                          communityOwned = ifelse(json[['community_owned']],
                            TRUE, FALSE),
                          title = json[['title']],
                          site = site, owner=curUser, comments=comments,
                          tags = as.list(json[['tags']]),
                          answers = answers,
                          site = site)
  }, jsonList, userIDs, MoreArgs=list(site=site, users=users))
}

getQuestions <- function(num=NULL, ids=NULL, fromDate=NULL, toDate=NULL,
                         min=NULL, max=NULL, sort=NULL, order=NULL,
                         tagged=NULL, site='stackoverflow.com') {
  questionBase(num=num, ids=ids, fromDate=fromDate, toDate=toDate,
               min=min, max=max, sort=sort, order=order, tagged=tagged, site=site)
}

getUnansweredQuestions <- function(num=NULL, fromDate=NULL, toDate=NULL,
                                   min=NULL, max=NULL, sort=NULL, order=NULL,
                                   tagged=NULL, site='stackoverflow.com') {
  ## FIXME:  Dox list 'sort' as a possible argument, but it looks like it doesn't work.
  ## need to investigate this further
  if (!is.null(sort)) {
    sort <- NULL
    warning("Sort argument is temporarily disabled for getUnasweredQuestions")
  }
  questionBase(num=num, ids=NULL, fromDate=fromDate, toDate=toDate,
               min=min, max=max, sort=sort, order=order,
               postVex='unanswered', site=site, tagged=tagged)
}

getNoAnswerQuestions <- function(num=NULL, fromDate=NULL, toDate=NULL,
                                 min=NULL, max=NULL, sort=NULL, order=NULL,
                                 tagged=NULL, site='stackoverflow.com') {
  questionBase(num=num, ids=NULL, fromDate=fromDate, toDate=toDate,
               min=min, max=max, sort=sort, order=order,
               postVex='no-answers', site=site, tagged=tagged)
}

getQuestionLinks <- function(num=NULL, ids=NULL, fromDate=NULL,
                             toDate=NULL, min=NULL, max=NULL, sort=NULL,
                             order=NULL, site='stackoverflow.com') {
  if (is.null(ids))
    stop("getQuestionLinks requres at least one id")
  
  questionBase(num=num, ids=ids, fromDate=fromDate, toDate=toDate,
               min=min, max=max, sort=sort, order=order, postVex='linked',
               site=site)
}

getQuestionRelated <- function(num=NULL, ids=NULL, fromDate=NULL,
                               toDate=NULL, min=NULL, max=NULL, sort=NULL,
                               order=NULL, site='stackoverflow.com') {
  if (is.null(ids))
    stop("getQuestionRelated requires at least one ID")
  
  questionBase(num=num, ids=ids, fromDate=fromDate, toDate=toDate,
                           min=min, max=max, sort=sort, order=order, site=site,
                           postVex='related')
}

## FIXME:  Skipping timeline for now

questionBase <- function(num=NULL, ids=NULL, fromDate=NULL, toDate=NULL,
                         min=NULL, max=NULL, sort=NULL, order=NULL,
                         tagged=NULL, site='stackoverflow.com', postVex=NULL) {
  params <- buildCommonArgs(fromdate=fromDate, todate=toDate, min=min,
                            max=max, sort=sort, order=order)
  if (!is.null(tagged))
    params[['tagged']] <- paste(tagged, collapse=';')
  params[['body']] <- params[['answers']] <- params[['comments']] <- 'true'
  jsonList <- seInterfaceObj$request('questions', ids, postVex, params,
                                     'questions', num=num, site=site)
  buildQuestions(jsonList, site)
}

          
