%%raw(`import "./CoursesCurriculum__SubmissionsAndFeedback.css"`)

let str = React.string
let tr = I18n.t(~scope="components.CoursesCurriculum__SubmissionsAndFeedback", ...)

open CoursesCurriculum__Types

let gradeBar = (evaluationCriteria, grade) => {
  let criterion = Js.Array.find(
    c => EvaluationCriterion.id(c) == Grade.evaluationCriterionId(grade),
    evaluationCriteria,
  )

  switch criterion {
  | Some(criterion) =>
    let criterionId = EvaluationCriterion.id(criterion)
    let criterionName = EvaluationCriterion.name(criterion)
    let gradeNumber = Grade.grade(grade)
    let grading = Grading.make(~criterionId, ~criterionName, ~grade=gradeNumber)

    <div key={string_of_int(gradeNumber)} className="mb-4">
      <CoursesCurriculum__GradeBar grading criterion />
    </div>
  | None => React.null
  }
}

let statusBar = (~color, ~text) => {
  let textColor = "text-" ++ (color ++ "-500 ")
  let bgColor = "bg-" ++ (color ++ "-100 ")

  let icon = switch color {
  | "green" =>
    <span>
      <i className="fas fa-certificate fa-stack-2x" />
      <i className="fas fa-check fa-stack-1x fa-inverse" />
    </span>
  | _anyOtherColor => <i className="fas fa-exclamation-triangle text-3xl text-red-500 mx-1" />
  }

  <div
    className={"font-semibold p-2 py-4 flex border-t w-full items-center justify-center " ++
    (textColor ++
    bgColor)}>
    <span className={"fa-stack text-lg me-1 " ++ textColor}> icon </span>
    {str(text)}
  </div>
}

let submissionStatusIcon = (~passed) => {
  let text = passed ? tr("completed") : tr("rejected")
  let textColor = passed ? "text-green-700" : "text-red-700"

  <div className="max-w-fit flex items-center">
    {passed
      ? <span className="flex text-green-500 text-lg me-2">
          <Icon className="if i-badge-check-solid text-2xl" />
        </span>
      : React.null}
    <p className={"text-center text-sm font-semibold " ++ textColor}> {str(text)} </p>
  </div>
}

let undoSubmissionCB = () => {
  open Webapi.Dom
  Location.reload(location)
}

let gradingSection = (~grades, ~evaluationCriteria, ~gradeBar, ~passed) =>
  <div>
    <div
      className={`flex border-t flex-wrap items-center justify-center py-4
    ${passed
          ? "bg-gradient-to-br from-white via-white via-40% to-green-200"
          : "bg-gradient-to-br from-red-50 via-red-50 via-40% to-red-200"}`}>
      {passed
        ? <div className="w-full md:w-1/2 shrink-0 md:order-first px-4 md:px-6">
            <h5 className="pb-2 text-sm font-semibold"> {str(tr("grading"))} </h5>
            <div className="mt-3">
              {React.array(
                Js.Array.map(grade => gradeBar(grade), Grade.sort(evaluationCriteria, grades)),
              )}
            </div>
          </div>
        : React.null}
      <div className="w-full md:w-1/2 shrink-0 justify-center flex px-6">
        {submissionStatusIcon(~passed)}
      </div>
    </div>
  </div>

let handleAddAnotherSubmission = (setShowSubmissionForm, event) => {
  ReactEvent.Mouse.preventDefault(event)
  setShowSubmissionForm(showSubmissionForm => !showSubmissionForm)
}

let submissions = (
  currentUser,
  target,
  targetStatus,
  targetDetails,
  evaluationCriteria,
  coaches,
  users,
) => {
  let curriedGradeBar = gradeBar(evaluationCriteria)

  let submissions = TargetDetails.submissions(targetDetails)
  let totalSubmissions = Js.Array2.length(submissions)

  let completionType = targetDetails->TargetDetails.computeCompletionType

  React.array(
    Js.Array2.mapi(Submission.sort(submissions), (submission, index) => {
      let grades = TargetDetails.grades(Submission.id(submission), targetDetails)

      <div
        id={"submission-" ++ submission->Submission.id}
        key={Submission.id(submission)}
        className="mt-4 pb-4 relative curriculum__submission-feedback-container"
        ariaLabel={tr("submission_details") ++ Submission.createdAtPretty(submission)}>
        <div className="rounded-lg bg-gray-50 border border-gray-200">
          <div className="bg-gray-100 rounded-t-lg flex justify-between items-end p-4">
            <h2 className="font-medium text-sm lg:text-base leading-tight">
              {switch completionType {
              | SubmitForm =>
                str(tr("form_response_number") ++ (totalSubmissions - index)->string_of_int)
              | NoAssignment
              | TakeQuiz
              | Evaluated =>
                str(tr("submission_number") ++ (totalSubmissions - index)->string_of_int)
              }}
            </h2>
            <div className="text-xs font-mdium inline-block px-3 py-1 text-gray-800 leading-tight">
              <span className="hidden md:inline"> {str(tr("submitted_on"))} </span>
              {str(Submission.createdAtPretty(submission))}
            </div>
          </div>
          <div>
            <div className="px-4 py-4 md:px-6 md:pt-6 md:pb-5">
              <SubmissionChecklistShow
                checklist={Submission.checklist(submission)} updateChecklistCB=None
              />
            </div>
            {switch Submission.status(submission) {
            | MarkedAsComplete => statusBar(~color="green", ~text=tr("completed"))
            | Pending =>
              <div
                className="bg-white p-3 md:px-6 md:py-4 flex border-t justify-between items-center w-full">
                <div
                  className="flex items-center justify-center font-semibold text-sm ps-2 pe-3 py-1 bg-orange-100 text-orange-600 rounded">
                  <span className="fa-stack text-orange-400 me-2 shrink-0">
                    <i className="fas fa-circle fa-stack-2x" />
                    <i className="fas fa-hourglass-half fa-stack-1x fa-inverse" />
                  </span>
                  {str(tr("pending_review"))}
                </div>
                {switch TargetStatus.status(targetStatus) {
                | PendingReview =>
                  <CoursesCurriculum__UndoButton undoSubmissionCB targetId={Target.id(target)} />

                | Pending
                | Completed
                | Rejected
                | Locked(_) => React.null
                }}
              </div>
            | Completed =>
              gradingSection(~grades, ~evaluationCriteria, ~passed=true, ~gradeBar=curriedGradeBar)
            | Rejected =>
              gradingSection(~grades, ~evaluationCriteria, ~passed=false, ~gradeBar=curriedGradeBar)
            }}
            {React.array(Js.Array.map(feedback => {
                let coach =
                  Feedback.coachId(feedback)->Belt.Option.flatMap(
                    id => Js.Array.find(c => Coach.id(c) == id, coaches),
                  )

                let user = switch coach {
                | Some(coach) => Js.Array.find(up => User.id(up) == Coach.userId(coach), users)
                | None => None
                }

                let (coachName, coachTitle, coachAvatar) = switch user {
                | Some(user) => (User.name(user), User.title(user), User.avatar(user))
                | None => (
                    tr("unknown_coach"),
                    None,
                    <div
                      className="w-10 h-10 rounded-full bg-gray-400 flex items-center justify-center">
                      <i className="fas fa-user-times" />
                    </div>,
                  )
                }

                <div className="bg-white border-t p-4 md:p-6" key={Feedback.id(feedback)}>
                  <div className="flex items-center">
                    <div
                      className="shrink-0 w-12 h-12 bg-gray-300 rounded-full overflow-hidden ltr:mr me-3 object-cover">
                      coachAvatar
                    </div>
                    <div>
                      <p className="text-xs leading-tight"> {str("Feedback from:")} </p>
                      <div>
                        <h4
                          className="font-semibold text-base leading-tight block md:inline-flex self-end">
                          {str(coachName)}
                        </h4>
                        {switch coachTitle {
                        | Some(title) =>
                          <span
                            className="block md:inline-flex text-xs text-gray-800 ms-2 leading-tight self-end">
                            {str("(" ++ (title ++ ")"))}
                          </span>
                        | None => React.null
                        }}
                      </div>
                    </div>
                  </div>
                  <MarkdownBlock
                    profile=Markdown.Permissive
                    className="ms-15"
                    markdown={Feedback.feedback(feedback)}
                  />
                </div>
              }, Js.Array.filter(
                feedback => Feedback.submissionId(feedback) == Submission.id(submission),
                TargetDetails.feedback(targetDetails),
              )))}
            {switch targetDetails->TargetDetails.discussion {
            | false => React.null
            | true => {
                let comments =
                  targetDetails
                  ->TargetDetails.comments
                  ->Js.Array2.filter(comment =>
                    comment->Comment.submissionId == submission->Submission.id
                  )
                let reactions =
                  targetDetails
                  ->TargetDetails.reactions
                  ->Js.Array2.filter(reaction =>
                    reaction->Reaction.reactionableId == submission->Submission.id
                  )

                let showComments =
                  DomUtils.hasUrlParam(~key="comment_id") &&
                  DomUtils.getUrlParam(~key="submission_id")->Belt.Option.getWithDefault("") ==
                    submission->Submission.id

                <div className="flex flex-col gap-4 items-start relative p-4">
                  <div>
                    <CoursesCurriculum__Reactions
                      currentUser
                      reactionableType="TimelineEvent"
                      reactionableId={submission->Submission.id}
                      reactions
                    />
                  </div>
                  <div
                    className="curriculum-submission-comments__container relative flex w-full flex-col-reverse md:flex-row justify-end">
                    {switch submission->Submission.hiddenAt {
                    | Some(_) =>
                      <div
                        className="inline-flex md:absolute z-1 justify-center md:justify-end text-xs pt-1.5">
                        <p>
                          {("This submission was hidden by course moderators on " ++
                          Submission.hiddenAtPretty(submission))->str}
                        </p>
                      </div>
                    | None => React.null
                    }}
                    <CoursesCurriculum__SubmissionComments
                      currentUser
                      submissionId={submission->Submission.id}
                      comments
                      commentsInitiallyVisible={showComments}
                    />
                  </div>
                </div>
              }
            }}
          </div>
        </div>
      </div>
    }),
  )
}

let addSubmission = (setShowSubmissionForm, addSubmissionCB, submission) => {
  setShowSubmissionForm(_ => false)
  addSubmissionCB(submission)
}

@react.component
let make = (
  ~currentUser,
  ~targetDetails,
  ~target,
  ~evaluationCriteria,
  ~addSubmissionCB,
  ~targetStatus,
  ~coaches,
  ~users,
  ~preview,
  ~checklist,
) => {
  let (showSubmissionForm, setShowSubmissionForm) = React.useState(() => false)
  let completionType = targetDetails->TargetDetails.computeCompletionType

  <div className="max-w-3xl mx-auto mt-8">
    <div className="flex justify-between items-end pb-2">
      <h4 className="text-sm md:text-base md:leading-tight font-semibold">
        {switch completionType {
        | SubmitForm => tr("your_responses")->str
        | NoAssignment
        | TakeQuiz
        | Evaluated =>
          tr("your_submissions")->str
        }}
      </h4>
      {TargetStatus.canSubmit(~resubmittable=Target.resubmittable(target), targetStatus)
        ? switch showSubmissionForm {
          | true =>
            <button
              className="btn btn-subtle"
              onClick={handleAddAnotherSubmission(setShowSubmissionForm)}>
              <PfIcon className="if i-times-regular text-lg me-2" />
              <span className="hidden md:inline"> {str(tr("cancel"))} </span>
              <span className="md:hidden"> {str(tr("cancel"))} </span>
            </button>
          | false =>
            <button
              className="btn btn-primary"
              onClick={handleAddAnotherSubmission(setShowSubmissionForm)}>
              <PfIcon className="if i-plus-regular text-lg me-2" />
              <span className="hidden md:inline">
                {switch completionType {
                | SubmitForm => tr("add_another_response")->str
                | NoAssignment
                | TakeQuiz
                | Evaluated =>
                  tr("add_another_submission")->str
                }}
              </span>
              <span className="md:hidden"> {str(tr("add_another"))} </span>
            </button>
          }
        : React.null}
    </div>
    {showSubmissionForm
      ? <CoursesCurriculum__SubmissionBuilder
          target
          targetDetails
          addSubmissionCB={addSubmission(setShowSubmissionForm, addSubmissionCB)}
          checklist
          preview
        />
      : submissions(
          currentUser,
          target,
          targetStatus,
          targetDetails,
          evaluationCriteria,
          coaches,
          users,
        )}
  </div>
}
