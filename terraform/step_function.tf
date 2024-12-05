resource "aws_sfn_state_machine" "upload_workflow" {
  name     = "${var.project_name}-upload-workflow"
  role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"

  definition = jsonencode({
    StartAt = "ValidateFile"
    States = {
      ValidateFile = {
        Type = "Task"
        Resource = aws_lambda_function.validate_file.arn
        Next = "ProcessUpload"
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next = "FailureState"
        }]
      }
      ProcessUpload = {
        Type = "Task"
        Resource = aws_lambda_function.upload_file.arn
        End = true
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next = "FailureState"
        }]
        ResultPath = "$.uploadResult"
      }
      FailureState = {
        Type = "Fail"
        Cause = "File Upload Process Failed"
        Error = "FileUploadError"
      }
    }
  })
}
