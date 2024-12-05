"use client"

import { useState } from "react"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { UploadIcon } from "lucide-react"

export function UploadFileDialog() {
  const [isUploading, setIsUploading] = useState(false)
  const [file, setFile] = useState<File | null>(null)

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      setFile(e.target.files[0])
    }
  }

  const handleUpload = async () => {
    if (!file) return

    try {
      console.log("Starting file upload process...")
      console.log("File details:", {
        name: file.name,
        type: file.type,
        size: file.size
      })

      setIsUploading(true)
      const token = localStorage.getItem("token")
      console.log("Token retrieved from localStorage")

      // Step 1: Start the workflow
      console.log("Step 1: Starting workflow...")
      const startWorkflowResponse = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/files`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`
        },
        body: JSON.stringify({
          fileName: file.name,
          fileType: file.type,
          fileSize: file.size
        })
      })

      if (!startWorkflowResponse.ok) {
        console.error("Workflow start failed with status:", startWorkflowResponse.status)
        throw new Error("Failed to start upload workflow")
      } else {
        console.log("Workflow started successfully")
        console.log("Response:", startWorkflowResponse)
      }

      const responseText = await startWorkflowResponse.text()
      const cleanedText = responseText.replace(/,\s*}/, '}') // Remove trailing comma before closing brace
      const workflowResponse = JSON.parse(cleanedText)
      console.log("Workflow response:", workflowResponse)
      const { executionArn } = workflowResponse
      console.log("Workflow started successfully:", workflowResponse)

      // Step 2: Get the upload URL
      console.log("Step 2: Fetching upload URL...")
      console.log("Using Execution ARN:", executionArn)

      let attempts = 0;
      let getUploadUrlResponse;
      let responseData;
      
      while (attempts < 3) {
        getUploadUrlResponse = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/executions/${executionArn}`, {
          headers: {
            Authorization: `Bearer ${token}`
          }
        });

        if (!getUploadUrlResponse.ok) {
          console.error("Failed to get upload URL. Status:", getUploadUrlResponse.status);
          throw new Error("Failed to get upload URL");
        }

        responseData = await getUploadUrlResponse.json();
        
        if (responseData.status === "running") {
          console.log("Execution still in progress, waiting 2 seconds before retry...");
          await new Promise(resolve => setTimeout(resolve, 2000));
          attempts++;
          continue;
        }
        
        // If we get here, the execution is complete
        console.log("Execution completed successfully")
        break;
      }

      if (attempts >= 3) {
        throw new Error("Upload workflow is taking too long to complete");
      }

      if (!getUploadUrlResponse) {
        throw new Error("Failed to get upload URL response");
      }

      // We've already read the response body in the while loop above,
      // so we need to use that response data instead of trying to read it again
      const { uploadUrl } = responseData;
      console.log("Upload URL received:", uploadUrl)

      // Step 3: Upload the file
      console.log("Step 3: Uploading file to S3...")
      const uploadResponse = await fetch(uploadUrl, {
        method: "PUT",
        body: file,
        headers: {
          "Content-Type": file.type
        }
      })

      if (!uploadResponse.ok) {
        console.error("File upload failed. Status:", uploadResponse.status)
        throw new Error("Failed to upload file")
      }

      console.log("File upload completed successfully!")

      // Reset state and close dialog
      setFile(null)
      setIsUploading(false)
      
    } catch (error) {
      console.error("Error uploading file:", error)
      if (error instanceof Error) {
        console.error("Error message:", error.message)
        console.error("Error stack:", error.stack)
      }
      setIsUploading(false)
    }
  }

  return (
    <Dialog>
      <DialogTrigger asChild>
        <Button>
          <UploadIcon className="mr-2 h-4 w-4" />
          Upload File
        </Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Upload File</DialogTitle>
        </DialogHeader>
        <div className="grid gap-4 py-4">
          <Input
            type="file"
            onChange={handleFileChange}
            disabled={isUploading}
          />
          <Button 
            onClick={handleUpload}
            disabled={!file || isUploading}
          >
            {isUploading ? "Uploading..." : "Upload"}
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  )
}
