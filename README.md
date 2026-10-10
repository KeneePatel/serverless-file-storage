# Serverless File Storage

A small cloud file storage app built for the CSCI 5409 (Advanced Topics in Cloud Computing) term project, Fall 2024. Users sign up with an email address, upload JPEG, PNG, or PDF files up to 10 MB, and download them later. Each user sees only their own files.

Terraform provisions all of the AWS infrastructure. The backend is six Node.js Lambda functions, and the frontend is a Next.js app running in Docker on Elastic Beanstalk.

## How it works

```
Browser (Next.js on Elastic Beanstalk)
  │  sign up / sign in ──────────────► Cognito user pool (returns a JWT)
  ▼
API Gateway (Cognito authorizer on every route)
  ├─ GET  /files             → list_files           → DynamoDB
  ├─ POST /files             → Step Functions: validate_file → upload_file
  ├─ GET  /executions/{arn}  → get_execution_result
  └─ GET  /files/{fileId}    → download_file        → presigned S3 GET URL

Browser ── PUT file ──► S3 ── ObjectCreated ──► update_file_status → DynamoDB
```

An upload happens in three steps. The browser posts the file's name, type, and size to `/files`, which starts a Step Functions workflow: `validate_file` checks the size and type, then `upload_file` writes a `pending` row to DynamoDB and creates a presigned S3 PUT URL. The browser polls `/executions/{arn}` until the workflow finishes and returns that URL. Finally, the browser uploads the file straight to S3, and the S3 event triggers `update_file_status`, which marks the row `uploaded`.

Files live in S3 under `<cognito-sub>/<fileId>`, and DynamoDB keys the metadata on `userId` and `fileId`. The list and download handlers take the user ID from the verified token, so one user can't read another user's files. Download links expire after an hour.

## AWS services

| Service | Role in the project |
|---|---|
| Lambda | API handlers and the upload workflow steps |
| Elastic Beanstalk | Hosts the Next.js frontend (Docker, single t2.medium instance) |
| S3 | Stores user files and frontend deployment bundles |
| API Gateway | REST API with a Cognito authorizer |
| DynamoDB | File metadata, on-demand billing |
| Step Functions | Upload workflow (validate, then prepare the upload) |
| CloudWatch | API Gateway metrics and logs, Beanstalk log streaming |
| Cognito | Sign-up, email verification, and sign-in |

Every resource uses the AWS Academy `LabRole` and `LabInstanceProfile`.

## Repository layout

```
terraform/               Infrastructure, one .tf file per service
terraform/lambda/        Lambda source, one folder per function
terraform/scripts/       generate-env.ts copies Terraform outputs into the frontend's .env.local
file-storage-frontend/   Next.js 15 app and the Dockerfile Beanstalk builds
project_details.pdf      Assignment brief
```

## Prerequisites

- An AWS Academy Learner Lab session, with its credentials in your AWS CLI config
- Terraform, Node.js 22, and pnpm
- The Terraform state bucket `aws-backend-bucket-2804` and lock table `app-state` in `us-east-1`. Terraform doesn't create these (see `terraform/backend.tf`).

## Deploy

Install the Lambda dependencies first. Five of the functions use AWS SDK v2, which the `nodejs22.x` runtime doesn't include, and `node_modules` isn't committed.

```bash
cd terraform/lambda
for fn in download_file get_execution_result list_files update_file_status upload_file; do
  (cd $fn && npm install)
done
```

Then provision everything:

```bash
cd terraform
terraform init
terraform apply
```

Next.js bakes the `NEXT_PUBLIC_*` settings (Cognito IDs and the API URL) into the frontend at build time, but Beanstalk sets environment variables only when the container runs. On a first deploy, write the settings to `.env.local` and apply again so the Docker build includes them:

```bash
cd file-storage-frontend
pnpm install
pnpm generate-env
cd ../terraform
terraform apply
```

`terraform output frontend_url` prints the app's address. Each apply uploads a new frontend version, so Beanstalk redeploys every time.

To tear it all down, run `terraform destroy`. Both S3 buckets use `force_destroy`, so their contents go with them.

## Run the frontend locally

After a deploy:

```bash
cd file-storage-frontend
pnpm install
pnpm dev
```

`pnpm dev` regenerates `.env.local` from the Terraform outputs and starts Next.js at http://localhost:3000.

## Limitations

- The size and type checks use what the browser reports. The presigned URL doesn't enforce them, so a modified client could upload a bigger file.
- Sessions last one hour with no token refresh. After that, API calls fail until you sign in again.
- There's no delete or sharing, and the file list doesn't update after an upload until you reload the page.
